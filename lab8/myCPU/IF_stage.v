`include "mycpu.h"

module if_stage(
    input                          clk            ,
    input                          reset          ,
    //allwoin
    input                          ds_allowin     ,
    //brbus
    input  [`BR_BUS_WD       -1:0] br_bus         ,
    //to ds
    output                         fs_to_ds_valid ,
    output [`FS_TO_DS_BUS_WD -1:0] fs_to_ds_bus   ,
    //from cp0
    input  [`CP0_GENERAL_BUS_WD-1:0]    cp0_general_bus,
    input  [31:0]                       cp0_EPC_bus,
    input                               go_excp_entry,
    // inst sram interface
    output        inst_sram_en   ,
    output [ 3:0] inst_sram_wen  ,
    output [31:0] inst_sram_addr ,
    output [31:0] inst_sram_wdata,
    input  [31:0] inst_sram_rdata
);

reg         fs_valid;
wire        fs_ready_go;
wire        fs_allowin;
wire        to_fs_valid;

wire [31:0] seq_pc;
wire [31:0] nextpc;

wire         make_bd;
wire         br_taken;
wire [ 31:0] br_target;
wire         br_stall;
assign {make_bd,br_stall,br_taken,br_target} = br_bus;

//exception tag: add here
wire       fs_excp_valid;
wire [6:2] fs_excp_execode;
//exception cause: add here
assign fs_excp_valid = 
                  (reset || cp0_status_EXL)     ? 1'h0   :
                  1'h0;
assign fs_excp_execode = 
                  (reset || cp0_status_EXL) ? 5'h00             :
                  5'h00;

wire        eret_flush;
wire [7:0]  cp0_status_IM;
wire        cp0_status_EXL;
wire        cp0_status_IE;
assign {
        eret_flush,     //10
        cp0_status_IM,  //9:2
        cp0_status_EXL, //1
        cp0_status_IE   //0
} = cp0_general_bus;

wire [31:0] fs_inst;
reg  [31:0] fs_pc;
assign fs_to_ds_bus = { fs_bd,          //70
                        fs_excp_valid,  //69
                        fs_excp_execode,//68:64
                        fs_inst ,       //63:32
                        fs_pc   };      //31:0

// pre-IF stage
assign to_fs_valid  = ~reset;
assign seq_pc       = fs_pc + 3'h4;
assign nextpc       = (br_taken&br_stall) ? br_target : seq_pc; 

// IF stage
assign fs_ready_go    = 1'b1;
assign fs_allowin     = !fs_valid || fs_ready_go && ds_allowin;
assign fs_to_ds_valid =  fs_valid && fs_ready_go;
always @(posedge clk) begin
    if (reset || eret_flush) begin
        fs_valid <= 1'b0;
    end
    else if (fs_allowin) begin
        fs_valid <= to_fs_valid;
    end

    if (reset) begin
        fs_pc <= 32'hbfbffffc;  //trick: to make nextpc be 0xbfc00000 during reset 
    end
    else if(go_excp_entry) begin
        fs_pc <= 32'hbfc0037c;  //0xbfc00380
    end
    else if(eret_flush) begin
        fs_pc <= cp0_EPC_bus;
    end
    else if (to_fs_valid && fs_allowin) begin
        fs_pc <= nextpc;
    end
end

assign inst_sram_en    = to_fs_valid && fs_allowin && br_stall;
assign inst_sram_wen   = 4'h0;
assign inst_sram_addr  = nextpc;
assign inst_sram_wdata = 32'b0;

assign fs_inst         = inst_sram_rdata;

wire     fs_bd;
assign fs_bd = (reset)  ?   1'b0:
               (make_bd)?   1'b1:
               1'b0;
endmodule
