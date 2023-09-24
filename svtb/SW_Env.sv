class SW_Env extends uvm_env;
  //SW_BFM        SW_Bfm;
  SW_Agent      SW_Agt;
  SW_Scoreboard SW_Scbd;
  SW_Configuration SW_Config;
  
  `uvm_component_utils(SW_Env)
  
  function new(string name = "SW_Env", uvm_component parent);
    super.new(name,parent);
  endfunction : new
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db #(SW_Configuration)::get(null, "", "SW_Config", SW_Config))
      `uvm_fatal(get_name(), "ENV: Failed to get config object");
    //SW_Bfm  = SW_BFM::type_id::create("SW_Bfm", this);
    SW_Agt  = SW_Agent::type_id::create("SW_Agt", this);
    SW_Scbd = SW_Scoreboard::type_id::create("SW_Scbd", this);
  endfunction : build_phase
  
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    SW_Agt.SW_Drvr.Drv_Inp_Port.connect(SW_Scbd.Drv_Pkt_Fifo.analysis_export);
    SW_Agt.SW_Inp_Mon.Inp_Mon_Port.connect(SW_Scbd.Inp_Mon_Pkt_Fifo.analysis_export);
    foreach(SW_Agt.SW_Out_Mon[idx])
      SW_Agt.SW_Out_Mon[idx].Out_Mon_Port.connect(SW_Scbd.Out_Mon_Pkt_Fifo[idx].analysis_export);
  endfunction : connect_phase  
endclass : SW_Env
