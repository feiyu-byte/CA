module cache(
	input 			clk_g,
	input 			resetn,

	input			valid,
	input			op,
	input 	[ 7:0]	index,
	input 	[19:0]	tag,
	input 	[ 3:0]	offset,
	input 	[ 3:0]	wstrb,
	input 	[31:0]	wdata,
	output 			addr_ok,
	output 			data_ok,
	output	[31:0]	rdata,

	output 			rd_req,
	output 	[ 2:0]	rd_type,
	output	[31:0]	rd_addr,
	input 			rd_rdy,
	input 			ret_valid,
	input 			ret_last,
	input	[31:0]	ret_data,

	output			wr_req,
	output	[ 2:0]	wr_type,
	output	[31:0]	wr_addr,
	output	[ 3:0]	wr_wstrb,
	output	[127:0]	wr_data,
	input			wr_rdy

	);
parameter LR_IDLE = 5'b00001;
parameter LR_LOOKUP = 5'b00010;
parameter LR_MISS = 5'b00100;
parameter LR_REPLACE = 5'b01000;
parameter LR_REFILL = 5'b10000;
parameter OP_READ = 1'b0;
parameter OP_WRITE = 1'b1;
parameter WB_IDLE = 2'b01;
parameter WB_WRITE = 2'b10;
assign way0_tagv_en = valid|lr_state == LR_MISS & wr_rdy| ret_last & !replace_way;
assign way1_tagv_en = valid|lr_state == LR_MISS & wr_rdy| ret_last & replace_way;
assign way0_tagv_we = ret_last & !replace_way;
assign way1_tagv_we = ret_last & replace_way;
assign way0_tagv_wdata = {tag_r,1'b1};
assign way1_tagv_wdata = {tag_r,1'b1};

//TODO : MISS
assign way0_data_bank0_en = valid | (wb_state==WB_WRITE & hw_sel_bank == 2'b00 & !hw_sel_way) | lr_state == LR_MISS & wr_rdy & !replace_way | ret_valid & ret_count==2'b00 & !replace_way;
assign way0_data_bank1_en = valid | (wb_state==WB_WRITE & hw_sel_bank == 2'b01 & !hw_sel_way) | lr_state == LR_MISS & wr_rdy & !replace_way | ret_valid & ret_count==2'b01 & !replace_way;
assign way0_data_bank2_en = valid | (wb_state==WB_WRITE & hw_sel_bank == 2'b10 & !hw_sel_way) | lr_state == LR_MISS & wr_rdy & !replace_way | ret_valid & ret_count==2'b10 & !replace_way;
assign way0_data_bank3_en = valid | (wb_state==WB_WRITE & hw_sel_bank == 2'b11 & !hw_sel_way) | lr_state == LR_MISS & wr_rdy & !replace_way | ret_valid & ret_count==2'b11 & !replace_way;
assign way1_data_bank0_en = valid | (wb_state==WB_WRITE & hw_sel_bank == 2'b00 & hw_sel_way) | lr_state == LR_MISS & wr_rdy & replace_way | ret_valid & ret_count==2'b00 & replace_way;
assign way1_data_bank1_en = valid | (wb_state==WB_WRITE & hw_sel_bank == 2'b01 & hw_sel_way) | lr_state == LR_MISS & wr_rdy & replace_way | ret_valid & ret_count==2'b01 & replace_way;
assign way1_data_bank2_en = valid | (wb_state==WB_WRITE & hw_sel_bank == 2'b10 & hw_sel_way) | lr_state == LR_MISS & wr_rdy & replace_way | ret_valid & ret_count==2'b10 & replace_way;
assign way1_data_bank3_en = valid | (wb_state==WB_WRITE & hw_sel_bank == 2'b11 & hw_sel_way) | lr_state == LR_MISS & wr_rdy & replace_way | ret_valid & ret_count==2'b11 & replace_way;

assign way0_data_bank0_we = {4{(wb_state==WB_WRITE & hw_sel_bank == 2'b00 & !hw_sel_way) | ret_valid & ret_count==2'b00 & !replace_way}} & ((ret_valid && ret_count==2'b00) ? refill_bank_wstrb : hw_wstrb);
assign way0_data_bank1_we = {4{(wb_state==WB_WRITE & hw_sel_bank == 2'b01 & !hw_sel_way) | ret_valid & ret_count==2'b01 & !replace_way}} & ((ret_valid && ret_count==2'b01) ? refill_bank_wstrb : hw_wstrb);
assign way0_data_bank2_we = {4{(wb_state==WB_WRITE & hw_sel_bank == 2'b10 & !hw_sel_way) | ret_valid & ret_count==2'b10 & !replace_way}} & ((ret_valid && ret_count==2'b10) ? refill_bank_wstrb : hw_wstrb);
assign way0_data_bank3_we = {4{(wb_state==WB_WRITE & hw_sel_bank == 2'b11 & !hw_sel_way) | ret_valid & ret_count==2'b11 & !replace_way}} & ((ret_valid && ret_count==2'b11) ? refill_bank_wstrb : hw_wstrb);
assign way1_data_bank0_we = {4{(wb_state==WB_WRITE & hw_sel_bank == 2'b00 & hw_sel_way) | ret_valid & ret_count==2'b00 & replace_way}} & ((ret_valid && ret_count==2'b00) ? refill_bank_wstrb : hw_wstrb);
assign way1_data_bank1_we = {4{(wb_state==WB_WRITE & hw_sel_bank == 2'b01 & hw_sel_way) | ret_valid & ret_count==2'b01 & replace_way}} & ((ret_valid && ret_count==2'b01) ? refill_bank_wstrb : hw_wstrb);
assign way1_data_bank2_we = {4{(wb_state==WB_WRITE & hw_sel_bank == 2'b10 & hw_sel_way) | ret_valid & ret_count==2'b10 & replace_way}} & ((ret_valid && ret_count==2'b10) ? refill_bank_wstrb : hw_wstrb);
assign way1_data_bank3_we = {4{(wb_state==WB_WRITE & hw_sel_bank == 2'b11 & hw_sel_way) | ret_valid & ret_count==2'b11 & replace_way}} & ((ret_valid && ret_count==2'b11) ? refill_bank_wstrb : hw_wstrb);

assign way0_data_bank0_wdata = (ret_valid && ret_count==2'b00) ? refill_bank_data :hw_wdata;
assign way0_data_bank1_wdata = (ret_valid && ret_count==2'b01) ? refill_bank_data :hw_wdata;
assign way0_data_bank2_wdata = (ret_valid && ret_count==2'b10) ? refill_bank_data :hw_wdata;
assign way0_data_bank3_wdata = (ret_valid && ret_count==2'b11) ? refill_bank_data :hw_wdata;
assign way1_data_bank0_wdata = (ret_valid && ret_count==2'b00) ? refill_bank_data :hw_wdata;
assign way1_data_bank1_wdata = (ret_valid && ret_count==2'b01) ? refill_bank_data :hw_wdata;
assign way1_data_bank2_wdata = (ret_valid && ret_count==2'b10) ? refill_bank_data :hw_wdata;
assign way1_data_bank3_wdata = (ret_valid && ret_count==2'b11) ? refill_bank_data :hw_wdata;

assign rdata = (ret_valid & ret_last)?refill_rdata:load_result;//TODO:not considering miss
wire [31:0] refill_rdata;
assign refill_rdata = {32{offset_r[3:2] == 2'b00}} & miss_bank0 
					| {32{offset_r[3:2] == 2'b01}} & miss_bank1
					| {32{offset_r[3:2] == 2'b10}} & miss_bank2
					| {32{offset_r[3:2] == 2'b11}} & miss_bank3;
assign addr_ok = lr_state == LR_IDLE & valid & !(hw_sel_bank == offset[3:2] && tag_r == tag && wb_state == WB_WRITE)/*| lr_state == LR_LOOKUP & cache_hit*/;
//TODO:MISS
assign data_ok = (cache_hit & lr_state == LR_LOOKUP & op_r == OP_READ)/*for hit read*/
			   | (wb_state==WB_WRITE) | ret_valid & ret_last/*for hit write*/;
//for way0 
wire 			way0_tagv_en;
wire			way0_tagv_we;
wire [  7:0]	way0_tagv_addr;
wire [ 20:0]	way0_tagv_wdata;
wire [ 20:0]	way0_tagv_rdata;
wire 			way0_v;
wire [ 19:0]	way0_tag;
tagv way0_tagv(
	.clka(clk_g),
	.ena(way0_tagv_en),
	.wea(way0_tagv_we),
	.addra(way0_tagv_addr),
	.dina(way0_tagv_wdata),
	.douta(way0_tagv_rdata)
	);
assign way0_tagv_addr = (way0_tagv_we)?index_r:index;
assign way0_v = way0_tagv_rdata[0];
assign way0_tag = way0_tagv_rdata[20:1];
wire 			way0_data_bank0_en;
wire [  3:0]	way0_data_bank0_we;
wire [  7:0]	way0_data_bank0_addr;
wire [ 31:0]	way0_data_bank0_wdata;
wire [ 31:0]	way0_data_bank0_rdata;
data_bank way0_data_bank0(
	.clka(clk_g),
	.ena(way0_data_bank0_en),
	.wea(way0_data_bank0_we),
	.addra(way0_data_bank0_addr),
	.dina(way0_data_bank0_wdata),
	.douta(way0_data_bank0_rdata)	
	);
assign way0_data_bank0_addr = (ret_valid)?index_r:index;
wire 			way0_data_bank1_en;
wire [  3:0]	way0_data_bank1_we;
wire [  7:0]	way0_data_bank1_addr;
wire [ 31:0]	way0_data_bank1_wdata;
wire [ 31:0]	way0_data_bank1_rdata;
data_bank way0_data_bank1(
	.clka(clk_g),
	.ena(way0_data_bank1_en),
	.wea(way0_data_bank1_we),
	.addra(way0_data_bank1_addr),
	.dina(way0_data_bank1_wdata),
	.douta(way0_data_bank1_rdata)	
	);
assign way0_data_bank1_addr = (ret_valid)?index_r:index;
wire 			way0_data_bank2_en;
wire [  3:0]	way0_data_bank2_we;
wire [  7:0]	way0_data_bank2_addr;
wire [ 31:0]	way0_data_bank2_wdata;
wire [ 31:0]	way0_data_bank2_rdata;
data_bank way0_data_bank2(
	.clka(clk_g),
	.ena(way0_data_bank2_en),
	.wea(way0_data_bank2_we),
	.addra(way0_data_bank2_addr),
	.dina(way0_data_bank2_wdata),
	.douta(way0_data_bank2_rdata)	
	);
assign way0_data_bank2_addr = (ret_valid)?index_r:index;
wire 			way0_data_bank3_en;
wire [  3:0]	way0_data_bank3_we;
wire [  7:0]	way0_data_bank3_addr;
wire [ 31:0]	way0_data_bank3_wdata;
wire [ 31:0]	way0_data_bank3_rdata;
data_bank way0_data_bank3(
	.clka(clk_g),
	.ena(way0_data_bank3_en),
	.wea(way0_data_bank3_we),
	.addra(way0_data_bank3_addr),
	.dina(way0_data_bank3_wdata),
	.douta(way0_data_bank3_rdata)	
	);
assign way0_data_bank3_addr = (ret_valid)?index_r:index;
reg way0_d[255:0];
integer	j;
always @(posedge clk_g) begin
	if (!resetn) begin
		// reset
								
		for(j=0;j<256;j=j+1)	
		begin					
			way0_d[j] <= 1'b0;
		end
	end
	else if (wb_state==WB_WRITE&&way0_hit) begin
		way0_d[index_r] <= 1'b1;
	end
	else if (lr_state == LR_REFILL && !replace_way)begin
		way0_d[index_r] <= op_r ;
	end
end
//for way1
wire 			way1_tagv_en;
wire			way1_tagv_we;
wire [  7:0]	way1_tagv_addr;
wire [ 20:0]	way1_tagv_wdata;
wire [ 20:0]	way1_tagv_rdata;
wire 			way1_v;
wire [ 19:0]	way1_tag;
tagv way1_tagv(
	.clka(clk_g),
	.ena(way1_tagv_en),
	.wea(way1_tagv_we),
	.addra(way1_tagv_addr),
	.dina(way1_tagv_wdata),
	.douta(way1_tagv_rdata)
	);
assign way1_tagv_addr = (way1_tagv_we)?index_r:index;
assign way1_v = way1_tagv_rdata[0];
assign way1_tag = way1_tagv_rdata[20:1];
wire 			way1_data_bank0_en;
wire [  3:0]	way1_data_bank0_we;
wire [  7:0]	way1_data_bank0_addr;
wire [ 31:0]	way1_data_bank0_wdata;
wire [ 31:0]	way1_data_bank0_rdata;
data_bank way1_data_bank0(
	.clka(clk_g),
	.ena(way1_data_bank0_en),
	.wea(way1_data_bank0_we),
	.addra(way1_data_bank0_addr),
	.dina(way1_data_bank0_wdata),
	.douta(way1_data_bank0_rdata)	
	);
assign way1_data_bank0_addr = (ret_valid)?index_r:index;
wire 			way1_data_bank1_en;
wire [  3:0]	way1_data_bank1_we;
wire [  7:0]	way1_data_bank1_addr;
wire [ 31:0]	way1_data_bank1_wdata;
wire [ 31:0]	way1_data_bank1_rdata;
data_bank way1_data_bank1(
	.clka(clk_g),
	.ena(way1_data_bank1_en),
	.wea(way1_data_bank1_we),
	.addra(way1_data_bank1_addr),
	.dina(way1_data_bank1_wdata),
	.douta(way1_data_bank1_rdata)	
	);
assign way1_data_bank1_addr = (ret_valid)?index_r:index;

wire 			way1_data_bank2_en;
wire [  3:0]	way1_data_bank2_we;
wire [  7:0]	way1_data_bank2_addr;
wire [ 31:0]	way1_data_bank2_wdata;
wire [ 31:0]	way1_data_bank2_rdata;
data_bank way1_data_bank2(
	.clka(clk_g),
	.ena(way1_data_bank2_en),
	.wea(way1_data_bank2_we),
	.addra(way1_data_bank2_addr),
	.dina(way1_data_bank2_wdata),
	.douta(way1_data_bank2_rdata)	
	);
assign way1_data_bank2_addr = (ret_valid)?index_r:index;

wire 			way1_data_bank3_en;
wire [  3:0]	way1_data_bank3_we;
wire [  7:0]	way1_data_bank3_addr;
wire [ 31:0]	way1_data_bank3_wdata;
wire [ 31:0]	way1_data_bank3_rdata;
data_bank way1_data_bank3(
	.clka(clk_g),
	.ena(way1_data_bank3_en),
	.wea(way1_data_bank3_we),
	.addra(way1_data_bank3_addr),
	.dina(way1_data_bank3_wdata),
	.douta(way1_data_bank3_rdata)	
	);
assign way1_data_bank3_addr = (ret_valid)?index_r:index;

reg way1_d[255:0];
integer	i;
always @(posedge clk_g) begin
	if (!resetn) begin
		// reset
								
		for(i=0;i<256;i=i+1)	
		begin					
			way1_d[i] <= 1'b0;
		end
	end
	else if (wb_state==WB_WRITE&&way1_hit) begin//for hit write TODO:
		way1_d[index_r] <= 1'b1;
	end
	else if (lr_state == LR_REFILL && replace_way)begin
		way1_d[index_r] <= op_r ;
	end
end
//state machine:LR

reg [4:0] lr_state;
reg [4:0] lr_nextstate;
always @(posedge clk_g) begin
	if (!resetn) begin
		// reset
		lr_state <= LR_IDLE;
	end
	else
		lr_state <= lr_nextstate;
end
always @(*) begin
	case(lr_state)
	LR_IDLE:begin
		if(valid)
			lr_nextstate <= LR_LOOKUP;
		else begin
			lr_nextstate <= LR_IDLE;
		end
	end
	LR_LOOKUP:begin
		if(cache_hit)
			lr_nextstate <= LR_IDLE;
		else
			lr_nextstate <= LR_MISS;
	end
	LR_MISS:begin
		if(wr_rdy)
			lr_nextstate <= LR_REPLACE;
	end
	LR_REPLACE:begin
		if(rd_rdy)
			lr_nextstate <= LR_REFILL;
	end
	LR_REFILL:begin
		if(ret_valid && ret_last)
			lr_nextstate <= LR_IDLE;
	end
	endcase
end
//state machine:WB

reg [1:0] wb_state;
reg [1:0] wb_nextstate;
always @(posedge clk_g) begin
	if (!resetn) begin
		// reset
		wb_state <= WB_IDLE;
	end
	else
		wb_state <= wb_nextstate;
end
always @(*) begin
	case(wb_state)
	WB_IDLE:begin
		if(hit_write)
			wb_nextstate <= WB_WRITE;
		else begin
			wb_nextstate <= WB_IDLE;
		end
	end
	WB_WRITE:begin
		wb_nextstate <= WB_IDLE;
	end
	endcase
end
//Request Buffer
wire [68:0] request_buffer;
reg  [68:0] request_buffer_r;
assign request_buffer = {
	op,//68:68
	index,//67:60
	tag,//59:40
	offset,//39:36
	wstrb,//35:32
	wdata//31:0
} ;
always @(posedge clk_g) begin
	if (!resetn) begin
		// reset
		request_buffer_r <= 0;
	end
	else if (valid&lr_state == LR_IDLE&addr_ok) begin
		request_buffer_r <= request_buffer;
	end
end
wire op_r;
wire [ 7:0] 	index_r;
wire [19:0] 	tag_r;
wire [ 3:0]		offset_r;
wire [ 3:0]		wstrb_r;
wire [31:0]		wdata_r;
assign op_r = request_buffer_r[68];
assign index_r = request_buffer_r[67:60];
assign tag_r = request_buffer_r[59:40];
assign offset_r = request_buffer_r[39:36];
assign wstrb_r = request_buffer_r[35:32];
assign wdata_r = request_buffer_r[31:0];
//Tag Compare
wire way0_hit;
wire way1_hit;
wire cache_hit;
assign way0_hit = way0_v && way0_tag==tag_r;
assign way1_hit = way1_v && way1_tag==tag_r;
assign cache_hit = way1_hit || way0_hit;

//Data Select
wire [31:0]	way0_load_word;
wire [31:0]	way1_load_word;
wire [31:0]	load_result;
wire [31:0] replaced_data;
wire sel_bank0;
wire sel_bank1;
wire sel_bank2;
wire sel_bank3;
assign sel_bank0 = offset_r[3:2]==2'b00;
assign sel_bank1 = offset_r[3:2]==2'b01;
assign sel_bank2 = offset_r[3:2]==2'b10;
assign sel_bank3 = offset_r[3:2]==2'b11;

assign way0_load_word = ({32{sel_bank0}}&way0_data_bank0_rdata)
					  | ({32{sel_bank1}}&way0_data_bank1_rdata)
					  | ({32{sel_bank2}}&way0_data_bank2_rdata)
					  | ({32{sel_bank3}}&way0_data_bank3_rdata);
assign way1_load_word = ({32{sel_bank0}}&way1_data_bank0_rdata)
					  | ({32{sel_bank1}}&way1_data_bank1_rdata)
					  | ({32{sel_bank2}}&way1_data_bank2_rdata)
					  | ({32{sel_bank3}}&way1_data_bank3_rdata);
		//TODO:not considering about miss
assign load_result = {32{way0_hit}} & way0_load_word | {32{way1_hit}} & way1_load_word;
//assign replaced_data = replace_way ? way1_data : way0_data;
//Miss Buffer
wire replace_way;
assign replace_way = 1'b1;
reg [1:0] ret_count;
always @(posedge clk_g) begin
	if (!resetn) begin
		// reset
		ret_count <= 0;
	end
	else if (ret_last) begin
		ret_count <= 0;
	end
	else if (ret_valid) begin
		ret_count <= ret_count+1;
	end
end
reg [31:0] miss_bank0,miss_bank1,miss_bank2,miss_bank3;
always @(posedge clk_g) begin
	if (!resetn) begin
		// reset
		miss_bank0 <= 0;
	end
	else if (ret_valid && ret_count==2'b00) begin
		miss_bank0 <= refill_bank_data;
	end
end
always @(posedge clk_g) begin
	if (!resetn) begin
		// reset
		miss_bank1 <= 0;
	end
	else if (ret_valid && ret_count==2'b01) begin
		miss_bank1 <= refill_bank_data;
	end
end
always @(posedge clk_g) begin
	if (!resetn) begin
		// reset
		miss_bank2 <= 0;
	end
	else if (ret_valid && ret_count==2'b10) begin
		miss_bank2 <= refill_bank_data;
	end
end
always @(posedge clk_g) begin
	if (!resetn) begin
		// reset
		miss_bank3 <= 0;
	end
	else if (ret_valid && ret_count==2'b11) begin
		miss_bank3 <= refill_bank_data;
	end
end
//Write Buffer
wire [49:0] write_buffer;
reg  [49:0]	write_buffer_r;
assign write_buffer = {
	index_r,//48:41
	way1_hit,//40
	wstrb_r,//39:36
	wdata_r,//35:4
	offset_r//3:0
} ;
wire hit_write;
assign hit_write = op_r==OP_WRITE && lr_state==LR_LOOKUP && cache_hit;
always @(posedge clk_g) begin
	if (!resetn) begin
		// reset
		write_buffer_r <= 0;
	end
	else if (hit_write) begin
		write_buffer_r <= write_buffer;
	end
end
wire 		hw_sel_way;
wire [ 3:0]	hw_wstrb;
wire [31:0]	hw_wdata;
wire [ 1:0] hw_sel_bank;
assign hw_sel_way = write_buffer_r[40];
assign hw_wdata = write_buffer_r[35:4];
assign hw_wstrb = write_buffer_r[39:36];
assign hw_sel_bank = write_buffer_r[3:2];
//LFSR
reg [3:0] LFSR;
reg [3:0] random;
always @(posedge clk_g) begin
	if (!resetn) begin
		// reset
		random <= 0;
	end
	else if (lr_state == LR_LOOKUP) begin
		random <= LFSR;
	end
end
always @(posedge clk_g) begin
	if (!resetn) begin
		// reset
		LFSR <= 0;
	end
	else if (LFSR==4'b1111) begin
		LFSR <= 0;
	end
	else begin
		LFSR <= LFSR+1;
	end
end
//AXI WR
reg wr_req_flag;
always @(posedge clk_g) begin
    if(!resetn)
        wr_req_flag <=1'b0;
    else if (wr_req_flag && lr_state == LR_REPLACE) begin
        wr_req_flag <= 1'b0;
    end
    else if (!wr_req_flag && wr_rdy)
        wr_req_flag <= 1'b1;
    
end
assign wr_req = lr_state==LR_REPLACE && (way0_d[index_r]&!replace_way | way1_d[index_r]&replace_way) & wr_req_flag;
assign wr_type = 3'b100;
assign wr_addr = {(replace_way)?way1_tag:way0_tag,index_r,offset_r};
assign wr_wstrb = 4'b1111;
assign wr_data = (replace_way) ? {way1_data_bank3_rdata,way1_data_bank2_rdata,way1_data_bank1_rdata,way1_data_bank0_rdata}
							   : {way0_data_bank3_rdata,way0_data_bank2_rdata,way0_data_bank1_rdata,way0_data_bank0_rdata};
//AXI RD
assign rd_req = lr_state == LR_REPLACE;
assign rd_type = 3'b100;
assign rd_addr = {tag_r,index_r,offset_r};
wire [31:0] refill_bank_data;
wire [ 3:0] refill_bank_wstrb;
assign refill_bank_data = (ret_count==offset_r[3:2] & op_r==OP_WRITE)?wdata_r:ret_data;
assign refill_bank_wstrb = (ret_count == offset_r[3:2] & op_r==OP_WRITE)?wstrb_r:4'b1111;
endmodule