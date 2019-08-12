// Possibly the most annoying component of this project: searching.
// Certainly not efficient, we will break this component down into:
// - logic for the keyboard input
// - logic to determine if two strings are equal in O(1)
// - logic to compare string lengths.
// - storing edit writes in memory
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
							output [27:0] DEBUG
							);
	parameter WRITETOMEMS = 7'd80;
	parameter WRITETOMEML = 7'd40;

	parameter XRESETS = 7'd82;
	parameter XRESETL = 7'd42;
	
	// timing and syncronization
	reg [12:0] counter;
							
	// search algorithm variables
	reg [6:0] sizes, sizel;
	reg [559:0] dataS, queryS;
	reg [279:0] dataL, queryL;
	reg [9:0] ssx, slx;
	
	wire [79:0] curHLS;
	wire [39:0] curHLL;
	// keyboard in variables
	reg [9:0] futsx, futlx;
	reg [22:0] acceptdelay;
	reg accept;
	reg state;
	
	
	// edit in variables
	
	// memory conversions, read/write perms
	wire [12:0] eaddrs, saddrs;
	wire [10:0] eaddrl, saddrl;
	wire [6:0] mascs, mascl;
	reg sTen, lTen;
	
	assign ccol = clrin;
	assign cy = sL ? 6'd29 : 6'd59;
	assign hen = counter != 12'd0;
	
	
	
	always @(*) begin
		if (sL) begin 
			lTen = editen;
			sTen = 1'b0;
			cx = slx;
			ho = curHLL[hx];
		end 
		else begin
			lTen = 1'b0;
			ho = curHLS[hx];
			sTen = editen;
			cx = ssx;
		end
	end
	
	
	largecoordstoaddr lcta(.x(xl), 
								  .y(yl),
								  .addr(saddrl)); 
	smallcoordstoaddr scta(.x(xs), 
								  .y(xl),
								  .addr(saddrs));
								
	wire swriteR, lwriteR;
	assign swriteR = (cx == WRITETOMEMS && counter[7]);
	assign lwriteR = (cx == WRITETOMEML && counter[6]);
	wire ms, ml;
	matchS(.line(dataS),
			 .pattern(queryS),
			 .size(sizes),
			 .offset(xs),
			 .match(ms));
	matchL mL(.line(dataL),
			 .pattern(queryL),
			 .size(sizel),
			 .offset(xl),
			 .match(ml));
	always @(posedge clk)
	begin
		if (~resetn) begin
			hx <= 0;
			hy <= 0;
			counter <= 13'd0;
		end
		else begin
			if (((hx >= 39) && sL) || (hx >= 79)) begin
				if (((hy >= 28) && sL) || (hy >= 58)) hy <= 0;
				else hy <= hy + 1'b1;
				hx <= 0;
			end
			else hx <= hx + 1'b1;
		end
		if (~resetn | counter == 13'd7680) counter <= 13'd0;
		else counter <= counter + 13'd1;
	end
	wire [6:0] xs, xl;
	wire [5:0] ys, yl;
	assign xs = counter[6:0];
	assign xl = {1'b0, counter[5:0]};
	assign ys = counter[12:8];
	assign yl = counter[11:7];
	
	always @(posedge clk)
	begin
		if (~counter[7]) begin
			dataS[(xs << 2) + (xs << 1) + xs +: 7] <= mascs;
		end
		if (~counter[6]) begin
			dataL[(xl << 2) + (xl << 1) + xl +: 7] <= mascl;
		end
	end
	reg [5:0] lxcc;
	reg [6:0] sxcc;
	
	wire [79:0] stmask;
	assign stmask = (((1 << sizes) - 1) << xs);
	wire [39:0] ltmask;
	assign ltmask = (((1 << sizel) - 1) << xl);
	
	reg [79:0] xbufs;
	reg [39:0] xbufl;
	
	always @(posedge clk) begin
		if (counter == 0) begin
		xbufs <= 80'd0;
		xbufl <= 40'd0;
		end
		else  begin 
			if (counter[7] == 1'b1) begin
				if (xs == XRESETS) xbufs <= 80'b0;
				else if (ms && (ys < 6'd59)) begin
				// hlS[(ys << 6) + (yl << 4)+:80] = hlS[(ys << 6) + (yl << 4)+:80] | ((1 << (sizes + 1)) - 1) << ((ys << 6) + (ys << 4) + xs);
			   // okay, so we have 80y + x...
				// which is 64y + 16y + x + moffset.
		
					xbufs <= xbufs | stmask;
				end
			end
		
		// End of Small Mode Search
		
		// large mode search 
		// Devote counter[5:0] to be x-coordinate, this is an overestimate.
		// hopefully the algo won't take more than 24 cycles to compute lol

		/* post processing */
			if (counter[6] == 1'b1) begin
				if (xl == XRESETL) xbufl <= 40'b0;
				else if (ml && (yl < 6'd29)) begin
					//for (lxcc = 0; lxcc < 40; lxcc = lxcc + 1) begin
						//hlL[(yl << 5) + (yl << 3) + lxcc] <= (hlL[(yl << 5) + (yl << 3) + lxcc] | (lxcc >= xl && (lxcc <= (xl + sizel))));
					//end
					xbufl <= (xbufl | ltmask);
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
		SeTextMemoryL.NUMWORDS_A = 1200,
		SeTextMemoryL.WIDTHAD_B = 11,
		SeTextMemoryL.NUMWORDS_B = 1200,
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
		SeTextMemoryS.NUMWORDS_A = 4800,
		SeTextMemoryS.WIDTHAD_B = 13,
		SeTextMemoryS.NUMWORDS_B = 4800,
		SeTextMemoryS.OUTDATA_REG_B = "CLOCK1",
		SeTextMemoryS.ADDRESS_REG_B = "CLOCK1",
		SeTextMemoryS.CLOCK_ENABLE_INPUT_A = "BYPASS",
		SeTextMemoryS.CLOCK_ENABLE_INPUT_B = "BYPASS",
		SeTextMemoryS.CLOCK_ENABLE_OUTPUT_B = "BYPASS",
		SeTextMemoryS.POWER_UP_UNINITIALIZED = "FALSE",
		SeTextMemoryS.INIT_FILE = S_INITIAL_ASCII;
		
	altsyncram	HighlightML (
				.wren_a (lwriteR),
				.wren_b (gnd),
				.clock0 (clk), // write clock
				.clock1 (clk), // read clock
				.clocken0 (vcc), // write enable clock
				.clocken1 (vcc), // read enable clock				
				.address_a (yl),
				.address_b (hy),
				.data_a (xbufl),
				.q_b (curHLL)	// data out
				);
	defparam
		HighlightML.WIDTH_A = 40,
		HighlightML.WIDTH_B = 40,
		// TextMemoryL.INTENDED_DEVICE_FAMILY = "Cyclone V",
		HighlightML.OPERATION_MODE = "DUAL_PORT",
		HighlightML.WIDTHAD_A = 6,
		HighlightML.NUMWORDS_A = 29,
		HighlightML.WIDTHAD_B = 6,
		HighlightML.NUMWORDS_B = 29,
		HighlightML.OUTDATA_REG_B = "CLOCK1",
		HighlightML.ADDRESS_REG_B = "CLOCK1",
		HighlightML.CLOCK_ENABLE_INPUT_A = "BYPASS",
		HighlightML.CLOCK_ENABLE_INPUT_B = "BYPASS",
		HighlightML.CLOCK_ENABLE_OUTPUT_B = "BYPASS",
		HighlightML.POWER_UP_UNINITIALIZED = "FALSE";
		
	altsyncram	HighlightMS (
				.wren_a (swriteR),
				.wren_b (gnd),
				.clock0 (clk), // write clock
				.clock1 (clk), // read clock
				.clocken0 (vcc), // write enable clock
				.clocken1 (vcc), // read enable clock				
				.address_a (ys),
				.address_b (hy),
				.data_a (xbufs),
				.q_b (curHLS)	// data out
				);
	defparam
		HighlightMS.WIDTH_A = 80,
		HighlightMS.WIDTH_B = 80,
		// TextMemoryS.INTENDED_DEVICE_FAMILY = "Cyclone V",
		HighlightMS.OPERATION_MODE = "DUAL_PORT",
		HighlightMS.WIDTHAD_A = 6,
		HighlightMS.NUMWORDS_A = 59,
		HighlightMS.WIDTHAD_B = 6,
		HighlightMS.NUMWORDS_B = 59,
		HighlightMS.OUTDATA_REG_B = "CLOCK1",
		HighlightMS.ADDRESS_REG_B = "CLOCK1",
		HighlightMS.CLOCK_ENABLE_INPUT_A = "BYPASS",
		HighlightMS.CLOCK_ENABLE_INPUT_B = "BYPASS",
		HighlightMS.CLOCK_ENABLE_OUTPUT_B = "BYPASS",
		HighlightMS.POWER_UP_UNINITIALIZED = "FALSE";
		

		
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
	// reg [6:0] iter;
	
	reg [2:0] iter;
	assign DEBUG = mascs;
	// write logic
	always @(posedge clk) begin
		if (~resetn) begin
			ssx <= 10'b0;
			slx <= 10'b0;
			futsx <= 10'b0;
			futlx <= 10'b0;
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
						sizel <= (slx == 7'b0) ? 0 : slx - 7'b0000001;
						cwren <= 1'b1;
						asciiout <= 7'd32;
						futlx <= (slx == 7'b0) ? 0 : sizel - 7'b0000001;
//						queryL[(slx << 4) + (slx << 2) + slx + 6] <= 1'b0;
//						queryL[(slx << 4) + (slx << 2) + slx + 5] <= 1'b0;
//						queryL[(slx << 4) + (slx << 2) + slx + 4] <= 1'b0;
//						queryL[(slx << 4) + (slx << 2) + slx + 3] <= 1'b0;
//						queryL[(slx << 4) + (slx << 2) + slx + 2] <= 1'b0;
//						queryL[(slx << 4) + (slx << 2) + slx + 1] <= 1'b0;
//						queryL[(slx << 4) + (slx << 2) + slx] <= 1'b0;
						queryL[(slx << 2) + (slx << 1) + slx +: 7] <= 7'b0;
					end
					default: begin
						cwren <= 1'b1;
						asciiout <= asciiin;
						sizel <= (slx == 7'b0100111) ? sizel : sizel + 7'b0000001;
//						queryL[(slx << 4) + (slx << 2) + slx + 6] <= asciiin[6];
//						queryL[(slx << 4) + (slx << 2) + slx + 5] <= asciiin[5];
//						queryL[(slx << 4) + (slx << 2) + slx + 4] <= asciiin[4];
//						queryL[(slx << 4) + (slx << 2) + slx + 3] <= asciiin[3];
//						queryL[(slx << 4) + (slx << 2) + slx + 2] <= asciiin[2];
//						queryL[(slx << 4) + (slx << 2) + slx + 1] <= asciiin[1];
//						//queryL[(slx << 4) + (slx << 2) + slx] <= asciiin[0];
						queryL[(slx << 2) + (slx << 1) + slx +: 7] <= asciiin;
						futlx <= (slx == 7'b0100111) ? 7'b0100111 : slx + 7'b0000001;
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
						sizes <= (ssx == 7'b0) ? 0 : ssx - 1'b1;
						futsx <= (ssx == 7'b0) ? 0 : ssx - 1'b1;
//						queryS[(ssx << 2) + (ssx << 1) + ssx + 6] <= 1'b0;
//						queryS[(ssx << 2) + (ssx << 1) + ssx + 5] <= 1'b0;
//						queryS[(ssx << 2) + (ssx << 1) + ssx + 4] <= 1'b0;
//						queryS[(ssx << 2) + (ssx << 1) + ssx + 3] <= 1'b0;
//						queryS[(ssx << 2) + (ssx << 1) + ssx + 2] <= 1'b0;
//						queryS[(ssx << 2) + (ssx << 1) + ssx + 1] <= 1'b0;
//						queryS[(ssx << 2) + (ssx << 1) + ssx] <= 1'b0;
						queryS[(ssx << 2) + (ssx << 1) + ssx +: 7] <= 7'b0;
					end
					default: begin
						cwren <= 1'b1;
						asciiout <= asciiin;
						sizes <= (ssx == 7'b1001111) ? sizes : sizes + 1'b1;
//						queryS[(ssx << 4) + (ssx << 1) + ssx + 6] <= asciiin[6];
//						queryS[(ssx << 4) + (ssx << 1) + ssx + 5] <= asciiin[5];
//						queryS[(ssx << 4) + (ssx << 2) + ssx + 4] <= asciiin[4];
//						queryS[(ssx << 4) + (ssx << 2) + ssx + 3] <= asciiin[3];
//						queryS[(ssx << 4) + (ssx << 2) + ssx + 2] <= asciiin[2];
//						queryS[(ssx << 4) + (ssx << 2) + ssx + 1] <= asciiin[1];
//						queryS[(ssx << 4) + (ssx << 2) + ssx] <= asciiin[0];
						queryS[(ssx << 2) + (ssx << 1) + ssx +: 7] <= asciiin;
						futsx <= (ssx == 7'b1001111) ? 7'b1001111 : ssx + 1'b1;
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
	wire [559:0] mask = (1 << ((size << 2) + (size << 1) + size)) - 1;
	wire [559:0] reducedA, finalB;
	assign finalB = (line >> 7 * offset) /*plsdontask[1120-(offset << 2) - (offset << 1) - offset -:560]*/ & mask;
	assign reducedA = pattern & mask;
	assign match = reducedA === finalB;
endmodule

module matchL( input [279:0] line,
					input [279:0] pattern,
					input [6:0] size, 
					input [6:0] offset,
					output match);
	wire [279:0] mask;
	assign mask = (1 << ((size << 2) + (size << 1) + size)) - 1;
	wire [279:0] reducedA, finalB;
	assign finalB = (line >> (7 * offset)) & mask;
	assign reducedA = pattern & mask;
	assign match = reducedA === finalB;
endmodule
