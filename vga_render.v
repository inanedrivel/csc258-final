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
						input vclk,
						input resetn,
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
				      output VGA_CLK,
						output [15:0] DEBUG);
parameter black = 6'b000000;
parameter BORDER = 6'b101111;
/* 8 x 6 bit colour */				
reg [47:0] linecols;
/* 16 x 6 bit colour */
reg [95:0] linecoll;
wire [47:0] cds;
wire [95:0] cdl;
reg [5:0] lastpixs, lastpixl;
wire [5:0] lastpxst, lastpxlt;
access6bitf48 a6b48l(linecols, 3'b111, lastpxst);
access6bitf96 a6b96l(linecoll, 4'b1111, lastpxlt);
reg [5:0] toutcol, outcol;
wire [9:0] x;
wire [8:0] y;
wire [6:0] cxs, cxl, nxs, nxl;
wire [5:0] cys, cyl, nys, nyl;
wire [3:0] nrl;
wire [2:0] nrs;
wire [255:0] datal;
wire [63:0] datas;
// fvga_pll mypll(clk, clock_25);
getcharindexL gciL(x, y, cxl, cyl);
getcharindexS gciS(x, y, cxs, cys);
getnextCharandRowL nCaRL(x, y, nxl, nyl, nrl); 
getnextCharandRowS nCaRS(x, y, nxs, nys, nrs);
wire [7:0] smask;
wire [15:0] lmask;
access8bit a8b(datas, nrs, smask);
access16bit a16b(datal, nrl, lmask);
wire [5:0] sincol, lincol;
access6bitf48 a6b48(linecols, x[2:0], sincol);
access6bitf96 a6b96(linecoll, x[3:0], lincol);
m96 m96l(ccolour, black, chl, lmask, cdl);
m48 m48s(ccolour, black, chl, smask, cds);
char_rom cr(clk, cascii, datal, datas);
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
	
	if ((x == 0) | (x == 639) | (y == 0) | (y == 479)) toutcol = BORDER;
	else toutcol = outcol;
	
end

always @(posedge clk)
begin
	/* read from buffer */
	if (sL) begin
		/* OK, here's the hacky part to load the next pixel data */
		if(x[3:0] == 4'b1111) begin
			outcol <= lastpixl;
			linecoll <= cdl;
		end
		else if (x[3:0] == 4'b1110) begin
			outcol <= lincol;
			lastpixl <= lastpxlt;
		end
		else begin
			outcol <= lincol;
		end
	end
	else
	begin
		if(x[2:0] == 3'b111) begin
			outcol <= lastpixs;
			linecols <= cds;
		end
		else if (x[2:0] == 3'b110) begin
			outcol <= sincol;
			lastpixs <= lastpxst;
		end
		else begin
			outcol <= sincol;
		end
	end
end
assign DEBUG = {10'b0, lincol};
vga_controller vcontrol(
					.vga_clock(vclk), 
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
	assign cy = py[8:3];
endmodule 

module getcharindexL(input [9:0] px,
						   input [8:0] py,
						   output [6:0] cx,
							output [5:0] cy);
	assign cx = px[9:4];
	assign cy = py[8:4];
endmodule 

module getnextCharandRowS(input [9:0] px,
								  input [8:0] py,
								  output reg [6:0] cx,
								  output reg [5:0] cy,
								  output reg [2:0] row);
	always @(*)
	begin
			if (px[9:3] >= 7'd79) begin
				/* end of row */
				if (py[2:0] == 3'b111) begin
					if (py[8:3] >= 6'd59) begin
						/* last row */
						cy <= 6'd0;
					end
					else begin
						cy <= py[8:3] + 1;
					end
					cx <= 7'd0;
					row <= 3'b0;
				end
				else
				begin
					cy <= py[8:3];
					cx <= 7'd0;
					row <= 3'b110 - py[2:0];
				end
			end
			else
			begin 
				cx <= px[9:3] + 1;
				cy <= py[8:3];
				row <= 3'b111 - py[2:0];
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
			if (px[9:4] >= 6'd39) begin
				/* end of row */
				if (py[3:0] == 4'b1111) begin
					if (py[8:4] >= 5'd29) begin
						/* last row */
						cy <= 6'd0;
					end
					else begin
						cy <= py[8:4];
					end
					cx <= 7'd0;
					row <= 3'b0;
				end
				else
				begin
					cy <= py[8:4];
					cx <= 7'd0;
					row <= py[3:0] + 1'b1;
				end
			end
			else
			begin 
				cx <= px[9:4] + 1'b1;
				cy <= py[8:4];
				row <= 4'b1111;
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
	if (c == inv) o <= b;
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
	assign o = x0 + (x1 << 6)
					  + (x2 << 12)
					  + (x3 << 18)
					  + (x4 << 24)
					  + (x5 << 30)
					  + (x6 << 36)
					  + (x7 << 42);
endmodule

module m96(input [5:0] a,
				 input [5:0] b,
				 input inv,
				 input [15:0] mask,
				 output [95:0] o);
	wire [5:0] x0, x1, x2, x3, x4, x5, x6, x7;
	wire [5:0] x8, x9, xa, xb, xc, xd, xe, xf;
	mux6 m0(a, b, inv, mask[0], x0);
	mux6 m1(a, b, inv, mask[1], x1);
	mux6 m2(a, b, inv, mask[2], x2);
	mux6 m3(a, b, inv, mask[3], x3);
	mux6 m4(a, b, inv, mask[4], x4);
	mux6 m5(a, b, inv, mask[5], x5);
	mux6 m6(a, b, inv, mask[6], x6);
	mux6 m7(a, b, inv, mask[7], x7);
	mux6 m8(a, b, inv, mask[8], x8);
	mux6 m9(a, b, inv, mask[9], x9);
	mux6 ma(a, b, inv, mask[10], xa);
	mux6 mb(a, b, inv, mask[11], xb);
	mux6 mc(a, b, inv, mask[12], xc);
	mux6 md(a, b, inv, mask[13], xd);
	mux6 me(a, b, inv, mask[14], xe);
	mux6 mf(a, b, inv, mask[15], xf);
	assign o = x0 + (x1 << 6)
					  + (x2 << 12)
					  + (x3 << 18)
					  + (x4 << 24)
					  + (x5 << 30)
					  + (x6 << 36)
					  + (x7 << 42)
					  + (x8 << 48)
					  + (x9 << 54)
					  + (xa << 60)
					  + (xb << 66)
					  + (xc << 72)
					  + (xd << 78)
					  + (xe << 84)
					  + (xf << 90);				 
endmodule


module access8bit(input [63:0] data, input [2:0] inputin, output reg [7:0] target);
	always @(*)
	begin
		case (inputin)
			3'h0: target = data[7:0];
			3'h1: target = data[15:8];
			3'h2: target = data[23:16];
			3'h3: target = data[31:24];
			3'h4: target = data[39:32];
			3'h5: target = data[47:40];
			3'h6: target = data[55:48];			
			3'h7: target = data[63:56];
		endcase
	end
endmodule

module access6bitf48(input [47:0] data, input [2:0] inputin, output reg [5:0] target);
	always @(*)
	begin		/* reversed due to font, for proper font rendering start from 0 */ 
		case (inputin)
			3'd7: target = data[5:0];
			3'd6: target = data[11:6];
			3'd5: target = data[17:12];
			3'd4: target = data[23:18];
			3'd3: target = data[29:24];
			3'd2: target = data[35:30];
			3'd1: target = data[41:36];			
			3'd0: target = data[47:42];
		endcase
	end
endmodule

module access6bitf96(input [95:0] data, input [3:0] inputin, output reg [5:0] target);
	always @(*)
	begin
		case (inputin)
			4'h0: target = data[5:0];
			4'h1: target = data[11:6];
			4'h2: target = data[17:12];
			4'h3: target = data[23:18];
			4'h4: target = data[29:24];
			4'h5: target = data[35:30];
			4'h6: target = data[41:36];			
			4'h7: target = data[47:42];
			4'h8: target = data[53:48];
			4'h9: target = data[59:54];
			4'ha: target = data[65:60];
			4'hb: target = data[71:66];
			4'hc: target = data[77:72];
			4'hd: target = data[83:78];
			4'he: target = data[89:84];			
			4'hf: target = data[95:90];
		endcase 
	end
endmodule

module access16bit(input [255:0] data, input [3:0] inputin, output reg [15:0] target);
	always @(*)
	begin
		case (inputin)
			4'h0: target = data[15:0];
			4'h1: target = data[31:16];
			4'h2: target = data[47:32];
			4'h3: target = data[63:48];
			4'h4: target = data[79:64];
			4'h5: target = data[95:80];
			4'h6: target = data[111:96];			
			4'h7: target = data[127:112];
			4'h8: target = data[143:128];
			4'h9: target = data[159:144];
			4'ha: target = data[175:160];
			4'hb: target = data[191:176];
			4'hc: target = data[207:192];
			4'hd: target = data[223:208];
			4'he: target = data[239:224];			
			4'hf: target = data[255:240];
		endcase
	end
endmodule

module l25c(input clk, input resetn, output reg oclk);
	always @(posedge clk, negedge resetn)
	begin
		if(~resetn)
		begin
			oclk<= 1'b0;
		end
		else
			oclk <= ~oclk;
	end
endmodule