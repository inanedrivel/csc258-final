/* 
 * Manages character data for the program.
 * It is the mode's responsibility to deal with it's own
 * state. This just maps it to the output.
 *
 * We assume:
 * sL = 0 \implies 80x60
 * sL = 1 \implies 40x30
 * 6 bits of colour since I'm cheap.
 *
 * Notice that 7'b0000000 (NUL) is returned on out of bounds for output,
 * and input out of bounds are ignored.
 *
 * Basically wraps all the cancer memory modules together.
 *
 */

module memory_controller(input sL,
								 input [6:0] wrx,
			      			 input [5:0] wry,
								 input wren,
								 input [6:0] wascii,
								 input [5:0] wcolour,
								 input wclock,
								 input [6:0] hix,
								 input [5:0] hiy,
								 input hien,
								 input highlight,
								 input hclock,
								 input rclock,
								 input [6:0] rex,
								 input [5:0] rey,
								 output DEBUG,
								 output reg [6:0] rascii,
								 output reg [5:0] rcolour,
								 output reg rhighlight
								 );
	parameter S_INITIAL_HIGHLIGHT = "s_initial_highlight.mif";
	parameter S_INITIAL_COLOUR = "s_initial_colour.mif";
	parameter S_INITIAL_ASCII = "s_initial_text.mif";
	parameter L_INITIAL_HIGHLIGHT = "l_initial_highlight.mif";
	parameter L_INITIAL_COLOUR = "l_initial_colour.mif";
	parameter L_INITIAL_ASCII = "l_initial_text.mif";

								
	parameter NIL = 7'b0000000;
	parameter NCLR = 6'b111111;
	parameter NHL = 1'b1;
	reg wtens, htens, wtenl, htenl;
	wire [12:0] waddrs, haddrs, raddrs;
	wire [10:0] waddrl, haddrl, raddrl;
	
	smallcoordstoaddr wcs(wrx, wry, waddrs);
	smallcoordstoaddr hcs(hix, hiy, haddrs);
	smallcoordstoaddr rcs(rex, rey, raddrs);
	
	largecoordstoaddr wcl(wrx, wry, waddrl);
	largecoordstoaddr hcl(hix, hiy, haddrl);
	largecoordstoaddr rcl(rex, rey, raddrl);
   //assign DEBUG = raddrs;
   /* write enable logic so we know which chip to go to */	
	always @(*)
	begin
		if(sL == 1'b1) begin
			/* enable large IO */
			wtens <= 1'b0;
			htens <= 1'b0;
			wtenl <= wren & (waddrl != 11'b11111111111);
			htenl <= hien & (haddrl != 11'b11111111111);
		end
		else
		begin 
			wtenl <= 1'b0;
			htenl <= 1'b0;
			wtens <= wren & (waddrs != 13'b1111111111111);
			htens <= hien & (haddrs != 13'b1111111111111);
		end
	end
	
	/* OOB check for proper return values */
	wire [6:0] oasciis, oasciil;
	wire [5:0] ocolours, ocolourl;
	wire ohls, ohll;
	
	always @(*)
	begin
		if(sL == 1'b1) begin
			/* enable large IO */
			if (raddrl == 11'b11111111111) begin
				rascii <= NIL;
				rcolour <= NCLR;
				rhighlight <= NHL; 
			end
			else
			begin
				rascii <= oasciil;
				rcolour <= ocolourl;
				rhighlight <= ohll;
			end
		end
		else
		begin 
			if (raddrl == 13'b1111111111111) begin
				rascii <= NIL;
				rcolour <= NCLR;
				rhighlight <= NHL; 
			end
			else
			begin
				rascii <= oasciis;
				rcolour <= ocolours;
				rhighlight <= ohls;
			end
		end	
	end
	
	/* OK, Fuck my life */
	wire vcc, gnd;
	assign vcc = 1'b1;
	assign gnd = 1'b0;
	
		/* Create text memory for small buffer*/
	altsyncram	TextMemoryS (
				.wren_a (wtens),
				.wren_b (gnd),
				.clock0 (wclock), // write clock
				.clock1 (rclock), // read clock
				.clocken0 (vcc), // write enable clock
				.clocken1 (vcc), // read enable clock				
				.address_a (waddrs),
				.address_b (raddrs),
				.data_a (wascii),
				.q_b (oasciis)	// data out
				);
	defparam
		TextMemoryS.WIDTH_A = 7,
		TextMemoryS.WIDTH_B = 7,
		// TextMemoryS.INTENDED_DEVICE_FAMILY = "Cyclone V",
		TextMemoryS.OPERATION_MODE = "DUAL_PORT",
		TextMemoryS.WIDTHAD_A = 13,
		TextMemoryS.NUMWORDS_A = 4800,
		TextMemoryS.WIDTHAD_B = 13,
		TextMemoryS.NUMWORDS_B = 4800,
		TextMemoryS.OUTDATA_REG_B = "CLOCK1",
		TextMemoryS.ADDRESS_REG_B = "CLOCK1",
		TextMemoryS.CLOCK_ENABLE_INPUT_A = "BYPASS",
		TextMemoryS.CLOCK_ENABLE_INPUT_B = "BYPASS",
		TextMemoryS.CLOCK_ENABLE_OUTPUT_B = "BYPASS",
		TextMemoryS.POWER_UP_UNINITIALIZED = "FALSE",
		TextMemoryS.INIT_FILE = S_INITIAL_ASCII;

	/* Create colour memory */
	altsyncram	ColourMemoryS (
				.wren_a (wtens),
				.wren_b (gnd),
				.clock0 (wclock), // write clock
				.clock1 (rclock), // read clock
				.clocken0 (vcc), // write enable clock
				.clocken1 (vcc), // read enable clock				
				.address_a (waddrs),
				.address_b (raddrs),
				.data_a (wcolour), // data in
				.q_b (ocolours)	// data out
				);
	defparam
		ColourMemoryS.WIDTH_A = 6,
		ColourMemoryS.WIDTH_B = 6,
		// ColourMemoryS.INTENDED_DEVICE_FAMILY = "Cyclone V",
		ColourMemoryS.OPERATION_MODE = "DUAL_PORT",
		ColourMemoryS.WIDTHAD_A = 13,
		ColourMemoryS.NUMWORDS_A = 4800,
		ColourMemoryS.WIDTHAD_B = 13,
		ColourMemoryS.NUMWORDS_B = 4800,
		ColourMemoryS.OUTDATA_REG_B = "CLOCK1",
		ColourMemoryS.ADDRESS_REG_B = "CLOCK1",
		ColourMemoryS.CLOCK_ENABLE_INPUT_A = "BYPASS",
		ColourMemoryS.CLOCK_ENABLE_INPUT_B = "BYPASS",
		ColourMemoryS.CLOCK_ENABLE_OUTPUT_B = "BYPASS",
		ColourMemoryS.POWER_UP_UNINITIALIZED = "FALSE",
		ColourMemoryS.INIT_FILE = S_INITIAL_COLOUR;
		
	/* Create highlight memory */
	altsyncram	HighlightMemoryS (
				.wren_a (htens),
				.wren_b (gnd),
				.clock0 (hclock), // write clock
				.clock1 (rclock), // read clock
				.clocken0 (vcc), // write enable clock
				.clocken1 (vcc), // read enable clock				
				.address_a (haddrs),
				.address_b (raddrs),
				.data_a (highlight), // data in
				.q_b (ohls)	// data out
				);
	defparam
		HighlightMemoryS.WIDTH_A = 1,
		HighlightMemoryS.WIDTH_B = 1,
		// HighlightMemoryS.INTENDED_DEVICE_FAMILY = "Cyclone V",
		HighlightMemoryS.OPERATION_MODE = "DUAL_PORT",
		HighlightMemoryS.WIDTHAD_A = 13,
		HighlightMemoryS.NUMWORDS_A = 4800,
		HighlightMemoryS.WIDTHAD_B = 13,
		HighlightMemoryS.NUMWORDS_B = 4800,
		HighlightMemoryS.OUTDATA_REG_B = "CLOCK1",
		HighlightMemoryS.ADDRESS_REG_B = "CLOCK1",
		HighlightMemoryS.CLOCK_ENABLE_INPUT_A = "BYPASS",
		HighlightMemoryS.CLOCK_ENABLE_INPUT_B = "BYPASS",
		HighlightMemoryS.CLOCK_ENABLE_OUTPUT_B = "BYPASS",
		HighlightMemoryS.POWER_UP_UNINITIALIZED = "FALSE",
		HighlightMemoryS.INIT_FILE = S_INITIAL_HIGHLIGHT;
	
altsyncram	TextMemoryL (
				.wren_a (wtenl),
				.wren_b (gnd),
				.clock0 (wclock), // write clock
				.clock1 (rclock), // read clock
				.clocken0 (vcc), // write enable clock
				.clocken1 (vcc), // read enable clock				
				.address_a (waddrl),
				.address_b (raddrl),
				.data_a (wascii),
				.q_b (oasciil)	// data out
				);
	defparam
		TextMemoryL.WIDTH_A = 7,
		TextMemoryL.WIDTH_B = 7,
		// TextMemoryL.INTENDED_DEVICE_FAMILY = "Cyclone V",
		TextMemoryL.OPERATION_MODE = "DUAL_PORT",
		TextMemoryL.WIDTHAD_A = 11,
		TextMemoryL.NUMWORDS_A = 1200,
		TextMemoryL.WIDTHAD_B = 11,
		TextMemoryL.NUMWORDS_B = 1200,
		TextMemoryL.OUTDATA_REG_B = "CLOCK1",
		TextMemoryL.ADDRESS_REG_B = "CLOCK1",
		TextMemoryL.CLOCK_ENABLE_INPUT_A = "BYPASS",
		TextMemoryL.CLOCK_ENABLE_INPUT_B = "BYPASS",
		TextMemoryL.CLOCK_ENABLE_OUTPUT_B = "BYPASS",
		TextMemoryL.POWER_UP_UNINITIALIZED = "FALSE",
		TextMemoryL.INIT_FILE = L_INITIAL_ASCII;

	/* Create colour memory */
	altsyncram	ColourMemoryL (
				.wren_a (wtenl),
				.wren_b (gnd),
				.clock0 (wclock), // write clock
				.clock1 (rclock), // read clock
				.clocken0 (vcc), // write enable clock
				.clocken1 (vcc), // read enable clock				
				.address_a (waddrl),
				.address_b (raddrl),
				.data_a (wcolour), // data in
				.q_b (ocolourl)	// data out
				);
	defparam
		ColourMemoryL.WIDTH_A = 6,
		ColourMemoryL.WIDTH_B = 6,
		// ColourMemoryL.INTENDED_DEVICE_FAMILY = "Cyclone V",
		ColourMemoryL.OPERATION_MODE = "DUAL_PORT",
		ColourMemoryL.WIDTHAD_A = 11,
		ColourMemoryL.NUMWORDS_A = 1200,
		ColourMemoryL.WIDTHAD_B = 11,
		ColourMemoryL.NUMWORDS_B = 1200,
		ColourMemoryL.OUTDATA_REG_B = "CLOCK1",
		ColourMemoryL.ADDRESS_REG_B = "CLOCK1",
		ColourMemoryL.CLOCK_ENABLE_INPUT_A = "BYPASS",
		ColourMemoryL.CLOCK_ENABLE_INPUT_B = "BYPASS",
		ColourMemoryL.CLOCK_ENABLE_OUTPUT_B = "BYPASS",
		ColourMemoryL.POWER_UP_UNINITIALIZED = "FALSE",
		ColourMemoryL.INIT_FILE = L_INITIAL_COLOUR;
		
	/* Create highlight memory */
	altsyncram	HighlightMemoryL (
				.wren_a (htenl),
				.wren_b (gnd),
				.clock0 (hclock), // write clock
				.clock1 (rclock), // read clock
				.clocken0 (vcc), // write enable clock
				.clocken1 (vcc), // read enable clock				
				.address_a (haddrl),
				.address_b (raddrl),
				.data_a (highlight), // data in
				.q_b (ohll)	// data out
				);
	defparam
		HighlightMemoryL.WIDTH_A = 1,
		HighlightMemoryL.WIDTH_B = 1,
		// HighlightMemoryL.INTENDED_DEVICE_FAMILY = "Cyclone V",
		HighlightMemoryL.OPERATION_MODE = "DUAL_PORT",
		HighlightMemoryL.WIDTHAD_A = 11,
		HighlightMemoryL.NUMWORDS_A = 1200,
		HighlightMemoryL.WIDTHAD_B = 11,
		HighlightMemoryL.NUMWORDS_B = 1200,
		HighlightMemoryL.OUTDATA_REG_B = "CLOCK1",
		HighlightMemoryL.ADDRESS_REG_B = "CLOCK1",
		HighlightMemoryL.CLOCK_ENABLE_INPUT_A = "BYPASS",
		HighlightMemoryL.CLOCK_ENABLE_INPUT_B = "BYPASS",
		HighlightMemoryL.CLOCK_ENABLE_OUTPUT_B = "BYPASS",
		HighlightMemoryL.POWER_UP_UNINITIALIZED = "FALSE",
		HighlightMemoryL.INIT_FILE = L_INITIAL_HIGHLIGHT;

	
endmodule

module smallcoordstoaddr(input [6:0] x,
								 input [5:0] y,
								 output reg [12:0] addr);
/* returns 13'b111111111111111 on OOB*/
always @(*)
begin 
	if (((y >= 60) | (x >= 80)) == 1'b1) addr <= 13'b1111111111111;
	else begin
		/* 80y + x = 64y + 16y + x = 2**6 y + 2 ** 4 y + x*/
		addr <= (y << 6) + (y << 4) + x;
	end
end


endmodule 

module largecoordstoaddr(input [6:0] x,
								 input [5:0] y,
								 output reg [10:0] addr);
/* returns 11'b1111111111111 on OOB */
always @(*)
begin 
	if (((y >= 30) | (x >= 40)) == 1'b1) addr <= 11'b11111111111;
	else begin
		/* 40y + x = 32y + 8y + x = 2**5 y + 2 ** 3 y + x*/
		addr <= (y << 5) + x + (y << 3);
	end
end								 

endmodule 
