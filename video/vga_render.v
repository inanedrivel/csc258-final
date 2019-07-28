// This module will retrieve the pixel data required for the
// controller, but it is a bit.. unconventional in how it does it.
// When requested for the pixel coordinates, this module will
// compute and find out the data required by retrieving the textures
// plus colour data from the memory. However, in our original model,
// timing issues occured since we only started accessing memory when
// the pixel needed to be drawn. We counter this by retrieving one line
// from memory at a time.
// 
// This has some issues when starting, but due to the clock speed we don't
// really get any issues (since the pixel data is drawn 104 times a second).

// - Tim 

module vga_render(input sL,
					   input clk,
					   input [5:0] ccolour,
					   input [6:0] cascii,
					   input chl,
					   output reg [6:0] cx,
						output reg [5:0] cy,
					   output [9:0] VGA_R,
					   output [9:0] VGA_G,
					   output [9:0] VGA_B,
				      output VGA_HS,
				      output VGA_VS,
				      output VGA_BLANK,
				      output VGA_SYNC,
				      output VGA_CLK);
parameter black = 6'b000000;
/* 8 x 6 bit colour */				
reg [47:0] linecols;
/* 16 x 6 bit colour */
reg [95:0] linecoll;
wire [47:0] cds;
wire [95:0] cdl;
reg [5:0] outcol;
wire [9:0] x;
wire [8:0] y;
wire [6:0] cxs, cxl, nxs, nxl;
wire [5:0] cys, cyl, nys, nyl;
wire [3:0] nrl;
wire [2:0] nrs;
wire [255:0] datal;
wire [63:0] datas;
getcharindexL gciL(x, y, cxl, cyl);
getcharindexS gciS(x, y, cxs, cys);
getnextCharandRowL nCaRL(x, y, nxl, nyl, nrl); 
getnextCharandRowS nCaRS(x, y, nxs, nys, nrs);
wire [7:0] smask;
wire [15:0] lmask;
access8bit a8b(datas, rcs, smask);
access16bit a16b(datal, rcl, lmask);
wire [5:0] sincol, lincol;
access6bitf48 a6b48(linecols, x[2:0], sincol);
access6bitf96 a6b96(linecoll, x[3:0], lincol);
m96 m96l(ccolour, black, chl, smask, cdl);
m48 m48s(ccolour, black, chl, lmask, cds);
char_rom cr(clock, cascii, datal, datas);
always @(*)
begin
	if(sL) begin
		cx <= nxl;
		cy <= nyl;
	end
	else
	begin
		cx <= nxs;
		cy <= nys;
	end
end

vga_clk vc(.refclk(clk),
		  .rst(resetn),
		  .outclk_0(vclk));

always @(posedge clk)
begin
	/* read from buffer */
	if (sL) begin
		outcol <= lincol;
		/* OK, here's the hacky part to load the next pixel data */
		if(x[3:0] == 4'b1111) begin
			linecoll <= cdl;
		end
	end
	else
	begin
		outcol <= sincol;
		if(x[2:0] == 4'b111) begin
			linecols <= cds;
		end
	end
end
vga_controller vcontrol(.vga_clock(vclk), 
					.resetn(resetn), 
					.pixel_colour(outcol), 
					.x(x),
					.y(y),
					.VGA_R(VGA_R),
					.VGA_G(VGA_G),
					.VGA_B(VGA_B),
					.VGA_HS(VGA_HS),
					.VGA_VS(VGA_VS),
					.VGA_BLANK(VGA_BLANK),
					.VGA_SYNC(VGA_SYNC),
					.VGA_CLK(VGA_CLK)); 

endmodule

module getcharindexS(input [9:0] px,
						   input [8:0] py,
						   output [6:0] cx,
							output [5:0] cy);
	assign cx = px[9:3];
	assign cy = 59 - py[8:3];
endmodule 

module getcharindexL(input [9:0] px,
						   input [8:0] py,
						   output [6:0] cx,
							output [5:0] cy);
	assign cx = px[9:4];
	assign cy = 29 - py[8:4];
endmodule 

module getnextCharandRowS(input [9:0] px,
								  input [8:0] py,
								  output reg [6:0] cx,
								  output reg [5:0] cy,
								  output reg [2:0] row);
	always @(*)
	begin
		if(px[2:0] == 3'b111) begin
			if (px[9:3] == 7'd79) begin
				/* end of row */
				if (py[2:0] == 3'b111) begin
					if (py[8:3] == 6'd59) begin
						/* last row */
						cy <= 6'd59;
					end
					else begin
						cy <= 58 - py[8:3];
					end
					cx <= 7'd0;
					row <= 4'b0;
				end
				else
				begin
					cy <= 59 - py[8:3];
					cx <= 7'd0;
					row <= 3'b110 - py[2:0];
				end
			end
			else
			begin 
				cx <= px[9:3] + 1;
				cy <= 59 - py[8:3];
				row <= 3'b111 - py[2:0];
			end
		end
	end
endmodule

				 
module getnextCharandRowL(input [9:0] px,
								  input [8:0] py,
								  output reg [6:0] cx,
								  output reg [5:0] cy,
								  output reg [3:0] row);
	always @(*)
	begin
		if(px[3:0] == 4'b1111) begin
			if (px[9:4] == 6'd39) begin
				/* end of row */
				if (py[3:0] == 4'b1111) begin
					if (py[8:4] == 5'd29) begin
						/* last row */
						cy <= 6'd29;
					end
					else begin
						cy <= 28 - py[8:4];
					end
					cx <= 7'd0;
					row <= 3'b0;
				end
				else
				begin
					cy <= 29 - py[8:4];
					cx <= 7'd0;
					row <= 4'b1110 - py[3:0];
				end
			end
			else
			begin 
				cx <= px[9:4] + 1;
				cy <= 29 - py[8:4];
				row <= 4'b1111 - py[3:0];
			end
		end
	end
endmodule


module mux6(input [5:0] a,
				input [5:0] b,
				input inv,
				input c,
				output reg [5:0] o);
	always @(*)
	begin
	if (c == ~inv) o <= b;
	else o <= a;
	end
endmodule

module m48(input [5:0] a,
				 input [5:0] b,
				 input inv,
				 input [7:0] mask,
				 output [47:0] o);
	wire [5:0] x0, x1, x2, x3, x4, x5, x6, x7;
	mux6 m0(a, b, inv, mask[0], x0);
	mux6 m1(a, b, inv, mask[1], x1);
	mux6 m2(a, b, inv, mask[2], x2);
	mux6 m3(a, b, inv, mask[3], x3);
	mux6 m4(a, b, inv, mask[4], x4);
	mux6 m5(a, b, inv, mask[5], x5);
	mux6 m6(a, b, inv, mask[6], x6);
	mux6 m7(a, b, inv, mask[7], x7);
	assign o = {x7, x6, x5, x4, x3, x2, x2, x0};
endmodule

module m96(input [5:0] a,
				 input [5:0] b,
				 input inv,
				 input [15:0] mask,
				 output [47:0] o);
	wire [47:0] x0, x1;
	m48 m0(a, b, inv, mask[7:0], x0);
	m48 m1(a, b, inv, mask[15:8], x1);
	assign o = {x1, x0};
endmodule


module access8bit(input [63:0] data, input [2:0] inputin, output [7:0] target);
	assign target = {	data[8*inputin+7], 
							data[8*inputin+6],
							data[8*inputin+5],
							data[8*inputin+4],
							data[8*inputin+3],
							data[8*inputin+2],
							data[8*inputin+1],
							data[8*inputin]};
endmodule

module access6bitf48(input [47:0] data, input [2:0] inputin, output [5:0] target);
	assign target = {	data[6*inputin+5],
							data[6*inputin+4],
							data[6*inputin+3],
							data[6*inputin+2],
							data[6*inputin+1],
							data[6*inputin]};
endmodule
module access6bitf96(input [95:0] data, input [3:0] inputin, output [5:0] target);
	assign target = {	data[6*inputin+5],
							data[6*inputin+4],
							data[6*inputin+3],
							data[6*inputin+2],
							data[6*inputin+1],
							data[6*inputin]};
endmodule

module access16bit(input [255:0] data, input [3:0] inputin, output [7:0] target);
	assign target = {	data[16*inputin+15], 
							data[16*inputin+14],
							data[16*inputin+13],
							data[16*inputin+12],
							data[16*inputin+11],
							data[16*inputin+10],
							data[16*inputin+9],
							data[16*inputin+8],
							data[16*inputin+7], 
							data[16*inputin+6],
							data[16*inputin+5],
							data[16*inputin+4],
							data[16*inputin+3],
							data[16*inputin+2],
							data[16*inputin+1],
							data[16*inputin]};
endmodule

