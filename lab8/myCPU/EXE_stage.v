`include "mycpu.h"

module exe_stage(
    input                          clk           ,
    input                          reset         ,
    //allowin
    input                          ms_allowin    ,
    output                         es_allowin    ,
    output                         es_excp_valid ,
    //from ds
    input                          ds_to_es_valid,
    input  [`DS_TO_ES_BUS_WD -1:0] ds_to_es_bus  ,
    //to ms
    output                         es_to_ms_valid,
    output [`ES_TO_MS_BUS_WD -1:0] es_to_ms_bus  ,
    //forward
    output [`FW_BUS_WD       -1:0] es_to_ds_fw_bus,
    output                         out_es_valid,
    //from cp0
    input  [`CP0_GENERAL_BUS_WD-1:0]cp0_general_bus,
    // data sram interface
    output        data_sram_en   ,
    output [ 3:0] data_sram_wen  ,
    output [31:0] data_sram_addr ,
    output [31:0] data_sram_wdata
);

reg         es_valid      ;
wire        es_ready_go   ;

reg  [`DS_TO_ES_BUS_WD -1:0] ds_to_es_bus_r;
wire [11:0] es_alu_op     ;
wire        es_load_op    ;
wire        es_src1_is_sa ;  
wire        es_src1_is_pc ;
wire        es_src2_is_imm; 
wire        es_src2_is_8  ;
wire        es_gr_we      ;
wire        es_mem_we     ;
wire        es_zero_extend_imm;
wire [ 4:0] es_dest       ;
wire [15:0] es_imm        ;
wire [31:0] es_rs_value   ;
wire [31:0] es_rt_value   ;
wire [31:0] es_pc         ;
wire        es_mul_sel    ;
wire [1:0]  es_div_sel    ;
wire [31:0] es_hi         ;
wire [31:0] es_lo         ;
wire es_mtlo,es_mthi,es_mflo,es_mfhi;

wire es_mem_op_w          ;
wire es_mem_op_wl         ;
wire es_mem_op_wr         ;
wire es_mem_op_bu         ;
wire es_mem_op_b          ;
wire es_mem_op_hu         ;
wire es_mem_op_h          ;
wire        ds_bd;
wire        ds_excp_valid;
wire [4:0]  ds_excp_execode;
wire        inst_eret;
wire        inst_mtc0;
wire        inst_mfc0;
assign out_es_valid = es_valid;
assign {
        ds_excp_bvaddr  ,//264:233
        ds_bd           ,//232
        cp0_dest        ,//231:224
        inst_eret       ,//223
        inst_mtc0       ,//222
        inst_mfc0       ,//221
        ds_excp_valid   ,//220
        ds_excp_execode ,//219:215
        es_mem_op_wl    ,//214
        es_mem_op_wr    ,//213
        es_mem_op_w     ,//212
        es_mem_op_bu    ,//211
        es_mem_op_b     ,//210
        es_mem_op_hu    ,//209
        es_mem_op_h     ,//208
        es_mthi         ,//207
        es_mtlo         ,//206
        es_mfhi         ,//205
        es_mflo         ,//204
        es_mul_sel        ,//203:203
        es_div_sel        ,//202:201
        es_hi             ,//200:169
        es_lo             ,//168:137
        es_zero_extend_imm,//136
        es_alu_op      ,  //135:124
        es_load_op     ,  //123:123
        es_src1_is_sa  ,  //122:122
        es_src1_is_pc  ,  //121:121
        es_src2_is_imm ,  //120:120
        es_src2_is_8   ,  //119:119
        es_gr_we       ,  //118:118
        es_mem_we      ,  //117:117
        es_dest        ,  //116:112
        es_imm         ,  //111:96
        es_rs_value    ,  //95 :64
        es_rt_value    ,  //63 :32
        es_pc             //31 :0
       } = ds_to_es_bus_r;

wire [31:0] es_alu_src1   ;
wire [31:0] es_alu_src2   ;
wire [31:0] es_alu_result ;

wire        es_res_from_mem;
wire [31:0] es_result     ;
wire [31:0] hi,lo;
wire        addr_offset0  ;
wire        addr_offset1  ;
wire        addr_offset2  ;
wire        addr_offset3  ;
wire [31:0] st_bhw_wdata   ;
wire [31:0] st_wl_wdata   ;
wire [31:0] st_wr_wdata   ;
wire [3:0]  sb_wen        ;
wire [3:0]  sh_wen        ;
wire [3:0]  swl_wen       ;
wire [3:0]  swr_wen       ;

//exception tag: add here
wire [7:0]  cp0_dest;
wire       es_excp_valid;
wire [6:2] es_excp_execode;
wire [31:0]ds_excp_bvaddr;
wire [31:0]es_excp_bvaddr;
assign es_excp_valid = 
                  (reset || cp0_status_EXL)     ? 1'h0   :
                  (ds_excp_valid)               ? 1'h1   :
                  (unalgn_load_op || unalgn_mem_we || overflow)? 1'h1:1'h0;
assign es_excp_execode = 
                  (reset || cp0_status_EXL)     ? 5'h00             :
                  (ds_excp_valid)               ? ds_excp_execode   :
                  (unalgn_load_op)              ? 5'h04             :
                  (unalgn_mem_we)               ? 5'h05             :
                  (overflow)                    ? 5'h0c             :
                  5'h00;
assign es_excp_bvaddr = 
                  (ds_excp_valid)                   ? ds_excp_bvaddr    :
                  (unalgn_load_op || unalgn_mem_we) ? data_sram_addr    :
                  32'b0;
//TODO: unalgn_load_op\unalgn_mem_we\overflow

//assign es_excp_valid = !(reset || cp0_status_EXL) && (ds_to_es_valid && es_allowin) && ds_excp_valid;
//assign es_excp_execode = {5{ds_to_es_valid && es_allowin}} & ds_excp_execode |
//                         {5{0}} & 5'b0;
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

assign es_res_from_mem = es_load_op;
assign es_result = {32{es_mfhi}}&hi | {32{es_mflo}}&lo | es_alu_result;
assign es_to_ms_bus = { 
                        es_excp_bvaddr  ,//159:128
                        es_bd           ,//127
                        cp0_dest        ,//126:119
                        inst_eret       ,//118
                        inst_mtc0       ,//117
                        inst_mfc0       ,//116
                        es_excp_valid   ,//115
                        es_excp_execode ,//114:110
                        es_rt_value     ,//109:78
                        es_mem_op_wl    ,//77
                        es_mem_op_wr    ,//76
                        es_mem_op_w     ,//75
                        es_mem_op_bu    ,//74
                        es_mem_op_b     ,//73
                        es_mem_op_hu    ,//72
                        es_mem_op_h     ,//71
                        es_res_from_mem,  //70:70
                        es_gr_we       ,  //69:69
                        es_dest        ,  //68:64
                        es_result      ,  //63:32
                        es_pc             //31:0
                      };
assign es_to_ds_fw_bus = {es_gr_we    ,  //37:37
                          es_dest     ,  //36:32
                          es_result      //31:0
                         };
assign es_ready_go    = ~(es_div_sel[1]&~signed_dout_tvalid | es_div_sel[0]&~unsigned_dout_tvalid);
assign es_allowin     = !es_valid || es_ready_go && ms_allowin;
assign es_to_ms_valid =  es_valid && es_ready_go;
always @(posedge clk) begin
    if (reset || eret_flush ) begin
        es_valid <= 1'b0;
    end
    else if (es_allowin) begin
        es_valid <= ds_to_es_valid;
    end

    if (ds_to_es_valid && es_allowin) begin
        ds_to_es_bus_r <= ds_to_es_bus;
    end
end

assign es_alu_src1  = es_src1_is_sa  ? {27'b0, es_imm[10:6]} : 
                      es_src1_is_pc  ? es_pc[31:0] :
                                      es_rs_value;
assign es_alu_src2  = es_src2_is_imm ? (es_zero_extend_imm ? {{16{1'b0}},es_imm[15:0]} :{{16{es_imm[15]}}, es_imm[15:0]} ): 
                     (es_src2_is_8   ? 32'd8 :
                                      es_rt_value);
assign addr_offset0 =(es_alu_result[1:0] == 2'b00);
assign addr_offset1 =(es_alu_result[1:0] == 2'b01);
assign addr_offset2 =(es_alu_result[1:0] == 2'b10);
assign addr_offset3 =(es_alu_result[1:0] == 2'b11);

assign st_bhw_wdata = es_mem_op_b ? {4{es_rt_value[7:0]}} : 
                      es_mem_op_h ? {2{es_rt_value[15:0]}} :
                                    es_rt_value;

assign {st_wr_wdata[7:0],st_wr_wdata[15:8],st_wr_wdata[23:16],st_wr_wdata[31:24]} = {es_rt_value[7:0],
                      {8{addr_offset1}}&es_rt_value[7:0] | {8{addr_offset0}}&es_rt_value[15:8],
                      {8{addr_offset2}}&es_rt_value[7:0] | {8{addr_offset1}}&es_rt_value[15:8] | {8{addr_offset0}}&es_rt_value[23:16],
                      {8{addr_offset3}}&es_rt_value[7:0] | {8{addr_offset2}}&es_rt_value[15:8] | {8{addr_offset1}}&es_rt_value[23:16] | {8{addr_offset0}}&es_rt_value[31:24]
                     };
assign {st_wl_wdata[7:0],st_wl_wdata[15:8],st_wl_wdata[23:16],st_wl_wdata[31:24]} = 
                    { {8{addr_offset3}}&es_rt_value[7:0] | {8{addr_offset2}}&es_rt_value[15:8] | {8{addr_offset1}}&es_rt_value[23:16] | {8{addr_offset0}}&es_rt_value[31:24],
                      {8{addr_offset3}}&es_rt_value[15:8] | {8{addr_offset2}}&es_rt_value[23:16] | {8{addr_offset1}}&es_rt_value[31:24],
                      {8{addr_offset3}}&es_rt_value[23:16] | {8{addr_offset2}}&es_rt_value[31:24],
                      es_rt_value[31:24]
                     };
assign sb_wen  = {addr_offset3,addr_offset2,addr_offset1,addr_offset0};
assign sh_wen  = {addr_offset2,addr_offset2,addr_offset0,addr_offset0};
assign {swr_wen[0],swr_wen[1],swr_wen[2],swr_wen[3]} = {addr_offset0,addr_offset0|addr_offset1,addr_offset0|addr_offset1|addr_offset2,1'b1};
assign {swl_wen[0],swl_wen[1],swl_wen[2],swl_wen[3]} = {1'b1,addr_offset1|addr_offset2|addr_offset3,addr_offset2|addr_offset3,addr_offset3};
alu u_alu(
    .alu_op     (es_alu_op    ),
    .alu_src1   (es_alu_src1  ),//2 --> 1 little bug
    .alu_src2   (es_alu_src2  ),
    .alu_result (es_alu_result)
    );

assign data_sram_en    = 1'b1;
assign data_sram_wen   = {4{es_mem_we&&es_valid}}&({4{es_mem_op_b}}&sb_wen | {4{es_mem_op_h}}&sh_wen | {4{es_mem_op_wr}}&swr_wen | {4{es_mem_op_wl}}&swl_wen | {4{es_mem_op_w}}) ;
assign data_sram_addr  = es_alu_result;
assign data_sram_wdata = {32{es_mem_op_b|es_mem_op_h|es_mem_op_w}}&st_bhw_wdata | {32{es_mem_op_wr}}&st_wr_wdata | {32{es_mem_op_wl}}&st_wl_wdata;

wire [31:0] signed_divisor_tdata,signed_dividend_tdata;
wire [31:0] unsigned_divisor_tdata,unsigned_dividend_tdata;
wire [63:0] signed_dout_tdata,unsigned_dout_tdata;
wire signed_dividend_tready,unsigned_dividend_tready;
wire signed_divisor_tready,unsigned_divisor_tready;
reg  signed_dividend_tvalid,unsigned_dividend_tvalid;
reg  signed_divisor_tvalid,unsigned_divisor_tvalid;
wire signed_dout_tvalid,unsigned_dout_tvalid;

wire [31:0] signed_quotient,signed_remainder;
wire [31:0] unsigned_quotient,unsigned_remainder;
wire hi_we,lo_we;
wire [31:0] hi_wdata,lo_wdata;
reg div_en;

always @(posedge clk ) begin
  if (reset) begin
    // reset
    div_en <= 1'b1;
  end
  else if (es_div_sel[1]|es_div_sel[0]) begin
    div_en <= 1'b0;
  end
  else begin
    div_en <= 1'b1;
  end
end
mydiv u_mydiv(
    .aclk(clk),
    .s_axis_divisor_tdata(signed_divisor_tdata),
    .s_axis_divisor_tready(signed_divisor_tready),
    .s_axis_divisor_tvalid(signed_divisor_tvalid),
    //dividend
    .s_axis_dividend_tdata(signed_dividend_tdata),
    .s_axis_dividend_tready(signed_dividend_tready),
    .s_axis_dividend_tvalid(signed_dividend_tvalid),
    //out
    .m_axis_dout_tdata(signed_dout_tdata),
    .m_axis_dout_tvalid(signed_dout_tvalid)
    );
assign signed_divisor_tdata = es_rt_value ;
assign signed_dividend_tdata = es_rs_value;
always @(posedge clk ) begin
  if (reset) begin
      signed_dividend_tvalid <= 1'b0;
      signed_divisor_tvalid <= 1'b0;
  end
  else if (es_div_sel[1]&div_en) begin
      signed_dividend_tvalid <= 1'b1;
      signed_divisor_tvalid <= 1'b1;
  end
  else if (signed_dividend_tready) begin
      signed_dividend_tvalid <= 1'b0;
      signed_divisor_tvalid <= 1'b0;
  end
end

assign signed_quotient = signed_dout_tdata[63:32];
assign signed_remainder = signed_dout_tdata[31:0];
mydivu u_mydivu(
    .aclk(clk),
    .s_axis_divisor_tdata(unsigned_divisor_tdata),
    .s_axis_divisor_tready(unsigned_divisor_tready),
    .s_axis_divisor_tvalid(unsigned_divisor_tvalid),
    .s_axis_dividend_tdata(unsigned_dividend_tdata),
    .s_axis_dividend_tready(unsigned_dividend_tready),
    .s_axis_dividend_tvalid(unsigned_dividend_tvalid),
    .m_axis_dout_tdata(unsigned_dout_tdata),
    .m_axis_dout_tvalid(unsigned_dout_tvalid)
    );
assign unsigned_divisor_tdata = es_rt_value ;
assign unsigned_dividend_tdata = es_rs_value ;
always @(posedge clk ) begin
  if (reset) begin
      unsigned_dividend_tvalid <= 1'b0;
      unsigned_divisor_tvalid <= 1'b0;
  end
  else if (es_div_sel[0]&div_en) begin
      unsigned_dividend_tvalid <= 1'b1;
      unsigned_divisor_tvalid <= 1'b1;
  end
  else if (unsigned_dividend_tready)begin
      unsigned_dividend_tvalid <= 1'b0;
      unsigned_divisor_tvalid <= 1'b0;
  end
end

assign unsigned_quotient = unsigned_dout_tdata[63:32];
assign unsigned_remainder = unsigned_dout_tdata[31:0];


assign lo_wdata = {32{es_mul_sel}}&es_lo | {32{es_div_sel[1]}}&signed_quotient | 
				  {32{es_div_sel[0]}}&unsigned_quotient | {32{es_mtlo}}&es_rs_value ;
assign hi_wdata = {32{es_mul_sel}}&es_hi | {32{es_div_sel[1]}}&signed_remainder | 
				  {32{es_div_sel[0]}}&unsigned_remainder | {32{es_mthi}}&es_rs_value ;
assign hi_we = es_valid&(es_mul_sel|es_div_sel[1]|es_div_sel[0]|es_mthi);
assign lo_we = es_valid&(es_mul_sel|es_div_sel[1]|es_div_sel[0]|es_mtlo);

HI_LO u_HI_LO(
	.clk(clk),
	.reset(reset),
	.hi_we(hi_we),
	.lo_we(lo_we),
	.hi_wdata(hi_wdata),
	.lo_wdata(lo_wdata),
	.hi(hi),
	.lo(lo)
	);
wire es_bd;
assign es_bd = (reset)  ?   1'b0:ds_bd;
endmodule



module HI_LO(
	input 				clk		,
	input				reset	,
	input 				hi_we	,
	input 				lo_we	,
	input      [31:0]	hi_wdata,
	input      [31:0]	lo_wdata,
	output reg [31:0]	hi,
	output reg [31:0]   lo
	);

always @(posedge clk) begin
    if (reset) begin
        hi <= 32'b0;
    end
    else if (hi_we) begin
        hi <= hi_wdata;
    end
    
end

always @(posedge clk) begin
    if (reset) begin
        lo <= 32'b0;
    end
    else if (lo_we) begin
        lo <= lo_wdata;
    end
    
end
endmodule
