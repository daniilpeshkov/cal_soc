
module ch_measure_ctl #(
    parameter DEFAULT_THRESHOLD_DELTA = 1,
    parameter DEFAULT_D_CODE_DELTA = 1    
) (
    input logic clk_i,
    input logic arst_i,

    //internal strobe generator
    input logic stb_i,

    //control threshold and delay delta
    input logic [15:0] threshold_delta_i,
    input logic threshold_delta_wr_i,
    input logic [9:0] d_code_delta_i,
    input logic d_code_delta_wr_i,

    //dac (threshold) output
    output logic [23:0] dac_dat_o,
    output logic dac_wre_o,
    input logic dac_rdy_i,

    //delay line
    output logic [9:0] d_code_o = 0
);

    typedef enum logic[1:0] { IDLE  } ctl_state_t;
    ctl_state_t state = IDLE;

////////////////////////////////////////////////////////////////////////////////////

    logic [15:0] threshold;
    logic [15:0] threshold_delta;
    logic [9:0] d_code_delta;

    always_ff @(posedge clk_i, posedge arst_i) begin
        if (arst_i) begin
            threshold_delta <= 0;
            d_code_delta <= 0;
        end else if (state == IDLE) begin
            if (d_code_delta_wr_i) d_code_delta <= d_code_delta_i;
            if (threshold_delta_wr_i) threshold_delta <= threshold_delta_i;
        end
    end
    
////////////////////////////////////////////////////////////////////////////////////



endmodule