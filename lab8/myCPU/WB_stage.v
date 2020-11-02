`include "mycpu.h"

module wb_stage(
    input                           clk           ,
    input                           reset         ,
    //allowin
    output                          ws_allowin    ,
    //from ms
    input                           ms_to_ws_valid,
    input  [`MS_TO_WS_BUS_WD -1:0]  ms_to_ws_bus  ,
    //to rf: for write back
    output [`WS_TO_RF_BUS_WD -1:0]  ws_to_rf_bus  ,
    //forward
    output [`FW_BUS_WD       -1:0]  ws_to_ds_fw_bus,
    output                          out_ws_valid,
    //trace debug interface
    output [31:0] debug_wb_pc     ,
    output [ 3:0] debug_wb_rf_wen ,
    output [ 4:0] debug_wb_rf_wnum,
    output [31:0] debug_wb_rf_wdata,
    //to cp0
    output [`WS_TO_CP0_BUS_WD-1:0] ws_to_cp0_bus    ,
    output                        ws_to_cp0_valid  
);

reg         ws_valid;
wire        ws_ready_go;
reg [`MS_TO_WS_BUS_WD -1:0] ms_to_ws_bus_r;
wire        ws_gr_we;
wire [ 4:0] ws_dest;
wire [31:0] ws_final_result;
wire [31:0] ws_pc;
wire [31:0] ws_rt_value;
wire [5:0]  padding_excp;
wire        inst_eret;
wire        inst_mtc0;
wire        inst_mfc0;

assign out_ws_valid = ws_valid;
assign {
        ws_rt_value     , //111:80
        cp0_addr        , //86:79
        inst_eret       , //78
        inst_mtc0       , //77
        inst_mfc0       , //76
        padding_excp    , //75:70
        ws_gr_we       ,  //69:69
        ws_dest        ,  //68:64
        ws_final_result,  //63:32
        ws_pc             //31:0
       } = ms_to_ws_bus_r;

//exception tag: add here
reg ws_excp_valid;
reg [6:2] ws_excp_execode;
always @(posedge clk) begin
    if(reset) begin
        ws_excp_valid   <=0;
        ws_excp_execode <=5'h00;
    end    
    else if(ms_to_ws_valid&&ms_to_ws_bus[75]) begin
        ws_excp_valid   <=1;
        ws_excp_execode <=ms_to_ws_bus[74:70];
    end
end
assign ws_to_cp0_valid = ws_excp_valid;
assign ws_to_cp0_bus = { ws_excp_execode,
                         ws_pc
};
//handle mtc0 & mfc0, using block to solve cp0 hazard
wire        mtc0_we;
wire [7:0]  cp0_addr;
wire [31:0] cp0_wdata;
assign mtc0_we  =   ws_valid && inst_mtc0 && !ws_excp_valid;
assign cp0_wdata=   ws_rt_value;

wire        rf_we;
wire [4 :0] rf_waddr;
wire [31:0] rf_wdata;
assign ws_to_rf_bus = {ws_valid,  //38:38
                       rf_we   ,  //37:37
                       rf_waddr,  //36:32
                       rf_wdata   //31:0
                      };
assign ws_to_ds_fw_bus = {rf_we,   //37:37
                        rf_waddr,  //36:32
                        rf_wdata   //31:0
                        };
assign ws_ready_go = 1'b1;
assign ws_allowin  = !ws_valid || ws_ready_go;
always @(posedge clk) begin
    if (reset) begin
        ws_valid <= 1'b0;
    end
    else if (ws_allowin) begin
        ws_valid <= ms_to_ws_valid;
    end

    if (ms_to_ws_valid && ws_allowin) begin
        ms_to_ws_bus_r <= ms_to_ws_bus;
    end
end

assign rf_we    = ws_gr_we&&ws_valid;
assign rf_waddr = ws_dest;
assign rf_wdata = ws_final_result;

// debug info generate
assign debug_wb_pc       = ws_pc;
assign debug_wb_rf_wen   = {4{rf_we}};
assign debug_wb_rf_wnum  = ws_dest;
assign debug_wb_rf_wdata = ws_final_result;
///TODO: ws_bd
reg     ws_bd;
assign ws_to_cp0_bus = {                            
                        cp0_addr,       //77:70
                        cp0_wdata,      //69:38
                        ws_excp_execode,//37:33
                        ws_pc,          //32:1
                        ws_bd           //0
};
endmodule
