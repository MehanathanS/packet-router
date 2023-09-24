interface SW_OUT_Interface(input bit clk, input bit rst);
  logic ready;
  logic read;
  logic [7:0] port;
  
  clocking out_cb @(posedge clk);
    input ready;
    input port;
    output read;	
  endclocking : out_cb
  
  clocking bfm_cb @(posedge clk);
    output ready;
    output port;
    input  read;	
  endclocking : bfm_cb
endinterface : SW_OUT_Interface
