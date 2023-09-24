class SW_OUT_Monitor extends uvm_monitor;
  int ID;
  SW_Transaction   SW_Out_Mon_Pkt;
  SW_Configuration SW_Config;
  virtual SW_OUT_Interface out_intf;
  
  uvm_analysis_port #(SW_Transaction) Out_Mon_Port;
  
  `uvm_component_utils_begin(SW_OUT_Monitor)
  `uvm_field_int(ID, UVM_ALL_ON)
  `uvm_component_utils_end
  
  function new(string name = "SW_OUT_Monitor", uvm_component parent);
    super.new(name,parent);
  endfunction : new
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    Out_Mon_Port = new($sformatf("Out_Mon_%0d_Port", this.ID), this);
    if(!uvm_config_db #(virtual SW_OUT_Interface)::get(this, "", $sformatf("SW_OUT_Intf_%0d", ID), out_intf))
      `uvm_fatal(get_type_name(), $sformatf("Failed to get OUT_%0d Interface", ID));
    if(!uvm_config_db #(SW_Configuration)::get(this, "", "SW_Config", SW_Config))
      `uvm_fatal(get_type_name(), "Failed to get config object");
  endfunction : build_phase
  
  virtual task run_phase(uvm_phase phase);
    out_intf.out_cb.read <= 1'b0;
    @(out_intf.out_cb);
    forever begin
      int         txn_len = -1;
      logic [7:0] rcvd_data[$];
      
      SW_Out_Mon_Pkt = SW_Transaction::type_id::create($sformatf("SW_Out_Mon_%0d_Pkt",this.ID));
      `uvm_info(get_type_name(),"WAITING FOR READY", UVM_HIGH);
      while(out_intf.out_cb.ready !== 1'b1) begin
        @(out_intf.out_cb);
      end

      realize_delay();
      out_intf.out_cb.read <= 1'b1;
      @(out_intf.out_cb);
      @(out_intf.out_cb);
      `uvm_info(get_type_name(),"GOT READY, DRIVEN READ", UVM_HIGH);
      rcvd_data.push_back(out_intf.out_cb.port); //Capture DA
      @(out_intf.out_cb);
      `uvm_info(get_type_name(),"DA Received", UVM_HIGH);
      rcvd_data.push_back(out_intf.out_cb.port); //Capture SA
      @(out_intf.out_cb);
      `uvm_info(get_type_name(),"SA Received", UVM_HIGH);
      rcvd_data.push_back(out_intf.out_cb.port); //Capture Len
      @(out_intf.out_cb);
      txn_len = rcvd_data[$];
      `uvm_info(get_type_name(),$sformatf("Len Received = %0d", txn_len), UVM_HIGH);
      for(int idx = 0; idx < txn_len; idx++) begin
        rcvd_data.push_back(out_intf.out_cb.port); //Capture Data
        @(out_intf.out_cb);
      end
      `uvm_info(get_type_name(),"Data Received", UVM_HIGH);
      rcvd_data.push_back(out_intf.out_cb.port); //Capture CRC
      `uvm_info(get_type_name(),"CRC Received", UVM_HIGH);
      out_intf.out_cb.read <= 1'b0;
      @(out_intf.out_cb);
      `uvm_info(get_type_name(),"END OF PACKET, RELEASING READ", UVM_HIGH);
      SW_Out_Mon_Pkt.packed_data = new[rcvd_data.size()];
      foreach(rcvd_data[ii]) 
        SW_Out_Mon_Pkt.packed_data[ii] = rcvd_data[ii];
      SW_Out_Mon_Pkt.unpack_packet();
      Out_Mon_Port.write(SW_Out_Mon_Pkt);
    end 
  endtask : run_phase
  
  task realize_delay();
    int dly;

    if($test$plusargs("RAND_DELAY")) begin
      std::randomize(dly) with {dly inside {[SW_Config.MIN_DELAY:SW_Config.mon_rand_dly[this.ID]]};};
    end
    else begin
      dly = SW_Config.mon_rand_dly[this.ID];
    end
    repeat(dly)
      @(out_intf.out_cb);		
  endtask : realize_delay  
endclass : SW_OUT_Monitor
