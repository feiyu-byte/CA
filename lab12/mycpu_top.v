module mycpu_top(
    input    int       ,   //never used
    input    aclk      ,
    input    aresetn   ,   //low active
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
    output          bready    ,
    // trace debug interface
    output [31:0] debug_wb_pc,
    output [ 3:0] debug_wb_rf_wen,
    output [ 4:0] debug_wb_rf_wnum,
    output [31:0] debug_wb_rf_wdata
);
reg         reset;
always @(posedge aclk) reset <= ~aresetn;
wire         ms_inst_eret;
wire         ws_inst_eret;
wire         ds_allowin;
wire         es_allowin;
wire         ms_allowin;
wire         ws_allowin;
wire         fs_to_ds_valid;
wire         ds_to_es_valid;
wire         es_to_ms_valid;
wire         ms_to_ws_valid;
wire         ws_to_cp0_valid;
wire         out_es_valid;
wire         out_ms_valid;
wire         out_ws_valid;
wire         go_excp_entry;
wire         es_excp_valid;
wire         ms_excp_valid;
wire         ws_excp_valid;
wire [`FS_TO_DS_BUS_WD -1:0] fs_to_ds_bus;
wire [`DS_TO_ES_BUS_WD -1:0] ds_to_es_bus;
wire [`ES_TO_MS_BUS_WD -1:0] es_to_ms_bus;
wire [`MS_TO_WS_BUS_WD -1:0] ms_to_ws_bus;
wire [`WS_TO_RF_BUS_WD -1:0] ws_to_rf_bus;
wire [`BR_BUS_WD       -1:0] br_bus;
wire [`FW_BUS_WD       -1:0] es_to_ds_fw_bus;
wire [`FW_BUS_WD       -1:0] ms_to_ds_fw_bus;
wire [`FW_BUS_WD       -1:0] ws_to_ds_fw_bus;
wire [`WS_TO_CP0_BUS_WD-1:0] ws_to_cp0_bus;
wire [`CP0_GENERAL_BUS_WD-1:0] cp0_general_bus;
wire [31:0]                  cp0_EPC_bus;
wire [31:0]                  cp0_rdata_bus;
wire [7:0]                   cp0_cause_IP_bus;
// IF stage
if_stage if_stage(
    .clk            (aclk            ),
    .reset          (reset          ),
    //allowin
    .ds_allowin     (ds_allowin     ),
    .out_ws_valid   (out_ws_valid   ),
    //brbus
    .br_bus         (br_bus         ),
    //outputs
    .fs_to_ds_valid (fs_to_ds_valid ),
    .fs_to_ds_bus   (fs_to_ds_bus   ),
    //from cp0
    .cp0_general_bus(cp0_general_bus),
    .cp0_EPC_bus    (cp0_EPC_bus)   ,
    .go_excp_entry  (go_excp_entry) ,
    // inst sram interface
    .inst_sram_req    (inst_sram_req  ),
    .inst_sram_wr     (inst_sram_wr   ),
    .inst_sram_size   (inst_sram_size ),
    .inst_sram_wstrb  (inst_sram_wstrb),
    .inst_sram_addr   (inst_sram_addr ),
    .inst_sram_wdata  (inst_sram_wdata),
    .inst_sram_addr_ok(inst_sram_addr_ok),
    .inst_sram_data_ok(inst_sram_data_ok),
    .inst_sram_rdata  (inst_sram_rdata)
);
// ID stage
id_stage id_stage(
    .clk            (aclk            ),
    .reset          (reset          ),
    //exception
    .es_excp_valid  (es_excp_valid  ),
    .ms_excp_valid  (ms_excp_valid  ),
    .ws_excp_valid  (ws_excp_valid  ),
    //allowin
    .es_allowin     (es_allowin     ),
    .ds_allowin     (ds_allowin     ),
    //from fs
    .fs_to_ds_valid (fs_to_ds_valid ),
    .fs_to_ds_bus   (fs_to_ds_bus   ),
    //for block
    .ms_to_ws_bus   (ms_to_ws_bus   ),
    .es_to_ms_bus   (es_to_ms_bus   ),
    .es_to_ms_valid (es_to_ms_valid ),
    .ms_to_ws_valid (ms_to_ws_valid ),
    //for forward
    .es_to_ds_fw_bus(es_to_ds_fw_bus),
    .ms_to_ds_fw_bus(ms_to_ds_fw_bus),
    .ws_to_ds_fw_bus(ws_to_ds_fw_bus),
    .out_es_valid   (out_es_valid   ),
    .out_ms_valid   (out_ms_valid   ),
    .out_ws_valid   (out_ws_valid   ),
    .ms_res_from_mem(ms_res_from_mem),
    //to es
    .ds_to_es_valid (ds_to_es_valid ),
    .ds_to_es_bus   (ds_to_es_bus   ),
    //to fs
    .br_bus         (br_bus         ),
    //from cp0
    .cp0_general_bus    (cp0_general_bus    ),
    .cp0_cause_IP_bus   (cp0_cause_IP_bus   ),
    //to rf: for write back
    .ws_to_rf_bus   (ws_to_rf_bus   )
);
// EXE stage
exe_stage exe_stage(
    .clk            (aclk            ),
    .reset          (reset          ),
    //allowin
    .ms_allowin     (ms_allowin     ),
    .es_allowin     (es_allowin     ),
    .es_excp_valid  (es_excp_valid  ),
    .ms_excp_valid  (ms_excp_valid  ),
    .ws_excp_valid  (ws_excp_valid  ),
    .out_ms_valid   (out_ms_valid   ),
    .out_ws_valid   (out_ws_valid   ),
    .ms_inst_eret   (ms_inst_eret   ),
    .ws_inst_eret   (ws_inst_eret   ),
    //from ds
    .ds_to_es_valid (ds_to_es_valid ),
    .ds_to_es_bus   (ds_to_es_bus   ),
    //forward
    .es_to_ds_fw_bus(es_to_ds_fw_bus),
    .out_es_valid   (out_es_valid   ),
    //to ms
    .es_to_ms_valid (es_to_ms_valid ),
    .es_to_ms_bus   (es_to_ms_bus   ),
    //from cp0
    .cp0_general_bus(cp0_general_bus),
    // data sram interface
    .data_sram_req    (data_sram_req  ),
    .data_sram_wr     (data_sram_wr   ),
    .data_sram_size   (data_sram_size ),
    .data_sram_wstrb  (data_sram_wstrb),
    .data_sram_addr   (data_sram_addr ),
    .data_sram_wdata  (data_sram_wdata),
    .data_sram_addr_ok(data_sram_addr_ok),
    .data_sram_data_ok(data_sram_data_ok)
);
// MEM stage
wire ms_res_from_mem;
mem_stage mem_stage(
    .clk            (aclk            ),
    .reset          (reset          ),
    //allowin
    .ws_allowin     (ws_allowin     ),
    .ms_allowin     (ms_allowin     ),
    .ms_excp_valid  (ms_excp_valid  ),
    //from es
    .es_to_ms_valid (es_to_ms_valid ),
    .es_to_ms_bus   (es_to_ms_bus   ),
    //forward
    .ms_to_ds_fw_bus(ms_to_ds_fw_bus),
    .out_ms_valid   (out_ms_valid   ),
    .ms_res_from_mem(ms_res_from_mem),
    //to ws
    .ms_to_ws_valid (ms_to_ws_valid ),
    .ms_to_ws_bus   (ms_to_ws_bus   ),
    .ms_inst_eret   (ms_inst_eret   ),
    //from cp0
    .cp0_general_bus(cp0_general_bus),
    //from data-sram
    .data_sram_data_ok(data_sram_data_ok),
    .data_sram_rdata(data_sram_rdata)
);
// WB stage
wb_stage wb_stage(
    .clk            (aclk            ),
    .reset          (reset          ),
    //allowin
    .ws_allowin     (ws_allowin     ),
    .ws_excp_valid  (ws_excp_valid  ),
    //from ms
    .ms_to_ws_valid (ms_to_ws_valid ),
    .ms_to_ws_bus   (ms_to_ws_bus   ),
    .ws_inst_eret   (ws_inst_eret   ),
    //forward
    .ws_to_ds_fw_bus(ws_to_ds_fw_bus),
    .out_ws_valid   (out_ws_valid   ),
    //to rf: for write back
    .ws_to_rf_bus   (ws_to_rf_bus   ),
    //trace debug interface
    .debug_wb_pc      (debug_wb_pc      ),
    .debug_wb_rf_wen  (debug_wb_rf_wen  ),
    .debug_wb_rf_wnum (debug_wb_rf_wnum ),
    .debug_wb_rf_wdata(debug_wb_rf_wdata),
    //from cp0
    .cp0_general_bus(cp0_general_bus    ),
    .cp0_rdata_bus  (cp0_rdata_bus      ),
    //to cp0
    .ws_to_cp0_bus    (ws_to_cp0_bus    ),
    .ws_to_cp0_valid  (ws_to_cp0_valid  ),
    //to IF
    .go_excp_entry    (go_excp_entry)
);
// CP0
cp0 cp0(
    .clk            (aclk            ),
    .reset          (reset          ),
    //from ws
    .ws_to_cp0_bus  (ws_to_cp0_bus  ),
    .ws_to_cp0_valid(ws_to_cp0_valid),
    //output
    .cp0_general_bus (cp0_general_bus ),
    .cp0_cause_IP_bus(cp0_cause_IP_bus),
    .cp0_rdata_bus   (cp0_rdata_bus   ),
    .cp0_EPC_bus     (cp0_EPC_bus     )
);
// inst sram interface
wire        inst_sram_req;
wire        inst_sram_wr;
wire [ 1:0] inst_sram_size;
wire [ 3:0] inst_sram_wstrb;
wire [31:0] inst_sram_addr;
wire [31:0] inst_sram_wdata;
wire         inst_sram_addr_ok;
wire         inst_sram_data_ok;
wire  [31:0] inst_sram_rdata;
// data sram interface
wire        data_sram_req;
wire        data_sram_wr;
wire [ 1:0] data_sram_size;
wire [ 3:0] data_sram_wstrb;
wire [31:0] data_sram_addr;
wire [31:0] data_sram_wdata;
wire         data_sram_addr_ok;
wire         data_sram_data_ok;
wire  [31:0] data_sram_rdata;
    
sram_to_axi_bridge sram_to_axi_bridge(
    .clk            (aclk            ),
    .reset          (reset          ),
    // slave: inst sram interface
    .inst_sram_req  (inst_sram_req  ),
    .inst_sram_wr   (inst_sram_wr   ),
    .inst_sram_size (inst_sram_size ),
    .inst_sram_wstrb(inst_sram_wstrb),
    .inst_sram_addr (inst_sram_addr ),
    .inst_sram_wdata(inst_sram_wdata),
    .inst_sram_addr_ok(inst_sram_addr_ok),
    .inst_sram_data_ok(inst_sram_data_ok),
    .inst_sram_rdata(inst_sram_rdata),
    // slave: data sram interface
    .data_sram_req  (data_sram_req  ),
    .data_sram_wr   (data_sram_wr   ),
    .data_sram_size (data_sram_size ),
    .data_sram_wstrb(data_sram_wstrb),
    .data_sram_addr (data_sram_addr ),
    .data_sram_wdata(data_sram_wdata),
    .data_sram_addr_ok(data_sram_addr_ok),
    .data_sram_data_ok(data_sram_data_ok),
    .data_sram_rdata(data_sram_rdata),
    //master:   axi
    //read request
    .arid      (arid        ),
    .araddr    (araddr      ),
    .arlen     (arlen       ),
    .arsize    (arsize      ),
    .arburst   (arburst     ),
    .arlock    (arlock      ),
    .arcache   (arcache     ),
    .arprot    (arprot      ),
    .arvalid   (arvalid     ),
    .arready   (arready     ),
    //read response
    .rid       (rid         ),
    .rdata     (rdata       ),
    .rresp     (rresp       ),
    .rlast     (rlast       ),
    .rvalid    (rvalid      ),
    .rready    (rready      ),
    //write request
    .awid      (awid        ),
    .awaddr    (awaddr      ),
    .awlen     (awlen       ),
    .awsize    (awsize      ),
    .awburst   (awburst     ),
    .awlock    (awlock      ),
    .awcache   (awcache     ),
    .awprot    (awprot      ),
    .awvalid   (awvalid     ),
    .awready   (awready     ),
    //write data
    .wid       (wid       ),
    .wdata     (wdata     ),
    .wstrb     (wstrb     ),
    .wlast     (wlast     ),
    .wvalid    (wvalid    ),
    .wready    (wready    ),
    //write response
    .bid       (bid       ),
    .bresp     (bresp     ),
    .bvalid    (bvalid    ),
    .bready    (bready    )
);
endmodule
