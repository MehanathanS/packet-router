interface SW_MEM_Interface(input bit clk, input bit rst);
  logic mem_en;
  logic mem_wr;
  logic [1:0] mem_addr;
  logic [7:0] mem_data;
  
  clocking mem_cb @(posedge clk);
    output mem_en;
    output mem_wr;
    output mem_addr;
    output mem_data;
  endclocking : mem_cb
  
  clocking bfm_cb @(posedge clk);
    input mem_en;
    input mem_wr;
    input mem_addr;
    input mem_data;
  endclocking : bfm_cb  
endinterface : SW_MEM_Interface
