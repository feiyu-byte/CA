module sram_to_axi_bridge (
    input        clk,
    input        reset,
    // slave: inst sram interface
    input        inst_sram_req,
    input        inst_sram_wr,
    input [ 1:0] inst_sram_size,
    input [ 3:0] inst_sram_wstrb,
    input [31:0] inst_sram_addr,
    input [31:0] inst_sram_wdata,
    output       inst_sram_addr_ok, //TODO
    output       inst_sram_data_ok, //TODO
    output[31:0] inst_sram_rdata,   //TODO
    // slave: data sram interface
    input        data_sram_req,
    input        data_sram_wr,
    input [ 1:0] data_sram_size,
    input [ 3:0] data_sram_wstrb,
    input [31:0] data_sram_addr,
    input [31:0] data_sram_wdata,
    output       data_sram_addr_ok, //TODO
    output       data_sram_data_ok, //TODO
    output[31:0] data_sram_rdata,   //TODO
    // master: axi interface
    //read request
    output [3:0]    arid      ,
    output [31:0]   araddr    ,
    output [7:0]    arlen     ,
    output [2:0]    arsize    ,
    output [1:0]    arburst   ,
    output [1:0]    arlock    ,
    output [3:0]    arcache   ,
    output [2:0]    arprot    ,
    output          arvalid   ,
    input           arready   ,
    //read response
    input [3:0]     rid       ,
    input [31:0]    rdata     ,
    input [1:0]     rresp     ,
    input           rlast     ,
    input           rvalid    ,
    output          rready    ,
    //write request
    output [3:0]    awid      ,
    output [31:0]   awaddr    ,
    output [7:0]    awlen     ,
    output [2:0]    awsize    ,
    output [1:0]    awburst   ,
    output [1:0]    awlock    ,
    output [3:0]    awcache   ,
    output [2:0]    awprot    ,
    output          awvalid   ,
    input           awready   ,
    //write data
    output [3:0]    wid       ,
    output [31:0]   wdata     ,
    output [3:0]    wstrb     ,
    output          wlast     ,
    output          wvalid    ,
    input           wready    ,
    //write response
    input [3:0]     bid       ,
    input [1:0]     bresp     ,
    input           bvalid    ,
    output          bready    
);
// reg          inst_sram_addr_ok_r;//?
// reg          inst_sram_data_ok_r;//?
// reg   [31:0] inst_sram_rdata_r;
// reg          data_sram_addr_ok_r;//?
// reg          data_sram_data_ok_r;//?
// reg   [31:0] data_sram_rdata_r;

//read request
reg [3:0]    arid_r      ;
reg [31:0]   araddr_r    ;
reg [2:0]    arsize_r    ;
reg          arvalid_r   ;
// /****PART 1
	parameter AR_Q      = 2'b00;    //WAIT REQ
	parameter AR_DHS    = 2'b01;    //DATA HANDSHAKE
    parameter AR_IHS    = 2'b10;    //INST HANDSHAKE
    reg [1:0] ar_state;
	reg [1:0] ar_nextstate;
	always@(posedge clk) begin
		if(reset)   ar_state<=AR_Q;
		else        ar_state<=ar_nextstate;
	end
// */
// /****PART 2
    // THIS IS COMBINATIONAL
	always@(*) begin
		case(ar_state)
        AR_Q:begin
            if(data_sram_req&&!data_sram_wr)
                    ar_nextstate<=AR_DHS;
            else if(inst_sram_req&&!inst_sram_wr)
                    ar_nextstate<=AR_IHS;
            else    ar_nextstate<=AR_Q;
        end
        AR_DHS:begin
            if(arready&&arvalid) ar_nextstate<=AR_Q;
            else                 ar_nextstate<=AR_DHS;
        end
        AR_IHS:begin
            if(arready&&arvalid) ar_nextstate<=AR_Q;
            else                 ar_nextstate<=AR_IHS;
        end
        default:ar_nextstate<=AR_Q;
		endcase
	end
// */
// /****PART 3
// reg [3:0]    arid_r      ;
// reg [31:0]   araddr_r    ;
// reg [2:0]    arsize_r    ;
// reg          arvalid_r   ;
wire raw_block; //ar_transaction->addr==unfinished w_transaction->addr
wire rnw_block; //ar_transaction->addr==current w_transaction->addr
assign raw_block = baddr_r==araddr && b_state==B_WAIT;
assign rnw_block = baddr_r==araddr && (wready && wvalid); 
	always@(posedge clk) begin
		if(reset)       arvalid_r<=0;
        else if(ar_state==AR_DHS || ar_state==AR_IHS) begin
            if(raw_block || rnw_block)   
                            arvalid_r<=0;
            else if(arready)arvalid_r<=0;
            else            arvalid_r<=1;
        end
        else            arvalid_r<=0;
	end
    always@(posedge clk) begin
        if(ar_state==AR_Q) begin
            if(data_sram_req && !data_sram_wr)
                arsize_r<=data_sram_size;
            else if(inst_sram_req && !inst_sram_wr)
                arsize_r<=inst_sram_size;
        end 
    end
    always@(posedge clk) begin
        if(ar_state==AR_Q) begin
            if(data_sram_req && !data_sram_wr)
                araddr_r<=data_sram_addr;
            else if(inst_sram_req && !inst_sram_wr)
                araddr_r<=inst_sram_addr;
        end 
    end
    always@(posedge clk) begin
        if(ar_state==AR_Q) begin
            if(data_sram_req && !data_sram_wr)
                arid_r<=4'd1;
            else if(inst_sram_req && !inst_sram_wr)
                arid_r<=4'd0;
        end
    end
// */
assign       arlen  = 8'b0;
assign       arburst= 2'b01;
assign       arlock = 2'b0;
assign       arcache= 4'b0;
assign       arprot = 3'b0;

//read response
reg          rready_r    ;
	parameter R_WV      = 2'b00;    //WAIT VALID
    parameter R_WB      = 2'b01;    //WRITE BACK TO CPU
	reg [1:0] r_state;
	reg [1:0] r_nextstate;
	always@(posedge clk) begin
		if(reset)   r_state<=R_WV;
		else        r_state<=r_nextstate;
	end
    always@(*) begin
        case(r_state)
        R_WV:begin
            if(rvalid&&rready)  r_state<=R_WB;
            else                r_state<=R_WV;
        end
        R_WB:   r_nextstate<=R_WV;
        default:r_nextstate<=R_WV;
        endcase
    end
    always@(posedge clk) begin
        if(r_state==R_WV) begin
            if(rvalid)      rready_r<=0;
            else            rready_r<=1;
        end
        else                rready_r<=0;
    end
//rdata related
reg          rid_r       ;
reg [31:0]   rdata_r     ;
always@(posedge clk) begin
    if(r_state==R_WV) begin
        if(rvalid&&rready) begin
            rid_r   <=rid;
            rdata_r <=rdata;
        end
    end
end

//write request & data
reg [31:0]   awaddr_r    ;
reg [2:0]    awsize_r    ;
reg          awvalid_r   ;
reg [31:0]   wdata_r     ;
reg [3:0]    wstrb_r     ;
reg          wvalid_r    ;
	parameter AW_Q      = 2'b00;    //WAIT REQ
    parameter AW_HS     = 2'b01;    //HANDSHAKE(ONLY DATA)
    parameter AW_W      = 2'b10;    //WRITE
	reg [1:0] aw_state;
	reg [1:0] aw_nextstate;
	always@(posedge clk) begin
		if(reset)   aw_state<=AW_Q;
		else        aw_state<=aw_nextstate;
	end
    always@(*) begin
        case(aw_state)
        AW_Q:begin
            if(data_sram_req&&data_sram_wr)
                    aw_nextstate<=AW_HS;
            else    aw_nextstate<=AW_Q;
        end
        AW_HS:begin
            if(awready&&awvalid)        aw_nextstate<=AW_W;
            else                        aw_nextstate<=AW_HS;
        end
        AW_W:begin
            if(wready&&wvalid&&wlast)   aw_nextstate<=AW_Q;
            else                        aw_nextstate<=AW_W;
        end
        default:aw_nextstate<=AW_Q;
        endcase
    end
always@(posedge clk) begin
    if(reset)       awvalid_r<=0;
    else if(aw_state==AW_HS) begin
        if(awready) awvalid_r<=0;
        else        awvalid_r<=1;
    end
    else            awvalid_r<=0;
end
always@(posedge clk) begin
    if(reset)       wvalid_r<=0;
    else if(aw_state==AW_W) begin
        if(wready)  wvalid_r<=0;
        else        wvalid_r<=1;
    end
    else            wvalid_r<=0;
end
always@(posedge clk) begin
    if(aw_state==AW_Q) begin
        if(data_sram_req && data_sram_wr) begin
            awaddr_r<=data_sram_addr;
            awsize_r<=data_sram_size;
            wdata_r <=data_sram_wdata;
            wstrb_r <=data_sram_wstrb;    
        end
    end
end

assign       awid   = 4'b1;
assign       awlen  = 8'b0;
assign       awburst= 2'b01;
assign       awlock = 2'b0;
assign       awcache= 4'b0;
assign       awprot = 3'b0;
assign       wid   = 4'b1;
assign       wlast  =1'b1;

//write response
reg         bready_r;   //record addr of last AW TRANSACTION(data only)
reg [31:0]  baddr_r;
	parameter B_FIN     = 2'b00;    //FINISHED
    parameter B_WAIT    = 2'b01;    //WAIT FOR RESPONSE
    reg [1:0] b_state;
	reg [1:0] b_nextstate;
	always@(posedge clk) begin
		if(reset)   b_state<=B_FIN;
		else        b_state<=b_nextstate;
	end
    always@(*) begin
        case(b_state)
        B_FIN:begin
            if(wready && wvalid)    b_nextstate<=B_WAIT;
            else                    b_nextstate<=B_FIN;
        end
        B_WAIT:begin
            if(bready && bvalid)    b_nextstate<=B_FIN;
            else                    b_nextstate<=B_WAIT;
        end
        default:b_nextstate<=B_FIN;
        endcase
    end
always@(posedge clk) begin
    if(b_state==B_WAIT) begin
        if(bvalid)  bready_r<=0;
        else        bready_r<=1;
    end
    else            bready_r<=0;
end
always@(posedge clk) begin
    if(aw_state==AW_Q)
        if(data_sram_req && data_sram_wr)
            baddr_r<=data_sram_addr;
end
endmodule