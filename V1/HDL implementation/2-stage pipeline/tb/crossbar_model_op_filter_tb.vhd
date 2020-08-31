-- Project: CiM-Tile HW Design/implementation                        --
-- File	  : crossbar_model_op_filter_tb.vhd                          --
-- Author : Remon van Duijnen (R.F.J.vanDuijnen@student.tudelft.nl)  --
-- Version: 1.0														 --
-----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity crossbar_model_op_filter_tb is
end crossbar_model_op_filter_tb;

architecture tb of crossbar_model_op_filter_tb is

-- constants
	constant crossbar_rows    : integer := 16;
	constant crossbar_columns : integer := 3;

-- components
	component crossbar_model_op_filter is
		generic(crossbar_rows    : integer;
				crossbar_columns : integer);
		port   (i_array_inter   : in std_logic_vector(crossbar_columns * (integer(log2(real(crossbar_rows))) + 1) - 1 downto 0);
				i_array_AND	 	: in std_logic_vector(crossbar_columns - 1 downto 0);
			    i_all_columns   : in std_logic;
				i_mux_select	: in std_logic_vector(1 downto 0);
		
				o_crossbar_output : out std_logic_vector(crossbar_columns * (integer(log2(real(crossbar_rows))) + 1) - 1 downto 0));
	end component;

-- signals
	-- inputs
	signal s_array_inter : std_logic_vector(crossbar_columns * (integer(log2(real(crossbar_rows))) + 1) - 1 downto 0);
	signal s_array_AND   : std_logic_vector(crossbar_columns-1 downto 0);
	signal s_all_columns : std_logic;
	signal s_mux_select  : std_logic_vector(1 downto 0);

	-- outputs
	signal s_crossbar_output : std_logic_vector(crossbar_columns * (integer(log2(real(crossbar_rows))) + 1) - 1 downto 0);

begin

uut: crossbar_model_op_filter generic map(crossbar_rows 	=> crossbar_rows, crossbar_columns => crossbar_columns)
							  port map   (i_array_inter 	=> s_array_inter,
										  i_array_AND   	=> s_array_AND,
										  i_all_columns 	=> s_all_columns,
										  i_mux_select  	=> s_mux_select,
										  o_crossbar_output => s_crossbar_output);


-- test for 16 rows, 3 columns
	s_array_inter <= "000000000000000",
					 "000010000100000" after 20 ns,
					 "000100001000000" after 22 ns,
					 "001000010000000" after 24 ns,
					 "010000100000000" after 26 ns,
					 "111111111100000" after 28 ns,
					 "000000000000000" after 30 ns,
					 "000010000100000" after 60 ns,
					 "000000000000000" after 61 ns,
					 "000100001000000" after 62 ns,
					 "000000000000000" after 63 ns,
					 "001000010000000" after 64 ns,
					 "000000000000000" after 65 ns,
					 "010000100000000" after 66 ns,
					 "000000000000000" after 67 ns,
					 "100001000000000" after 68 ns,
					 "000000000000000" after 69 ns,
					 "000010000100000" after 120 ns,
					 "000100001000000" after 122 ns,
					 "001000010000000" after 124 ns,
					 "010000100000000" after 126 ns,
					 "111111111100000" after 128 ns,
					 "000010000100000" after 160 ns,
					 "000100001000000" after 162 ns,
					 "001000010000000" after 164 ns,
					 "010000100000000" after 166 ns,
					 "111111111100000" after 168 ns;

	s_array_AND   <= "000",
					 "111" after 5 ns,
					 "000" after 8 ns,
					 "111" after 55 ns,
					 "000" after 58 ns,
					 "111" after 105 ns,
					 "000" after 108 ns,
					 "111" after 155 ns,
					 "000" after 158 ns;

	s_all_columns <= '0', 			    	-- single column
					 '1' after 100 ns, 		-- all columns
					 '0' after 140 ns, 	
					 '1' after 145 ns; 	

	s_mux_select  <= "00", 			     	-- and
					 "01" after 50  ns, 	-- or
					 "10" after 100 ns, 	-- lsb feedthrough
					 "11" after 150 ns; 	-- lsb feedthrough
end tb;
