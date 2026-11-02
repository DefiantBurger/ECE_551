module steer_en_SM(
	input clk,		// 50MHz clock
	rst_n, 			// Active low asynch reset
	tmr_full, 		// asserted when timer reaches 1.3 sec
	sum_gt_min, 	// asserted when left and right load cells together exceed min rider weight
	sum_lt_min, 	// asserted when left_and right load cells are less than min_rider_weight
	diff_gt_1_4, 	// asserted if load cell difference exceeds 1/4 sum (rider not situated)
	diff_gt_15_16, 	// asserted if load cell difference is great (rider stepping off)

	output logic 
	clr_tmr,		// clears the 1.3sec timer
	en_steer, 		// enables steering (goes to balance_cntrl)
	rider_off		// held high in intitial state when waiting for sum_gt_min
);
	typedef enum logic [1:0] { INIT, BALANCING, BALANCED } e_state;

	e_state state, next_state;

	always_ff @(negedge rst_n or posedge clk) begin
		if (!rst_n)
			state <= INIT;
		else
			state <= next_state;
	end

	always_comb begin
		// Default outputs
		clr_tmr    = '1;
		en_steer   = '0;
		rider_off  = '1;
		next_state = INIT;

		case (state)
			INIT: begin
				if (sum_gt_min) begin
					rider_off  = '0;
					clr_tmr    = '1;
					next_state = BALANCING;
				end
			end

			BALANCING: begin
				if (sum_lt_min) begin // Rider completely stepped off
					rider_off  = '1;
					clr_tmr    = '1;
					next_state = INIT;
				end else if (diff_gt_1_4) begin // Rider not balanced: clear timer
					rider_off  = '0;
					clr_tmr    = '1;
					next_state = BALANCING;
				end else if (tmr_full) begin // Rider balanced for 1.3s: enable steering
					rider_off  = '0;
					en_steer   = '1;
					clr_tmr    = '1;
					next_state = BALANCED;
				end else begin // Rider balanced, let timer count up
					rider_off  = '0;
					clr_tmr    = '0;
					next_state = BALANCING;
				end
			end

			BALANCED: begin
				if (sum_lt_min) begin // Knocked off (important): go back to INIT
					rider_off  = '1;
					clr_tmr    = '1;
					en_steer   = '0;
					next_state = INIT;
				end else if (diff_gt_15_16) begin // Stepping off: go to BALANCING
					rider_off  = '0;
					clr_tmr    = '1;
					en_steer   = '0;
					next_state = BALANCING;
				end else begin // Normal riding
					rider_off  = '0;
					clr_tmr    = '1;
					en_steer   = '1;
					next_state = BALANCED;
				end
			end

			default: begin
				// what the frick how did we get here
				next_state = INIT;
			end
		endcase
	end

endmodule