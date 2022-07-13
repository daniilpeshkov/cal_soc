
module pipelined_equal_32 (
    input logic clk_i,
    input logic [31:0] a_i, b_i,
    input logic ena_i,
    output logic eq_o
);
    logic eq_hi, eq_lo;

	always_ff @(posedge clk_i) eq_lo <=  ~|(a_i[15:0] ^ b_i[15:0]);
	always_ff @(posedge clk_i) eq_hi <=  ~|(a_i[31:16] ^ b_i[31:16]);
	always_ff @(posedge clk_i) if (ena_i) eq_o <= eq_hi & eq_lo; 

endmodule