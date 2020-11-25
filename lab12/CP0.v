`include "mycpu.h"

module cp0 (
    input                           clk           ,
    input                           reset         ,
    //from ws
    input [`WS_TO_CP0_BUS_WD-1:0]   ws_to_cp0_bus  ,
    input                           ws_to_cp0_valid,
    //to fs\ds\es\ms\ws
    //general-rdata-EPC
    output[`CP0_GENERAL_BUS_WD-1:0] cp0_general_bus,
    output[7:0]                     cp0_cause_IP_bus,
    output[31:0]                    cp0_rdata_bus,
    output[31:0]                    cp0_EPC_bus
);
assign cp0_general_bus ={
                        eret_flush,     //10
                        cp0_status_IM,  //9:2
                        cp0_status_EXL, //1
                        cp0_status_IE   //0
};
assign cp0_cause_IP_bus = cp0_cause_IP;
assign cp0_EPC_bus   = cp0_EPC;
assign cp0_rdata_bus = cp0_rdata;
wire [31:0] cp0_rdata;
assign cp0_rdata = 
    {32{cp0_addr==`CR_STATUS}}  & cp0_status_rdata   |
    {32{cp0_addr==`CR_CAUSE}}   & cp0_cause_rdata    |
    {32{cp0_addr==`CR_EPC}}     & cp0_EPC            |
    {32{cp0_addr==`CR_COUNT}}   & cp0_count          |
    {32{cp0_addr==`CR_COMPARE}} & cp0_compare        |
    {32{cp0_addr==`CR_BVADDR}}  & cp0_bvaddr
    ;
wire        eret_flush;
wire        mtc0_we;
wire [7:0]  cp0_addr;
wire [31:0] cp0_wdata;
wire [4:0]  ws_excp_execode;
wire [31:0] ws_excp_bvaddr;
wire [31:0] ws_pc;
wire        ws_bd;

assign {    mtc0_we,//111 
            ws_excp_bvaddr, //110:79
            eret_flush,     //78
            cp0_addr,       //77:70
            cp0_wdata,      //69:38
            ws_excp_execode,//37:33
            ws_pc,          //32:1
            ws_bd           //0
} = ws_to_cp0_bus;
//{BD,TI,14'b0,       IP,   1'b0,execode,2'b0  } == cause
// 31 30 29:16        15:8  7    6:2     1:0
reg         cp0_cause_BD;
reg         cp0_cause_TI;
reg [7:0]   cp0_cause_IP;
reg [4:0]   cp0_cause_execode;
wire[31:0]  cp0_cause_rdata;
assign cp0_cause_rdata  = { cp0_cause_BD,
                        cp0_cause_TI,
                        14'b0,
                        cp0_cause_IP,
                        1'b0,
                        cp0_cause_execode,
                        2'b0};
always @(posedge clk) begin
    
end
//{9'b0,bev=1'b1,6'b0,IM,   6'b0,        EXL,IE} == status
reg         cp0_status_bev;
reg [7:0]   cp0_status_IM;
reg         cp0_status_EXL;
reg         cp0_status_IE;
wire[31:0]  cp0_status_rdata;
assign cp0_status_rdata = { 9'b0,
                            cp0_status_bev,
                            6'b0,
                            cp0_status_IM,
                            6'b0,
                            cp0_status_EXL,
                            cp0_status_IE};
always @(posedge clk) begin
    if(reset) begin
        cp0_status_bev <= 1;
    end
end
always @(posedge clk) begin
    if(reset)   cp0_status_IM <= 8'b0;
    else if(mtc0_we && cp0_addr==`CR_STATUS)
                cp0_status_IM <= cp0_wdata[15:8];
end
always @(posedge clk) begin
    if(reset)   cp0_status_EXL <= 1'b0;
    else if(ws_to_cp0_valid)
                cp0_status_EXL <= 1'b1;
    else if(eret_flush)
                cp0_status_EXL <= 1'b0;
    else if(mtc0_we && cp0_addr==`CR_STATUS)
                cp0_status_EXL <= cp0_wdata[1];
end
always @(posedge clk) begin
    if(reset)   cp0_status_IE <= 1'b0;
    else if(mtc0_we && cp0_addr==`CR_STATUS)
                cp0_status_IE <= cp0_wdata[0];
end
always @(posedge clk) begin
    if(reset)       cp0_cause_BD <= 1'b0;
    else if(ws_to_cp0_valid && !cp0_status_EXL)
                    cp0_cause_BD <= ws_bd;
end
always @(posedge clk) begin
    if(reset)       cp0_cause_TI <= 1'b0;
    else if(mtc0_we && cp0_addr == `CR_COMPARE)
                    cp0_cause_TI <= 1'b0;
    else if(count_eq_compare)
                    cp0_cause_TI <= 1'b1;
end
//NOTICE: no ext_int_in given
always @(posedge clk) begin
    if(reset)   cp0_cause_IP[7:2] <= 6'b0;
    else begin
                cp0_cause_IP[7]   <= cp0_cause_TI; 
    end

    if(reset)   cp0_cause_IP[1:0] <= 2'b0;
    else if(mtc0_we && cp0_addr==`CR_CAUSE)
                cp0_cause_IP[1:0] <= cp0_wdata[9:8];
end
always @(posedge clk) begin
    if(reset)       cp0_cause_execode <= 5'b0;
    else if(ws_to_cp0_valid)
                    cp0_cause_execode <= ws_excp_execode;
end
//{                                            } == EPC
reg [31:0]  cp0_EPC;
always @(posedge clk) begin
    if(ws_to_cp0_valid && !cp0_status_EXL)
        cp0_EPC <= ws_bd ? ws_pc-32'd4 : ws_pc;
    else if(mtc0_we && cp0_addr==`CR_EPC)
        cp0_EPC <= cp0_wdata;
end
//{                                            } == bvaddr
reg [31:0]  cp0_bvaddr;
always @(posedge clk) begin
    if(ws_to_cp0_valid &&  (ws_excp_execode==5'h04 || ws_excp_execode==5'h05))
        cp0_bvaddr <= ws_excp_bvaddr;
end
//{                                            } == count & compare
reg         tick;
wire        count_eq_compare;
reg [31:0]  cp0_count;
reg [31:0]  cp0_compare;
assign count_eq_compare = (cp0_count==cp0_compare);
always @(posedge clk) begin
    if(reset)   tick <= 1'b0;
    else        tick <= ~tick;

    if(mtc0_we && cp0_addr==`CR_COUNT)
                    cp0_count <= cp0_wdata;
    else if(tick)   cp0_count <= cp0_count + 32'b1;

    if(mtc0_we && cp0_addr==`CR_COMPARE)
        cp0_compare <= cp0_wdata;
end
endmodule