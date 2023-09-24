class SW_Configuration extends uvm_object;
  rand logic [7:0]  port[NUM_OF_PORTS];
  rand int          num_txn;
  rand int          mon_rand_dly[NUM_OF_PORTS];
  int               MIN_DELAY;
  int               MAX_DELAY;
  local bit         rand_dly;

  constraint port_c {
    foreach(port[ii])
      port[ii] != 8'h00;
    unique{port};
  }
  
  constraint delay_c {
    if(rand_dly) {
      foreach(mon_rand_dly[ii]) {
	mon_rand_dly[ii] inside {[MIN_DELAY:MAX_DELAY]};
      }
    }
    else {
      foreach(mon_rand_dly[ii])
	mon_rand_dly[ii] == 'd0;
    }
  }
 
  constraint num_txn_c {
    num_txn >  'd0;
    num_txn <= 'd5000;
  }
  
  `uvm_object_utils_begin(SW_Configuration)
  `uvm_field_sarray_int(port, UVM_ALL_ON)
  `uvm_object_utils_end
  
  function new(string name = "SW_Configuration");
    super.new(name);
    MIN_DELAY = 'd1;
    MAX_DELAY = 'd20;
    if($test$plusargs("NO_DELAY")) rand_dly = 1'b0;
    else                           rand_dly = 1'b1;
  endfunction : new
  
  function void post_randomize();
    if($value$plusargs("NUM_TXN=%0d", num_txn))
      `uvm_info(get_name(), "NUM_TXN Randomization Overriden with PlusArgs", UVM_LOW);
    `uvm_info(get_name(), $sformatf("NUM_TXN = %0d", num_txn), UVM_LOW);
    `uvm_info(get_name(), $sformatf("NUM_PORTS = %0d", NUM_OF_PORTS), UVM_LOW);
    foreach(port[ii])
      `uvm_info(get_name(), $sformatf("Port [%0d] = %h", ii, port[ii]), UVM_LOW);
    foreach(mon_rand_dly[ii])
      `uvm_info(get_name(), $sformatf("Monitor Delay [%0d] = %0d", ii, mon_rand_dly[ii]), UVM_LOW);
  endfunction : post_randomize
  
endclass : SW_Configuration
