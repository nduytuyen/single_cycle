module pc(
  input  wire         i_pc_en,i_clk,i_rst_n,
  input  wire [31:0]  i_pc_next,
  output wire [31:0]  o_pc
);
  reg  [31:0]  pc_present, next_pc;  

  always @(*) begin
      next_pc = (i_pc_en) ? i_pc_next : pc_present;
  end    

  always @(posedge i_clk or negedge i_rst_n) begin 
      if(!i_rst_n) begin 
          pc_present <= 32'b0;
      end else begin
          pc_present <= next_pc;
      end
  end

  assign  o_pc  = pc_present;

endmodule  
 
