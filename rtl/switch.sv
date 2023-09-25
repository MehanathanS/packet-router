module switch (
  output logic [7:0] port0,
  output logic [7:0] port1,
  output logic [7:0] port2,
  output logic [7:0] port3,
  output logic ready_0,
  output logic ready_1,
  output logic ready_2,
  output logic ready_3,
  input logic read_0,
  input logic read_1,
  input logic read_2,
  input logic read_3,

  input logic mem_en,
  input logic mem_rd_wr,
  input logic [1:0] mem_add,
  input logic [7:0] mem_data,

  input logic [7:0] data,
  input logic data_status,

  input logic clk,
  input logic reset,

  output logic fifo_full
);

logic [7:0] port0_addr;
logic [7:0] port1_addr;
logic [7:0] port2_addr;
logic [7:0] port3_addr;
logic [1:0] out_sel;
logic [7:0] fifo_rd_data;
logic fifo_empty;
logic fifo_rd_en;
logic data_out_en;
logic [7:0] data_count;
logic [7:0] data_len;
shortint unsigned s_count;

enum {IDLE, AWAIT_READ, SEND_DA, SEND_LEN, SEND_DATA, FIFO_FLUSH} state, next_state;

//Output ports
assign port0 = (data_out_en && (out_sel==2'b00)) ? fifo_rd_data : 8'h00;
assign port1 = (data_out_en && (out_sel==2'b01)) ? fifo_rd_data : 8'h00;
assign port2 = (data_out_en && (out_sel==2'b10)) ? fifo_rd_data : 8'h00;
assign port3 = (data_out_en && (out_sel==2'b11)) ? fifo_rd_data : 8'h00;

//Port address configuration
always_ff@(posedge(clk),posedge(reset)) begin
  if(reset) begin 
    port0_addr <= 8'hff;
    port1_addr <= 8'hff;
    port2_addr <= 8'hff;
    port3_addr <= 8'hff;
  end
  else begin 
    port0_addr <= (mem_en && mem_rd_wr && (mem_add == 2'b00)) ? mem_data : port0_addr;
    port1_addr <= (mem_en && mem_rd_wr && (mem_add == 2'b01)) ? mem_data : port1_addr;
    port2_addr <= (mem_en && mem_rd_wr && (mem_add == 2'b10)) ? mem_data : port2_addr;
    port3_addr <= (mem_en && mem_rd_wr && (mem_add == 2'b11)) ? mem_data : port3_addr;
  end
end

//FSM
//Present state logic
always_ff@(posedge(clk),posedge(reset)) begin
  if(reset) begin
    state <= IDLE;
  end
  else begin
    state <= next_state;
  end
end

//Next state logic
always_comb begin
  next_state = IDLE;
  case(state) 
    IDLE : begin
      if(!fifo_empty) begin
        if((fifo_rd_data == port0_addr) || (fifo_rd_data == port1_addr) || (fifo_rd_data == port2_addr) || (fifo_rd_data == port3_addr)) begin
          next_state = AWAIT_READ;
        end
        else begin
          next_state = FIFO_FLUSH;
        end
      end
    end

    FIFO_FLUSH : begin
      if(s_count >= 3)
        next_state = SEND_LEN;
      else
        next_state = FIFO_FLUSH;     
    end

    AWAIT_READ : begin
      next_state = AWAIT_READ;      
      case(out_sel)
        2'b00 : if(read_0) next_state = SEND_DA;
        2'b01 : if(read_1) next_state = SEND_DA;
        2'b10 : if(read_2) next_state = SEND_DA;
        2'b11 : if(read_3) next_state = SEND_DA;
      endcase
    end

    SEND_DA : begin
      if(s_count >= 3)
        next_state = SEND_LEN;
      else
        next_state = SEND_DA;
    end

    SEND_LEN : begin
      if(data_len == 8'h00)
        next_state = IDLE;      
      else
        next_state = SEND_DATA;
    end

    SEND_DATA : begin
      if(data_count == data_len) 
        next_state = IDLE;
      else
        next_state = SEND_DATA;
    end

    default : next_state = IDLE;

  endcase
end

//Output Logic
always_ff@(posedge(clk),posedge(reset)) begin
  if(reset) begin
    ready_0 <= '0;
    ready_1 <= '0;
    ready_2 <= '0;
    ready_3 <= '0;
    fifo_rd_en <= '0;
    data_out_en <= '0;
    data_count <= '0;
    data_len <= '0;
    out_sel <= 'X;
    s_count <= 0;
  end
  else begin
    case(next_state)
 
      IDLE : begin
        ready_0 <= '0;
        ready_1 <= '0;
        ready_2 <= '0;
        ready_3 <= '0;
        fifo_rd_en <= '0;
        data_out_en <= '0;
        data_count <= '0;
        data_len <= '0;
        out_sel <= 'X;
        s_count <= 0;
      end

      AWAIT_READ : begin
        if(!fifo_empty) begin
          case(fifo_rd_data)
            port0_addr : begin
              ready_0 <= 1'b1;
              out_sel <= 2'b00;
            end

            port1_addr : begin
              ready_1 <= 1'b1;
              out_sel <= 2'b01;
            end

            port2_addr : begin
              ready_2 <= 1'b1;
              out_sel <= 2'b10;
            end

            port3_addr : begin
              ready_3 <= 1'b1;
              out_sel <= 2'b11;
            end
          endcase
        end
      end

      FIFO_FLUSH : begin
        fifo_rd_en <= 1'b1;
        data_out_en <= 1'b0;
        s_count <= s_count + 1'b1;        
      end

      SEND_DA : begin
        fifo_rd_en <= 1'b1;
        data_out_en <= 1'b1;
        s_count <= s_count + 1'b1;        
      end

      SEND_LEN : begin
        data_len <= fifo_rd_data;
      end

      SEND_DATA : begin
        data_count <= data_count + 1'b1;
      end

    endcase
  end
end

fifo_fwft
  #(
    .DATA_WIDTH(8),
    .DEPTH_WIDTH(10)
   )
   fifo_inst
   (
    .clk(clk),
    .rst(reset),
    .din(data),
    .wr_en(data_status),
    .full(fifo_full),
    .dout(fifo_rd_data),
    .rd_en(fifo_rd_en),
    .empty(fifo_empty)
);

endmodule
