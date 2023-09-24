class SW_Driver extends uvm_driver #(SW_Transaction);
  virtual SW_INP_Interface inp_intf;
  virtual SW_MEM_Interface mem_intf;
  SW_Transaction   SW_Drv_Pkt;  
  SW_Configuration SW_Config;
  bit cfg_done;
  uvm_analysis_port #(SW_Transaction) Drv_Inp_Port;

  `uvm_component_utils(SW_Driver)
  
  function new(string name = "SW_Driver", uvm_component parent);
    super.new(name,parent);
    cfg_done = 1'b0;
  endfunction : new
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    Drv_Inp_Port = new("Drv_Inp_Port",this);
    if(!uvm_config_db #(virtual SW_INP_Interface)::get(this, "", "SW_INP_Intf", inp_intf))
    `uvm_fatal(get_type_name(), "Failed to get INP Interface Handle");
    if(!uvm_config_db #(virtual SW_MEM_Interface)::get(this, "", "SW_MEM_Intf", mem_intf))
      `uvm_fatal(get_type_name(), "Failed to get MEM Interface Handle");
    if(!uvm_config_db #(SW_Configuration)::get(this, "", "SW_Config", SW_Config))
      `uvm_fatal(get_type_name(), "Failed to get config object");
  endfunction : build_phase
  
  virtual task run_phase(uvm_phase phase);
    fork
      reset_dut();
      config_dut();
      drive_dut();
    join
  endtask : run_phase
  
  virtual task reset_dut();
    forever begin
      @(posedge inp_intf.rst);
      cfg_done = 1'b0;
      `uvm_info(get_type_name(), "Received Reset for DUT", UVM_HIGH);
      while (inp_intf.rst == 1'b1) begin
        mem_intf.mem_cb.mem_en   <= 1'b0;
        mem_intf.mem_cb.mem_wr   <= 1'b0;
        mem_intf.mem_cb.mem_addr <= 2'b00;
        mem_intf.mem_cb.mem_data <= 8'h00;
    	
        inp_intf.inp_cb.data_status <= 1'b0;
        inp_intf.inp_cb.data        <= 8'h00;
        @(inp_intf.inp_cb);
      end
      `uvm_info(get_type_name(), "Deasserted Reset for DUT, Proceeding to Configuration", UVM_HIGH);
    end
  endtask : reset_dut
  
  virtual task config_dut();
    forever begin
      @(negedge mem_intf.rst);
      cfg_done = 1'b0;
      `uvm_info(get_type_name(), "Configuring MEM Interface after Reset Deassertion", UVM_HIGH);	  
      @(mem_intf.mem_cb);
      mem_intf.mem_cb.mem_en   <= 1'b1;
      @(mem_intf.mem_cb);
      mem_intf.mem_cb.mem_wr   <= 1'b1;
      foreach(SW_Config.port[ii]) begin
        mem_intf.mem_cb.mem_addr <= ii;
        mem_intf.mem_cb.mem_data <= SW_Config.port[ii];
        @(posedge mem_intf.clk);
      end
      mem_intf.mem_cb.mem_en   <= 1'b0;
      mem_intf.mem_cb.mem_wr   <= 1'b0;
      mem_intf.mem_cb.mem_addr <= 'd0;
      mem_intf.mem_cb.mem_data <= 'h0;
      @(mem_intf.mem_cb);
      @(mem_intf.mem_cb);
      cfg_done = 1'b1;
      `uvm_info(get_type_name(), "Completed Configuring MEM Interface", UVM_HIGH);
    end	  
  endtask : config_dut
  
  virtual task drive_dut();
    forever begin
      SW_Drv_Pkt = SW_Transaction::type_id::create("SW_Drv_Pkt");
      seq_item_port.get_next_item(SW_Drv_Pkt);
      Drv_Inp_Port.write(SW_Drv_Pkt);
      drive_intf(SW_Drv_Pkt);
      seq_item_port.item_done();
    end
  endtask :drive_dut
  
  virtual task drive_intf(SW_Transaction Pkt);
    logic [7:0] pkt[$];
	
    foreach(Pkt.packed_data[ii]) pkt.push_back(Pkt.packed_data[ii]);
    if(pkt.size() != Pkt.packed_data.size())
      `uvm_fatal(get_type_name(), "Serious Problem")

    while(cfg_done != 1'b1) begin
      `uvm_info(get_type_name(), "SEQ_ITEM waiting in driver for Config to be done and then it will be driven", UVM_HIGH);
      @(inp_intf.inp_cb);
    end
    
    while(pkt.size() != 0) begin
      if(inp_intf.full) begin
        inp_intf.inp_cb.data_status <= 1'b0;
        inp_intf.inp_cb.data        <= $urandom;
        @(inp_intf.inp_cb);
      end
      else begin
        inp_intf.inp_cb.data_status <= 1'b1;
        inp_intf.inp_cb.data        <= pkt.pop_front();
        @(inp_intf.inp_cb);
      end
    end
    
    inp_intf.inp_cb.data_status <= 1'b0;
    inp_intf.inp_cb.data        <= 8'h00;
    @(inp_intf.inp_cb);
  endtask : drive_intf
endclass : SW_Driver
