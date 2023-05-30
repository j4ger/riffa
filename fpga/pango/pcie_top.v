`include "riffa.vh"

module pcie_top (
    input clock,
    perst_n,
    button_rst_n,

    //clk and rst
    input ref_clk_n,
    input ref_clk_p,

    //diff signals
    input       [1:0] rxn,
    input       [1:0] rxp,
    output wire [1:0] txn,
    output wire [1:0] txp


);

  localparam C_NUM_CHNL = 1;
  localparam C_PCI_DATA_WIDTH = 128;

  wire                                       rst_out;
  wire [                     C_NUM_CHNL-1:0] chnl_rx_clk;
  wire [                     C_NUM_CHNL-1:0] chnl_rx;
  wire [                     C_NUM_CHNL-1:0] chnl_rx_ack;
  wire [                     C_NUM_CHNL-1:0] chnl_rx_last;
  wire [(C_NUM_CHNL*`SIG_CHNL_LENGTH_W)-1:0] chnl_rx_len;
  wire [(C_NUM_CHNL*`SIG_CHNL_OFFSET_W)-1:0] chnl_rx_off;
  wire [  (C_NUM_CHNL*C_PCI_DATA_WIDTH)-1:0] chnl_rx_data;
  wire [                     C_NUM_CHNL-1:0] chnl_rx_data_valid;
  wire [                     C_NUM_CHNL-1:0] chnl_rx_data_ren;

  wire [                     C_NUM_CHNL-1:0] chnl_tx_clk;
  wire [                     C_NUM_CHNL-1:0] chnl_tx;
  wire [                     C_NUM_CHNL-1:0] chnl_tx_ack;
  wire [                     C_NUM_CHNL-1:0] chnl_tx_last;
  wire [(C_NUM_CHNL*`SIG_CHNL_LENGTH_W)-1:0] chnl_tx_len;
  wire [(C_NUM_CHNL*`SIG_CHNL_OFFSET_W)-1:0] chnl_tx_off;
  wire [  (C_NUM_CHNL*C_PCI_DATA_WIDTH)-1:0] chnl_tx_data;
  wire [                     C_NUM_CHNL-1:0] chnl_tx_data_valid;
  wire [                     C_NUM_CHNL-1:0] chnl_tx_data_ren;

  wire                                       reset = ~perst_n;

  riffa_pango #(
      .C_NUM_CHNL(1),
      .C_PCI_DATA_WIDTH(128)
  ) riffa_inst (
      .USER_CLK  (clock),
      .USER_RESET(reset),

      .RST_OUT(rst_out),

      .CHNL_RX_CLK(chnl_rx_clk),
      .CHNL_RX(chnl_rx),
      .CHNL_RX_ACK(chnl_rx_ack),
      .CHNL_RX_LAST(chnl_rx_last),
      .CHNL_RX_LEN(chnl_rx_len),
      .CHNL_RX_OFF(chnl_rx_off),
      .CHNL_RX_DATA(chnl_rx_data),
      .CHNL_RX_DATA_VALID(chnl_rx_data_valid),
      .CHNL_RX_DATA_REN(chnl_rx_data_ren),
      // Tx interface
      .CHNL_TX_CLK(chnl_tx_clk),
      .CHNL_TX(chnl_tx),
      .CHNL_TX_ACK(chnl_tx_ack),
      .CHNL_TX_LAST(chnl_tx_last),
      .CHNL_TX_LEN(chnl_tx_len),
      .CHNL_TX_OFF(chnl_tx_off),
      .CHNL_TX_DATA(chnl_tx_data),
      .CHNL_TX_DATA_VALID(chnl_tx_data_valid),
      .CHNL_TX_DATA_REN(chnl_tx_data_ren),

      .ref_clk_n(ref_clk_n),
      .ref_clk_p(ref_clk_p),

      .rxn(rxn),
      .rxp(rxp),
      .txn(txn),
      .txp(txp)

  );


  chnl_tester #(
      .C_PCI_DATA_WIDTH(128)
  ) module1 (
      .CLK(clock),
      .RST(rst_out),  // riffa_reset includes riffa_endpoint resets
      // Rx interface
      .CHNL_RX_CLK(chnl_rx_clk),
      .CHNL_RX(chnl_rx),
      .CHNL_RX_ACK(chnl_rx_ack),
      .CHNL_RX_LAST(chnl_rx_last),
      .CHNL_RX_LEN(chnl_rx_len),
      .CHNL_RX_OFF(chnl_rx_off),
      .CHNL_RX_DATA(chnl_rx_data),
      .CHNL_RX_DATA_VALID(chnl_rx_data_valid),
      .CHNL_RX_DATA_REN(chnl_rx_data_ren),
      // Tx interface
      .CHNL_TX_CLK(chnl_tx_clk),
      .CHNL_TX(chnl_tx),
      .CHNL_TX_ACK(chnl_tx_ack),
      .CHNL_TX_LAST(chnl_tx_last),
      .CHNL_TX_LEN(chnl_tx_len),
      .CHNL_TX_OFF(chnl_tx_off),
      .CHNL_TX_DATA(chnl_tx_data),
      .CHNL_TX_DATA_VALID(chnl_tx_data_valid),
      .CHNL_TX_DATA_REN(chnl_tx_data_ren)
  );


endmodule
