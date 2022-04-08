//------------------------------------------------------
//	Module for frequency measurement and strobe generation
//------------------------------------------------------
//	author:  	Peshkov Daniil
//	email:  	daniil.peshkov@spbpu.com
//------------------------------------------------------


module stb_gen #(
   parameter ZERO_HOLD_CYCLES = 5,
   parameter T_CNT_WIDTH = 32,
   parameter OFFSET = 20
) (
   input wire clk_i,
   input wire arst_i,

   input wire sig_i,
   input wire run_det_i,
   input wire oe_i,

   output logic err_o = 0,
   output logic rdy_o,
   output logic stb_o
);
   logic int_stb = 1;
   assign stb_o = (int_stb & oe_i);

   typedef enum logic[1:0] {GEN, FIND_FIRST_EDGE, FIND_SECOND_EDGE} stb_gen_state;

   stb_gen_state state = GEN;

   assign rdy_o = state == GEN;
   logic prev_sig; //edge detect

   logic [T_CNT_WIDTH-1 : 0] t_cnt;
   logic [T_CNT_WIDTH-1 : 0] t_end;
   logic [T_CNT_WIDTH-1 : 0] t_stb_pos;
   logic [T_CNT_WIDTH-1 : 0] t_end_neg;

   always_ff @(posedge clk_i, posedge arst_i) begin
      if (arst_i) begin 
         t_cnt = 0;
         t_end = 0;
         int_stb <= 1;
      end else begin 
         t_cnt <= t_cnt + 1;
         case (state) 
         GEN: begin
            if (run_det_i) begin 
               state <= FIND_FIRST_EDGE;
               int_stb <= 0;
               err_o <= 0;
            end else begin 
               if (t_cnt == t_end) begin 
                  int_stb <= 1;
                  t_cnt <= 0;
               end else if (t_cnt == t_end - ZERO_HOLD_CYCLES) begin
                  int_stb <= 0;
               end
            end
         end
         FIND_FIRST_EDGE: begin
            if (prev_sig == 0 && sig_i == 1) begin 
               state <= FIND_SECOND_EDGE;
               t_cnt <= 0;
            end
         end
         FIND_SECOND_EDGE: begin 
            if (prev_sig == 0 && sig_i == 1) begin 
               state <= GEN;
               t_cnt <= t_cnt; //make offset
               t_end <= t_cnt;
            end else if (t_cnt == 0) begin
               err_o <= 1; //overflow
            end
         end
         endcase
      end
   end

   always_ff @(posedge clk_i) begin
      prev_sig <= sig_i;
   end

endmodule
