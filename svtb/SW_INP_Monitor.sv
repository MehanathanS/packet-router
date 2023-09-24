class SW_INP_Monitor extends uvm_monitor;
  SW_Transaction   SW_Inp_Mon_Pkt;
  SW_Configuration SW_Config;
  virtual SW_INP_Interface inp_intf;
  
  uvm_analysis_port #(SW_Transaction) Inp_Mon_Port;

  `uvm_component_utils(SW_INP_Monitor)
  
  function new(string name = "SW_INP_Monitor", uvm_component parent);
    super.new(name,parent);
  endfunction : new
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    Inp_Mon_Port = new("Inp_Mon_Port",this);
    if(!uvm_config_db #(virtual SW_INP_Interface)::get(this, "", "SW_INP_Intf", inp_intf))
      `uvm_fatal(get_type_name(), "Failed to get INP Interface");
    if(!uvm_config_db #(SW_Configuration)::get(this, "", "SW_Config", SW_Config))
      `uvm_fatal(get_type_name(), "Failed to get config object");
  endfunction : build_phase
  
  virtual task run_phase(uvm_phase phase);
    @(inp_intf.out_cb);
    forever begin
      int         txn_len = -1;
      int         run_len = 0;
      logic [7:0] rcvd_data[$];

      SW_Inp_Mon_Pkt = SW_Transaction::type_id::create("SW_Inp_Mon_Pkt");
      `uvm_info(get_type_name(),"WAITING FOR DATA_STATUS", UVM_HIGH);
      while(inp_intf.out_cb.data_status !== 1'b1) begin
        @(inp_intf.out_cb);
      end
      `uvm_info(get_type_name(),"GOT DATA_STATUS, COLLECTING TRANSACTION", UVM_HIGH);

      while(1) begin
        if(inp_intf.out_cb.data_status === 1'b1) begin
          rcvd_data.push_back(inp_intf.out_cb.data);
          if(rcvd_data.size() == 'd3) begin
            txn_len = inp_intf.out_cb.data;
            txn_len = txn_len + 4;
          end
          run_len++; 
          @(inp_intf.out_cb);
        end
        else begin
          if(inp_intf.out_cb.full === 1'b1) begin
            @(inp_intf.out_cb);
            if(run_len == txn_len) break;
          end
          else begin
            break;
          end
        end
      end
      `uvm_info(get_type_name(),"END OF PACKET, DISCOVERED BY DATA_STATUS GOING LOW", UVM_HIGH);

      SW_Inp_Mon_Pkt.packed_data = new[rcvd_data.size()];
      foreach(rcvd_data[ii]) 
        SW_Inp_Mon_Pkt.packed_data[ii] = rcvd_data[ii];
      SW_Inp_Mon_Pkt.unpack_packet();
      Inp_Mon_Port.write(SW_Inp_Mon_Pkt);
    end
  endtask : run_phase
endclass : SW_INP_Monitor
