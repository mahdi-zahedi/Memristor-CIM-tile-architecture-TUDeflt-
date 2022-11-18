-----------------------------------------------------------------------
-- Project: CiM-Tile HW Design/implementation                        --
-- File	  : tile-top_tb.vhd                                          --
-- Author : Remon van Duijnen (R.F.J.vanDuijnen@student.tudelft.nl)  --
-- Version: 1.0														 --
-----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity tile_plus_inst_tb is
end tile_plus_inst_tb;

architecture tb of tile_plus_inst_tb is

-- constants
	constant clk_period		   : time	 := 2 ns;
	constant crossbar_rows     : integer := 32;
	constant crossbar_columns  : integer := 32;
	constant mem_size_1		   : integer := 1024;
	constant mem_size_2		   : integer := 1024;
	constant inst_size		   : integer := 2;
	constant WD_bandwidth      : integer := 8;
	constant WDS_bandwidth     : integer := 8; -- should be equal to RDS BW in this version
	constant max_datatype_size : integer := 16;
	constant RS_buffer_type    : integer := 1;
	constant RD_bandwidth	   : integer := max_datatype_size; -- equal to max_datatype_size for now
	constant RDS_bandwidth     : integer := 8; -- only for RDSb instruction 
	constant num_ADCs          : integer := 2;
	constant ADC_latency 	   : integer := 0;

-- components
	component tile_top is
		generic(crossbar_rows     : integer;
				mem_size_1		  : integer;
				mem_size_2		  : integer;
				inst_size		  : integer;
				crossbar_columns  : integer;
				WD_bandwidth      : integer;
				WDS_bandwidth     : integer; -- should be equal to RDS BW in this version
				max_datatype_size : integer;
				RS_buffer_type    : integer;
			    RD_bandwidth	  : integer; -- equal to max_datatype_size for now
				RDS_bandwidth     : integer; -- only for RDSb instruction 
				num_ADCs          : integer;
				ADC_latency 	  : integer);
		port(i_clk : in std_logic;
			 i_rst : in std_logic;
	
			 i_instruction_1 : in std_logic_vector(RDS_bandwidth + 8 - 1 downto 0);
			 i_instruction_2 : in std_logic_vector((inst_size + 1) * 8 - 1 downto 0);
	
			 i_RD			 : in std_logic_vector(max_datatype_size - 1 downto 0);
			 i_RD_buffer_index	: in std_logic_vector(integer(log2(real(crossbar_rows))) - 1 downto 0);
			 i_RD_outside_E  : in std_logic;
			 i_RD_write_done : in std_logic;
			 i_WD			 : in std_logic_vector(WD_bandwidth - 1 downto 0);
			 i_WD_outside_E  : in std_logic;
			 i_WD_write_done : in std_logic;
			 i_output_buffer_read : in std_logic;
		
			 i_RD_set_val : in std_logic_vector(integer(log2(real(max_datatype_size))) - 1 downto 0);
			 
			 o_RD_request : out std_logic;
		 	 o_WD_request : out std_logic;
			 o_output_request : out std_logic;
	
			 o_output_buffer_out 	   : out std_logic_vector(num_ADCs * ((2*crossbar_columns/num_ADCs) + integer(log2(real(crossbar_rows)))) - 1 downto 0);
			 o_output_buffer_logic_out : out std_logic_vector(crossbar_columns - 1 downto 0);
			
			 o_PC_1 : out std_logic_vector(integer(log2(real(mem_size_1))) - 1 downto 0);
			 o_PC_2 : out std_logic_vector(integer(log2(real(mem_size_2))) - 1 downto 0);

			 o_tile_done : out std_logic;

			-- test signals
			test_array_FF_out_signals : out std_logic_vector(crossbar_rows * crossbar_columns - 1  downto 0);
			test_stall_1 : out std_logic; 
			test_stall_2 : out std_logic;
			test_array_done : out std_logic;
			test_VRF_flag : out std_logic;
			test_logic_reg_output : out std_logic_vector (crossbar_columns - 1 downto 0);
			test_crossbar_output : out std_logic_vector (crossbar_columns * integer(log2(real(crossbar_rows))) - 1 downto 0);
			test_sampled_data : out std_logic_vector(crossbar_columns * integer(log2(real(crossbar_rows))) - 1 downto 0);
			test_ADC_output : out std_logic_vector(num_ADCs * integer(log2(real(crossbar_rows))) - 1 downto 0);
			test_RD_buffer : out std_logic_vector(crossbar_rows - 1 downto 0);
			test_addition_out : out std_logic_vector(num_ADCs * (2 * crossbar_columns / num_ADCs + integer(log2(real(crossbar_rows)))) - 1 downto 0);
			test_return_reg : out std_logic_vector(integer(log2(real(mem_size_1))) - 1 downto 0);
			test_jr_flag : out std_logic

	);
	end component;

	component instruction_memory_1 is
		generic(inst_size : integer;
				PC_size   : integer;
				mem_size  : integer);
		port( i_PC : in std_logic_vector(PC_size - 1 downto 0);
	
			  o_inst : out std_logic_vector(inst_size * 8 - 1 downto 0)
	);
	end component;

	component instruction_memory_2 is
		generic(inst_size : integer;
				PC_size   : integer;
				mem_size  : integer);
		port( i_PC : in std_logic_vector(PC_size - 1 downto 0);
	
			  o_inst : out std_logic_vector(inst_size * 8 - 1 downto 0)
	);
	end component;

-- signals
	-- inputs
	signal clk 								: std_logic := '1';
	signal rst 								: std_logic;
	signal s_instruction_1 					: std_logic_vector(RDS_bandwidth + 8 - 1 downto 0);
	signal s_instruction_2 					: std_logic_vector((inst_size + 1) * 8 - 1 downto 0);
	signal i_RD 							: std_logic_vector(max_datatype_size - 1 downto 0);
	signal i_RD_buffer_index 				: std_logic_vector(integer(log2(real(crossbar_rows))) - 1 downto 0);
	signal i_RD_outside_E, i_RD_write_done 	: std_logic;
	signal i_WD 							: std_logic_vector(WD_bandwidth - 1 downto 0);
	signal i_WD_outside_E, i_WD_write_done 	: std_logic;
	signal i_output_buffer_read 			: std_logic;
	signal i_RD_set_val 					: std_logic_vector(integer(log2(real(max_datatype_size))) - 1 downto 0);
	
	-- outputs
	signal o_RD_request, o_WD_request, o_output_request : std_logic;
	signal o_output_buffer_out : std_logic_vector(num_ADCs * ((2*crossbar_columns/num_ADCs) + integer(log2(real(crossbar_rows)))) - 1 downto 0);
	signal o_output_buffer_logic_out : std_logic_vector(crossbar_columns - 1 downto 0);
	signal s_PC_1 : std_logic_vector(integer(log2(real(mem_size_1))) - 1 downto 0);
	signal s_PC_2 : std_logic_vector(integer(log2(real(mem_size_2))) - 1 downto 0);
	signal o_tile_done : std_logic;

	-- test signals
	signal test_stall_1, test_stall_2, test_array_done, test_VRF_flag : std_logic;
	signal test_array_FF_out_signals : std_logic_vector(crossbar_rows * crossbar_columns - 1  downto 0);
	signal test_logic_reg_output : std_logic_vector(crossbar_columns - 1 downto 0);
	signal test_crossbar_output : std_logic_vector(crossbar_columns * integer(log2(real(crossbar_rows))) - 1 downto 0);
	signal test_sampled_data : std_logic_vector(crossbar_columns * integer(log2(real(crossbar_rows))) - 1 downto 0);
	signal test_ADC_output : std_logic_vector(num_ADCs * integer(log2(real(crossbar_rows))) - 1 downto 0);
	signal test_RD_buffer : std_logic_vector(crossbar_rows - 1 downto 0);
	signal test_addition_out : std_logic_vector(num_ADCs * (2 * crossbar_columns / num_ADCs + integer(log2(real(crossbar_rows)))) - 1 downto 0);
	signal test_return_reg : std_logic_vector(integer(log2(real(mem_size_1))) - 1 downto 0);
	signal test_jr_flag : std_logic;

	

begin

	clk <= NOT clk after clk_period/2;

	rst <= 	 '0',
			 '1' after 2 ns,
			 '0' after 4 ns;


	i_RD <= "1111111111111111";

	i_RD_buffer_index <= "11100",
						 "11101" after 13 ns,
						 "11110" after 15 ns,
						 "11111" after 17 ns;
						 --"00100" after 21 ns,
						 --"00101" after 23 ns,
						 --"00110" after 25 ns,
						 --"00111" after 27 ns,
						 --"01000" after 29 ns,
						 --"01001" after 31 ns,
						 --"01010" after 33 ns,
						 --"01011" after 35 ns,
						 --"01100" after 37 ns,
						 --"01101" after 39 ns,
						 --"01110" after 41 ns,
						 --"01111" after 43 ns,
						 --"10000" after 45 ns,
						 --"10001" after 47 ns,
						 --"10010" after 49 ns,
						 --"10011" after 51 ns,
						 --"10100" after 53 ns,
						 --"10101" after 55 ns,
						 --"10110" after 57 ns,
						 --"10111" after 59 ns,
						 --"11000" after 61 ns,
						 --"11001" after 63 ns,
						 --"11010" after 65 ns,
						 --"11011" after 67 ns,
						 --"11100" after 69 ns,
						 --"11101" after 71 ns,
						 --"11110" after 73 ns,
						 --"11111" after 75 ns;

	i_RD_outside_E <= '0',
					  '1' after 11 ns,
					  '0' after 19 ns;

	i_RD_write_done <= '0',
					   '1' after 17 ns,
					   '0' after 19 ns;

	i_WD <= "00000000",
			"00000001" after 11 ns,
			"00000010" after 13 ns,
			"00000011" after 15 ns,
			"00000100" after 17 ns,
			"00000010" after 29 ns,
			"00000011" after 31 ns,
			"00000111" after 33 ns,
			"00001111" after 35 ns;

	i_WD_outside_E <= '0',
					  '1' after 11 ns,
					  '0' after 19 ns,
					  '1' after 29 ns,
					  '0' after 37 ns;

	i_WD_write_done <=  '0',
						'1' after 17 ns,
						'0' after 19 ns,
						'1' after 35 ns,
						'0' after 37 ns;

	i_output_buffer_read <= '0',
							'1' after 600 ns,
							'0' after 602 ns,
							'1' after 700 ns,
							'0' after 702 ns,
							'1' after 780 ns,
							'0' after 782 ns,
							'1' after 800 ns,
							'0' after 802 ns;

	i_RD_set_val <= "1000";

uut: tile_top generic map(	crossbar_rows		=> crossbar_rows,
						    crossbar_columns	=> crossbar_columns,
							mem_size_1			=> mem_size_1,
							mem_size_2			=> mem_size_2,
							inst_size			=> inst_size,
							WD_bandwidth		=> WD_bandwidth,
							WDS_bandwidth		=> WDS_bandwidth,
							max_datatype_size	=> max_datatype_size,
							RS_buffer_type		=> RS_buffer_type,
							RD_bandwidth		=> RD_bandwidth,
							RDS_bandwidth		=> RDS_bandwidth,
							num_ADCs			=> num_ADCs,
							ADC_latency			=> ADC_latency)
			  port map(	i_clk						=> clk,
						i_rst						=> rst,
						i_instruction_1				=> s_instruction_1,
						i_instruction_2				=> s_instruction_2,
						i_RD						=> i_RD,
						i_RD_buffer_index			=> i_RD_buffer_index,
						i_RD_outside_E				=> i_RD_outside_E,
						i_RD_write_done				=> i_RD_write_done,
						i_WD						=> i_WD,
						i_WD_outside_E				=> i_WD_outside_E,
						i_WD_write_done				=> i_WD_write_done,
						i_output_buffer_read		=> i_output_buffer_read,
						i_RD_set_val				=> i_RD_set_val,
						o_RD_request				=> o_RD_request,
						o_WD_request				=> o_WD_request,
						o_output_request			=> o_output_request,
						o_output_buffer_out			=> o_output_buffer_out,
						o_output_buffer_logic_out	=> o_output_buffer_logic_out,
						o_PC_1						=> s_PC_1,
						o_PC_2						=> s_PC_2,
						o_tile_done					=> o_tile_done,

						-- test signal
						test_array_FF_out_signals => test_array_FF_out_signals,
						test_stall_1 => test_stall_1,
						test_stall_2 => test_stall_2,
						test_array_done => test_array_done,
						test_VRF_flag => test_VRF_flag,
						test_logic_reg_output => test_logic_reg_output,
						test_crossbar_output => test_crossbar_output,
						test_sampled_data => test_sampled_data,
						test_ADC_output => test_ADC_output,
						test_RD_buffer => test_RD_buffer,
						test_addition_out => test_addition_out,
						test_return_reg => test_return_reg,
						test_jr_flag => test_jr_flag);

uut1: instruction_memory_1 generic map(inst_size => ((RDS_bandwidth/8)+1), PC_size => integer(log2(real(mem_size_1))), mem_size => mem_size_1)
						  port map(i_PC => s_PC_1, o_inst => s_instruction_1);

uut2: instruction_memory_2 generic map(inst_size => (inst_size+1), PC_size => integer(log2(real(mem_size_2))), mem_size => mem_size_2)
						  port map(i_PC => s_PC_2, o_inst => s_instruction_2);

end tb;
