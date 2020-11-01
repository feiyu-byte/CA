module cp0 (
    input                           clk           ,
    input                           reset         ,
    //from ws
    input [`WS_TOCP0_BUS_WD-1:0]    ws_to_cp0_bus  ,
    input                           ws_to_cp0_valid    
);
//{BD,TI,14'b0,       IP,   1'b0,execode,2'b0  } == cause
// 31 30 29:16        15:8  7    6:2     1:0
//{9'b0,bev=1'b1,6'b0,IM,   6'b0,        EXL,IE} == status
//{                                            } == EPC
///to be implemented!
//0.check status(IE=1 && IM[?]=1 && EXL=1)
//1.update EPC(ws_pc)\cause(execode=ws_excp_execode;IP)\status(IE=0;EXL=1) or more ?
//2.feedback to all stages to clear them (xs_valid=0)
//3.fs_pc = 32'hbfc00380
//ps: MFC0 & MTC0 & ERET to be implemented
//pps: ws_to_cp0_valid has been updated at the start of WS. maybe ONE cycle to process exception is enough.
//ppps: bus from cp0 to xs(x=f\d\e\m\w) to be added
endmodule