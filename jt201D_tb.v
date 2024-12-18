`timescale 1ns / 1ns
//1000M clk
////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   16:48:08 11/21/2024
// Design Name:   jt201D_test_top
// Module Name:   C:/UserCodes/FPGA/ISE/SPI_jt201D_test/source/jt201D_tb.v
// Project Name:  SPI_jt201D_test
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: jt201D_test_top
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module jt201D_tb;

	// Inputs
	reg i_clk_sys;
	reg i_rst;
	reg i_uart_rx;
	reg i_MISO;

	// Outputs
	wire o_uart_tx;
	wire o_ld_parity;
	wire o_SCLK;
	wire o_MOSI;
	wire o_SEN;


	parameter UART_CNT = 573;
	integer uart_int= 0;
	parameter testStr = "test";
	parameter testStr2 = "{a:3CD:1aAfF}";
	parameter testStr3 = "{A:3CD:ABCDE}";
	integer str_index = 0;

	// Instantiate the Unit Under Test (UUT)
	jt201D_test_top uut (
		.i_clk_sys(i_clk_sys), 
		.i_rst_n(i_rst), 
		.i_uart_rx(i_uart_rx), 
		.o_uart_tx(o_uart_tx), 
		.o_ld_parity(o_ld_parity), 
		.o_ld_debug(),
		.o_SCLK(o_SCLK), 
		.o_MOSI(o_MOSI), 
		.i_MISO(i_MISO), 
		.o_SEN(o_SEN)
	);

	initial begin
		// Initialize Inputs
		i_clk_sys = 0;
		i_rst = 1;
		i_uart_rx = 1;
		i_MISO = 1;
		#50;
		i_rst = 0;
		// Wait 100 ns for global reset to finish
		#100;
		//send "t"
		i_uart_rx = 0;
		#1146;
		for(uart_int=1;uart_int<=8;uart_int=uart_int+1) begin
		i_uart_rx = testStr[uart_int-1];
		#1146;
		end
		i_uart_rx = 1;
		#1146;

		//send "{"
		i_uart_rx = 0;
		#1146;
		for(uart_int=1;uart_int<=8;uart_int=uart_int+1) begin
		i_uart_rx = testStr2[uart_int-1+96];
		#1146;
		end
		i_uart_rx = 1;
		#1146;

		//send "A"
		i_uart_rx = 0;
		#1146;
		for(uart_int=1;uart_int<=8;uart_int=uart_int+1) begin
		i_uart_rx = testStr2[uart_int-1+88];
		#1146;
		end
		i_uart_rx = 1;
		#1146;

		//send ":"
		i_uart_rx = 0;
		#1146;
		for(uart_int=1;uart_int<=8;uart_int=uart_int+1) begin
		i_uart_rx = testStr2[uart_int-1+80];
		#1146;
		end
		i_uart_rx = 1;
		#1146

		//send "3"
		i_uart_rx = 0;
		#1146;
		for(uart_int=1;uart_int<=8;uart_int=uart_int+1) begin
		i_uart_rx = testStr2[uart_int-1+72];
		#1146;
		end
		i_uart_rx = 1;
		#1146;

		//send "C"
		i_uart_rx = 0;
		#1146;
		for(uart_int=1;uart_int<=8;uart_int=uart_int+1) begin
		i_uart_rx = testStr2[uart_int-1+64];
		#1146;
		end
		i_uart_rx = 1;
		#1146;

		//send addr


		//write data
		for(str_index=0;str_index<7;str_index=str_index+1)begin
			i_uart_rx = 0;
			#1146;
			for(uart_int=1;uart_int<=8;uart_int=uart_int+1) begin
				i_uart_rx = testStr2[uart_int-1+(7-str_index)*8];
				#1146;
			end
			i_uart_rx = 1;	
			#1146;
		end

		#80000;
		//read data
		for(str_index=0;str_index<12;str_index=str_index+1)begin
			i_uart_rx = 0;
			#1146;
			for(uart_int=1;uart_int<=8;uart_int=uart_int+1) begin
				i_uart_rx = testStr3[uart_int-1+(12-str_index)*8];
				#1146;
			end
			i_uart_rx = 1;	
			#1146;
		end
		#50000

		$stop;
		

		// Add stimulus here
	end
    always #1 i_clk_sys = ~i_clk_sys;

endmodule

