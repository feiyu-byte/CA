`include "mycpu.h"

module if_stage(
    input                          clk            ,
    input                          reset          ,
    //allwoin
    input                          ds_allowin     ,
    //brbus
    input  [`BR_BUS_WD       -1:0] br_bus         ,
    input                          out_ws_valid,
    //to ds
    output                         fs_to_ds_valid ,
    output [`FS_TO_DS_BUS_WD -1:0] fs_to_ds_bus   ,
    //from cp0
    input  [`CP0_GENERAL_BUS_WD-1:0]    cp0_general_bus,
    input  [31:0]                       cp0_EPC_bus,
    input                               go_excp_entry,
    input                               go_tlb_refill,
    // TLB search interface
    output [18:0]                       vpn2,
    output                              odd_page,
    input                               s0_found,
    input                               s0_v,
    input  [19:0]                       pfn,
    input                               tlb_refetch,
    input  [31:0]                       refetch_addr,
    // inst sram interface
    output                              inst_sram_req,
    output                              inst_sram_wr,
    output [ 1:0]                       inst_sram_size,
    output [ 3:0]                       inst_sram_wstrb,
    output [31:0]                       inst_sram_addr,
    output [31:0]                       inst_sram_wdata,
    input                               inst_sram_addr_ok,
    input                               inst_sram_data_ok,
    input  [31:0]                       inst_sram_rdata
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
reg          go_excp_entry_r;
reg          go_tlb_refill_r;
wire         tlb_refill;
wire         tlb_invalid;
always @(posedge clk ) begin
    if (reset) begin
        go_excp_entry_r <= 0;
    end
    else if (go_excp_entry) begin
        go_excp_entry_r <= 1 ;
    end
    else if (go_excp_entry_r && fs_valid)begin
        go_excp_entry_r <= 0;
    end
end
reg          go_tlb_refill_r;
always @(posedge clk ) begin
    if (reset) begin
        // reset
        go_tlb_refill_r<=0;
    end
    else if (go_tlb_refill) begin
        go_tlb_refill_r<= 1;
    end
    else if (go_tlb_refill_r && fs_valid) begin
        go_tlb_refill_r <= 0;
    end
end
reg [`BR_BUS_WD       -1:0] br_bus_r;
reg br_bus_valid;
reg bd_done;
always @(posedge clk ) begin
	if (reset) begin
		br_bus_valid <= 1'b0;
	end
    else if (make_bd) begin
        br_bus_valid <= 1'b1;
    end
	else if (to_fs_ready_go&fs_allowin&bd_done|cancel) begin
		br_bus_valid <= 1'b0;
	end
	
end
always @(posedge clk) begin
    if (reset) begin
        // reset
        br_bus_r <= 0;
    end
    else if (make_bd || !make_bd&&(br_stall_r==0 && br_stall)) begin
        br_bus_r <= br_bus;        
    end
    else if (!br_bus_valid & inst_sram_data_ok) begin
        br_bus_r <= 0;
    end
end
always @(posedge clk) begin
    if (reset) begin
        bd_done <= 1'b0;
    end
    else if (br_bus_valid&fs_valid) begin
        bd_done <= 1'b1;
    end
    else if (make_bd)begin
        bd_done <= 1'b0;
    end
end
reg br_stall_r;
always @(posedge clk ) begin
    if (reset) begin
        // reset
        br_stall_r <= 1'b0;
    end
    else if (make_bd ) begin
        br_stall_r <= br_stall;
    end
    else if (br_stall_r==0 && br_stall) begin
        br_stall_r <= br_stall;
    end
end
assign {make_bd,br_stall,br_taken,br_target} =br_bus;
//exception tag: add here
wire       fs_excp_valid;
wire [6:2] fs_excp_execode;
wire [31:0]fs_excp_bvaddr;
wire       unalgn_inst_load_op;
assign     unalgn_inst_load_op = fs_pc[1:0]!=2'b0;
wire       fs_tlbl;
assign fs_tlbl = tlb_refill || tlb_invalid;
assign tlb_refill = !s0_found && mapped;
assign tlb_invalid = s0_found && !s0_v && mapped;
//exception cause: add here
assign fs_excp_valid = 
                  (reset || cp0_status_EXL)     ? 1'h0   :
                  (unalgn_inst_load_op)         ? 1'h1   :
                  (fs_tlbl)                     ? 1'h1 :1'h0;
assign fs_excp_execode = 
                  (reset || cp0_status_EXL)     ? 5'h00  :
                  (unalgn_inst_load_op)         ? `EX_ADEL  :
                  (fs_tlbl)                     ? `EX_TLBL  :
                  5'h00;
assign fs_excp_bvaddr = (fs_tlbl)?nextpc:fs_pc;

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
assign fs_to_ds_bus = { fs_tlbl,//137
                        tlb_refill,//136
                        fs_valid,//135
                        nextpc,//134:103
                        fs_excp_bvaddr, //102:71
                        fs_bd,          //70
                        fs_excp_valid,  //69
                        fs_excp_execode,//68:64
                        fs_inst ,       //63:32
                        fs_pc   };      //31:0
wire to_fs_ready_go;
// pre-IF stage
assign to_fs_ready_go = inst_sram_req && inst_sram_addr_ok;
assign to_fs_valid  = ~reset;
assign seq_pc       = fs_pc + 3'h4;
assign nextpc       = /*(reset)?seq_pc:(go_tlb_refill)? 32'hbfc00200 : (go_excp_entry)?32'hbfc00380:*/(br_bus_r[32]&br_bus_r[33]&!(make_bd&!fs_valid)&bd_done&br_bus_valid&!cancel) ? br_bus_r[31:0] :seq_pc; 

// IF stage
assign fs_ready_go    = 
    inst_sram_data_ok
|   inst_valid
; 
//& !(br_bus_valid & !to_fs_ready_go);
assign fs_allowin     = !fs_valid|| fs_ready_go && ds_allowin;
assign fs_to_ds_valid =  fs_ready_go && fs_valid;
always @(posedge clk) begin
    if (reset || eret_flush || tlb_refetch) begin
        fs_valid <= 1'b0;
    end
    else if (go_excp_entry_r&&fs_valid || go_tlb_refill_r && fs_valid) begin
        fs_valid <= 0;
    end
    else if (to_fs_ready_go && fs_allowin) begin
        fs_valid <= to_fs_valid;
    end
    else if(ds_allowin && fs_ready_go )
        fs_valid <= 1'b0;

    if (reset) begin
        fs_pc <= 32'hbfbffffc;  //trick: to make nextpc be 0xbfc00000 during reset 
    end
    else if (go_tlb_refill_r && fs_valid) begin
        fs_pc <= 32'hbfc00200 - 32'h4; 
    end
    else if(go_excp_entry_r && fs_valid) begin
        fs_pc <= 32'hbfc0037c;  //0xbfc00380
    end
    else if(eret_flush) begin
        fs_pc <= cp0_EPC_bus-32'h4;
    end
    else if(tlb_refetch) begin
        fs_pc <= refetch_addr-32'h4;
    end
    else if (to_fs_valid && fs_allowin && to_fs_ready_go) begin
        fs_pc <= nextpc;
    end
end
//TLB interface
assign vpn2 = nextpc[31:13];
assign odd_page = nextpc[12];
wire mapped;
assign mapped = (nextpc[31:30] == 2'b00 || nextpc[31:30] == 2'b11 );
//assign inst_sram_en    = to_fs_valid && fs_allowin && br_stall;
reg req_flag;
always @(posedge clk) begin
    if(reset)
        req_flag <=1'b0;
    else if (inst_sram_data_ok)
        req_flag <= 1'b0;
    else if (inst_sram_addr_ok && inst_sram_req) begin
        req_flag <= 1'b1;
    end
end
assign inst_sram_req = 
    to_fs_valid 
&   fs_allowin 
&   !req_flag 
&   !fs_excp_valid
;
assign inst_sram_addr  = (mapped) ? {pfn,nextpc[11:2],2'b0} : {nextpc[31:2],2'b0};
assign inst_sram_wr = 1'b0;
assign inst_sram_size = 2'h2;
assign inst_sram_wstrb = 4'h0;
assign inst_sram_wdata = 32'h0;
reg [31:0] inst_r;
reg 	   inst_valid;
always @(posedge clk ) begin
	if (reset) begin
		inst_r <= 32'h0;
	end
	else if (inst_sram_data_ok) begin
		inst_r <= inst_sram_rdata;
	end
end
always @(posedge clk ) begin
	if (reset) begin
		inst_valid <= 1'b0;
	end
    else if (to_fs_valid && fs_allowin && to_fs_ready_go) begin
        inst_valid <= 1'b0;
    end
	else if (inst_sram_data_ok) begin
		inst_valid <= 1'b1;
	end
end
reg cancel;
always @(posedge clk ) begin
	if (reset) begin
		cancel <= 1'b0;		
	end
	else if (eret_flush & (to_fs_valid | !fs_ready_go & !fs_allowin)) begin
		cancel <= 1'b1;
	end
	else if (inst_sram_data_ok) begin
		cancel <= 1'b0;
	end
end
assign fs_inst         = (inst_valid)?inst_r:inst_sram_rdata;

wire     fs_bd;
assign fs_bd = (reset)  ?   1'b0:(!br_bus_valid)?make_bd:br_bus_r[33];
endmodule
