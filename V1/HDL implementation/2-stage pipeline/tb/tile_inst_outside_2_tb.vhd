-----------------------------------------------------------------------
-- Project: CiM-Tile HW Design/implementation                        --
-- File	  : tile_inst_outside_2_tb.vhd                               --
-- Author : Remon van Duijnen (R.F.J.vanDuijnen@student.tudelft.nl)  --
-- Version: 1.0														 --
-----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity tile_inst_outside_2_tb is
end tile_inst_outside_2_tb;

architecture tb of tile_inst_outside_2_tb is

-- constants
	constant clk_period : time := 2 ns;

-- components
	component tile_inst_outside is
		port(i_clk : in std_logic;
			 i_rst : in std_logic;
			 o_tile_done : out std_logic);
	end component;


-- signals
	-- inputs
	signal clk 								: std_logic := '1';
	signal rst 								: std_logic;
	--signal s_instruction_1 					: std_logic_vector(RDS_bandwidth + 8 - 1 downto 0);
	--signal s_instruction_2 					: std_logic_vector((inst_size + 1) * 8 - 1 downto 0);
	--signal i_RD 							: std_logic_vector(max_datatype_size - 1 downto 0);
	--signal i_RD_buffer_index 				: std_logic_vector(integer(log2(real(crossbar_rows))) - 1 downto 0);
	--signal i_RD_outside_E, i_RD_write_done 	: std_logic;
	--signal i_WD 							: std_logic_vector(WD_bandwidth - 1 downto 0);
	--signal i_WD_outside_E, i_WD_write_done 	: std_logic;
	--signal i_output_buffer_read 			: std_logic;
	--signal i_RD_set_val 					: std_logic_vector(integer(log2(real(max_datatype_size))) - 1 downto 0);
	
	-- outputs
	--signal o_RD_request, o_WD_request, o_output_request : std_logic;
	--signal o_output_buffer_out : std_logic_vector(num_ADCs * ((2*crossbar_columns/num_ADCs) + integer(log2(real(crossbar_rows)))) - 1 downto 0);
	--signal o_output_buffer_logic_out : std_logic_vector(crossbar_columns - 1 downto 0);
	--signal s_PC_1 : std_logic_vector(integer(log2(real(mem_size_1))) - 1 downto 0);
	--signal s_PC_2 : std_logic_vector(integer(log2(real(mem_size_2))) - 1 downto 0);
	signal o_tile_done : std_logic;

	-- test signals
	--signal test_stall_1, test_stall_2, test_array_done, test_VRF_flag : std_logic;
	--signal test_array_FF_out_signals : std_logic_vector(crossbar_rows * crossbar_columns - 1  downto 0);
	--signal test_logic_reg_output : std_logic_vector(crossbar_columns - 1 downto 0);
	--signal test_crossbar_output : std_logic_vector(crossbar_columns * integer(log2(real(crossbar_rows))) - 1 downto 0);
	--signal test_sampled_data : std_logic_vector(crossbar_columns * integer(log2(real(crossbar_rows))) - 1 downto 0);
	--signal test_ADC_output : std_logic_vector(num_ADCs * integer(log2(real(crossbar_rows))) - 1 downto 0);
	--signal test_RD_buffer : std_logic_vector(crossbar_rows - 1 downto 0);
	--signal test_addition_out : std_logic_vector(num_ADCs * (2 * crossbar_columns / num_ADCs + integer(log2(real(crossbar_rows)))) - 1 downto 0);
	--signal test_return_reg : std_logic_vector(integer(log2(real(mem_size_1))) - 1 downto 0);
	--signal test_jr_flag : std_logic;

	

begin

	clk <= NOT clk after clk_period/2;

	rst <= 	 '0',

			 '1' after 2 ns,
			 '0' after 4 ns;


uut: tile_inst_outside port map(i_clk => clk, i_rst => rst, o_tile_done => o_tile_done);

end tb;
