module packet_router (
  output logic [7:0] port0,
  output logic [7:0] port1,
  output logic [7:0] port2,
  output logic [7:0] port3,
  output logic       ready_0,
  output logic       ready_1,
  output logic       ready_2,
  output logic       ready_3,
  input  logic       read_0,
  input  logic       read_1,
  input  logic       read_2,
  input  logic       read_3,
  input  logic       mem_en,
  input  logic       mem_rd_wr,
  input  logic [1:0] mem_add,
  input  logic [7:0] mem_data,
  input  logic [7:0] data,
  input  logic       data_status,
  input  logic       reset,
  output logic       fifo_full
);

logic       clock;
logic [7:0] lport0;
logic [7:0] lport1;
logic [7:0] lport2;
logic [7:0] lport3;
logic       lready_0;
logic       lready_1;
logic       lready_2;
logic       lready_3;
logic       lfifo_full;

assign port0 = lport0;
assign port1 = lport1;
assign port2 = lport2;
assign port3 = lport3;

assign ready_0 = lready_0;
assign ready_1 = lready_1;
assign ready_2 = lready_2;
assign ready_3 = lready_3;

assign fifo_full = lfifo_full;

switch dut(
             .port0       (lport0),
             .port1       (lport1),
             .port2       (lport2),
             .port3       (lport3),
             .ready_0     (lready_0),
             .ready_1     (lready_1),
             .ready_2     (lready_2),
             .ready_3     (lready_3),
             .read_0      (read_0),
             .read_1      (read_1),
             .read_2      (read_2),
             .read_3      (read_3),
             .mem_en      (mem_en),
             .mem_rd_wr   (mem_rd_wr),
             .mem_add     (mem_add),
             .mem_data    (mem_data),
             .data        (data),
             .data_status (data_status),
             .clk         (clock),
             .reset       (reset),
             .fifo_full   (lfifo_full)
            );

initial begin
  $dumpfile("dump.vcd");
  $dumpvars(0,dut);
end

initial clock = 1'b1;
always #10 clock = ~clock;
endmodule
