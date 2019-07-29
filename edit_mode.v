module edit_mode(input sL,
					  input resetn,
					  input clk,
					  input [6:0] asciiin,
					  input [5:0] clrin,
					  input asciiready,
					  output reg [6:0] cx,
					  output reg [5:0] cy,
					  output [5:0] ccol,
					  output reg [6:0] asciiout,
					  output reg cwren,
					  output reg [6:0] hx,
					  output reg [5:0] hy,
					  output ho,
					  output hen);
assign ccol = clrin;					  

reg [6:0] cxs, cxl, futxs, futxl;
reg [5:0] cys, cyl, futys, futyl;
reg state;

wire [6:0] nxs, bxs, nlxs, nxl, bxl, nlxl;
wire [5:0] nys, bys, nlys, nyl, byl, nlyl;

backspaceS bss(cxs, cys, bxs, bys);
backspaceL bsl(cxl, cyl, bxl, byl);
nextS nes(cxs, cys, nxs, nys);
nextL nel(cxl, cyl, nxl, nyl);
enterS ens(cxs, cys, nlxs, nlys);
enterL enl(cxl, cyl, nlxl, nlyl);

always @(*)
begin
	if (sL) begin
		cx <= cxl;
		cy <= cyl;
	end else begin
		cx <= cxs;
		cy <= cys;
	end
end

reg counter;
reg accept;
always @(negedge resetn or 
			posedge clk)
begin
if (~resetn) begin
	counter <= 1'b0;
	accept <= 1'b1;
end else if (asciiready) begin
	accept <= 1'b1;
	counter <= 1'b1;
end else if (counter) begin
	counter <= 1'b0;
end
else accept <= 1'b0;
end
// write logic
always @(negedge resetn or posedge clk) begin
	if (~resetn) begin
		cxs <= 7'b0;
		cxl <= 7'b0;
		cys <= 6'b0;
		cyl <= 6'b0;
		futxs <= 7'b0;
		futxl <= 7'b0;
		futys <= 6'b0;
		futyl <= 6'b0;
		state <= 2'b00;
	end
	else if (~state) begin
		// do nothing for new chars
		if (accept) begin
			state <= 1'b1;
			if (sL) begin
				case (asciiin)
				7'd10: begin
					// newline
					cwren <= 1'b0;
					futxl <= nlxl;
					futyl <= nlyl;
				end
				7'd8: begin
					// backspace
					cwren <= 1'b1;
					asciiout <= 7'd32;
					futxl <= bxl;
					futyl <= byl;
				end
				default: begin
					cwren <= 1'b1;
					asciiout <= asciiin;
					futxl <= nxl;
					futyl <= nyl;
				end
				endcase
			end else begin
				case (asciiin)
				7'd10: begin
					// newline
					cwren <= 1'b0;
					futxs <= nlxs;
					futys <= nlys;
				end
				7'd8: begin
					// backspace
					cwren <= 1'b1;
					asciiout <= 7'd32;
					futxs <= bxs;
					futys <= bys;
				end
				default: begin
					cwren <= 1'b1;
					asciiout <= asciiin;
					futxs <= nxs;
					futys <= nys;
				end
				endcase
			end
		end
	end else begin
		cwren <= 1'b0;
		if (sL) begin
			cyl <= futyl;
			cxl <= futxl;
		end else begin
			cxs <= futxs;
			cys <= futys;
		end
	end
end

// highlight logic
reg [23:0] hlc;
assign hen = 1'b1;
reg hlyes;
always @(posedge clk) begin
	
	if (~resetn) begin
		hlc <= 23'b01010000000000000000000;
		hlyes <= 1'b1;
	end
	else if (hlc != 23'b0) begin
		hlc <= hlc - 23'b000000000000000000001;
	end
	else begin
		hlc <= 23'b01010000000000000000000;
		hlyes <= ~hlyes;
	end
end

always @(posedge clk or negedge resetn) begin
	if (~resetn) begin
		hx <= 7'b0;
		hy <= 6'b0;
	end else begin
		if (((hx > 7'd40) & sL) | ((hx > 7'd80))) begin
			if (((hy > 6'd29) & sL) | ((hy > 6'd59))) begin
				hx <= 7'b0;
				hy <= 6'b0;
			end else begin
				hx <= 7'b0;
				hy <= hy + 1'b1;
			end
		end else begin
			hx <= hx + 1'b1;
			hy <= hy;
		end
	end
end

assign ho = ((hx == cx) && (hy == cy) && hlyes);

endmodule

module backspaceS(input [6:0] x,
					 input [5:0] y,
					 output reg [6:0] nx,
					 output reg [5:0] ny);
	always @(*) begin
		if (x == 7'b0) begin
			if (y == 6'b0) begin
				nx = 7'd79;
				ny = 6'd58; 
			end else begin
				nx = 7'd79;
				ny = y - 1'b1;
			end
		end else begin
			nx = x - 1'b1;
			ny = y;
		end
	end
endmodule 

module backspaceL(input [6:0] x,
					 input [5:0] y,
					 output reg [6:0] nx,
					 output reg [5:0] ny);
	always @(*) begin
		if (x == 7'b0) begin
			if (y == 6'b0) begin
				nx = 7'd39;
				ny = 6'd28; 
			end else begin
				nx = 7'd39;
				ny = y - 1'b1;
			end
		end else begin
			nx = x - 1'b1;
			ny = y;
		end
	end
endmodule 

module nextS(input [6:0] x,
					 input [5:0] y,
					 output reg [6:0] nx,
					 output reg [5:0] ny);
	always @(*) begin
		if (x == 7'd79) begin
			if (y == 6'd58) begin
				nx = 7'd0;
				ny = 6'd0; 
			end else begin
				nx = 7'd0;
				ny = y + 1'b1;
			end
		end else begin
			nx = x + 1'b1;
			ny = y;
		end
	end
endmodule

module nextL(input [6:0] x,
					 input [5:0] y,
					 output reg [6:0] nx,
					 output reg [5:0] ny);
	always @(*) begin
		if (x == 7'd39) begin
			if (y == 6'd28) begin
				nx = 7'd0;
				ny = 6'd0; 
			end else begin
				nx = 7'd0;
				ny = y + 1'b1;
			end
		end else begin
			nx = x + 1'b1;
			ny = y;
		end
	end
endmodule

module enterS(input [6:0] x,
					 input [5:0] y,
					 output reg [6:0] nx,
					 output reg [5:0] ny);
	always @(*) begin
		if (y == 6'd58) begin
			nx = 7'd0;
			ny = 6'd0;
		end else begin
			nx = 7'd0;
			ny = y + 1'd1;
		end
	end
endmodule

module enterL(input [6:0] x,
					 input [5:0] y,
					 output reg [6:0] nx,
					 output reg [5:0] ny);
	always @(*) begin
		if (y == 6'd28) begin
			nx = 7'd0;
			ny = 6'd0;
		end else begin
			nx = 7'd0;
			ny = y + 1'd1;
		end
	end
endmodule

