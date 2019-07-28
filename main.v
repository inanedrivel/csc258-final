module main(input CLOCK_50,
				input [2:0] KEY,
				input [7:0] SW,
				output [6:0] LEDR,
				output [6:0] HEX0, 
				output [6:0] HEX1, 
				output [6:0] HEX2, 
				output [6:0] HEX3, 
				output [6:0] HEX4,
				output [6:0] HEX5,
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
				output VGA_CLK);
	wire clock_25;
	l25c delay(CLOCK_50, resetn, clock_25);
			
	wire searchMode;
	wire largeMode;
	wire resetn;
	
	assign searchMode = SW[1];
	assign largeMode = SW[0];
	assign resetn = KEY[0];
	
	memory_controller memctrl(.sL(largeMode),
								     .wrx(7'b0),
			      				  .wry(6'b0),
								     .wren(1'b0),
								     .wascii(1'b0),
								     .wcolour(6'b0),
								     .wclock(CLOCK_50),
								     .hix(7'b0),
								     .hiy(6'b0),
								     .hien(1'b0),
								     .highlight(1'b0),
								     .hclock(CLOCK_50),
								     .rex(vgx),
								     .rey(vgy),
								     .rascii(vgascii),
								     .rcolour(vgclr),
								     .rhighlight(vghl),
									  .DEBUG(LEDR[6]),
								     .rclock(CLOCK_50));
	wire [6:0] vgascii;
	wire [6:0] vgx;
	wire [5:0] vgy;
	wire [5:0] vgclr;
	wire vghl;
	assign LEDR[5:0] = vgclr;
	
	wire [15:0] VDBG;
	hex_decoder h5(VDBG[15:12], HEX5);
	hex_decoder h4(VDBG[11:8], HEX4);
	hex_decoder h3(VDBG[7:4], HEX3);
	hex_decoder h2(VDBG[3:0], HEX2);
	hex_decoder h1({2'b0, vgclr[5:4]}, HEX1);
	hex_decoder h0(vgclr[3:0], HEX0);
	
	vga_render va(.sL(largeMode),
					  .resetn(resetn),
					  .clk(CLOCK_50),
					  .vclk(clock_25),
					  .cx(vgx),
					  .cy(vgy),
					  .ccolour(vgclr),
					  .cascii(vgascii),
					  .chl(vghl),
					  .VGA_R(VGA_R),
					  .VGA_G(VGA_G),
					  .VGA_B(VGA_B),
				     .VGA_HS(VGA_HS),
				     .VGA_VS(VGA_VS),
				     .VGA_BLANK(VGA_BLANK),
				     .VGA_SYNC(VGA_SYNC),
					  .DEBUG(VDBG),
				     .VGA_CLK(VGA_CLK));
	/*
	keyboard_in kbin(.PS2_CLK(),
						  .PS2_DAT()
						  .asciiin());
				 
	
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
			// make the IM go through search mode 
		end
		else
		begin
			// make the IM go through edut mode 
		end
	end
	*/
endmodule

/* stack overflow hexdec because i didnt have
   time to use my own. use only for debugging. */
module hex_decoder(hex_digit, segments);
    input [3:0] hex_digit;
    output reg [6:0] segments;

    always @(*)
        case (hex_digit)
            4'h0: segments = 7'b100_0000;
            4'h1: segments = 7'b111_1001;
            4'h2: segments = 7'b010_0100;
            4'h3: segments = 7'b011_0000;
            4'h4: segments = 7'b001_1001;
            4'h5: segments = 7'b001_0010;
            4'h6: segments = 7'b000_0010;
            4'h7: segments = 7'b111_1000;
            4'h8: segments = 7'b000_0000;
            4'h9: segments = 7'b001_1000;
            4'hA: segments = 7'b000_1000;
            4'hB: segments = 7'b000_0011;
            4'hC: segments = 7'b100_0110;
            4'hD: segments = 7'b010_0001;
            4'hE: segments = 7'b000_0110;
            4'hF: segments = 7'b000_1110;   
            default: segments = 7'h7f;
        endcase
endmodule