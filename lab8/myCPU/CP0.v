module cp0 (
    input                           clk           ,
    input                           reset         ,
    //from ws
    input [`WS_TO_CP0_BUS_WD-1:0]   ws_to_cp0_bus  ,
    input                           ws_to_cp0_valid,
    //to fs\ds\es\ms\ws, for excp detection
    output[`CP0_TO_FS_BUS_WD-1:0]   cp0_to_fs_bus,
    output[`CP0_TO_DS_BUS_WD-1:0]   cp0_to_ds_bus,
    output[`CP0_TO_ES_BUS_WD-1:0]   cp0_to_es_bus,
    output[`CP0_TO_MS_BUS_WD-1:0]   cp0_to_ms_bus,
    output[`CP0_TO_WS_BUS_WD-1:0]   cp0_to_ws_bus,
    //to ws, for mfc0
    output[31:0]    cp0_rdata
);
assign cp0_rdata = 
    {32{cp0_addr==`CR_STATUS}}  & cp0_status_rdata   |
    {32{cp0_addr==`CR_CAUSE}}   & cp0_cause_rdata    |
    {32{cp0_addr==`CR_EPC}}     & cp0_EPC 
    ;

wire        mtc0_we;
wire [7:0]  cp0_addr;
wire [31:0] cp0_wdata;
wire [4:0]  ws_excp_execode;
wire [31:0] ws_pc;
wire        ws_bd;

assign {    cp0_addr,       //77:70
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
    if(mtc0_we && cp0_addr==`CR_STATUS)
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
                    cp0_cause_BD <= 1'b1;
end
//always @(posedge clk) begin
//   *TI\IP* 
//end
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
//0.check status(IE=1 && EXL=0)
//1.update EPC(ws_pc)\cause(execode=ws_excp_execode;IP)\status(IE=0;EXL=1) or more ?
//2.feedback to all stages to clear them (xs_valid=0)
//3.fs_pc = 32'hbfc00380
//ps: MFC0 & MTC0 & ERET to be implemented
//pps: ws_to_cp0_valid has been updated at the start of WS. maybe ONE cycle to process exception is enough.
//ppps: bus from cp0 to xs(x=f\d\e\m\w) to be added

//TODO: xs_bd: in branch delay slot for fs\ds\es\ms\ws
endmodule