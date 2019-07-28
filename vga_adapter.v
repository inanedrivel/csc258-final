/* Adapted VGA Adapter
 * ----------------
 *
 * This is an implementation of a VGA Adapter. The adapter uses VGA mode signalling to initiate
 * a 640x480 resolution mode on a computer monitor, with a refresh rate of approximately 60Hz.
 * It is designed for easy use in an early digital logic design course to facilitate student
 * projects on the Altera DE2 Educational board.
 *
 * This implementation of the VGA adapter can display images of varying colour depth at a resolution of
 * 320x240 or 160x120 superpixels. The concept of superpixels is introduced to reduce the amount of on-chip
 * memory used by the adapter. The following table shows the number of bits of on-chip memory used by
 * the adapter in various resolutions and colour depths.
 * 
 * -------------------------------------------------------------------------------------------------------------------------------
 * Resolution | Mono    | 8 colours | 64 colours | 512 colours | 4096 colours | 32768 colours | 262144 colours | 2097152 colours |
 * -------------------------------------------------------------------------------------------------------------------------------
 * 160x120    |   19200 |     57600 |     115200 |      172800 |       230400 |        288000 |         345600 |          403200 |
 * 320x240    |   78600 |    230400 | ############## Does not fit ############################################################## |
 * -------------------------------------------------------------------------------------------------------------------------------
 *
 * By default the adapter works at the resolution of 320x240 with 8 colours. To set the adapter in any of
 * the other modes, the adapter must be instantiated with specific parameters. These parameters are:
 * - RESOLUTION - a string that should be either "320x240" or "160x120".
 * - MONOCHROME - a string that should be "TRUE" if you only want black and white colours, and "FALSE"
 *                otherwise.
 * - BITS_PER_COLOUR_CHANNEL  - an integer specifying how many bits are available to describe each colour
 *                          (R,G,B). A default value of 1 indicates that 1 bit will be used for red
 *                          channel, 1 for green channel and 1 for blue channel. This allows 8 colours
 *                          to be used.
 * 
 * In addition to the above parameters, a BACKGROUND_IMAGE parameter can be specified. The parameter
 * refers to a memory initilization file (MIF) which contains the initial contents of video memory.
 * By specifying the initial contents of the memory we can force the adapter to initially display an
 * image of our choice. Please note that the image described by the BACKGROUND_IMAGE file will only
 * be valid right after your program the DE2 board. If your circuit draws a single pixel on the screen,
 * the video memory will be altered and screen contents will be changed. In order to restore the background
 * image your circuti will have to redraw the background image pixel by pixel, or you will have to
 * reprogram the DE2 board, thus allowing the video memory to be rewritten.
 *
 * To use the module connect the vga_adapter to your circuit. Your circuit should produce a value for
 * inputs X, Y and plot. When plot is high, at the next positive edge of the input clock the vga_adapter
 * will change the contents of the video memory for the pixel at location (X,Y). At the next redraw
 * cycle the VGA controller will update the contants of the screen by reading the video memory and copying
 * it over to the screen. Since the monitor screen has no memory, the VGA controller has to copy the
 * contents of the video memory to the screen once every 60th of a second to keep the image stable. Thus,
 * the video memory should not be used for other purposes as it may interfere with the operation of the
 * VGA Adapter.
 *
 * As a final note, ensure that the following conditions are met when using this module:
 * 1. You are implementing the the VGA Adapter on the Altera DE2 board. Using another board may change
 *    the amount of memory you can use, the clock generation mechanism, as well as pin assignments required
 *    to properly drive the VGA digital-to-analog converter.
 * 2. Outputs VGA_* should exist in your top level design. They should be assigned pin locations on the
 *    Altera DE2 board as specified by the DE2_pin_assignments.csv file.
 * 3. The input clock must have a frequency of 50 MHz with a 50% duty cycle. On the Altera DE2 board
 *    PIN_N2 is the source for the 50MHz clock.
 *
 * During compilation with Quartus II you may receive the following warnings:
 * - Warning: Variable or input pin "clocken1" is defined but never used
 * - Warning: Pin "VGA_SYNC" stuck at VCC
 * - Warning: Found xx output pins without output pin load capacitance assignment
 * These warnings can be ignored. The first warning is generated, because the software generated
 * memory module contains an input called "clocken1" and it does not drive logic. The second warning
 * indicates that the VGA_SYNC signal is always high. This is intentional. The final warning is
 * generated for the purposes of power analysis. It will persist unless the output pins are assigned
 * output capacitance. Leaving the capacitance values at 0 pf did not affect the operation of the module.
 *
 * If you see any other warnings relating to the vga_adapter, be sure to examine them carefully. They may
 * cause your circuit to malfunction.
 *
 * NOTES/REVISIONS:
 * July 10, 2007 - Modified the original version of the VGA Adapter written by Sam Vafaee in 2006. The module
 *		   now supports 2 different resolutions as well as uses half the memory compared to prior
 *		   implementation. Also, all settings for the module can be specified from the point
 *		   of instantiation, rather than by modifying the source code. (Tomasz S. Czajkowski)
 */

module vga_adapter(
			resetn,
			clock,
			colour, character, highlight,
			x, y, plot,
			/* Signals for the DAC to drive the monitor. */
			VGA_R,
			VGA_G,
			VGA_B,
			VGA_HS,
			VGA_VS,
			VGA_BLANK,
			VGA_SYNC,
			VGA_CLK);
 
	parameter BITS_PER_COLOUR_CHANNEL = 6;
	/* The number of bits per colour channel used to represent the colour of each pixel. A value
	 * of 1 means that Red, Green and Blue colour channels will use 1 bit each to represent the intensity
	 * of the respective colour channel. For BITS_PER_COLOUR_CHANNEL=1, the adapter can display 8 colours.
	 * In general, the adapter is able to use 2^(3*BITS_PER_COLOUR_CHANNEL ) colours. The number of colours is
	 * limited by the screen resolution and the amount of on-chip memory available on the target device.
	 */	
	
	parameter MONOCHROME = "FALSE";
	/* Set this parameter to "TRUE" if you only wish to use black and white colours. Doing so will reduce
	 * the amount of memory you will use by a factor of 3. */
	
	parameter RESOLUTION = "640x480";
	/* Set this parameter to "160x120" or "320x240". It will cause the VGA adapter to draw each dot on
	 * the screen by using a block of 4x4 pixels ("160x120" resolution) or 2x2 pixels ("320x240" resolution).
	 * It effectively reduces the screen resolution to an integer fraction of 640x480. It was necessary
	 * to reduce the resolution for the Video Memory to fit within the on-chip memory limits.
	 */
	
	parameter BACKGROUND_IMAGE = "background.mif";
	/* The initial screen displayed when the circuit is first programmed onto the DE2 board can be
	 * defined useing an MIF file. The file contains the initial colour for each pixel on the screen
	 * and is placed in the Video Memory (VideoMemory module) upon programming. Note that resetting the
	 * VGA Adapter will not cause the Video Memory to revert to the specified image. */
	parameter BG_COL = 18'b0;
	parameter INITIAL_TEXT = "initial_text.mif";
	parameter INITIAL_COLOUR = "initial_colour.mif";
	parameter INITIAL_HIGHLIGHT = "initial_highlight.mif";
	
	parameter CHAR_DATA = "character_data.mif";
	/*****************************************************************************/
	/* Declare inputs and outputs.                                               */
	/*****************************************************************************/
	input resetn;
	input clock;
	
	/* The colour input can be either 1 bit or 3*BITS_PER_COLOUR_CHANNEL bits wide, depending on
	 * the setting of the MONOCHROME parameter.
	 */
	input [((MONOCHROME == "TRUE") ? (0) : (BITS_PER_COLOUR_CHANNEL*3-1)):0] colour;
	input [6:0] character;
	input highlight;
	/* Specify the number of bits required to represent an (X,Y) coordinate on the screen for
	 * a given resolution.
	 */
	input [6:0] x; 
	input [5:0] y;
	
	/* When plot is high then at the next positive edge of the clock the pixel at (x,y) will change to
	 * a new colour, defined by the value of the colour input.
	 */
	input plot;
	
	/* These outputs drive the VGA display. The VGA_CLK is also used to clock the FSM responsible for
	 * controlling the data transferred to the DAC driving the monitor. */
	output [9:0] VGA_R;
	output [9:0] VGA_G;
	output [9:0] VGA_B;
	output VGA_HS;
	output VGA_VS;
	output VGA_BLANK;
	output VGA_SYNC;
	output VGA_CLK;

	/*****************************************************************************/
	/* Declare local signals here.                                               */
	/*****************************************************************************/
	
	wire valid_640x480;
	wire valid_320x240;
	/* Set to 1 if the specified coordinates are in a valid range for a given resolution.*/
	
	wire writeEn;
	/* This is a local signal that allows the Video Memory contents to be changed.
	 * It depends on the screen resolution, the values of X and Y inputs, as well as 
	 * the state of the plot signal.
	 */
	
	wire [((MONOCHROME == "TRUE") ? (0) : (BITS_PER_COLOUR_CHANNEL*3-1)):0] to_ctrl_colour;
	/* Pixel colour read by the VGA controller */
	
	wire [12:0] user_to_text_memory_addr;
	/* This bus specifies the address in memory the user must write
	 * data to in order for the pixel intended to appear at location (X,Y) to be displayed
	 * at the correct location on the screen.
	 */
	
	wire [((RESOLUTION == "640x480") ? (18) : (16)):0] controller_to_video_memory_addr;
	/* This bus specifies the address in memory the vga controller must read data from
	 * in order to determine the colour of a pixel located at coordinate (X,Y) of the screen.
	 */
	
	wire clock_25;
	/* 25MHz clock generated by dividing the input clock frequency by 2. */
	
	wire vcc, gnd;
	
	/*****************************************************************************/
	/* Instances of modules for the VGA adapter.                                 */
	/*****************************************************************************/	
	assign vcc = 1'b1;
	assign gnd = 1'b0;
	c_address_trans ui_t(.cx(x), .cy(y), .mem_address(user_to_text_memory_addr));
	/* Convert user coordinates into a memory address. */

	assign valid_640x480 = (({1'b0, x} >= 0) & ({1'b0, x} < 80) & ({1'b0, y} >= 0) & ({1'b0, y} < 60)) & (RESOLUTION == "640x480");
	assign valid_320x240 = (({1'b0, x} >= 0) & ({1'b0, x} < 320) & ({1'b0, y} >= 0) & ({1'b0, y} < 240)) & (RESOLUTION == "320x240");
	assign writeEn = (plot) & (valid_640x480 | valid_320x240);
	/* Allow the user to plot a pixel if and only if the (X,Y) coordinates supplied are in a valid range. */
	
	wire [12:0] inputcaddr;
	wire [12:0] outputcaddr;
	wire [63:0] outchar;
	wire [17:0] outcolour;
	wire [6:0] outascii;
	wire outhl;
	fetch(controller_to_video_memory_addr, outputcaddr, outcolour, outchar, outhl, to_ctrl_colour);
	
	/* Create font */
	altsyncram	CharInfo (
				.clock0 (clock),
				.address_a (outascii),
				.q_a (outchar)	// data out
				);
	defparam
		CharInfo.WIDTH_A = 64,
		CharInfo.INTENDED_DEVICE_FAMILY = "Cyclone V",
		CharInfo.OPERATION_MODE = "ROM",
		CharInfo.WIDTHAD_A = 7,
		CharInfo.NUMWORDS_A = 128,
		CharInfo.POWER_UP_UNINITIALIZED = "FALSE",
		CharInfo.INIT_FILE = CHAR_DATA;	
	
	/* Create text memory */
	altsyncram	TextMemory (
				.wren_a (writeEn),
				.wren_b (gnd),
				.clock0 (clock), // write clock
				.clock1 (clock_25), // read clock
				.clocken0 (vcc), // write enable clock
				.clocken1 (vcc), // read enable clock				
				.address_a (inputcaddr),
				.address_b (outputcaddr),
				.data_a (character), // data in
				.q_b (outascii)	// data out
				);
	defparam
		TextMemory.WIDTH_A = 7,
		TextMemory.WIDTH_B = 7,
		TextMemory.INTENDED_DEVICE_FAMILY = "Cyclone V",
		TextMemory.OPERATION_MODE = "DUAL_PORT",
		TextMemory.WIDTHAD_A = ((RESOLUTION == "640x480") ? (13) : (11)),
		TextMemory.NUMWORDS_A = ((RESOLUTION == "640x480") ? (4800) : (1200)),
		TextMemory.WIDTHAD_B = ((RESOLUTION == "640x480") ? (13) : (11)),
		TextMemory.NUMWORDS_B = ((RESOLUTION == "640x480") ? (4800) : (1200)),
		TextMemory.OUTDATA_REG_B = "CLOCK1",
		TextMemory.ADDRESS_REG_B = "CLOCK1",
		TextMemory.CLOCK_ENABLE_INPUT_A = "BYPASS",
		TextMemory.CLOCK_ENABLE_INPUT_B = "BYPASS",
		TextMemory.CLOCK_ENABLE_OUTPUT_B = "BYPASS",
		TextMemory.POWER_UP_UNINITIALIZED = "FALSE",
		TextMemory.INIT_FILE = INITIAL_TEXT;

	/* Create colour memory */
	altsyncram	ColourMemory (
				.wren_a (writeEn),
				.wren_b (gnd),
				.clock0 (clock), // write clock
				.clock1 (clock_25), // read clock
				.clocken0 (vcc), // write enable clock
				.clocken1 (vcc), // read enable clock				
				.address_a (inputcaddr),
				.address_b (outputcaddr),
				.data_a (colour), // data in
				.q_b (outcolour)	// data out
				);
	defparam
		ColourMemory.WIDTH_A = 18,
		ColourMemory.WIDTH_B = 18,
		ColourMemory.INTENDED_DEVICE_FAMILY = "Cyclone V",
		ColourMemory.OPERATION_MODE = "DUAL_PORT",
		ColourMemory.WIDTHAD_A = ((RESOLUTION == "640x480") ? (13) : (11)),
		ColourMemory.NUMWORDS_A = ((RESOLUTION == "640x480") ? (4800) : (1200)),
		ColourMemory.WIDTHAD_B = ((RESOLUTION == "640x480") ? (13) : (11)),
		ColourMemory.NUMWORDS_B = ((RESOLUTION == "640x480") ? (4800) : (1200)),
		ColourMemory.OUTDATA_REG_B = "CLOCK1",
		ColourMemory.ADDRESS_REG_B = "CLOCK1",
		ColourMemory.CLOCK_ENABLE_INPUT_A = "BYPASS",
		ColourMemory.CLOCK_ENABLE_INPUT_B = "BYPASS",
		ColourMemory.CLOCK_ENABLE_OUTPUT_B = "BYPASS",
		ColourMemory.POWER_UP_UNINITIALIZED = "FALSE",
		ColourMemory.INIT_FILE = INITIAL_COLOUR;
		
	/* Create highlight memory */
	altsyncram	HighlightMemory (
				.wren_a (writeEn),
				.wren_b (gnd),
				.clock0 (clock), // write clock
				.clock1 (clock_25), // read clock
				.clocken0 (vcc), // write enable clock
				.clocken1 (vcc), // read enable clock				
				.address_a (inputcaddr),
				.address_b (outputcaddr),
				.data_a (highlight), // data in
				.q_b (outhl)	// data out
				);
	defparam
		HighlightMemory.WIDTH_A = 1,
		HighlightMemory.WIDTH_B = 1,
		HighlightMemory.INTENDED_DEVICE_FAMILY = "Cyclone V",
		HighlightMemory.OPERATION_MODE = "DUAL_PORT",
		HighlightMemory.WIDTHAD_A = ((RESOLUTION == "640x480") ? (13) : (11)),
		HighlightMemory.NUMWORDS_A = ((RESOLUTION == "640x480") ? (4800) : (1200)),
		HighlightMemory.WIDTHAD_B = ((RESOLUTION == "640x480") ? (13) : (11)),
		HighlightMemory.NUMWORDS_B = ((RESOLUTION == "640x480") ? (4800) : (1200)),
		HighlightMemory.OUTDATA_REG_B = "CLOCK1",
		HighlightMemory.ADDRESS_REG_B = "CLOCK1",
		HighlightMemory.CLOCK_ENABLE_INPUT_A = "BYPASS",
		HighlightMemory.CLOCK_ENABLE_INPUT_B = "BYPASS",
		HighlightMemory.CLOCK_ENABLE_OUTPUT_B = "BYPASS",
		HighlightMemory.POWER_UP_UNINITIALIZED = "FALSE",
		HighlightMemory.INIT_FILE = INITIAL_HIGHLIGHT;
	
	
	/* Create video memory. */ /*
	altsyncram	VideoMemory (
				.wren_a (writeEn),
				.wren_b (gnd),
				.clock0 (clock), // write clock
				.clock1 (clock_25), // read clock
				.clocken0 (vcc), // write enable clock
				.clocken1 (vcc), // read enable clock				
				.address_a (user_to_video_memory_addr),
				.address_b (controller_to_video_memory_addr),
				.data_a (colour), // data in
				.q_b (to_ctrl_colour)	// data out
				);
	defparam
		VideoMemory.WIDTH_A = ((MONOCHROME == "FALSE") ? (BITS_PER_COLOUR_CHANNEL*3) : 1),
		VideoMemory.WIDTH_B = ((MONOCHROME == "FALSE") ? (BITS_PER_COLOUR_CHANNEL*3) : 1),
		VideoMemory.INTENDED_DEVICE_FAMILY = "Cyclone II",
		VideoMemory.OPERATION_MODE = "DUAL_PORT",
		VideoMemory.WIDTHAD_A = ((RESOLUTION == "640x480") ? (19) : (17)),
		VideoMemory.NUMWORDS_A = ((RESOLUTION == "640x480") ? (314400) : (314400)),
		VideoMemory.WIDTHAD_B = ((RESOLUTION == "640x480") ? (19) : (17)),
		VideoMemory.NUMWORDS_B = ((RESOLUTION == "640x480") ? (314400) : (314400)),
		VideoMemory.OUTDATA_REG_B = "CLOCK1",
		VideoMemory.ADDRESS_REG_B = "CLOCK1",
		VideoMemory.CLOCK_ENABLE_INPUT_A = "BYPASS",
		VideoMemory.CLOCK_ENABLE_INPUT_B = "BYPASS",
		VideoMemory.CLOCK_ENABLE_OUTPUT_B = "BYPASS",
		VideoMemory.POWER_UP_UNINITIALIZED = "FALSE",
		VideoMemory.INIT_FILE = BACKGROUND_IMAGE;
		*/
	vga_pll mypll(clock, clock_25);
	/* This module generates a clock with half the frequency of the input clock.
	 * For the VGA adapter to operate correctly the clock signal 'clock' must be
	 * a 50MHz clock. The derived clock, which will then operate at 25MHz, is
	 * required to set the monitor into the 640x480@60Hz display mode (also known as
	 * the VGA mode).
	 */
	
	vga_controller controller(
			.vga_clock(clock_25),
			.resetn(resetn),
			.pixel_colour(to_ctrl_colour),
			.memory_address(controller_to_video_memory_addr), 
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK),
			.VGA_SYNC(VGA_SYNC),
			.VGA_CLK(VGA_CLK)				
		);
		defparam controller.BITS_PER_COLOUR_CHANNEL  = BITS_PER_COLOUR_CHANNEL ;
		defparam controller.MONOCHROME = MONOCHROME;
		defparam controller.RESOLUTION = RESOLUTION;

endmodule

module pixel_to_char_addr_trans(paddress, caddress, cx, cy);
/* 
we want to compute 80(59 - (y << 3)) + (x << 3)
from 640y + x. we will do this inefficiently.
*/
input [18:0] paddress;
output reg [12:0] caddress;
output reg [6:0] cx;
output reg [5:0] cy;
wire [9:0] px;
wire [8:0] ty, py;
assign px = {1'b0, paddress} % 640;
assign py = paddress / 640;
always @(*)
begin
	caddress = 80*py[8:3] + px[9:3];
	/*if (px[2:0] == 3'b111)
		caddress = (80*py[8:3] + px[9:3] - 1'b1) % 4800;
	else*/ 
end
endmodule

module fetch(p_address, c_address, incolour, character, highlight, outcolour);
	parameter BACKGROUND = 18'b0;
input [18:0] p_address;
input [17:0] incolour;
input [63:0] character;
input highlight;
output reg [17:0] outcolour;
output [12:0] c_address;
pixel_to_char_addr_trans getcharcoords(p_address, c_address);
wire [2:0] yd, xd;
wire [5:0] ydet;
assign ydet = p_address / 640; 
assign yd = ydet[2:0];
assign xd = p_address[2:0]; /* our font is shit, flip x */
wire yc = character[{3'b111 - yd,3'b111 - xd}];
always @(*)
begin
	if(yc ^ highlight) outcolour <= incolour;
	else outcolour <= BACKGROUND;
end

endmodule

module c_address_trans(cx, cy, mem_address);
	input [6:0] cx; 
	input [5:0] cy;	
	output [12:0] mem_address;
	assign mem_address = (cy << 6) + (cy << 4) + cx;

endmodule

module vga_address_translator(x, y, mem_address);

	parameter RESOLUTION = "640x480";
	/* Set this parameter to "640x480" or "320x240". It will cause the VGA adapter to draw each dot on
	 * the screen by using a block of 1x1 pixels ("640x480" resolution) or 2x2 pixels ("320x240" resolution).
	 * It effectively reduces the screen resolution to an integer fraction of 640x480. It was necessary
	 * to reduce the resolution for the Video Memory to fit within the on-chip memory limits.
	 */

	input [((RESOLUTION == "640x480") ? (9) : (8)):0] x; 
	input [((RESOLUTION == "640x480") ? (8) : (7)):0] y;	
	output reg [((RESOLUTION == "640x480") ? (18) : (16)):0] mem_address;
	
	/* The basic formula is address = y*WIDTH + x;
	 * For 320x240 resolution we can write 320 as (256 + 64). Memory address becomes
	 * (y*256) + (y*64) + x;
	 * This simplifies multiplication a simple shift and add operation.
	 * A leading 0 bit is added to each operand to ensure that they are treated as unsigned
	 * inputs. By default the use a '+' operator will generate a signed adder.
	 * Similarly, for 160x120 resolution we write 160 as 128+32.
	 */
	wire [16:0] res_320x240 = ({1'b0, y, 8'd0} + {1'b0, y, 6'd0} + {1'b0, x});
	wire [18:0] res_640x480 = ({1'b0, y, 9'd0} + {1'b0, y, 7'd0} + {1'b0, x});
	
	always @(*)
	begin
		if (RESOLUTION == "640x480")
			mem_address = res_640x480;
		else
			mem_address = res_320x240;
	end
endmodule
