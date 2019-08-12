module main(input CLOCK_50,
				input [2:0] KEY,
				input [7:0] SW,
				output [9:0] LEDR,
				output [6:0] HEX0, 
				output [6:0] HEX1, 
				output [6:0] HEX2, 
				output [6:0] HEX3, 
				output [6:0] HEX4,
				output [6:0] HEX5,
				/* KB IN */
				input PS2_CLK,
				input PS2_DAT,
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

	reg [6:0] editasciiin, searchasciiin;
	wire [6:0] editasciio, searchasciio;
	wire [5:0] editcolouro, searchcolouro;
	wire edithlo, searchhlo;
	wire edwrdy, edhrdy, sewrdy, sehrdy;
	wire [6:0] editxo, searchxo, edithxo, searchhxo;
	wire [5:0] edityo, searchyo, edithyo, searchhyo;
	reg [6:0] ui_asciiin;
	reg [5:0] ui_clrin;
	reg ui_hlin;
	reg [6:0] ui_xin;
	reg [5:0] ui_yin;
	reg [6:0] uih_xin;
	reg [5:0] uih_yin;
	reg ui_wready;
	reg ui_hready;
	
	wire [27:0] SIZEDBG;
	
	assign searchMode = SW[1];
	assign largeMode = SW[0];
	assign resetn = KEY[0];
	memory_controller memctrl(.sL(largeMode),
								     .wrx(ui_xin),
			      				  .wry(ui_yin),
								     .wren(ui_wready),
								     .wascii(ui_asciiin),
								     .wcolour(ui_clrin),
								     .wclock(CLOCK_50),
								     .hix(uih_xin),
								     .hiy(uih_yin),
								     .hien(ui_hready),
								     .highlight(ui_hlin),
								     .hclock(CLOCK_50),
								     .rex(vgx),
								     .rey(vgy),
								     .rascii(vgascii),
								     .rcolour(vgclr),
								     .rhighlight(vghl),
								     .rclock(CLOCK_50));
	wire [6:0] vgascii;
	wire [6:0] vgx;
	wire [5:0] vgy;
	wire [5:0] vgclr;
	wire vghl;

	
	wire [15:0] VDBG;
	hex_decoder h5(SIZEDBG[23:20], HEX5);
	hex_decoder h4(SIZEDBG[19:16], HEX4);
	hex_decoder h3(SIZEDBG[15:12], HEX3);
	hex_decoder h2(SIZEDBG[11:8], HEX2);
	hex_decoder h1(SIZEDBG[7:4], HEX1);
	hex_decoder h0(SIZEDBG[3:0], HEX0);
	
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

	wire [6:0] asciiready;	
	wire asciigo;
	
	ps2_keyboard_to_ascii vdhl_kb(.clk(CLOCK_50),
											.ps2_clk(PS2_CLK),
											.ps2_data(PS2_DAT),
											.ascii_new(asciigo),
											.ascii_code(asciiready));
	
	assign LEDR[5:0] = vgclr;
	assign LEDR[7] = asciigo;
	assign LEDR[9:8] = {ps2datyes, ps2clkyes};
	
	reg ps2clkyes,ps2datyes;
	always @(negedge resetn or posedge CLOCK_50) begin
		if(~resetn) begin
			ps2datyes<= 1'b0;
			ps2clkyes <= 1'b0;
		end else begin 
			if((PS2_CLK == 1'b1) & ~(^PS2_CLK === 1'bx)) ps2clkyes <= 1'b1;
			if((PS2_DAT == 1'b1) & ~(^PS2_DAT === 1'bx)) ps2datyes <= 1'b1;
		end
	end
	
	always @(*)
	begin
		if (searchMode) begin
				// make the IM go through search mode
				editasciiin = 7'b0;
				searchasciiin = asciiready;
				ui_asciiin = searchasciio;
				ui_clrin = searchcolouro;
				ui_hlin = searchhlo;
				ui_xin = searchxo;
				ui_yin = searchyo;
				uih_xin = searchhxo;
				uih_yin = searchhyo;
				ui_wready = sewrdy;
				ui_hready = sehrdy;
		end
		else
		begin
			// make the IM go through edut mode 
				editasciiin = asciiready;
				searchasciiin = 7'b0;
				ui_asciiin = editasciio;
				ui_clrin = editcolouro;
				ui_hlin = edithlo;
				ui_xin = editxo;
				ui_yin = edityo;
				uih_xin = edithxo;
				uih_yin = edithyo;
				ui_wready = edwrdy;
				ui_hready = edhrdy;
		end
	end
	
	edit_mode em(.sL(largeMode),
					 .resetn(resetn),
					 .clk(CLOCK_50),
					 .asciiin(editasciiin),
					 .clrin(SW[7:2]),
					 .asciiready(asciigo & ~searchMode),
					 .cx(editxo),
					 .cy(edityo),
					 .ccol(editcolouro),
					 .asciiout(editasciio),
					 .cwren(edwrdy),
					 .hx(edithxo),
					 .hy(edithyo),
					 .ho(edithlo),
					 .hen(edhrdy));
					 
	 search_mode sm(.sL(largeMode),
						 .resetn(resetn),
						 .clk(CLOCK_50),
						 .editen(~searchMode),
						 .editxin(editxo),
						 .edityin(edityo),
						 .editasciiin(editasciio),
						 .asciiin(searchasciiin),
						 .clrin(SW[7:2]),
						 .asciiready(asciigo & searchMode),
						 .cx(searchxo),
						 .cy(searchyo),
						 .ccol(searchcolouro),
						 .asciiout(searchasciio),
						 .cwren(sewrdy),
						 .hx(searchhxo),
						 .hy(searchhyo),
						 .ho(searchhlo),
						 .hen(sehrdy),
						 .DEBUG(SIZEDBG));
	
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
