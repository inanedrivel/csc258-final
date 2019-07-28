/* I didn't make this one.
 *
 * This module implements the VGA controller. It assumes a 25MHz clock is supplied as input.
 *
 * General approach:
 * Go through each line of the screen and read the colour each pixel on that line should have from
 * the Video memory. To do that for each (x,y) pixel on the screen convert (x,y) coordinate to
 * a memory_address at which the pixel colour is stored in Video memory. Once the pixel colour is
 * read from video memory its brightness is first increased before it is forwarded to the VGA DAC.
 */
module vga_controller(input vga_clock, 
							 input resetn, 
							 input [5:0] pixel_colour, 
							 output reg [9:0] x,
							 output reg [8:0] y,
							 output reg [9:0] VGA_R,
							 output reg [9:0] VGA_G,
							 output reg [9:0] VGA_B,
							 output reg VGA_HS,
							 output reg VGA_VS,
							 output reg VGA_BLANK,
							 output VGA_SYNC,
							 output VGA_CLK); 
	
	//--- Timing parameters.
	/* Recall that the VGA specification requires a few more rows and columns are drawn
	 * when refreshing the screen than are actually present on the screen. This is necessary to
	 * generate the vertical and the horizontal syncronization signals. If you wish to use a
	 * display mode other than 640x480 you will need to modify the parameters below as well
	 * as change the frequency of the clock driving the monitor (VGA_CLK).
	 */
	parameter C_VERT_NUM_PIXELS  = 10'd480;
	parameter C_VERT_SYNC_START  = 10'd493;
	parameter C_VERT_SYNC_END    = 10'd494; //(C_VERT_SYNC_START + 2 - 1); 
	parameter C_VERT_TOTAL_COUNT = 10'd525;

	parameter C_HORZ_NUM_PIXELS  = 10'd640;
	parameter C_HORZ_SYNC_START  = 10'd659;
	parameter C_HORZ_SYNC_END    = 10'd754; //(C_HORZ_SYNC_START + 96 - 1); 
	parameter C_HORZ_TOTAL_COUNT = 10'd800;	
		
	parameter dontdrawout = 6'b0;
	
	/*****************************************************************************/
	/* Local Signals.                                                            */
	/*****************************************************************************/
	
	reg VGA_HS1;
	reg VGA_VS1;
	reg VGA_BLANK1; 
	reg [9:0] xCounter, yCounter;
	wire xCounter_clear;
	wire yCounter_clear;
	wire vcc;
	
	reg [5:0] tc;
	
	/*****************************************************************************/
	/* Controller implementation.                                                */
	/*****************************************************************************/

	assign vcc =1'b1;
	
	/* A counter to scan through a horizontal line. */
	always @(posedge vga_clock or negedge resetn)
	begin
		if (!resetn)
			xCounter <= 10'd0;
		else if (xCounter_clear)
			xCounter <= 10'd0;
		else
		begin
			xCounter <= xCounter + 1'b1;
		end
	end
	assign xCounter_clear = (xCounter == (C_HORZ_TOTAL_COUNT-1));

	/* A counter to scan vertically, indicating the row currently being drawn. */
	always @(posedge vga_clock or negedge resetn)
	begin
		if (!resetn)
			yCounter <= 10'd0;
		else if (xCounter_clear && yCounter_clear)
			yCounter <= 10'd0;
		else if (xCounter_clear)		//Increment when x counter resets
			yCounter <= yCounter + 1'b1;
	end
	assign yCounter_clear = (yCounter == (C_VERT_TOTAL_COUNT-1)); 
	
	always @(*)
	begin
		x = xCounter[9:0];
		y = yCounter[8:0];
	end
	
	always @(*)
	begin
		if ((x <= 640) & (y <= 480)) begin
			tc <= pixel_colour;
		end
		else tc <= dontdrawout;
	end

	/* Generate the vertical and horizontal synchronization pulses. */
	always @(posedge vga_clock)
	begin
		//- Sync Generator (ACTIVE LOW)
		VGA_HS1 <= ~((xCounter >= C_HORZ_SYNC_START) && (xCounter <= C_HORZ_SYNC_END));
		VGA_VS1 <= ~((yCounter >= C_VERT_SYNC_START) && (yCounter <= C_VERT_SYNC_END));
		
		//- Current X and Y is valid pixel range
		VGA_BLANK1 <= ((xCounter < C_HORZ_NUM_PIXELS) && (yCounter < C_VERT_NUM_PIXELS));	
	
		//- Add 1 cycle delay
		VGA_HS <= VGA_HS1;
		VGA_VS <= VGA_VS1;
		VGA_BLANK <= VGA_BLANK1;	
	end
	
	/* VGA sync should be 1 at all times. */
	assign VGA_SYNC = vcc;
	
	/* Generate the VGA clock signal. */
	assign VGA_CLK = vga_clock;
	
	/* Brighten the colour output. */
	// The colour input is first processed to brighten the image a little. Setting the top
	// bits to correspond to the R,G,B colour makes the image a bit dull. To brighten the image,
	// each bit of the colour is replicated through the 10 DAC colour input bits. For example,
	// when BITS_PER_COLOUR_CHANNEL is 2 and the red component is set to 2'b10, then the
	// VGA_R input to the DAC will be set to 10'b1010101010.
	
	integer index;
	integer sub_index;
	
	always @(tc)
	begin		
		VGA_R <= 'b0;
		VGA_G <= 'b0;
		VGA_B <= 'b0;
		for (index = 8; index >= 0; index = index - 2)
		begin
			for (sub_index = 1; sub_index >= 0; sub_index = sub_index - 1)
			begin
				VGA_R[sub_index+index] <= tc[sub_index + 4];
				VGA_G[sub_index+index] <= tc[sub_index + 2];
				VGA_B[sub_index+index] <= tc[sub_index];
			end
		end	
	end

endmodule

