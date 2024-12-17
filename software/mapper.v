//////////////////////////////////////////////////////////////////////////////////
// Engineer: nikita600
// Create Date:    21:24:48 04/13/2024 
//////////////////////////////////////////////////////////////////////////////////
module mapper(
    input [23:1] cart_address,
    inout [15:0] cart_data,
	 
    input cas0, 		
	 // Read(0) or Write(1) on $000000-$DFFFFF region.
	 
	 input ce_0, 		
	 // Chip Enable for the cartridge.
	 // Normally low when accessing $000000-$3FFFFF region.
	 // When expension unit is present then low when accessing $400000-$7FFFFF.
	 
	 input lwr,
	 // Lower byte WRite, the lower byte on the data lines should be written to 
	 // the location in the address lines.
	 
	 input tme,
	 // Set for r/w at/to $A13000-$A130FF, given the name suggests it might be 
	 // for a real time clock in the cartridge.
	 // This would enable usage as a chip enable on a RTC, using fewer address 
	 // lines or logic to that RTC. Used in Sonic 3 for SRAM.
	
	 
	 input vres, 		
	 // System reset, from front panel switch.
	 
	 output [21:0] rom_address,
	 inout [15:0] rom_data,
	 output [1:0] rom_oe,
	 output [1:0] rom_ce,
	 
	 output sram_oe,
	 output sram_ce,
	 output sram_we
);

reg sram_enabled;
reg sram_writable;
reg [5:0] banks[7:1];

wire is_read;
wire cart_enabled;

wire sram_active;
wire [1:0] rom_ctrl;
wire [2:0] bank_idx;
wire [5:0] current_bank;

initial 
begin

	sram_enabled = 1'b0;
	sram_writable = 1'b0;

	//banks[0] = 6'b010000; // $000000 - $07FFFF
	banks[1] = 6'b000001; // $080000 - $0FFFFF
	banks[2] = 6'b000010; // $100000 - $17FFFF
	banks[3] = 6'b000011; // $180000 - $1FFFFF
	banks[4] = 6'b000100; // $200000 - $27FFFF
	banks[5] = 6'b000101; // $280000 - $2FFFFF
	banks[6] = 6'b000110; // $300000 - $37FFFF
	banks[7] = 6'b000111; // $380000 - $3FFFFF

end

assign is_read = ~cas0;
assign cart_enabled = ~ce_0;

assign sram_active = sram_enabled & cart_address[21];
assign sram_rw = sram_active & cart_enabled ? 1'b0 : 1'b1;

assign sram_we = lwr;
assign sram_ce = sram_rw;
assign sram_oe = cas0;

assign bank_idx = cart_address[21:19];
assign current_bank = banks[bank_idx];
assign is_zero_bank = bank_idx == 3'b000;

assign rom_ctrl[1:0] = cart_enabled ?
	is_zero_bank ? 2'b10
		: sram_active ? 2'b11 
			: current_bank[5:4] == 2'b00 ? 2'b10 : 2'b01
	: 2'b11;
	
assign rom_oe[1:0] = rom_ctrl[1:0];
assign rom_ce[1:0] = rom_ctrl[1:0];
	
assign rom_address[17:0] = cart_address[18:1];
assign rom_address[21:18] = is_zero_bank ? 4'b0000 : current_bank[3:0];

assign cart_data = cart_enabled & is_read ? rom_data : 16'hz;
assign rom_data = cart_enabled & is_read ? 16'hz : cart_data;

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
		
	end
	
end

endmodule
