
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
    input logic [9:0] d_code_delta_i,

    //dac (threshold) output
    output logic [15:0] threshold_o,
    output logic threshold_wre_o,
    input logic threshold_rdy_i,

    //delay line
    output logic [9:0] d_code_o,

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

    typedef enum logic [1:0] { FIND_DIRECTION, FIND_VAL } measure_state_t;
    typedef enum logic {UP, DOWN} direction_t;

    measure_state_t measure_state = FIND_VAL;
    direction_t dir = UP;

    always_ff @(posedge clk_i, posedge arst_i) begin
        if (arst_i) begin
            cmp_out_prev <= 1;
        end else begin
            if (stb_posedge && threshold_rdy_i) cmp_out_prev <= cmp_out_i;
        end
    end


    always_ff @(posedge clk_i, posedge arst_i) begin
        if (arst_i) begin
            state = IDLE;
        end else begin
            threshold_wre_o <= 0;
            point_rdy_o <= 0;
            if (run_i && state == IDLE) begin
                state <= RUN;
                threshold_o <= 0;
                d_code_o <= 0;
                threshold_wre_o <= 1;

                measure_state <= FIND_VAL;
                dir <= UP;
            end

            if (state == RUN) begin
                case (measure_state)
                    FIND_VAL: begin
                        if (stb_posedge && threshold_rdy_i) begin
                            if (cmp_out_i != cmp_out_prev) begin
                                point_rdy_o <= 1;
                                point_t_o <= d_code_o;
                                point_v_o <= threshold_o;

                                d_code_o <= d_code_o + d_code_delta_i;
                                measure_state <= FIND_DIRECTION;
                            end else begin
                                threshold_o <= threshold_o + (dir == UP ? threshold_delta_i : -threshold_delta_i);
                                threshold_wre_o <= 1;
                            end
                        end
                    end
                    FIND_DIRECTION: begin
                        if (stb_posedge && threshold_rdy_i) begin
                            if (cmp_out_i == 1 && cmp_out_prev == 0) dir <= UP;
                            else if (cmp_out_i == 0 && cmp_out_prev == 1) dir <= DOWN;
                            else begin 
                                if (dir == UP) dir <= DOWN;
                                else dir <= UP;
                            end
                            measure_state <= FIND_VAL;
                        end
                    end 
                endcase
            end
        end
    end


endmodule