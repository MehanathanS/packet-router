`timescale 1ns/100ps

`include "SW_Package.sv"
`include "SW_INP_Interface.sv"
`include "SW_MEM_Interface.sv"
`include "SW_OUT_Interface.sv"

`include "../../rtl/simple_dpram_sclk.v"
`include "../../rtl/fifo.v"
`include "../../rtl/fifo_fwft_adapter.v"
`include "../../rtl/fifo_fwft.v"
`include "../../rtl/switch.sv"

import uvm_pkg::*;
`include "uvm_macros.svh"
import SW_Package::*;

module SW_Top;
  bit clock;
  bit reset;
  
  SW_Configuration SW_Config;
  SW_INP_Interface inp_intf(clock, reset);
  SW_MEM_Interface mem_intf(clock, reset);
  SW_OUT_Interface out_intf[NUM_OF_PORTS] (clock, reset);

  switch dut(
             .port0       (out_intf[0].port    ),
             .port1       (out_intf[1].port    ),
             .port2       (out_intf[2].port    ),
             .port3       (out_intf[3].port    ),
             .ready_0     (out_intf[0].ready   ),
             .ready_1     (out_intf[1].ready   ),
             .ready_2     (out_intf[2].ready   ),
             .ready_3     (out_intf[3].ready   ),
             .read_0      (out_intf[0].read    ),
             .read_1      (out_intf[1].read    ),
             .read_2      (out_intf[2].read    ),
             .read_3      (out_intf[3].read    ),
             .mem_en      (mem_intf.mem_en     ),
             .mem_rd_wr   (mem_intf.mem_wr     ),
             .mem_add     (mem_intf.mem_addr   ),
             .mem_data    (mem_intf.mem_data   ),
             .data        (inp_intf.data       ),
             .data_status (inp_intf.data_status),
             .clk         (clock               ),
             .reset       (reset               ),
             .fifo_full   (inp_intf.full       )
            );
  
  initial begin
    SW_Config = SW_Configuration::type_id::create("SW_Config");
    void'(SW_Config.randomize());
    uvm_config_db #(SW_Configuration)::set(null,"*", "SW_Config", SW_Config);
  end
  
  initial begin
    uvm_config_db #(virtual SW_INP_Interface)::set(null, "*", "SW_INP_Intf", inp_intf);
    uvm_config_db #(virtual SW_MEM_Interface)::set(null, "*", "SW_MEM_Intf", mem_intf);
    run_test();
  end
  
  genvar idx;
  generate
  for(idx = 0; idx < NUM_OF_PORTS; idx++) begin
    initial begin
      uvm_config_db #(virtual SW_OUT_Interface)::set(null, "*", $sformatf("SW_OUT_Intf_%0d",idx), out_intf[idx]);
    end
  end
  endgenerate
  
  initial begin
    int bfr_rst_dly;
    int aft_rst_dly;
    
    void'(std::randomize(bfr_rst_dly) with {bfr_rst_dly inside {['d2:'d10]};});
    void'(std::randomize(aft_rst_dly) with {aft_rst_dly inside {['d2:'d12]};});
    
    $timeformat(-9,0,"ns",8);
    reset <= 1'b0;
    clock <= 1'b1;
    
    repeat(bfr_rst_dly)
      @(posedge clock);
     
    @(posedge clock)
      #1 reset <= 1'b1;
  
    repeat(aft_rst_dly)
      @(posedge clock);
      
    @(posedge clock)
      #1 reset <= 1'b0;
  end
  
  always
   #10 clock = ~clock;
endmodule
