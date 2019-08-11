// Possibly the most annoying component of this project: searching.
// This is a heavily brute force approach which is certainly not
// register efficient.
// 
 module search_mode(	input sL,
							input resetn,
							input clk,
							input editen,
							input [6:0] editxin,
							input [5:0] edityin,
							input [6:0] editasciiin,
							input [6:0] asciiin,
							input [5:0] clrin,
							input asciiready,
							output reg [6:0] cx,
							output [5:0] cy,
							output [5:0] ccol,
							output reg [6:0] asciiout,
							output reg cwren,
							output reg [6:0] hx,
							output reg [5:0] hy,
							output reg ho,
							output hen,
							output [7:0] DEBUG
							);

	assign hen = counter != 12'd0;
	
	
	reg [12:0] counter;
	assign ccol = clrin;
	assign cy = sL ? 6'd29 : 6'd59;
	
	wire [12:0] eaddrs, saddrs;
	wire [10:0] eaddrl, saddrl;
	wire [6:0] mascs, mascl;
	reg sTen, lTen;
	
	reg [6:0] ssx, slx;
	
	reg [559:0] dataS, queryS;
	reg [4799:0] hlS;
	reg [279:0] dataL, queryL;
	reg [1199:0] hlL;
	
	always @(*) begin
		if (sL) begin 
			lTen = editen;
			sTen = 1'b0;
			cx = slx;
			ho = hlL[(hy << 3) + (hy << 5) + hx];
		end 
		else begin
			lTen = 1'b0;
			ho = hlS[(hy << 4) + (hy << 6) + hx];
			sTen = editen;
			cx = ssx;
		end
	end
	
	
	largecoordstoaddr lcta(.x({1'b0, counter[5:0]}), 
								  .y(counter[11:7]),
								  .addr(saddrl)); 
	smallcoordstoaddr scta(.x(counter[6:0]), 
								  .y(counter[12:8]),
								  .addr(saddrs)); 	
	wire ms, ml;
	matchS(.line(dataS),
			 .pattern(queryS),
			 .size(sizes),
			 .offset(counter[6:0]),
			 .match(ms));
	matchL(.line(dataL),
			 .pattern(queryL),
			 .size(sizel),
			 .offset({1'b0, counter[5:0]}),
			 .match(ml));
	reg rrdy;
	reg rrrdy;
	always @(posedge clk)
	begin
		if (~resetn) begin
			hx <= 0;
			hy <= 0;
			rrdy <= 1'b0;
			counter <= 13'd0;
		end
		else begin
			if (((hx >= 39) && sL) || (hx >= 79)) begin
				if (((hy >= 29) && sL) || (hy >= 59)) hy <= 0;
				else hy <= hy + 1'b1;
				hx <= 0;
			end
			else hx <= hx + 1'b1;
		end
		rrdy <= (counter == 13'd7679);
		if (~resetn | rrdy) counter <= 13'd0;
		else counter <= counter + 13'd1;
	end
	wire [6:0] xs, xl;
	wire [5:0] ys, yl;
	assign xs = counter[6:0];
	assign xl = counter[5:0];
	assign ys = counter[12:8];
	assign yl = counter[11:7];
	
	always @(posedge clk)
	begin
		// small mode search 
		// Devote counter[6:0] to be x-coordinate, this is an overestimate
		// since we will gladly, for timing's sake, devote 48 cycles for
		// computations and delays.
		if (counter[7:0] < 7'd80) begin
			dataS[(xs << 2) + (xs << 1) + xs +:7] <= mascs;
		end
		
		if (counter[6:0] < 6'd40) begin
			dataL[(xl << 2) + (xl << 1) + xl +:7] <= mascl;
		end
	end
	
	always @(posedge clk) begin
		if (counter == 0) hlS <= 4800'd0;
		else  begin 
			if (counter[7] == 1'b1) begin
				if (ms && (counter[12:8] < 6'd59)) begin
				// hlS[(ys << 6) + (yl << 4)+:80] = hlS[(ys << 6) + (yl << 4)+:80] | ((1 << (sizes + 1)) - 1) << ((ys << 6) + (ys << 4) + xs);
			   // okay, so we have 80y + x...
				// which is 64y + 16y + x + moffset.
					// hlS[(ys << 6) + (ys << 4)+:80] <= (hlS[(ys << 6) + (ys << 4)+:80] | (((1 << (sizes + 1)) - 1) << xs));
					hlS[(ys << 6) + (ys << 4) + xs] <= 1'b1;
				end
			end
		
		// End of Small Mode Search
		
		// large mode search 
		// Devote counter[5:0] to be x-coordinate, this is an overestimate.
		// hopefully the algo won't take more than 24 cycles to compute lol

		/* post processing */
			if (counter[6] == 1'b1) begin
				if (ml && (counter[11:7] < 6'd29)) begin
					hlL[(yl << 5) + (yl << 3)+:40] <= (hlL[(yl << 5) + (yl << 3)+:40] |(((1 << (sizel + 1)) - 1) << xl));
				end
			end
		end
		// End of Large Mode Search
	end
	
	parameter S_INITIAL_ASCII = "s_initial_text.mif";
	parameter L_INITIAL_ASCII = "l_initial_text.mif";
	smallcoordstoaddr wcs(editxin, edityin, eaddrs);
	// smallcoordstoaddr rcs(sx, sy, saddrs);
	
	largecoordstoaddr wcl(editxin, edityin, eaddrl);
	// largecoordstoaddr rcl(sx, sy, saddrl);
	
	wire vcc;
	assign vcc = 1'b1;
	altsyncram	SeTextMemoryL (
				.wren_a (lTen),
				.wren_b (gnd),
				.clock0 (clk), // write clock
				.clock1 (clk), // read clock
				.clocken0 (vcc), // write enable clock
				.clocken1 (vcc), // read enable clock				
				.address_a (eaddrl),
				.address_b (saddrl),
				.data_a (editasciiin),
				.q_b (mascl)	// data out
				);
	defparam
		SeTextMemoryL.WIDTH_A = 7,
		SeTextMemoryL.WIDTH_B = 7,
		// TextMemoryL.INTENDED_DEVICE_FAMILY = "Cyclone V",
		SeTextMemoryL.OPERATION_MODE = "DUAL_PORT",
		SeTextMemoryL.WIDTHAD_A = 11,
		SeTextMemoryL.NUMWORDS_A = 1160,
		SeTextMemoryL.WIDTHAD_B = 11,
		SeTextMemoryL.NUMWORDS_B = 1160,
		SeTextMemoryL.OUTDATA_REG_B = "CLOCK1",
		SeTextMemoryL.ADDRESS_REG_B = "CLOCK1",
		SeTextMemoryL.CLOCK_ENABLE_INPUT_A = "BYPASS",
		SeTextMemoryL.CLOCK_ENABLE_INPUT_B = "BYPASS",
		SeTextMemoryL.CLOCK_ENABLE_OUTPUT_B = "BYPASS",
		SeTextMemoryL.POWER_UP_UNINITIALIZED = "FALSE",
		SeTextMemoryL.INIT_FILE = L_INITIAL_ASCII;
		
	altsyncram	SeTextMemoryS (
				.wren_a (sTen),
				.wren_b (gnd),
				.clock0 (clk), // write clock
				.clock1 (clk), // read clock
				.clocken0 (vcc), // write enable clock
				.clocken1 (vcc), // read enable clock				
				.address_a (eaddrs),
				.address_b (saddrs),
				.data_a (editasciiin),
				.q_b (mascs)	// data out
				);
	defparam
		SeTextMemoryS.WIDTH_A = 7,
		SeTextMemoryS.WIDTH_B = 7,
		// TextMemoryS.INTENDED_DEVICE_FAMILY = "Cyclone V",
		SeTextMemoryS.OPERATION_MODE = "DUAL_PORT",
		SeTextMemoryS.WIDTHAD_A = 13,
		SeTextMemoryS.NUMWORDS_A = 4720,
		SeTextMemoryS.WIDTHAD_B = 13,
		SeTextMemoryS.NUMWORDS_B = 4720,
		SeTextMemoryS.OUTDATA_REG_B = "CLOCK1",
		SeTextMemoryS.ADDRESS_REG_B = "CLOCK1",
		SeTextMemoryS.CLOCK_ENABLE_INPUT_A = "BYPASS",
		SeTextMemoryS.CLOCK_ENABLE_INPUT_B = "BYPASS",
		SeTextMemoryS.CLOCK_ENABLE_OUTPUT_B = "BYPASS",
		SeTextMemoryS.POWER_UP_UNINITIALIZED = "FALSE",
		SeTextMemoryS.INIT_FILE = S_INITIAL_ASCII;
		
	reg accept;
	reg state;
	reg [6:0] futsx, futlx, sizes, sizel;
	reg [22:0] acceptdelay;
	always @(negedge resetn or 
				posedge clk)
	begin
	if (~resetn) begin
		accept <= 1'b1;
		acceptdelay <= 23'b0;
	end else if (asciiready && (acceptdelay == 23'b0)) begin
		accept <= 1'b1;
		acceptdelay <= 23'b11111111111111111111111;
	end else if (acceptdelay != 23'b0) begin
		acceptdelay <= acceptdelay - 1'b1;
		accept <= 1'b0;
	end
	else accept <= 1'b0;
	end
	
	assign DEBUG = sizes;
	// write logic
	always @(negedge resetn or posedge clk) begin
		if (~resetn) begin
			ssx <= 7'b0;
			slx <= 7'b0;
			futsx <= 7'b0;
			futlx <= 7'b0;
			state <= 1'b0;
			sizes <= 7'b0;
			sizel <= 7'b0;
			queryS <= 560'b0;
			queryL <= 280'b0;
		end
		else if (~state) begin
			// do nothing for new chars
			if (accept) begin
				state <= 1'b1;
				if (sL) begin
					case (asciiin)
					7'd13: begin
						// newline
					end
					7'd8: begin
						// backspace
						sizel <= (queryL[6:0] == 7'b0) ? 0 : slx - 1'b1;
						cwren <= 1'b1;
						asciiout <= 7'd32;
						futlx <= (slx == 7'b0) ? 0 : sizel - 1'b1;
						queryL[(slx << 4) + (slx << 2) + slx +:7] <= 7'b0;
					end
					default: begin
						cwren <= 1'b1;
						asciiout <= asciiin;
						sizel <= (slx == 7'd39) ? sizel : sizel + 1'b1;
						queryL[(slx << 4) + (slx << 2) + slx +:7] <= asciiin;
						futlx <= (slx == 7'd39) ? 7'd39 : slx + 1'b1;
					end
					endcase
				end else begin 
					case (asciiin)
					7'd13: begin
						// newline
					end
					7'd8: begin
						// backspace
						cwren <= 1'b1;
						asciiout <= 7'd32;
						sizes <= (ssx == 7'b0) ? 0 : sizes - 1'b1;
						futsx <= (ssx == 7'b0) ? 0 : ssx - 1'b1;
						queryS[(ssx << 4) + (ssx << 2) + ssx +:7] <= 7'b0;
					end
					default: begin
						cwren <= 1'b1;
						asciiout <= asciiin;
						sizes <= (ssx == 7'd79) ? sizes : sizes + 1'b1;
						queryS[(ssx << 4) + (ssx << 2) + ssx +:7] <= asciiin;
						futsx <= (ssx == 7'd79) ? 7'd79 : ssx + 1'b1;
					end
					endcase
				end
			end
		end else begin
			state <= 1'b0; 
			cwren <= 1'b0; 
			ssx <= futsx;
			slx <= futlx;
		end
	end
		
endmodule 

/*
 * General algorithm: more bit shifts!
 * pattern, but only |size * 7| length, so and it with 1 >> size*7+1 
 * (line >> 7 * offset)
 * call this B
 * if (B & A) == (B | A) == A, return 1.
 */
module matchS( input [559:0] line,
					input [559:0] pattern,
					input [6:0] size, 
					input [6:0] offset,
					output match);
	wire [559:0] mask = (1 << ((size << 2) + (size << 1) + size + 1)) - 1;
	wire [559:0] reducedA, finalB;
	wire [1119:0] plsdontask;
	assign plsdontask = {line, 560'b0};
	assign finalB = plsdontask[(offset << 2) + (offset << 1) + offset +:560] & mask;
	assign reducedA = pattern & mask;
	assign match = reducedA == finalB;
endmodule

module matchL( input [279:0] line,
					input [279:0] pattern,
					input [6:0] size, 
					input [6:0] offset,
					output match);
	wire [279:0] mask;
	assign mask = (1 << ((size << 2) + (size << 1) + size + 1)) - 1;
	wire [279:0] reducedA, finalB;
	wire [559:0] plsdontask;
	assign plsdontask = {280'b0, line};
	assign finalB = plsdontask[(offset << 2) + (offset << 1) + offset +: 280] & mask;
	assign reducedA = pattern & mask;
	assign match = reducedA == finalB;
endmodule
