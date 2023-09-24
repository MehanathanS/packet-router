class SW_Test extends uvm_test;
  SW_Env SW_env;
  
  `uvm_component_utils(SW_Test)
  
  function new(string name = "SW_Test", uvm_component parent);
    super.new(name,parent);
  endfunction : new
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    SW_env = SW_Env::type_id::create("SW_env", this);
  endfunction : build_phase

  function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    if($test$plusargs("ENV_PRINT"))
      uvm_top.print_topology();
  endfunction : end_of_elaboration_phase

  function void check_phase(uvm_phase phase);
    super.check_phase(phase);
    check_config_usage();
  endfunction : check_phase

  virtual task run_phase(uvm_phase phase);
    SW_Sequence seq;
    seq = SW_Sequence::type_id::create("seq");
    phase.raise_objection(this);
    seq.start(SW_env.SW_Agt.SW_Seqr);
    phase.phase_done.set_drain_time(this, 200us);
    phase.drop_objection(this);
  endtask : run_phase
endclass : SW_Test  
