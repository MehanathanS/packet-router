class SW_BFM extends uvm_component;
  logic [7:0] memory[NUM_OF_PORTS];
  SW_Configuration SW_Config;

  virtual SW_MEM_Interface mem_intf;
  virtual SW_INP_Interface inp_intf;
  virtual SW_OUT_Interface out_intf[NUM_OF_PORTS];
  
  `uvm_component_utils(SW_BFM)
  
  function new(string name = "SW_BFM", uvm_component parent);
    super.new(name,parent);
    memory = '{NUM_OF_PORTS{8'h00}};
  endfunction : new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db #(virtual SW_MEM_Interface)::get(this, "", "SW_MEM_Intf", mem_intf))
      `uvm_fatal(get_type_name(), "Failed to get MEM Interface Handle");	  
    if(!uvm_config_db #(virtual SW_INP_Interface)::get(this, "", "SW_INP_Intf", inp_intf))
      `uvm_fatal(get_type_name(), "Failed to get INP Interface Handle");
    foreach(out_intf[idx]) begin
      if(!uvm_config_db #(virtual SW_OUT_Interface)::get(this, "", $sformatf("SW_OUT_Intf_%0d", idx), out_intf[idx]))
        `uvm_fatal(get_type_name(), $sformatf("Failed to get OUT_%0d Interface", idx));
    end
    if(!uvm_config_db #(SW_Configuration)::get(null, "", "SW_Config", SW_Config))
      `uvm_fatal(get_name(), "BFM: Failed to get config object")
  endfunction : build_phase
  
  virtual task run_phase(uvm_phase phase);
    fork
      react_to_resets();
      react_to_config();
      react_to_inputs();
    join
  endtask : run_phase
  
  virtual task react_to_resets();
    forever begin
      @(posedge mem_intf.rst);
      `uvm_info(get_name(), "Reset Asserted", UVM_HIGH);
	  
      while (mem_intf.rst === 1'b1) begin
        memory = '{NUM_OF_PORTS{8'h00}};
        foreach(out_intf[idx]) begin
	  out_intf[idx].bfm_cb.ready <= 1'b0;
          out_intf[idx].bfm_cb.port  <= 'h0;
        end
        @(mem_intf.bfm_cb);
      end
      `uvm_info(get_name(), "Reset Deasserted", UVM_HIGH);
    end
  endtask : react_to_resets
  
  virtual task react_to_config();
    forever begin	  
      @(mem_intf.bfm_cb);
      if((mem_intf.bfm_cb.mem_en === 1'b1) && (mem_intf.bfm_cb.mem_wr === 1'b1)) begin
        memory[mem_intf.bfm_cb.mem_addr] = mem_intf.bfm_cb.mem_data;
        `uvm_info(get_name(), $sformatf("Storing to Memory[%0d] = %0h", mem_intf.bfm_cb.mem_addr, mem_intf.bfm_cb.mem_data), UVM_HIGH);
      end
    end	  
  endtask : react_to_config
  
  virtual task react_to_inputs();
    logic [7:0] data[$];
    semaphore   q_sem = new(1);
    fork
      begin
        forever begin	  
          @(inp_intf.bfm_cb);
          if(inp_intf.bfm_cb.data_status === 1'b1) begin
            q_sem.get(1);
            `uvm_info(get_name(), "Data Captured", UVM_HIGH);
            data.push_back(inp_intf.bfm_cb.data);
            q_sem.put(1);
          end
        end
      end
      begin
        forever begin	  
	  @(inp_intf.bfm_cb);
	  if(data.size() != 0) begin
            int         txn_len = -1;
            int         which_outp = -1;
            logic [7:0] local_data;

            q_sem.get(1);
            local_data = data.pop_front();
            q_sem.put(1);

	    foreach(SW_Config.port[idx]) begin
	      if(SW_Config.port[idx] == local_data) begin
                which_outp = idx;
              end
	    end
            `uvm_info(get_name(), $sformatf("Ready Will be Driven to %0d Output Interface", which_outp), UVM_HIGH);
            
            out_intf[which_outp].bfm_cb.ready <= 1'b1;
            out_intf[which_outp].bfm_cb.port  <= local_data; //Sent DA
            while(out_intf[which_outp].bfm_cb.read !== 1'b1) begin
              @(inp_intf.bfm_cb);
            end
            
            //@(inp_intf.bfm_cb);

            q_sem.get(1);
            local_data = data.pop_front();
            q_sem.put(1);
            out_intf[which_outp].bfm_cb.port <= local_data; //Sent SA
            @(inp_intf.bfm_cb);

            q_sem.get(1);
            local_data = data.pop_front();
            txn_len    = local_data;
            q_sem.put(1);
            out_intf[which_outp].bfm_cb.port <= local_data; //Sent Length 
            @(inp_intf.bfm_cb);
            
            for(int idx = 0; idx <= txn_len; idx++) begin
              q_sem.get(1);
              local_data = data.pop_front();
              q_sem.put(1);
              out_intf[which_outp].bfm_cb.port <= local_data; //Sent Payload/CRC
              @(inp_intf.bfm_cb);
            end
            out_intf[which_outp].bfm_cb.ready <= 1'b0;
            out_intf[which_outp].bfm_cb.port  <= 'h0; //Clear Port Data
            @(inp_intf.bfm_cb);
	  end
	end
      end
    join
  endtask : react_to_inputs
endclass : SW_BFM
