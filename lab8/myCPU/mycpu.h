`ifndef MYCPU_H
    `define MYCPU_H
    ///to be changed!
    `define BR_BUS_WD       34
    `define FS_TO_DS_BUS_WD 70
    `define DS_TO_ES_BUS_WD 232
    `define ES_TO_MS_BUS_WD 127
    `define MS_TO_WS_BUS_WD 112
    `define WS_TO_RF_BUS_WD 39
    `define FW_BUS_WD 38
    ///undefined!
    `define CP0_GENERAL_BUS_WD  4
    `define WS_TO_CP0_BUS_WD    79
    ///define ALL cp0 reg addr in [rd\sel]
    //0<<3+12
    `define CR_STATUS   12
    //0<<3+13
    `define CR_CAUSE    13
    //0<<3+14
    `define CR_EPC      14
`endif
