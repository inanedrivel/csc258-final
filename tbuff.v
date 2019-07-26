// The main program for the text buffer.
// Basically inits all the modules.
// - Tim

module tbuff(input CLOCK_50,
				input [2:0] KEY,
				input [7:0] SW,
				/* KB IN */
				inout PS2_CLK,
				inout PS2_DAT,
				/* FUCK VGA */
				output [9:0] VGA_R,
				output [9:0] VGA_G,
				output [9:0] VGA_B,
				output VGA_HS,
				output VGA_VS,
				output VGA_BLANK,
				output VGA_SYNC,
				output VGA_CLK););
				
	wire searchMode;
	wire largeMode;
	wire resetn;
	
	assign searchMode = SW[1];
	assign largeMode = SW[0];
	assign resetn = KEY[0];
	
	memory_controller memctrl(.sL(largeMode),
								     .wrx(),
			      				  .wry(),
								     .wren(),
								     .wrascii(),
								     .wrcolour(),
								     .wclock(),
								     .hix(),
								     .hiy(),
								     .hien(),
								     .highlight(),
								     .hclock(),
								     .rex(),
								     .rey(),
								     .rascii(),
								     .rcolour(),
								     .rhighlight(),
								     .rclock());
	
	vga_render va(.sL(largeMode),
					  .clk(),
					  .cx(),
					  .cy(),
					  .ccolour(),
					  .cascii(),
					  .chl(),
					  .VGA_R(),
					  .VGA_G(),
					  .VGA_B(),
				     .VGA_HS(),
				     .VGA_VS(),
				     .VGA_BLANK(),
				     .VGA_SYNC(),
				     .VGA_CLK());
	
	keyboard_in kbin(.PS2_CLK(),
						  .PS2_DAT()
						  .asciiin());
	
	char_data cd(.sl(largeMode),
					 .ascii(),
					 .data());
					 
	
	edit_mode em(.sL(largeMode),
					 .clk(),
					 .asciiin(),
					 .cx(),
					 .cy(),
					 .ccol(),
					 .cascii(),
					 .cwren(),
					 .hx(),
					 .hy(),
					 .hen());
	
	search_mode em(.sL(largeMode),
					 .clk(),
					 .asciiin(),
					 .editxin(),
					 .edityin(),
					 .editchar(),
					 .cx(),
					 .cy(),
					 .ccol(),
					 .cascii(),
					 .cwren(),
					 .hx(),
					 .hy(),
					 .hen());
	
	always @(*)
	begin
		if (searchMode) begin
			/* make the IM go through search mode */
		end
		else
		begin
			/* make the IM go through edut mode */
		end
	end
	
endmodule
