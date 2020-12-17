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
    output[31:0]                    cp0_EPC_bus,
    //TLB search
    output [ 7:0]    s0_asid,

    output [ 18:0]   entryhi_vpn2,
    output           s1_odd_page,
    output [ 7:0]    s1_asid,
    
     // write port
    output [3:0] w_index,
    output [ 18:0] w_vpn2,
    output [ 7:0] w_asid,
    output w_g,
    output [ 19:0] w_pfn0,
    output [ 2:0] w_c0,
    output w_d0,
    output w_v0,
    output [ 19:0] w_pfn1,
    output [ 2:0] w_c1,
    output w_d1,
    output w_v1,

    output [3:0] r_index,
    input [ 18:0] r_vpn2,
    input [ 7:0] r_asid,
    input r_g,
    input [ 19:0] r_pfn0,
    input [ 2:0] r_c0,
    input r_d0,
    input r_v0,
    input [ 19:0] r_pfn1,
    input [ 2:0] r_c1,
    input r_d1,
    input r_v1
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
    {32{cp0_addr==`CR_BVADDR}}  & cp0_bvaddr         |
    {32{cp0_addr==`CR_ENTRYHI}} & cp0_EntryHi_rdata  |
    {32{cp0_addr==`CR_ENTRYLO0}} & cp0_EntryLo0_rdata  |
    {32{cp0_addr==`CR_ENTRYLO1}} & cp0_EntryLo1_rdata  |
    {32{cp0_addr==`CR_INDEX}} & cp0_index_rdata  
    ;
wire        eret_flush;
wire        mtc0_we;
wire [7:0]  cp0_addr;
wire [31:0] cp0_wdata;
wire [4:0]  ws_excp_execode;
wire [31:0] ws_excp_bvaddr;
wire [31:0] ws_pc;
wire        ws_bd;
wire        tlbp_we;
wire        tlbr_we;
wire        s1_found;
wire [3:0]  s1_index;
wire        fs_tlbl;
assign {    fs_tlbl,//119
            tlbr_we,//118
            tlbp_we,//117
            s1_found,//116
            s1_index,//115:112
            mtc0_we,//111 
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
    if(ws_to_cp0_valid && fs_tlbl)begin
        cp0_EPC <= ws_excp_bvaddr;
    end
    else if(ws_to_cp0_valid && !cp0_status_EXL)
        cp0_EPC <= ws_bd ? ws_pc-32'd4 : ws_pc;
    else if(mtc0_we && cp0_addr==`CR_EPC)
        cp0_EPC <= cp0_wdata;
end
//{                                            } == bvaddr
reg [31:0]  cp0_bvaddr;
always @(posedge clk) begin
    if(ws_to_cp0_valid &&  (ws_excp_execode==5'h04 || ws_excp_execode==5'h05 || ws_excp_execode == 5'h02 || ws_excp_execode == 5'h03 || ws_excp_execode == 5'h01))
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
/*
output [3:0] w_index,
    output [ 18:0] w_vpn2,
    output [ 7:0] w_asid,
    output w_g,
    output [ 19:0] w_pfn0,
    output [ 2:0] w_c0,
    output w_d0,
    output w_v0,
    output [ 19:0] w_pfn1,
    output [ 2:0] w_c1,
    output w_d1,
    output w_v1,
*/
//For TLB 
assign s0_asid = cp0_EntryHi_ASID;
assign s1_asid = cp0_EntryHi_ASID;
assign entryhi_vpn2 = cp0_EntryHi_VPN2;
assign r_index = cp0_index_Index;

assign w_index = cp0_index_Index;
assign w_vpn2 = cp0_EntryHi_VPN2;
assign w_asid = cp0_EntryHi_ASID;
assign w_g = cp0_EntryLo1_G1 & cp0_EntryLo0_G0; //!!!&
assign w_pfn0 = cp0_EntryLo0_PFN0;
assign w_c0 = cp0_EntryLo0_C0;
assign w_d0 = cp0_EntryLo0_D0;
assign w_v0 = cp0_EntryLo0_V0;
assign w_pfn1 = cp0_EntryLo1_PFN1;
assign w_c1 = cp0_EntryLo1_C1;
assign w_d1 = cp0_EntryLo1_D1;
assign w_v1 = cp0_EntryLo1_V1;
//EntryHi
reg [18:0] cp0_EntryHi_VPN2;
reg [7:0]  cp0_EntryHi_ASID;
wire [31:0] cp0_EntryHi_rdata;
assign cp0_EntryHi_rdata = {cp0_EntryHi_VPN2,5'b0,cp0_EntryHi_ASID};
always @(posedge clk) begin
    if (reset) begin
        cp0_EntryHi_VPN2 <= 0;
    end
    else if (ws_to_cp0_valid && (ws_excp_execode == 5'h02 || ws_excp_execode == 5'h03 || ws_excp_execode == 5'h01)) begin
        cp0_EntryHi_VPN2 <= ws_excp_bvaddr[31:13];
    end
    else if (mtc0_we &&cp0_addr == `CR_ENTRYHI) begin
        cp0_EntryHi_VPN2 <=cp0_wdata[31:13];
    end
    else if (tlbr_we) begin
        cp0_EntryHi_VPN2 <= r_vpn2;
    end
end
always @(posedge clk) begin
    if (reset) begin
        cp0_EntryHi_ASID <= 0;
    end
    else if (mtc0_we &&cp0_addr == `CR_ENTRYHI) begin
        cp0_EntryHi_ASID <= cp0_wdata[7:0];
    end
    else if (tlbr_we) begin
        cp0_EntryHi_ASID <=r_asid;
    end
end
//EntryLo1
reg [19:0] cp0_EntryLo1_PFN1;
reg [ 2:0] cp0_EntryLo1_C1;
reg        cp0_EntryLo1_D1;
reg        cp0_EntryLo1_V1;
reg        cp0_EntryLo1_G1;
wire [31:0] cp0_EntryLo1_rdata;
assign cp0_EntryLo1_rdata = {6'b0,cp0_EntryLo1_PFN1,cp0_EntryLo1_C1,cp0_EntryLo1_D1,cp0_EntryLo1_V1,cp0_EntryLo1_G1};
always @(posedge clk) begin
    if (reset) begin
        cp0_EntryLo1_PFN1 <= 0;
    end
    else if (mtc0_we &&cp0_addr == `CR_ENTRYLO1) begin
        cp0_EntryLo1_PFN1 <= cp0_wdata[25:6];
    end
    else if (tlbr_we) begin
        cp0_EntryLo1_PFN1 <= r_pfn1;
    end
end
always @(posedge clk) begin
    if (reset) begin
        cp0_EntryLo1_C1 <= 0;
    end
    else if (mtc0_we &&cp0_addr == `CR_ENTRYLO1) begin
        cp0_EntryLo1_C1 <= cp0_wdata[5:3];
    end
    else if (tlbr_we) begin
        cp0_EntryLo1_C1 <= r_c1;
    end
end
always @(posedge clk) begin
    if (reset) begin
        cp0_EntryLo1_V1 <= 0;
    end
    else if (mtc0_we &&cp0_addr == `CR_ENTRYLO1) begin
        cp0_EntryLo1_V1 <=cp0_wdata[1];
    end
    else if (tlbr_we) begin
       cp0_EntryLo1_V1 <= r_v1; 
    end
end
always @(posedge clk) begin
    if (reset) begin
        cp0_EntryLo1_D1 <= 0;
    end
    else if (mtc0_we &&cp0_addr == `CR_ENTRYLO1) begin
        cp0_EntryLo1_D1 <=cp0_wdata[2];
    end
    else if (tlbr_we) begin
        cp0_EntryLo1_D1 <= r_d1;
    end
end
always @(posedge clk) begin
    if (reset) begin
        cp0_EntryLo1_G1 <= 0;
    end
    else if (mtc0_we &&cp0_addr == `CR_ENTRYLO1) begin
        cp0_EntryLo1_G1 <= cp0_wdata[0];
    end
    else if (tlbr_we) begin
        cp0_EntryLo1_G1 <= r_g;
    end
end
//EntryLo0
reg [19:0] cp0_EntryLo0_PFN0;
reg [ 2:0] cp0_EntryLo0_C0;
reg        cp0_EntryLo0_D0;
reg        cp0_EntryLo0_V0;
reg        cp0_EntryLo0_G0;
wire [31:0] cp0_EntryLo0_rdata;
assign cp0_EntryLo0_rdata = {6'b0,cp0_EntryLo0_PFN0,cp0_EntryLo0_C0,cp0_EntryLo0_D0,cp0_EntryLo0_V0,cp0_EntryLo0_G0} ;
always @(posedge clk) begin
    if (reset) begin
        cp0_EntryLo0_PFN0 <= 0;
    end
    else if (mtc0_we &&cp0_addr == `CR_ENTRYLO0) begin
        cp0_EntryLo0_PFN0 <= cp0_wdata[25:6];
    end
    else if (tlbr_we) begin
       cp0_EntryLo0_PFN0 <= r_pfn0; 
    end
end
always @(posedge clk) begin
    if (reset) begin
        cp0_EntryLo0_C0 <= 0;
    end
    else if (mtc0_we &&cp0_addr == `CR_ENTRYLO0) begin
        cp0_EntryLo0_C0 <= cp0_wdata[5:3];
    end
    else if (tlbr_we) begin
        cp0_EntryLo0_C0 <= r_c0;
    end
end
always @(posedge clk) begin
    if (reset) begin
        cp0_EntryLo0_V0 <= 0;
    end
    else if (mtc0_we &&cp0_addr == `CR_ENTRYLO0) begin
        cp0_EntryLo0_V0 <= cp0_wdata[1];
    end
    else if (tlbr_we) begin
        cp0_EntryLo0_V0 <= r_v0;
    end
end
always @(posedge clk) begin
    if (reset) begin
        cp0_EntryLo0_D0 <= 0;
    end
    else if (mtc0_we &&cp0_addr == `CR_ENTRYLO0) begin
        cp0_EntryLo0_D0 <= cp0_wdata[2];
    end
    else if (tlbr_we) begin
        cp0_EntryLo0_D0 <= r_d0;
    end
end
always @(posedge clk) begin
    if (reset) begin
        cp0_EntryLo0_G0 <= 0;
    end
    else if (mtc0_we &&cp0_addr == `CR_ENTRYLO0) begin
        cp0_EntryLo0_G0 <= cp0_wdata[0];
    end
    else if (tlbr_we) begin
        cp0_EntryLo0_G0 <= r_g;
    end
end
//Index
reg cp0_index_P;
reg [3:0] cp0_index_Index;
wire [31:0] cp0_index_rdata;
assign cp0_index_rdata ={cp0_index_P,27'b0,cp0_index_Index} ;
always @(posedge clk ) begin
    if (reset) begin
        // reset
        cp0_index_P<=1'b0;
        cp0_index_Index <= 4'b0;
    end
    else if (mtc0_we && cp0_addr == `CR_INDEX) begin
        cp0_index_Index <= cp0_wdata[3:0];
    end
    else if (tlbp_we)begin
        cp0_index_P <= !s1_found;//P=0 found P=1 notfound
        cp0_index_Index <= s1_index;
    end
end
endmodule