module edit_mode(input sL,
					  input clk,
					  input [6:0] asciiin,
					  input asciiready,
					  output reg [6:0] cx,
					  output reg [5:0] cy,
					  output reg [5:0] ccol,
					  output reg [6:0] asciiout,
					  output reg cwren,
					  output reg [6:0] hx,
					  output reg [5:0] hy,
					  output reg ho,
					  output hen);
					  
// write logic
always @(negedge resetn or posedge asciiready) begin
	
end
// highlight logic
reg [23:0] hlc;
assign hen = 1'b1;
reg hlyes;
always @(posedge clk) begin
	
	if (~resetn) begin
		hl <= 23'b01100000000000000000000;
		hlyes <= 1'b0;
	end
	else if (hlc != 23'b0) begin
		hl <= hl - 1'b1;
	end
	else begin
		hl <= 23'b01100000000000000000000;
		hlyes <= ~hlyes;
	end
end

always @(posedge clk or negedge resetn)
begin
	if((hx == cx) && (hy == cy)) begin
		
	end
end

endmodule
