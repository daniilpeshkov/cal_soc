
module ch_measure_ctl #(
    parameter DEFAULT_THRESHOLD_DELTA = 1,
    parameter DEFAULT_D_CODE_DELTA = 1    
) (
    input logic clk_i,
    input logic arst_i,

    //internal strobe generator
    input logic stb_i,

    //CMP input
    input logic cmp_out_i,

    //control threshold and delay delta
    input logic [15:0] threshold_delta_i,
    input logic threshold_delta_wr_i,
    input logic [9:0] d_code_delta_i,
    input logic d_code_delta_wr_i,

    //dac (threshold) output
    output logic [15:0] threshold_o = 0,
    output logic threshold_wre_o = 0,
    input logic threshold_rdy_i,

    //delay line
    output logic [9:0] d_code_o = 0,

    //ctl
    input logic run_i,

    //TODO output measured value
    output logic point_rdy_o,
    output logic [15:0] point_v_o,
    output logic [9:0] point_t_o
);

    typedef enum logic[1:0] { IDLE, RUN  } ctl_state_t;
    ctl_state_t state = IDLE;

////////////////////////////////////////////////////////////////////////////////////

    logic [15:0] threshold_delta;
    logic [9:0] d_code_delta;

    always_ff @(posedge clk_i, posedge arst_i) begin
        if (arst_i) begin
            threshold_delta = DEFAULT_THRESHOLD_DELTA;
            d_code_delta = DEFAULT_D_CODE_DELTA;
        end else if (state == IDLE) begin
            if (d_code_delta_wr_i) d_code_delta <= d_code_delta_i;
            if (threshold_delta_wr_i) threshold_delta <= threshold_delta_i;
        end
    end
    
////////////////////////////////////////////////////////////////////////////////////
    logic stb_posedge;
    logic stb_prev;

    assign stb_posedge = (stb_prev == 0 && stb_i == 1);
    // TODO may be used to make latency after stb posedge
    always_ff @(posedge clk_i, posedge arst_i) begin
        if (arst_i) begin
            stb_prev = 0;
        end else begin
            stb_prev <= stb_i;
        end
    end

////////////////////////////////////////////////////////////////////////////////////
    
    //previously latched data 
    logic cmp_out_prev = 0;

    logic cmp_out_posedge;
    assign cmp_out_posedge = cmp_out_i == 0 && cmp_out_prev == 1;

    always_ff @(posedge clk_i, posedge arst_i) begin
        if (arst_i) begin
            cmp_out_prev = 0;
        end else begin
            if (stb_posedge && threshold_rdy_i) cmp_out_prev <= cmp_out_i;
        end
    end

    logic initial_cmp_ok = 0;


    always_ff @(posedge clk_i, posedge arst_i) begin
        if (arst_i) begin
            initial_cmp_ok = 0;
            state = IDLE;
        end else begin
            threshold_wre_o <= 0;
            point_rdy_o <= 0;
            if (run_i && state == IDLE) begin
                state <= RUN;
                threshold_o <= 0;
                d_code_o <= 0;
                threshold_wre_o <= 1;
            end

            if (state == RUN) begin
                if (stb_posedge && threshold_rdy_i) begin 
                    threshold_wre_o <= 1;
                    if (cmp_out_posedge) begin
                        point_rdy_o <= 1;
                        point_t_o <= d_code_o;
                        point_v_o <= threshold_o;
                        threshold_o <= 0;
                        d_code_o <= d_code_o + d_code_delta;
                    end else begin
                        threshold_o <= threshold_o + threshold_delta; 
                    end
                end
            end
        end
    end


endmodule