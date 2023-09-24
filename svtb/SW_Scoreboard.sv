class SW_Scoreboard extends uvm_scoreboard;
  uvm_tlm_analysis_fifo #(SW_Transaction) Drv_Pkt_Fifo;
  uvm_tlm_analysis_fifo #(SW_Transaction) Inp_Mon_Pkt_Fifo;
  uvm_tlm_analysis_fifo #(SW_Transaction) Out_Mon_Pkt_Fifo[NUM_OF_PORTS];
  
  SW_Transaction   Drv_Pkt;
  SW_Transaction   Inp_Mon_Pkt;
  SW_Transaction   Out_Mon_Pkt;
  SW_Configuration SW_Config;
 
  static int actl_trans = 0;
  static int rcvd_trans = 0;
  static int imon_trans = 0;
  static int omon_trans = 0;
  static int drpd_trans = 0;
  static int pass_trans = 0;
  static int fail_trans = 0;
  static int out_mon_cnt[NUM_OF_PORTS] = '{NUM_OF_PORTS{0}};
 
  `uvm_component_utils(SW_Scoreboard)
  
  function new(string name = "SW_Scoreboard", uvm_component parent);
    super.new(name,parent);
  endfunction : new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    Drv_Pkt_Fifo = new("Drv_Pkt_Fifo", this);
    Inp_Mon_Pkt_Fifo = new("Inp_Mon_Pkt_Fifo", this);
    foreach(Out_Mon_Pkt_Fifo[idx])
      Out_Mon_Pkt_Fifo[idx] = new($sformatf("Out_Mon_Pkt_Fifo[%0d]", idx), this);
	  
    Drv_Pkt     = SW_Transaction::type_id::create("Drv_Pkt");
    Inp_Mon_Pkt = SW_Transaction::type_id::create("Inp_Mon_Pkt");
    Out_Mon_Pkt = SW_Transaction::type_id::create("Out_Mon_Pkt");
    
    if(!uvm_config_db #(SW_Configuration)::get(this, "", "SW_Config", SW_Config))
      `uvm_fatal(get_name(), "Scoreboard: Failed to get config object");
    actl_trans = SW_Config.num_txn;
  endfunction : build_phase
  
  virtual task run_phase(uvm_phase phase);
    forever begin
      int index = -1;
      bit dropped = 1;
      bit matched = 0;
    	  
      Drv_Pkt_Fifo.get(Drv_Pkt);
      rcvd_trans++;
      Inp_Mon_Pkt_Fifo.get(Inp_Mon_Pkt);
      imon_trans++;
      matched = compare_pkt(Drv_Pkt, Inp_Mon_Pkt);
    	  
      if(matched) begin
        matched = 0;
        foreach(SW_Config.port[idx]) begin
          if(SW_Config.port[idx] == Inp_Mon_Pkt.DA) begin
            index = idx;		  
            dropped = 0;
          end
        end
        if(index != -1) begin
          Out_Mon_Pkt_Fifo[index].get(Out_Mon_Pkt);
          out_mon_cnt[index]++;
          matched = compare_pkt(Inp_Mon_Pkt, Out_Mon_Pkt);
          if(matched) pass_trans++;
          else        fail_trans++;
          index = -1;
        end
        else begin
          if(dropped) begin
            drpd_trans++;
            pass_trans++;
          end
          else        fail_trans++;
        end
      end
      else fail_trans++;
    end    
  endtask : run_phase
  
  function bit compare_pkt(SW_Transaction Exp_Pkt, SW_Transaction Act_Pkt);
    if(Exp_Pkt.SA == Act_Pkt.SA) begin
      if(Exp_Pkt.DA == Act_Pkt.DA) begin
        if(Exp_Pkt.length == Act_Pkt.length) begin
          if(Exp_Pkt.FCS_Type == Act_Pkt.FCS_Type) begin
            if(Exp_Pkt.FCS == Act_Pkt.FCS) begin
              if(Exp_Pkt.data.size() == Act_Pkt.data.size()) begin
    	        foreach(Exp_Pkt.data[idx]) begin
    	          if(Exp_Pkt.data[idx] != Act_Pkt.data[idx])
    	            return 0;
    	        end
    	        return 1;
    	      end
    	      else return 0;
            end
            else return 0;
          end
          else return 0;
        end
        else return 0;
      end
      else return 0;
    end
    else return 0;
  endfunction : compare_pkt
  
  function void report_phase(uvm_phase phase);
    foreach(out_mon_cnt[idx]) begin
      omon_trans = omon_trans + out_mon_cnt[idx];
      `uvm_info(get_name(), $sformatf("NO. OF OUTPUT MONITOR[%0d] TRANSACTIONS : %0d", idx, out_mon_cnt[idx]), UVM_LOW)
    end 
    `uvm_info(get_name(), $sformatf("NO. OF EXPECTED          TRANSACTIONS : %0d", actl_trans), UVM_LOW)
    `uvm_info(get_name(), $sformatf("NO. OF ACTUAL            TRANSACTIONS : %0d", rcvd_trans), UVM_LOW)
    `uvm_info(get_name(), $sformatf("NO. OF INPUT  MONITOR    TRANSACTIONS : %0d", imon_trans), UVM_LOW)
    `uvm_info(get_name(), $sformatf("NO. OF DEFERRED DA       TRANSACTIONS : %0d", drpd_trans), UVM_LOW)
    `uvm_info(get_name(), $sformatf("NO. OF OUTPUT MONITOR    TRANSACTIONS : %0d", omon_trans), UVM_LOW)
    `uvm_info(get_name(), $sformatf("NO. OF PASSED            TRANSACTIONS : %0d", pass_trans), UVM_LOW)
    `uvm_info(get_name(), $sformatf("NO. OF FAILED            TRANSACTIONS : %0d", fail_trans), UVM_LOW)
    if(pass_trans == rcvd_trans && rcvd_trans == actl_trans && rcvd_trans == imon_trans &&
       imon_trans == omon_trans+drpd_trans && fail_trans == 0)
      `uvm_info(get_name(), "TEST PASSED", UVM_LOW)
    else
      `uvm_info(get_name(), "TEST_FAILED", UVM_LOW)
  endfunction
endclass : SW_Scoreboard
