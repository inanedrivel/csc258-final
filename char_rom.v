// Instantiates the ROM modules for the fonts.
// We store each font as a 128-long arr (ascii) of 64 (8x8)
// or 256 (16x16) bit numbers in the MIF.
// 
// This will probably be a nightmare.
// 
// - Tim
 
module char_rom(input clock,
					 input [6:0] ascii,
					 output [255:0] lf,
					 output [63:0] sf);
	parameter CHAR_DATA_S = "char_data_s.mif"
	parameter CHAR_DATA_L = "char_data_l.mif"
	
	altsyncram	CharInfoS (
				.clock0 (clock),
				.address_a (ascii),
				.q_a (sf)	// data out
				);
	defparam
		CharInfoS.WIDTH_A = 64,
		CharInfoS.INTENDED_DEVICE_FAMILY = "Cyclone V",
		CharInfoS.OPERATION_MODE = "ROM",
		CharInfoS.WIDTHAD_A = 7,
		CharInfoS.NUMWORDS_A = 128,
		CharInfoS.POWER_UP_UNINITIALIZED = "FALSE",
		CharInfoS.INIT_FILE = CHAR_DATA_S;	
	
		altsyncram	CharInfoL (
				.clock0 (clock),
				.address_a (ascii),
				.q_a (lf)	// data out
				);
	defparam
		CharInfoL.WIDTH_A = 256,
		CharInfoL.INTENDED_DEVICE_FAMILY = "Cyclone V",
		CharInfoL.OPERATION_MODE = "ROM",
		CharInfoL.WIDTHAD_A = 7,
		CharInfoL.NUMWORDS_A = 128,
		CharInfoL.POWER_UP_UNINITIALIZED = "FALSE",
		CharInfoL.INIT_FILE = CHAR_DATA_L;	
	
endmodule
