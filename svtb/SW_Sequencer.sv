class SW_Sequencer extends uvm_sequencer #(SW_Transaction);
  `uvm_component_utils(SW_Sequencer)
  
  function new(string name = "SW_Sequencer", uvm_component parent);
    super.new(name,parent);
  endfunction : new
endclass : SW_Sequencer
