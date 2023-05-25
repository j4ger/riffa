`include "trellis.vh"
`include "riffa.vh"
`include "functions.vh"
`timescale 1ps / 1ps

module riffa_pango #(
    C_NUM_CHNL = 1,
    C_PCI_DATA_WIDTH = 128
) (
    input USER_CLK,
    input USER_RESET,

    // RIFFA Interface Signals
    output RST_OUT,
    input [C_NUM_CHNL-1:0] CHNL_RX_CLK,  // Channel read clock
    output [C_NUM_CHNL-1:0] CHNL_RX,  // Channel read receive signal
    input [C_NUM_CHNL-1:0] CHNL_RX_ACK,  // Channel read received signal
    output [C_NUM_CHNL-1:0] CHNL_RX_LAST,  // Channel last read
    output [(C_NUM_CHNL*`SIG_CHNL_LENGTH_W)-1:0] CHNL_RX_LEN,  // Channel read length
    output [(C_NUM_CHNL*`SIG_CHNL_OFFSET_W)-1:0] CHNL_RX_OFF,  // Channel read offset
    output [(C_NUM_CHNL*C_PCI_DATA_WIDTH)-1:0] CHNL_RX_DATA,  // Channel read data
    output [C_NUM_CHNL-1:0] CHNL_RX_DATA_VALID,  // Channel read data valid
    input [C_NUM_CHNL-1:0] CHNL_RX_DATA_REN,  // Channel read data has been recieved

    input [C_NUM_CHNL-1:0] CHNL_TX_CLK,  // Channel write clock
    input [C_NUM_CHNL-1:0] CHNL_TX,  // Channel write receive signal
    output [C_NUM_CHNL-1:0] CHNL_TX_ACK,  // Channel write acknowledgement signal
    input [C_NUM_CHNL-1:0] CHNL_TX_LAST,  // Channel last write
    input [(C_NUM_CHNL*`SIG_CHNL_LENGTH_W)-1:0]  CHNL_TX_LEN, // Channel write length (in 32 bit words)
    input [(C_NUM_CHNL*`SIG_CHNL_OFFSET_W)-1:0] CHNL_TX_OFF,  // Channel write offset
    input [(C_NUM_CHNL*C_PCI_DATA_WIDTH)-1:0] CHNL_TX_DATA,  // Channel write data
    input [C_NUM_CHNL-1:0] CHNL_TX_DATA_VALID,  // Channel write data valid
    output [C_NUM_CHNL-1:0] CHNL_TX_DATA_REN,

    // pci-e IP

    //clk and rst
    input ref_clk_n,
    input ref_clk_p,

    //diff signals
    input       [3:0] rxn,
    input       [3:0] rxp,
    output wire [3:0] txn,
    output wire [3:0] txp

);
  wire [               3:0] M_AXIS_RX_TKEEP;  // [pango] 1 bit represents enable signal for 32 bits
  wire                      M_AXIS_RX_TLAST;
  wire                      M_AXIS_RX_TVALID;
  wire                      M_AXIS_RX_TREADY;
  wire [               7:0] M_AXIS_RX_TUSER;
  //    output RX_NP_OK,
  //    output RX_NP_REQ,

  // Interface: [pango] TX
  wire [             127:0] S_AXIS_TX_TDATA;
  //    output [(C_PCI_DATA_WIDTH/8)-1:0] S_AXIS_TX_TKEEP, // [pango] not used
  wire                      S_AXIS_TX_TLAST;
  wire                      S_AXIS_TX_TVALID;
  wire                      S_AXIS_TX_TREADY;
  wire                      S_AXIS_TX_TUSER;  // [pango] 1 bit
  //     output         TX_CFG_GNT, // [pango] not used

  // Interface: [pango] Configuration 
  wire [               7:0] CFG_BUS_NUMBER;
  wire [               4:0] CFG_DEVICE_NUMBER;
  wire [               2:0] CFG_MAX_PAYLOAD_SIZE;  // [pango] additional
  wire                      CFG_BUS_MASTER_EN;  // [pango] additional 
  wire                      CFG_MAX_READ_REQUEST_SIZE;  // [pango] additional
  wire                      CFG_RCB;  // [pango] additional
  // [pango] does not exist
  //    input [  `SIG_FNID_W-1:0] CFG_FUNCTION_NUMBER,
  //    input [`SIG_CFGREG_W-1:0] CFG_COMMAND,
  //    input [`SIG_CFGREG_W-1:0] CFG_DCOMMAND,
  //    input [`SIG_CFGREG_W-1:0] CFG_LSTATUS,
  //    input [`SIG_CFGREG_W-1:0] CFG_LCOMMAND,

  // Interface: [pango] Flow Control: 
  wire [`SIG_FC_CPLD_W-1:0] FC_CPLD;  // [pango] xadm_cpld_cdts
  wire [`SIG_FC_CPLH_W-1:0] FC_CPLH;  // [pango] xadm_cplh_cdts
  //    output [ `SIG_FC_SEL_W-1:0] FC_SEL,

  // Interface: [pango] Interrupt
  wire                      CFG_INTERRUPT_MSIEN;  // [pango] cfg_msi_en
  wire                      CFG_INTERRUPT_RDY;  // [pango] ven_msi_grant
  wire                      CFG_INTERRUPT;  // [pango] ven_msi_req

  riffa_wrapper_pango_generic wrapper (
      .M_AXIS_RX_TDATA (M_AXIS_RX_TDATA),
      .M_AXIS_RX_TKEEP (M_AXIS_RX_TKEEP),
      .M_AXIS_RX_TLAST (M_AXIS_RX_TLAST),
      .M_AXIS_RX_TVALID(M_AXIS_RX_TVALID),
      .M_AXIS_RX_TREADY(M_AXIS_RX_TREADY),
      .M_AXIS_RX_TUSER (M_AXIS_RX_TUSER),

      .S_AXIS_TX_TDATA (S_AXIS_TX_TDATA),
      .S_AXIS_TX_TLAST (S_AXIS_TX_TLAST),
      .S_AXIS_TX_TVALID(S_AXIS_TX_TVALID),
      .S_AXIS_TX_TREADY(S_AXIS_TX_TREADY),
      .S_AXIS_TX_TUSER (S_AXIS_TX_TUSER),

      .CFG_BUS_NUMBER(CFG_BUS_NUMBER),
      .CFG_DEVICE_NUMBER(CFG_DEVICE_NUMBER),
      .CFG_MAX_PAYLOAD_SIZE(CFG_MAX_PAYLOAD_SIZE),
      .CFG_BUS_MASTER_EN(CFG_BUS_MASTER_EN),
      .CFG_RCB(CFG_RCB),
      .CFG_MAX_READ_REQUEST_SIZE(CFG_MAX_READ_REQUEST_SIZE),

      .FC_CPLD(FC_CPLD),
      .FC_CPLH(FC_CPLH),

      .CFG_INTERRUPT_MSIEN(CFG_INTERRUPT_MSIEN),
      .CFG_INTERRUPT_RDY(CFG_INTERRUPT_RDY),
      .CFG_INTERRUPT(CFG_INTERRUPT),

      .USER_CLK  (USER_CLK),
      .USER_RESET(USER_RESET),

      .RST_OUT(RST_OUT),

      .CHNL_RX_CLK(CHNL_RX_CLK),
      .CHNL_RX(CHNL_RX),
      .CHNL_RX_ACK(CHNL_RX_ACK),
      .CHNL_RX_LAST(CHNL_RX_LAST),
      .CHNL_RX_LEN(CHNL_RX_LEN),
      .CHNL_RX_OFF(CHNL_RX_OFF),
      .CHNL_RX_DATA(CHNL_RX_DATA),
      .CHNL_RX_DATA_VALID(CHNL_RX_DATA_VALID),
      .CHNL_RX_DATA_REN(CHNL_RX_DATA_REN),

      .CHNL_TX_CLK(CHNL_TX_CLK),
      .CHNL_TX(CHNL_TX),
      .CHNL_TX_ACK(CHNL_TX_ACK),
      .CHNL_TX_LAST(CHNL_TX_LAST),
      .CHNL_TX_LEN(CHNL_TX_LEN),
      .CHNL_TX_OFF(CHNL_TX_OFF),
      .CHNL_TX_DATA(CHNL_TX_DATA),
      .CHNL_TX_DATA_VALID(CHNL_TX_DATA_VALID),
      .CHNL_TX_DATA_REN(CHNL_TX_DATA_REN)

  );

  wire rst_n;
  assign rst_n = ~USER_RESET;

  pcie_test pcie_inst (
      .ref_clk_n          (ref_clk_n),
      .ref_clk_p          (ref_clk_p),
      .power_up_rst_n     (rst_n),
      .perst_n            (rst_n),
      .rxn                (rxn),
      .rxp                (rxp),
      .txn                (txn),
      .txp                (txp),
      .axis_master_tvalid (M_AXIS_RX_TVALID),           // output
      .axis_master_tready (M_AXIS_RX_TREADY),           // input
      .axis_master_tdata  (M_AXIS_RX_TDATA),            // output [127:0]
      .axis_master_tkeep  (M_AXIS_RX_TKEEP),            // output [3:0]
      .axis_master_tlast  (M_AXIS_RX_TLAST),            // output
      .axis_master_tuser  (M_AXIS_RX_TUSER),            // output [7:0]
      .axis_slave0_tready (S_AXIS_TX_TREADY),           // output
      .axis_slave0_tvalid (S_AXIS_TX_TVALID),           // input
      .axis_slave0_tdata  (S_AXIS_TX_TDATA),            // input [127:0]
      .axis_slave0_tlast  (S_AXIS_TX_TLAST),            // input
      .axis_slave0_tuser  (S_AXIS_TX_TUSER),            // input
      .cfg_max_rd_req_size(CFG_MAX_READ_REQUEST_SIZE),
      .ven_msi_req        (CFG_INTERRUPT),
      .ven_msi_grant      (CFG_INTERRUPT_RDY),
      .cfg_msi_en         (CFG_INTERRUPT_MSIEN),
      .cfg_max_rd_req_size(CFG_MAX_READ_REQUEST_SIZE),
      .cfg_bus_master_en  (CFG_BUS_MASTER_EN),
      .cfg_rcb            (CFG_RCB),
      .cfg_pbus_num       (CFG_BUS_NUMBER),
      .cfg_pbus_dev_num   (CFG_DEVICE_NUMBER),
      .xadm_cpld_cdts     (FC_CPLD),
      .xadm_cplh_cdts     (FC_CPLH)

  );

endmodule
