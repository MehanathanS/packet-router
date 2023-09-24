typedef enum bit {GOOD_FCS, BAD_FCS} FCS_type_t;

class SW_Transaction extends uvm_sequence_item;
  rand logic [7:0] SA;
  rand logic [7:0] DA;
  rand logic [7:0] length;
  rand logic [7:0] data[];
  rand logic       valid_DA; 
  rand FCS_type_t  FCS_Type;
 
  logic [7:0] FCS;
  logic [7:0] packed_data[];
  
  SW_Configuration SW_Config;
   
  `uvm_object_utils_begin(SW_Transaction)
  `uvm_field_int(SA, UVM_ALL_ON)
  `uvm_field_int(DA, UVM_ALL_ON)
  `uvm_field_int(length, UVM_ALL_ON)
  `uvm_field_array_int(data, UVM_ALL_ON)
  `uvm_field_int(FCS, UVM_ALL_ON)
  `uvm_field_array_int(packed_data, UVM_ALL_ON)
  `uvm_field_enum(FCS_type_t, FCS_Type, UVM_ALL_ON)	
  `uvm_object_utils_end
  
  constraint data_c {
    solve length before data.size;
    length == data.size();
  }
  
  constraint FCS_c {
    soft FCS_Type == GOOD_FCS;
  }
  
  constraint valid_DA_c {
    valid_DA dist {1 := 95, 0 := 5};
  }
  constraint DA_C {
    solve valid_DA before DA;
    if(valid_DA) {
      DA inside {SW_Config.port};
    }
  }
  
  constraint SA_C {
    solve DA before SA;
    if(valid_DA) {
      foreach(SW_Config.port[ii]) {
        SA != SW_Config.port[ii];	
      }
    }
    else {
      SA != DA;
    }
  }
  
  function new(string name = "SW_Transaction");
    super.new(name);
  endfunction : new
  
  function void pre_randomize();
    if(!uvm_config_db #(SW_Configuration)::get(null, "", "SW_Config", SW_Config))
      `uvm_fatal(get_name(), "Transaction: Failed to get config object")
  endfunction : pre_randomize
  
  function void post_randomize();
    FCS = calc_fcs();
    if(FCS_Type == BAD_FCS)
      FCS = FCS ^ 8'hFF;
    pack_packet();
    print_packet();
  endfunction : post_randomize
  
  function logic [7:0] calc_fcs();
    logic [7:0] local_FCS;
    local_FCS = 8'h0;

    local_FCS = SA ^ DA;
    local_FCS = local_FCS ^ length;
    foreach(data[ii])
      local_FCS = local_FCS ^ data[ii];
    return local_FCS;
  endfunction : calc_fcs
  
  function void check_fcs();
    logic [7:0] chk_fcs;

    chk_fcs = calc_fcs;
    if(chk_fcs == FCS)
      FCS_Type = GOOD_FCS;
    else
      FCS_Type = BAD_FCS;
  endfunction : check_fcs;
  
  function void pack_packet();
    int pkt_size = data.size() + 4;
    packed_data = new[pkt_size];
    packed_data[0] = DA;
    packed_data[1] = SA;
    packed_data[2] = length;
    packed_data[pkt_size-1] = FCS;
    foreach(data[ii])
      packed_data[ii+3] = data[ii];
  endfunction : pack_packet;
  
  function void unpack_packet();
    int pkt_size = packed_data.size();
    DA = packed_data[0];
    SA = packed_data[1];
    length = packed_data[2];
    FCS = packed_data[pkt_size-1];
    data = new[pkt_size-4];
    foreach(data[ii])
      data[ii] = packed_data[ii+3];
    check_fcs();
    print_packet();
    if(length != data.size())
      `uvm_fatal(get_name(), "Problem Observed with Unpacked Packet");
  endfunction : unpack_packet
  
  function void print_packet();
    `uvm_info(get_name(), $sformatf("SA = %0h", SA), UVM_HIGH);
    `uvm_info(get_name(), $sformatf("DA = %0h", DA), UVM_HIGH);
    `uvm_info(get_name(), $sformatf("LENGTH = %0h", length), UVM_HIGH);
    `uvm_info(get_name(), $sformatf("DATA SIZE = %0d", data.size()), UVM_HIGH);
    foreach(data[ii])
      `uvm_info(get_name(), $sformatf("DATA[%0d] = %0h", ii, data[ii]), UVM_HIGH);
    `uvm_info(get_name(), $sformatf("FCS = %0h", FCS), UVM_HIGH);
    `uvm_info(get_name(), $sformatf("FCS_TYPE = %s", FCS_Type.name()), UVM_HIGH);
    `uvm_info(get_name(), $sformatf("PACKED_DATA SIZE = %0d", packed_data.size()), UVM_HIGH);
    foreach(packed_data[ii])
      `uvm_info(get_name(), $sformatf("PACKED_DATA[%0d] = %0h", ii, packed_data[ii]), UVM_HIGH);
  endfunction : print_packet
endclass : SW_Transaction
