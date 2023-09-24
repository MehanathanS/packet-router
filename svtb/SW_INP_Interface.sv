interface SW_INP_Interface(input bit clk, input bit rst);
  logic data_status;
  logic full;
  logic [7:0] data;
  
  clocking inp_cb @(posedge clk);
    output data_status;
    output data;
    input  full;
  endclocking : inp_cb
  
  clocking out_cb @(posedge clk);
    input data_status;
    input data;
    input full;
  endclocking : out_cb
  
  clocking bfm_cb @(posedge clk);
    input  data_status;
    input  data;
    output full;
  endclocking : bfm_cb
endinterface : SW_INP_Interface
