// Imagine working with the actual keyboard data.
// This module converts w/e comes out of keyboard.v
// into ascii codes when high.
 
module asciiin(input PS2_CLK,
					input PS2_DAT,
					input clock,
					input resetn,
					input read,
					output reg ascii_ready,
					output reg [6:0] ascii);

wire scrdy;
wire [7:0] scode;
reg shift;

keyboard kb(.keyboard_clk(PS2_CLK),
				.keyboard_data(PS2_DAT),
				.clock50(clock),
				.reset(resetn),
				.read(read),
				.scan_ready(scrdy),
				.scan_code(scode));

always @(posedge scrdy)
begin
	if(scode == 8'h)
end
		
endmodule
