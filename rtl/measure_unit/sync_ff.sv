
module sync_ff #(
    parameter WIDTH = 1,
    parameter STAGES = 2
) (
    input logic clk_i,
    input logic [WIDTH-1 : 0] data_i,
    output logic [WIDTH-1 : 0] data_o
);

    logic [WIDTH-1 : 0] sync_chain [STAGES : 1];
    assign data_o = sync_chain[STAGES];

    integer i;
    always_ff @(posedge clk_i) begin
        sync_chain[1] <= data_i;
        for (i = 2; i <= STAGES; i = i + 1)
            sync_chain[i] <= sync_chain[i-1];
    end

endmodule