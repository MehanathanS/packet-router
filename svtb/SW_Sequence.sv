class SW_Sequence extends uvm_sequence #(SW_Transaction);
  bit user_cfg;
  SW_Configuration SW_Config;
  
  `uvm_object_utils(SW_Sequence)
  
  function new(string name = "SW_Sequence");
    super.new(name);
    user_cfg = 0;
    if($test$plusargs("SMOKE")) user_cfg = 1;
    if(!uvm_config_db #(SW_Configuration)::get(null, "", "SW_Config", SW_Config))
      `uvm_fatal(get_name(), "Transaction: Failed to get config object")
  endfunction : new
  
  task body();
    for(int ii = 0; ii < SW_Config.num_txn; ii++) begin
      `uvm_do_with(req, { 
                         if(user_cfg) {
                           length == 1;
                           DA == SW_Config.port[(ii%NUM_OF_PORTS)];
                         }
                        });
    end
  endtask : body
endclass : SW_Sequence
