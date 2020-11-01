`include "mycpu.h"

module mem_stage(
    input                          clk           ,
    input                          reset         ,
    //allowin
    input                          ws_allowin    ,
    output                         ms_allowin    ,
    //from es
    input                          es_to_ms_valid,
    input  [`ES_TO_MS_BUS_WD -1:0] es_to_ms_bus  ,
    //forward
    output [`FW_BUS_WD       -1:0] ms_to_ds_fw_bus,
    output                         out_ms_valid,
    //to ws
    output                         ms_to_ws_valid,
    output [`MS_TO_WS_BUS_WD -1:0] ms_to_ws_bus  ,
    //from data-sram
    input  [31                 :0] data_sram_rdata
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

assign out_ms_valid = ms_valid;
assign {ms_rt_value     ,//109:78
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

assign ms_to_ws_bus = {ms_gr_we       ,  //69:69
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
    if (reset) begin
        ms_valid <= 1'b0;
    end
    else if (ms_allowin) begin
        ms_valid <= es_to_ms_valid;
    end

    if (es_to_ms_valid && ms_allowin) begin
        es_to_ms_bus_r  <= es_to_ms_bus;
    end
end
assign mem_result = {32{ms_mem_op_h|ms_mem_op_hu|ms_mem_op_w|ms_mem_op_b|ms_mem_op_bu}}&ld_bhw_rdata |
                    {32{ms_mem_op_wr}}&ld_wr_rdata | {32{ms_mem_op_wl}}&ld_wl_rdata ;

assign ms_final_result = ms_res_from_mem ? mem_result
                                         : ms_alu_result;

endmodule
