`ifndef MYCPU_H
    `define MYCPU_H
    ///to be changed!
    `define BR_BUS_WD       35
    `define FS_TO_DS_BUS_WD 71
    `define DS_TO_ES_BUS_WD 266
    `define ES_TO_MS_BUS_WD 160
    `define MS_TO_WS_BUS_WD 145
    `define WS_TO_RF_BUS_WD 39
    `define FW_BUS_WD 38
    ///undefined!
    `define CP0_GENERAL_BUS_WD  11
    `define WS_TO_CP0_BUS_WD    111
    ///define ALL cp0 reg addr in [rd\sel]
    //0<<3+12
    `define CR_STATUS   12
    //0<<3+13
    `define CR_CAUSE    13
    //0<<3+14
    `define CR_EPC      14
    //0<<3+8
    `define CR_BVADDR   8
    //0<<3+9
    `define CR_COUNT    9
    //0<<3+11
    `define CR_COMPARE  11
    
`endif
