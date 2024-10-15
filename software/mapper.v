//`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: nikita600
// Create Date:    21:24:48 04/13/2024 
//////////////////////////////////////////////////////////////////////////////////
module mapper(
    input [23:1] cart_address,
    inout [15:0] cart_data,
	 
    input cas0, 		
	 // Read or Write on $000000-$DFFFFF region.
	 
	 input ce_0, 		
	 /*	Chip Enable for the cartridge.
			Normally low when accessing $000000-$3FFFFF region.
			When expension unit is present then low when accessing $400000-$7FFFFF.
	 */
	 //(*buffer_type = "none"*) 
	 input lwr,
	 // Lower byte WRite, the lower byte on the data lines should be written to the location in the address lines.
	 
	 input tme,
	 /* 
		 Set for r/w at/to $A13000-$A130FF, given the name suggests it might be for a real time clock in the cartridge.
		 This would enable usage as a chip enable on a RTC, using fewer address lines or logic to that RTC. Used in Sonic 3 for SRAM.
	 */
	 
	 //input vres, 		// System reset, from front panel switch.
	 
	 output [21:0] rom_address,
	 inout [15:0] rom_data,
	 output [1:0] rom_oe,
	 output [1:0] rom_ce,
	 
	 output sram_oe,
	 output sram_ce,
	 output sram_we,
	 
	 output debug_write
    );

reg sram_enabled;
reg sram_writable;

//reg [5:0] bank0 = 6'b010000;
reg [5:0] banks [7:1];

wire [1:0] rom_ctrl;

wire write_bank_data;

assign sram_we = 1'b1;//lwr;
assign sram_oe = 1'b1;
assign sram_ce = 1'b1;

initial 
begin

	//banks[0] = 6'b010000; // $000000 - $07FFFF
	banks[1] = 6'b000001; // $080000 - $0FFFFF
	banks[2] = 6'b000010; // $100000 - $17FFFF
	banks[3] = 6'b000011; // $180000 - $1FFFFF
	banks[4] = 6'b000100; // $200000 - $27FFFF
	banks[5] = 6'b000101; // $280000 - $2FFFFF
	banks[6] = 6'b000110; // $300000 - $37FFFF
	banks[7] = 6'b000111; // $380000 - $3FFFFF

end

/*
assign rom_oe[0] = ce_0;
assign rom_oe[1] = 1'b1;

assign rom_ce[0] = cas0;
assign rom_ce[1] = 1'b1;

assign cart_data = !ce_0 && !cas0 ? rom_data : 16'hz;
assign rom_address[21:0] = cart_address[22:1];
*/

assign rom_ctrl[1:0] = ~ce_0 ?
			~(cart_address[21:19] == 3'b000 ? 2'b01 : banks[cart_address[21:19]][5:4] == 2'b00 ? 2'b01 : 2'b10) : 2'b11;
assign rom_oe[1:0] = rom_ctrl[1:0];
assign rom_ce[1:0] = rom_ctrl[1:0];
	
assign rom_address[17:0] = cart_address[18:1];
assign rom_address[21:18] = cart_address[21:19] == 3'b000 ? 4'b0000 : banks[cart_address[21:19]][3:0];

assign cart_data = ~ce_0 & ~cas0 ? rom_data : 16'hz;
assign rom_data = ~ce_0 & ~cas0 ? 16'hz : cart_data;

assign write_bank_data = ~tme & ~lwr & cas0 & ce_0 
							& ~cart_address[8] &  cart_address[7]
							&  cart_address[6] &  cart_address[5] & cart_address[4];

reg write_occur = 1;

assign debug_write = rom_ctrl[1];/*~tme & ~lwr & cas0 & ce_0 
							& cart_address[23] & ~cart_address[22]
							& cart_address[21] & ~cart_address[20] 
							& ~cart_address[8] &  cart_address[7]
							&  cart_address[6] &  cart_address[5] & cart_address[4];*/

always @(negedge lwr)
begin
	
	if (~tme & cas0 & ce_0 & cart_address[8:4] == 5'b01111)
	begin
	
		if (cart_address[3:1] == 3'b000)
		begin
			sram_enabled <= cart_data[0];
			sram_writable <= cart_data[1];
		end
		else
		begin
			banks[cart_address[3:1]][5:0] <= cart_data[5:0];
		end
		
		write_occur <= ~write_occur;
		
	end
	
end

endmodule
