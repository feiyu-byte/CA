`include "mycpu.h"

module mem_stage(
    input                          clk           ,
    input                          reset         ,
    //allowin
    input                          ws_allowin    ,
    output                         ms_allowin    ,
    output                         ms_excp_valid ,
    //from es
    input                          es_to_ms_valid,
    input  [`ES_TO_MS_BUS_WD -1:0] es_to_ms_bus  ,
    //forward
    output [`FW_BUS_WD       -1:0] ms_to_ds_fw_bus,
    output                         out_ms_valid,
    //to ws
    output                         ms_to_ws_valid,
    output [`MS_TO_WS_BUS_WD -1:0] ms_to_ws_bus  ,
    output                         ms_inst_eret,
    //from data-sram
    input                          data_sram_data_ok,
    input  [31                 :0] data_sram_rdata,
    //from cp0
    input  [`CP0_GENERAL_BUS_WD-1:0]cp0_general_bus
);

reg         ms_valid;
wire        ms_ready_go;

reg [`ES_TO_MS_BUS_WD -1:0] es_to_ms_bus_r;
wire        ms_res_from_mem;
wire        ms_gr_we;
wire [ 4:0] ms_dest;
wire [31:0] ms_alu_result;
wire [31:0] ms_pc;
wire        ms_mem_op_wl,ms_mem_op_wr,ms_mem_op_w,ms_mem_op_bu,ms_mem_op_b,ms_mem_op_hu,ms_mem_op_h;
wire        addr_offset0  ;
wire        addr_offset1  ;
wire        addr_offset2  ;
wire        addr_offset3  ;

wire [7:0]  load_byte     ;
wire [15:0] load_halfword ;
wire [31:0] ld_bhw_rdata  ;
wire [31:0] ld_wl_rdata   ;
wire [31:0] ld_wr_rdata   ;
wire [31:0] ms_rt_value   ;
assign ms_inst_eret = inst_eret;
assign load_byte = {8{addr_offset0}}&data_sram_rdata[7:0]   | {8{addr_offset1}}&data_sram_rdata[15:8] |
                   {8{addr_offset2}}&data_sram_rdata[23:16] | {8{addr_offset3}}&data_sram_rdata[31:24];
assign load_halfword  ={16{addr_offset0}}&data_sram_rdata[15:0] | {16{addr_offset2}}&data_sram_rdata[31:16];
assign ld_bhw_rdata   =   {32{ms_mem_op_b}}&{{24{load_byte[7]}},load_byte} | {32{ms_mem_op_bu}}&{24'b0,load_byte}
                        | {32{ms_mem_op_h}}&{{16{load_halfword[15]}},load_halfword} | {32{ms_mem_op_hu}}&{16'b0,load_halfword}
                        | {32{ms_mem_op_w}}&data_sram_rdata ;
assign ld_wl_rdata    = {32{addr_offset0}}&{data_sram_rdata[7:0],ms_rt_value[23:0]} | {32{addr_offset1}}&{data_sram_rdata[15:0],ms_rt_value[15:0]} |
                        {32{addr_offset2}}&{data_sram_rdata[23:0],ms_rt_value[7:0]} | {32{addr_offset3}}&data_sram_rdata ;
assign ld_wr_rdata    = {32{addr_offset0}}&data_sram_rdata| {32{addr_offset1}}&{ms_rt_value[31:24],data_sram_rdata[31:8]} |
                        {32{addr_offset2}}&{ms_rt_value[31:16],data_sram_rdata[31:16]} | {32{addr_offset3}}&{ms_rt_value[31:8],data_sram_rdata[31:24]} ;

assign addr_offset0   =(ms_alu_result[1:0] == 2'b00);
assign addr_offset1   =(ms_alu_result[1:0] == 2'b01);
assign addr_offset2   =(ms_alu_result[1:0] == 2'b10);
assign addr_offset3   =(ms_alu_result[1:0] == 2'b11);

//exception tag: add here
wire ms_excp_valid;
wire [6:2] ms_excp_execode;
wire [31:0]ms_excp_bvaddr;
wire [31:0]es_excp_bvaddr;
assign ms_excp_valid = 
                  (reset || cp0_status_EXL)     ? 1'h0   :
                  (es_excp_valid)               ? 1'h1   :
                  1'h0;
assign ms_excp_execode = 
                  (reset || cp0_status_EXL)     ? 5'h00             :
                  (es_excp_valid)               ? es_excp_execode   :
                  5'h00;
assign ms_excp_bvaddr = es_excp_bvaddr;
wire       es_bd;
wire       es_excp_valid;
wire [4:0] es_excp_execode;
assign out_ms_valid = ms_valid;
assign {
        es_excp_bvaddr  ,//159:128
        es_bd           ,//127
        cp0_dest        ,//126:119
        inst_eret       ,//118
        inst_mtc0       ,//117
        inst_mfc0       ,//116
        es_excp_valid   ,//115
        es_excp_execode ,//114:110
        ms_rt_value     ,//109:78
        ms_mem_op_wl    ,//77
        ms_mem_op_wr    ,//76
        ms_mem_op_w     ,//75
        ms_mem_op_bu    ,//74
        ms_mem_op_b     ,//73
        ms_mem_op_hu    ,//72
        ms_mem_op_h     ,//71
        ms_res_from_mem,  //70:70
        ms_gr_we       ,  //69:69
        ms_dest        ,  //68:64
        ms_alu_result  ,  //63:32
        ms_pc             //31:0
       } = es_to_ms_bus_r;

wire [31:0] mem_result;
wire [31:0] ms_final_result;

wire [7:0]  cp0_dest;
wire        inst_eret;
wire        inst_mfc0;
wire        inst_mtc0;
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

assign ms_to_ws_bus = { 
                        ms_excp_bvaddr  , //151:120
                        ms_bd           , //119
                        ms_rt_value     , //118:87
                        cp0_dest        , //86:79
                        inst_eret       , //78
                        inst_mtc0       , //77
                        inst_mfc0       , //76
                        ms_excp_valid  ,  //75
                        ms_excp_execode,  //74:70
                        ms_gr_we       ,  //69:69
                        ms_dest        ,  //68:64
                        ms_final_result,  //63:32
                        ms_pc             //31:0
                      };
assign ms_to_ds_fw_bus ={ms_gr_we,      //37:37
                        ms_dest,        //36:32
                        ms_final_result  //31:0
                        };
assign ms_ready_go    = 1'b1;
assign ms_allowin     = !ms_valid || ms_ready_go && ws_allowin;
assign ms_to_ws_valid = ms_valid && ms_ready_go;
always @(posedge clk) begin
    if (reset || eret_flush) begin
        ms_valid <= 1'b0;
    end
    else if (ms_allowin && es_to_ms_valid) begin
        ms_valid <= es_to_ms_valid;
    end
    else if(!es_to_ms_valid)
        ms_valid <= 1'b0;

    if (es_to_ms_valid && ms_allowin) begin
        es_to_ms_bus_r  <= es_to_ms_bus;
    end
end
assign mem_result = {32{ms_mem_op_h|ms_mem_op_hu|ms_mem_op_w|ms_mem_op_b|ms_mem_op_bu}}&ld_bhw_rdata |
                    {32{ms_mem_op_wr}}&ld_wr_rdata | {32{ms_mem_op_wl}}&ld_wl_rdata ;

assign ms_final_result =    ms_res_from_mem ? mem_result
                                         : ms_alu_result;

wire ms_bd;
assign ms_bd = (reset)  ?   1'b0:es_bd;
endmodule
