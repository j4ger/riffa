`include "trellis.vh"  // Defines the user-facing signal widths.
`include "functions.vh"
// `include "xilinx.vh" // [pango] not used
module translation_pango #(  // [pango] change name
    parameter C_PCI_DATA_WIDTH = 128
) (
    input CLK,
    input RST_IN,

    // Interface: [pango] RX 
    input [127:0] M_AXIS_RX_TDATA,
    input [3:0] M_AXIS_RX_TKEEP,  // [pango] 1 bit represents enable signal for 32 bits
    input M_AXIS_RX_TLAST,
    input M_AXIS_RX_TVALID,
    output M_AXIS_RX_TREADY,
    input [7:0] M_AXIS_RX_TUSER,
    //    output RX_NP_OK,
    //    output RX_NP_REQ,

    // Interface: [pango] TX
    output [127:0] S_AXIS_TX_TDATA,
    //    output [(C_PCI_DATA_WIDTH/8)-1:0] S_AXIS_TX_TKEEP, // [pango] not used
    output         S_AXIS_TX_TLAST,
    output         S_AXIS_TX_TVALID,
    input          S_AXIS_TX_TREADY,
    output         S_AXIS_TX_TUSER,   // [pango] 1 bit
    //     output         TX_CFG_GNT, // [pango] not used

    // Interface: [pango] Configuration 
    input [7:0] CFG_BUS_NUMBER,
    input [4:0] CFG_DEVICE_NUMBER,
    input [2:0] CFG_MAX_PAYLOAD_SIZE,  // [pango] additional
    input CFG_BUS_MASTER_EN,  // [pango] additional 
    input CFG_MAX_READ_REQUEST_SIZE,  // [pango] additional
    input CFG_RCB,  // [pango] additional
    // [pango] does not exist
    //    input [  `SIG_FNID_W-1:0] CFG_FUNCTION_NUMBER,
    //    input [`SIG_CFGREG_W-1:0] CFG_COMMAND,
    //    input [`SIG_CFGREG_W-1:0] CFG_DCOMMAND,
    //    input [`SIG_CFGREG_W-1:0] CFG_LSTATUS,
    //    input [`SIG_CFGREG_W-1:0] CFG_LCOMMAND,

    // Interface: [pango] Flow Control: 
    input [`SIG_FC_CPLD_W-1:0] FC_CPLD,  // [pango] xadm_cpld_cdts
    input [`SIG_FC_CPLH_W-1:0] FC_CPLH,  // [pango] xadm_cplh_cdts
    //    output [ `SIG_FC_SEL_W-1:0] FC_SEL,

    // Interface: [pango] Interrupt
    input CFG_INTERRUPT_MSIEN,  // [pango] cfg_msi_en
    input CFG_INTERRUPT_RDY,  // [pango] ven_msi_grant
    output CFG_INTERRUPT,  // [pango] ven_msi_req

    // Interface: RX Classic
    output [           C_PCI_DATA_WIDTH-1:0] RX_TLP,
    output                                   RX_TLP_VALID,
    output                                   RX_TLP_START_FLAG,
    output [clog2s(C_PCI_DATA_WIDTH/32)-1:0] RX_TLP_START_OFFSET,
    output                                   RX_TLP_END_FLAG,
    output [clog2s(C_PCI_DATA_WIDTH/32)-1:0] RX_TLP_END_OFFSET,
    output [           `SIG_BARDECODE_W-1:0] RX_TLP_BAR_DECODE,
    input                                    RX_TLP_READY,

    // Interface: TX Classic
    output                                   TX_TLP_READY,
    input  [           C_PCI_DATA_WIDTH-1:0] TX_TLP,
    input                                    TX_TLP_VALID,
    input                                    TX_TLP_START_FLAG,
    input  [clog2s(C_PCI_DATA_WIDTH/32)-1:0] TX_TLP_START_OFFSET,
    input                                    TX_TLP_END_FLAG,
    input  [clog2s(C_PCI_DATA_WIDTH/32)-1:0] TX_TLP_END_OFFSET,

    // Interface: Configuration
    output [     `SIG_CPLID_W-1:0] CONFIG_COMPLETER_ID,
    output                         CONFIG_BUS_MASTER_ENABLE,
    output [ `SIG_LINKWIDTH_W-1:0] CONFIG_LINK_WIDTH,
    output [  `SIG_LINKRATE_W-1:0] CONFIG_LINK_RATE,
    output [   `SIG_MAXREAD_W-1:0] CONFIG_MAX_READ_REQUEST_SIZE,
    output [`SIG_MAXPAYLOAD_W-1:0] CONFIG_MAX_PAYLOAD_SIZE,
    output                         CONFIG_INTERRUPT_MSIENABLE,
    output                         CONFIG_CPL_BOUNDARY_SEL,

    // Interface: Flow Control
    output [`SIG_FC_CPLD_W-1:0] CONFIG_MAX_CPL_DATA,
    output [`SIG_FC_CPLH_W-1:0] CONFIG_MAX_CPL_HDR,

    // Interface: Interrupt     
    output INTR_MSI_RDY,     // High when interrupt is able to be sent
    input  INTR_MSI_REQUEST  // High to request interrupt
);
  /* 
     Notes on the Configuration Interface:
     Link Width (cfg_lstatus[9:4]): 000001=x1, 000010=x2, 000100=x4, 001000=x8, 001100=x12, 010000=x16
     Link Rate (cfg_lstatus[3:0]): 0001=2.5GT/s, 0010=5.0GT/s, 0011=8.0GT/s
     Max Read Request Size (cfg_dcommand[14:12]): 000=128B, 001=256B, 010=512B, 011=1024B, 100=2048B, 101=4096B
     Max Payload Size (cfg_dcommand[7:5]): 000=128B, 001=256B, 010=512B, 011=1024B
     Bus Master Enable (cfg_command[2]): 1=Enabled, 0=Disabled
     Read Completion Boundary (cfg_lcommand[3]): 0=64 bytes, 1=128 bytes
     MSI Enable (cfg_msicsr[0]): 1=Enabled, 0=Disabled
     
     Notes on the Flow Control Interface:
     FC_CPLD (Xilinx) Receive credit limit for data 
     FC_CPLH (Xilinx) Receive credit limit for headers 
     FC_SEL (Xilinx Only) Selects the correct output on the FC_* signals

     Notes on the TX Interface:
     TX_CFG_GNT (Xilinx): 1=Always allow core to transmit internally generated TLPs
     
     Notes on the RX Interface:
     RX_NP_OK (Xilinx): 1=Always allow non posted transactions
     */

  /*AUTOWIRE*/

  reg rRxTlpValid;
  reg rRxTlpEndFlag;

  // Rx Interface (From PCIe Core)
  assign RX_TLP                       = M_AXIS_RX_TDATA;
  assign RX_TLP_VALID                 = M_AXIS_RX_TVALID;

  // Rx Interface (To PCIe Core)
  assign M_AXIS_RX_TREADY             = RX_TLP_READY;

  // TX Interface (From PCIe Core)
  assign TX_TLP_READY                 = S_AXIS_TX_TREADY;

  // TX Interface (TO PCIe Core)
  assign S_AXIS_TX_TDATA              = TX_TLP;
  assign S_AXIS_TX_TVALID             = TX_TLP_VALID;
  assign S_AXIS_TX_TLAST              = TX_TLP_END_FLAG;
  assign S_AXIS_TX_TUSER              = 0;  // [pango] don't drop

  // Configuration Interface
  assign CONFIG_COMPLETER_ID          = {CFG_BUS_NUMBER, CFG_DEVICE_NUMBER, 0};
  assign CONFIG_BUS_MASTER_ENABLE     = CFG_BUS_MASTER_EN;  // [pango] 1 additional port
  assign CONFIG_LINK_WIDTH            = 6'b000100;  // [pango] define as PCI-e x4
  assign CONFIG_LINK_RATE             = 4'b0001;  // [pango] define as 2.5GT/s only
  assign CONFIG_MAX_READ_REQUEST_SIZE = CFG_MAX_READ_REQUEST_SIZE;  // [pango] 1 additional port
  assign CONFIG_MAX_PAYLOAD_SIZE      = CFG_MAX_PAYLOAD_SIZE;  // [pango] 1 additional port
  assign CONFIG_INTERRUPT_MSIENABLE   = CFG_INTERRUPT_MSIEN;
  assign CONFIG_CPL_BOUNDARY_SEL      = CFG_RCB;  // [pango] 1 additional port
  assign CONFIG_MAX_CPL_DATA          = FC_CPLD;
  assign CONFIG_MAX_CPL_HDR           = FC_CPLH;

  //  assign FC_SEL                       = `SIG_FC_SEL_RX_MAXALLOC_V; // [pango] not used
  //  assign RX_NP_OK = 1'b1;
  //  assign RX_NP_REQ = 1'b1;
  //  assign TX_CFG_GNT                   = 1'b1; // [pango] not used

  // Interrupt interface
  assign CFG_INTERRUPT                = INTR_MSI_REQUEST;
  assign INTR_MSI_RDY                 = CFG_INTERRUPT_RDY;
  assign RX_TLP_START_FLAG            = ~rRxTlpValid | rRxTlpEndFlag;
  assign RX_TLP_START_OFFSET          = {clog2s(128 / 32) {1'b0}};
  assign RX_TLP_END_OFFSET            = 0;
  assign RX_TLP_END_FLAG              = M_AXIS_RX_TLAST;
  //   assign S_AXIS_TX_TKEEP = 4'hF;  // [pango] not used


  always @(posedge CLK) begin
    rRxTlpValid   <= RX_TLP_VALID;
    rRxTlpEndFlag <= RX_TLP_END_FLAG;
  end
endmodule  // translation_layer
