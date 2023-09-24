class SW_Agent extends uvm_agent;
  SW_Sequencer   SW_Seqr;
  SW_Driver      SW_Drvr;
  SW_INP_Monitor SW_Inp_Mon;
  SW_OUT_Monitor SW_Out_Mon[NUM_OF_PORTS];

  `uvm_component_utils(SW_Agent)
  
  function new(string name = "", uvm_component parent);
    super.new(name,parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    SW_Seqr = SW_Sequencer::type_id::create("SW_Seqr", this);
    SW_Drvr = SW_Driver::type_id::create("SW_Drvr", this);
    SW_Inp_Mon = SW_INP_Monitor::type_id::create("SW_Inp_Mon", this);
    foreach(SW_Out_Mon[ii]) begin
      SW_Out_Mon[ii] = SW_OUT_Monitor::type_id::create($sformatf("SW_Out_Mon[%0d]",ii),this);
      SW_Out_Mon[ii].ID = ii;
    end
  endfunction : build_phase
  
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    SW_Drvr.seq_item_port.connect(SW_Seqr.seq_item_export);
  endfunction : connect_phase
endclass : SW_Agent
