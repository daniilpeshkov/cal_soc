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

   output logic err_o,
   output logic rdy_o,
   output logic stb_o,
   output logic [T_CNT_WIDTH-1:0] stb_period_o
);
   
   logic int_stb = 1;
   assign stb_o = (int_stb & oe_i & ~err_o);

   typedef enum logic[1:0] { RUN, FREQ_DET } stb_gen_state;

   stb_gen_state state = RUN;


   logic [T_CNT_WIDTH-1 : 0] t_cnt;
   logic [T_CNT_WIDTH-1 : 0] t_end;

   logic sig_synced;

   sync_ff #(
      .WIDTH (1),
      .STAGES(2)
   ) sig_i_sync_ff_inst (
      .clk_i (clk_i),
      .data_i(sig_i),
      .data_o(sig_synced)
   );


   logic prev_sig; //edge detect

   always_ff @(posedge clk_i) begin
      prev_sig <= sig_synced;
   end

   logic sig_posedge;
   assign sig_posedge = sig_synced & ~prev_sig;

   logic [1:0] edge_num = 0;

   always_ff @(posedge clk_i, posedge arst_i, posedge run_det_i) begin
      if (arst_i) begin 
         int_stb = 1;
         err_o = 0;
         state = RUN;
         t_end = 0;
         t_cnt = 0;
         rdy_o = 1;
      end else if (run_det_i) begin
         state = FREQ_DET;
         edge_num = 0;
         rdy_o = 0;
      end else begin 
         t_cnt <= t_cnt + 1;
         case (state) 
            RUN: begin
               if (t_cnt == t_end) begin 
                  int_stb <= 1;
                  t_cnt <= 0;
               end else if (t_cnt == t_end - ZERO_HOLD_CYCLES) begin
                  int_stb <= 0;
               end
            end

            FREQ_DET: begin
               if (sig_posedge) begin 
                  case (edge_num)
                     1: begin //skip first edge for accuracy 
                        edge_num += 1;
                        t_cnt <= 0;
                     end
                     2: begin
                        t_cnt <= 0;
                        t_end <= t_cnt;
                        stb_period_o <= t_cnt + 1;
                        rdy_o <= 1;
                        state <= RUN;
                     end
                     default: edge_num <= edge_num + 1;
                  endcase
               end else if (&t_cnt) begin
                     err_o <= 1; //overflow
               end
            end
         endcase
      end
   end

endmodule
