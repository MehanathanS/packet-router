package SW_Package;
import uvm_pkg::*;
`include "uvm_macros.svh"

`ifndef NUM_PORTS
  `define NUM_PORTS 4
`endif
parameter NUM_OF_PORTS = `NUM_PORTS;

`include "SW_Configuration.sv"
//`include "SW_BFM.sv"
`include "SW_Transaction.sv"
`include "SW_Sequencer.sv"
`include "SW_Driver.sv"
`include "SW_INP_Monitor.sv"
`include "SW_OUT_Monitor.sv"
`include "SW_Agent.sv"
`include "SW_Scoreboard.sv"
`include "SW_Env.sv"
`include "SW_Sequence.sv"
`include "SW_Test.sv"
endpackage
