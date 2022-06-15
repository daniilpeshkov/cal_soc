
module sc_fifo #(
    parameter LGFLEN = 10,
    parameter WIDTH = 32
) (
    input logic     clk_i,
    input logic     arstn_i,

    input logic [WIDTH-1:0] data_i,
    input logic             wre_i,

    output logic [WIDTH-1:0] data_o,
    input  logic             re_i,
    output logic             n_empty_o
);

    logic [WIDTH-1:0] cyc_buf [LGFLEN-1:0];

    logic [LGFLEN-1:0] r_addr, w_addr;

    assign n_empty_o = (r_addr != w_addr);
    assign data_o = cyc_buf[r_addr];

    always_ff @(posedge clk_i, negedge arstn_i) begin : w_addr_ff
        if (~arstn_i) begin
            w_addr = 0;
        end else begin
            if (wre_i) begin
                w_addr <= w_addr + 1;
            end
        end
    end

    always_ff @(posedge clk_i, negedge arstn_i) begin : r_addr_ff
        if (~arstn_i) begin
            r_addr = 0;
        end else begin
            if (re_i & n_empty_o) begin
                r_addr <= r_addr + 1;
            end
        end
    end

    always_ff @(posedge clk_i) begin
        if (wre_i) begin
            cyc_buf[w_addr] <= data_i;
        end
    end

endmodule
