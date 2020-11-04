module mycpu_top(
    input         clk,
    input         resetn,
    // inst sram interface
    output        inst_sram_en,
    output [ 3:0] inst_sram_wen,
    output [31:0] inst_sram_addr,
    output [31:0] inst_sram_wdata,
    input  [31:0] inst_sram_rdata,
    // data sram interface
    output        data_sram_en,
    output [ 3:0] data_sram_wen,
    output [31:0] data_sram_addr,
    output [31:0] data_sram_wdata,
    input  [31:0] data_sram_rdata,
    // trace debug interface
    output [31:0] debug_wb_pc,
    output [ 3:0] debug_wb_rf_wen,
    output [ 4:0] debug_wb_rf_wnum,
    output [31:0] debug_wb_rf_wdata
);
reg         reset;
always @(posedge clk) reset <= ~resetn;

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
    .clk            (clk            ),
    .reset          (reset          ),
    //allowin
    .ds_allowin     (ds_allowin     ),
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
    .inst_sram_en   (inst_sram_en   ),
    .inst_sram_wen  (inst_sram_wen  ),
    .inst_sram_addr (inst_sram_addr ),
    .inst_sram_wdata(inst_sram_wdata),
    .inst_sram_rdata(inst_sram_rdata)
);
// ID stage
id_stage id_stage(
    .clk            (clk            ),
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
    .clk            (clk            ),
    .reset          (reset          ),
    //allowin
    .ms_allowin     (ms_allowin     ),
    .es_allowin     (es_allowin     ),
    .es_excp_valid  (es_excp_valid  ),
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
    .data_sram_en   (data_sram_en   ),
    .data_sram_wen  (data_sram_wen  ),
    .data_sram_addr (data_sram_addr ),
    .data_sram_wdata(data_sram_wdata)
);
// MEM stage
mem_stage mem_stage(
    .clk            (clk            ),
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
    //to ws
    .ms_to_ws_valid (ms_to_ws_valid ),
    .ms_to_ws_bus   (ms_to_ws_bus   ),
    //from cp0
    .cp0_general_bus(cp0_general_bus),
    //from data-sram
    .data_sram_rdata(data_sram_rdata)
);
// WB stage
wb_stage wb_stage(
    .clk            (clk            ),
    .reset          (reset          ),
    //allowin
    .ws_allowin     (ws_allowin     ),
    .ws_excp_valid  (ws_excp_valid  ),
    //from ms
    .ms_to_ws_valid (ms_to_ws_valid ),
    .ms_to_ws_bus   (ms_to_ws_bus   ),
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
    .clk            (clk            ),
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

endmodule
