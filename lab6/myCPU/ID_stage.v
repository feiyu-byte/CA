`include "mycpu.h"

module id_stage(
    input                          clk           ,
    input                          reset         ,
    //allowin
    input                          es_allowin    ,
    output                         ds_allowin    ,
    //from fs
    input                          fs_to_ds_valid,
    input  [`FS_TO_DS_BUS_WD -1:0] fs_to_ds_bus  ,
    //for block
    input  [`ES_TO_MS_BUS_WD -1:0] es_to_ms_bus,
    input  [`MS_TO_WS_BUS_WD -1:0] ms_to_ws_bus,
    input                          es_to_ms_valid,
    input                          ms_to_ws_valid,
    //for forward
    input  [`FW_BUS_WD       -1:0] es_to_ds_fw_bus,
    input  [`FW_BUS_WD       -1:0] ms_to_ds_fw_bus,
    input  [`FW_BUS_WD       -1:0] ws_to_ds_fw_bus,
    input                          out_es_valid,
    input                          out_ms_valid,
    input                          out_ws_valid,
    //to es
    output                         ds_to_es_valid,
    output [`DS_TO_ES_BUS_WD -1:0] ds_to_es_bus  ,
    //to fs
    output [`BR_BUS_WD       -1:0] br_bus        ,
    //to rf: for write back
    input  [`WS_TO_RF_BUS_WD -1:0] ws_to_rf_bus
);
//wire        block,r1_block,r2_block;
reg         ds_valid   ;
wire        ds_ready_go;

wire [31                 :0] fs_pc;
reg  [`FS_TO_DS_BUS_WD -1:0] fs_to_ds_bus_r;
assign fs_pc = fs_to_ds_bus[31:0];

wire [31:0] ds_inst;
wire [31:0] ds_pc  ;
assign {ds_inst,
        ds_pc  } = fs_to_ds_bus_r;

wire        rf_we   ;
wire [ 4:0] rf_waddr;
wire [31:0] rf_wdata;
assign {rf_we   ,  //37:37
        rf_waddr,  //36:32
        rf_wdata   //31:0
       } = ws_to_rf_bus;

wire        br_taken;
wire [31:0] br_target;

wire [11:0] alu_op;
wire        load_op;
wire        src1_is_sa;
wire        src1_is_pc;
wire        src2_is_imm;
wire        src2_is_8;
wire        res_from_mem;
wire        gr_we;
wire        mem_we;
wire 		zero_extend_imm;
wire [ 4:0] dest;
wire [15:0] imm;
wire [31:0] rs_value;
wire [31:0] rt_value;

wire [ 5:0] op;
wire [ 4:0] rs;
wire [ 4:0] rt;
wire [ 4:0] rd;
wire [ 4:0] sa;
wire [ 5:0] func;
wire [25:0] jidx;
wire [63:0] op_d;
wire [31:0] rs_d;
wire [31:0] rt_d;
wire [31:0] rd_d;
wire [31:0] sa_d;
wire [63:0] func_d;

wire        inst_addu;
wire        inst_subu;
wire        inst_slt;
wire        inst_sltu;
wire        inst_and;
wire        inst_or;
wire        inst_xor;
wire        inst_nor;
wire        inst_sll;
wire        inst_srl;
wire        inst_sra;
wire        inst_addiu;
wire        inst_lui;
wire        inst_lw;
wire        inst_sw;
wire        inst_beq;
wire        inst_bne;
wire        inst_jal;
wire        inst_jr;

//lab6 added
wire 		inst_add;
wire 		inst_addi;
wire 		inst_sub;
wire 		inst_slti;
wire  		inst_sltiu;
wire 		inst_andi;
wire 		inst_ori;
wire  		inst_xori;
wire 		inst_sllv;
wire 		inst_srlv;
wire 		inst_srav;
wire 		inst_mult;
wire 		inst_multu;
wire 		inst_div;
wire 		inst_divu;
wire 		inst_mfhi;
wire 		inst_mflo;
wire 		inst_mthi;
wire 		inst_mtlo;

wire        dst_is_r31;  
wire        dst_is_rt;   

wire [ 4:0] rf_raddr1;
wire [31:0] rf_rdata1;
wire [ 4:0] rf_raddr2;
wire [31:0] rf_rdata2;

wire        rs_eq_rt;
wire        br_stall;
wire        mul_sel;
wire [1:0]	div_sel;
wire [31:0] ds_hi,ds_lo;
assign br_stall = ds_ready_go;
assign br_bus       = {br_stall,br_taken,br_target};

assign ds_to_es_bus = {inst_mthi   ,//207
					   inst_mtlo   ,//206
					   inst_mfhi   ,//205
					   inst_mflo   ,//204
					   mul_sel     ,//203:203
					   div_sel     ,//202:201
					   ds_hi	   ,//200:169
					   ds_lo	   ,//168:137
					   zero_extend_imm,//136:136
					   alu_op      ,  //135:124
                       load_op     ,  //123:123
                       src1_is_sa  ,  //122:122
                       src1_is_pc  ,  //121:121
                       src2_is_imm ,  //120:120
                       src2_is_8   ,  //119:119
                       gr_we       ,  //118:118
                       mem_we      ,  //117:117
                       dest        ,  //116:112
                       imm         ,  //111:96
                       rs_value    ,  //95 :64
                       rt_value    ,  //63 :32
                       ds_pc          //31 :0
                      };


//for block
//assign ds_ready_go    = (!es_to_ms_valid&&!ms_to_ws_valid&&!ws_to_rf_bus[38])?1:!block;

/*ATTENTION:if add new instructions, remember to adapt the logic of ds_ready_go*/
assign ds_ready_go    = (!(es_to_ms_bus[70]&out_es_valid&((rf_raddr1==es_addr&&rf_raddr1!=0)|(rf_raddr2==es_addr&&rf_raddr2!=0))))|inst_mflo|inst_mfhi;
assign ds_allowin     = !ds_valid || ds_ready_go && es_allowin;
assign ds_to_es_valid = ds_valid && ds_ready_go;
always @(posedge clk) begin
    if (fs_to_ds_valid && ds_allowin) begin
        fs_to_ds_bus_r <= fs_to_ds_bus;
    end
end

always @(posedge clk) begin
    if (reset) begin
        ds_valid <= 1'b0;
    end
    else if (ds_allowin) begin
        ds_valid <= fs_to_ds_valid;
    end
end
assign op   = ds_inst[31:26];
assign rs   = ds_inst[25:21];
assign rt   = ds_inst[20:16];
assign rd   = ds_inst[15:11];
assign sa   = ds_inst[10: 6];
assign func = ds_inst[ 5: 0];
assign imm  = ds_inst[15: 0];
assign jidx = ds_inst[25: 0];

decoder_6_64 u_dec0(.in(op  ), .out(op_d  ));
decoder_6_64 u_dec1(.in(func), .out(func_d));
decoder_5_32 u_dec2(.in(rs  ), .out(rs_d  ));
decoder_5_32 u_dec3(.in(rt  ), .out(rt_d  ));
decoder_5_32 u_dec4(.in(rd  ), .out(rd_d  ));
decoder_5_32 u_dec5(.in(sa  ), .out(sa_d  ));

assign inst_addu   = op_d[6'h00] & func_d[6'h21] & sa_d[5'h00];
assign inst_subu   = op_d[6'h00] & func_d[6'h23] & sa_d[5'h00];
assign inst_slt    = op_d[6'h00] & func_d[6'h2a] & sa_d[5'h00];
assign inst_sltu   = op_d[6'h00] & func_d[6'h2b] & sa_d[5'h00];
assign inst_and    = op_d[6'h00] & func_d[6'h24] & sa_d[5'h00];
assign inst_or     = op_d[6'h00] & func_d[6'h25] & sa_d[5'h00];
assign inst_xor    = op_d[6'h00] & func_d[6'h26] & sa_d[5'h00];
assign inst_nor    = op_d[6'h00] & func_d[6'h27] & sa_d[5'h00];
assign inst_sll    = op_d[6'h00] & func_d[6'h00] & rs_d[5'h00];
assign inst_srl    = op_d[6'h00] & func_d[6'h02] & rs_d[5'h00];
assign inst_sra    = op_d[6'h00] & func_d[6'h03] & rs_d[5'h00];
assign inst_addiu  = op_d[6'h09];
assign inst_lui    = op_d[6'h0f] & rs_d[5'h00];
assign inst_lw     = op_d[6'h23];
assign inst_sw     = op_d[6'h2b];
assign inst_beq    = op_d[6'h04];
assign inst_bne    = op_d[6'h05];
assign inst_jal    = op_d[6'h03];
assign inst_jr     = op_d[6'h00] & func_d[6'h08] & rt_d[5'h00] & rd_d[5'h00] & sa_d[5'h00];

assign inst_add    = op_d[6'h00] & func_d[6'h20] & sa_d[5'h00];
assign inst_addi   = op_d[6'h08];
assign inst_sub    = op_d[6'h00] & func_d[6'h22] & sa_d[5'h00];
assign inst_slti   = op_d[6'h0a];
assign inst_sltiu  = op_d[6'h0b];
assign inst_andi   = op_d[6'h0c];
assign inst_ori    = op_d[6'h0d];
assign inst_xori   = op_d[6'h0e];
assign inst_sllv   = op_d[6'h00] & func_d[6'h04] & sa_d[5'h00];
assign inst_srlv   = op_d[6'h00] & func_d[6'h06] & sa_d[5'h00];
assign inst_srav   = op_d[6'h00] & func_d[6'h07] & sa_d[5'h00];
assign inst_mult   = op_d[6'h00] & func_d[6'h18] & rd_d[5'h00] & sa_d[5'h00];
assign inst_multu  = op_d[6'h00] & func_d[6'h19] & rd_d[5'h00] & sa_d[5'h00];
assign inst_div    = op_d[6'h00] & func_d[6'h1a] & rd_d[5'h00] & sa_d[5'h00];
assign inst_divu   = op_d[6'h00] & func_d[6'h1b] & rd_d[5'h00] & sa_d[5'h00];
assign inst_mfhi   = op_d[6'h00] & func_d[6'h10] & rs_d[5'h00] & rt_d[5'h00];
assign inst_mflo   = op_d[6'h00] & func_d[6'h12] & rs_d[5'h00] & rt_d[5'h00];
assign inst_mthi   = op_d[6'h00] & func_d[6'h11] & rd_d[5'h00] & rt_d[5'h00] & sa_d[5'h00];
assign inst_mtlo   = op_d[6'h00] & func_d[6'h13] & rd_d[5'h00] & rt_d[5'h00] & sa_d[5'h00];
//add
assign alu_op[ 0] = inst_addu | inst_addiu | inst_add | inst_addi | inst_lw | inst_sw | inst_jal;
assign alu_op[ 1] = inst_subu | inst_sub;//sub
assign alu_op[ 2] = inst_slt  | inst_slti; //slt
assign alu_op[ 3] = inst_sltu | inst_sltiu;//sltu
assign alu_op[ 4] = inst_and  | inst_andi; //and
assign alu_op[ 5] = inst_nor; //nor
assign alu_op[ 6] = inst_or   | inst_ori;  //or
assign alu_op[ 7] = inst_xor  | inst_xori; //xor
assign alu_op[ 8] = inst_sll  | inst_sllv; //sll
assign alu_op[ 9] = inst_srl  | inst_srlv; //srl
assign alu_op[10] = inst_sra  | inst_srav; //sra
assign alu_op[11] = inst_lui; //lui

assign src1_is_sa   = inst_sll   | inst_srl | inst_sra;
assign src1_is_pc   = inst_jal;
assign src2_is_imm  = inst_addiu | inst_lui | inst_lw | inst_sw | inst_addi | inst_slti | inst_sltiu | inst_andi | inst_ori | inst_xori;
assign src2_is_8    = inst_jal;
assign res_from_mem = inst_lw;
assign dst_is_r31   = inst_jal;
assign dst_is_rt    = inst_addiu | inst_lui | inst_lw | inst_addi | inst_slti | inst_sltiu | inst_andi | inst_ori | inst_xori;
assign gr_we        = ~inst_sw & ~inst_beq & ~inst_bne & ~inst_jr & ~inst_mult & ~inst_multu & ~inst_div & ~inst_divu & ~inst_mthi & ~inst_mtlo;
assign mem_we       = inst_sw;
assign load_op      = inst_lw;
assign dest         = dst_is_r31 ? 5'd31 :
                      dst_is_rt  ? rt    : 
                                   rd;
assign zero_extend_imm = inst_andi | inst_ori | inst_xori;

assign rf_raddr1 = rs;
assign rf_raddr2 = rt;
regfile u_regfile(
    .clk    (clk      ),
    .raddr1 (rf_raddr1),
    .rdata1 (rf_rdata1),
    .raddr2 (rf_raddr2),
    .rdata2 (rf_rdata2),
    .we     (rf_we    ),
    .waddr  (rf_waddr ),
    .wdata  (rf_wdata )
    );

assign rs_value = r1_fvalue;
assign rt_value = r2_fvalue;
//assign rs_value = rf_rdata1;
//assign rt_value = rf_rdata2;
assign rs_eq_rt = (rs_value == rt_value);
assign br_taken = (   inst_beq  &&  rs_eq_rt
                   || inst_bne  && !rs_eq_rt
                   || inst_jal
                   || inst_jr
                  ) && ds_valid;
assign br_target = (inst_beq || inst_bne) ? (fs_pc + {{14{imm[15]}}, imm[15:0], 2'b0}) :
                   (inst_jr)              ? rs_value :
                  /*inst_jal*/              {fs_pc[31:28], jidx[25:0], 2'b0};
//for block
/*assign r1_block = (rf_raddr1!=0)&(((rf_raddr1==ws_to_rf_bus[36:32])&ws_to_rf_bus[37])|((rf_raddr1==ms_to_ws_bus[68:64])&ms_to_ws_bus[69])|(rf_raddr1==es_to_ms_bus[68:64]&es_to_ms_bus[69]));
assign r2_block = (rf_raddr2!=0)&(((rf_raddr2==ws_to_rf_bus[36:32])&ws_to_rf_bus[37])|((rf_raddr2==ms_to_ws_bus[68:64])&ms_to_ws_bus[69])|(rf_raddr2==es_to_ms_bus[68:64]&es_to_ms_bus[69]));
assign block = r1_block|r2_block;*/

wire [31:0] es_value,ms_value,ws_value;
wire [4:0]  es_addr,ms_addr,ws_addr;
wire        es_gr_we,ms_gr_we,ws_gr_we;
//wire        r1_forward,r2_forward;
wire [31:0] r1_fvalue,r2_fvalue;
assign {es_gr_we,es_addr,es_value} = es_to_ds_fw_bus;
assign {ms_gr_we,ms_addr,ms_value} = ms_to_ds_fw_bus;
assign {ws_gr_we,ws_addr,ws_value} = ws_to_ds_fw_bus;
//assign r1_forward = ds_ready_go&(rf_raddr1!=0)&((rf_raddr1==es_addr)&es_gr_we&out_es_valid&!es_to_ms_bus[70]|(rf_raddr1==ms_addr)&ms_gr_we&out_ms_valid|(rf_raddr1==ws_addr)&ws_gr_we&out_ws_valid);
//assign r2_forward = ds_ready_go&(rf_raddr2!=0)&((rf_raddr2==es_addr)&es_gr_we&out_es_valid&!es_to_ms_bus[70]|(rf_raddr2==ms_addr)&ms_gr_we&out_ms_valid|(rf_raddr2==ws_addr)&ws_gr_we&out_ws_valid);
assign r1_fvalue = rf_raddr1==0 ? 0 :((rf_raddr1==es_addr)&es_gr_we&out_es_valid&!es_to_ms_bus[70])?es_value:
                  (((rf_raddr1==ms_addr)&ms_gr_we&out_ms_valid)?ms_value:
                    (((rf_raddr1==ws_addr)&ws_gr_we&out_ws_valid)?ws_value:rf_rdata1));
assign r2_fvalue = rf_raddr2==0 ? 0 :((rf_raddr2==es_addr)&es_gr_we&out_es_valid&!es_to_ms_bus[70])?es_value:
                  (((rf_raddr2==ms_addr)&ms_gr_we&out_ms_valid)?ms_value:
                    (((rf_raddr2==ws_addr)&ws_gr_we&out_ws_valid)?ws_value:rf_rdata2));

wire [31:0] src1,src2;
wire [63:0] signed_prod;
wire [63:0] unsigned_prod;

assign src1 = rs_value;
assign src2 = rt_value;
assign unsigned_prod = src1 * src2;
assign signed_prod = $signed(src1) * $signed(src2);
assign div_sel[1:0] = {inst_div,inst_divu};
assign mul_sel = inst_mult|inst_multu;  
assign ds_hi = {32{inst_mult}}&signed_prod[63:32] | {32{inst_multu}}&unsigned_prod[63:32];
assign ds_lo = {32{inst_mult}}&signed_prod[31:0] | {32{inst_multu}}&unsigned_prod[31:0];                                 
endmodule
