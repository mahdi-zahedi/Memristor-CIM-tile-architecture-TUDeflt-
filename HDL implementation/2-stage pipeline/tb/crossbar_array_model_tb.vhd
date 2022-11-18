-----------------------------------------------------------------------
-- Project: CiM-Tile HW Design/implementation                        --
-- File	  : crossbar_array_model_tb.vhd                              --
-- Author : Remon van Duijnen (R.F.J.vanDuijnen@student.tudelft.nl)  --
-- Version: 1.0														 --
-----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity crossbar_array_model_tb is
end crossbar_array_model_tb;

architecture tb of crossbar_array_model_tb is

-- constants
	constant clk_period			: time	  := 2 ns;
	constant crossbar_rows 		: integer := 4;
	constant crossbar_columns 	: integer := 4;

-- components
	component crossbar_array_model is
		generic(crossbar_rows	 :	integer;
				crossbar_columns :	integer);
		port(i_clk			:	in std_logic;
			 i_WD			:	in std_logic_vector(crossbar_columns-1 downto 0);
			 i_WDS			:	in std_logic_vector(crossbar_columns-1 downto 0);
			 i_RS			:	in std_logic_vector(crossbar_rows-1 downto 0);
			 i_DoA			:	in std_logic;
			 i_store		:	in std_logic;
			 i_WE			:	in std_logic;
			 i_W_S			:	in std_logic;
	
			 o_array_inter	:	out std_logic_vector(crossbar_columns*integer(log2(real(crossbar_rows))) downto 0);
			 o_array_AND	:	out std_logic_vector(crossbar_columns-1 downto 0);

			 test_array_FF_out_signals	:	out std_logic_vector(crossbar_rows * crossbar_columns - 1  downto 0));
	end component;

-- signals
	-- inputs
	signal clk 			:	std_logic := '0';
	signal i_WD			: 	std_logic_vector(crossbar_columns-1 downto 0);
	signal i_WDS		:	std_logic_vector(crossbar_columns-1 downto 0);
	signal i_RS			:	std_logic_vector(crossbar_rows-1 downto 0);
	signal i_DoA		:	std_logic;
	signal i_store		:	std_logic;
	signal i_WE			:	std_logic;
	signal i_W_S		:	std_logic;
	
	-- outputs
	signal o_array_inter	:	std_logic_vector(crossbar_columns * (integer(log2(real(crossbar_rows))) + 1) - 1 downto 0);
	signal o_array_AND		:	std_logic_vector(crossbar_columns-1 downto 0);

	-- test outputs
	signal test_array_FF_out_signals	:	std_logic_vector(crossbar_rows * crossbar_columns - 1  downto 0);
	

begin

	clk <= NOT clk after clk_period / 2;

uut: crossbar_array_model generic map(crossbar_rows	   => crossbar_rows,
								  	  crossbar_columns => crossbar_columns)
						  port map(	i_clk 		  => clk,
									i_WD 		  => i_WD,
			 						i_WDS 	      => i_WDS,
			 						i_RS 		  => i_RS,
			 						i_DoA 		  => i_DoA,
			 						i_store 	  => i_store,
			 						i_WE 		  => i_WE,
			 						i_W_S 		  => i_W_S,
	
			 						o_array_inter => o_array_inter,
			 						o_array_AND	  => o_array_AND,

									test_array_FF_out_signals => test_array_FF_out_signals);

-- test for row = columns = 4
	i_WD <= "0000",
			"1111"	after 5 ns,
			"0101"	after 10 ns,
			"1111"	after 20 ns,
			"0000"	after 30 ns;

	i_WDS <= "1111",
			 "1010"	after 20 ns,
			 "1111"	after 30 ns;

	i_RS <=  "1111",
			 "1000"	after 5 ns,
			 "0100"	after 10 ns,
			 "0010"	after 20 ns,
			 "0001"	after 30 ns,
			 "1111"	after 40 ns;

	i_DoA   <=  '0',
			 	'1' after 1 ns,
			 	'0' after 3 ns,
			 	'1' after 5 ns,
			 	'0' after 7 ns,
			 	'1' after 15 ns,
			 	'0' after 17 ns,
			 	'1' after 25 ns,
			 	'0' after 27 ns,
			 	'1' after 35 ns,
				'0' after 37 ns,
				'1' after 45 ns,
				'0' after 47 ns;

	i_store <=  '1',
			 	'0' after 40 ns;

	i_WE    <=  '0',
			 	'1' after 50 ns,
			 	'0' after 52 ns,
			 	'1' after 60 ns,
			 	'0' after 62 ns,
			 	'1' after 70 ns,
			 	'0' after 72 ns,
			 	'1' after 80 ns,
				'0' after 82 ns,
				'1' after 90 ns,
				'0' after 92 ns;

	i_W_S   <=  '0',
			 	'1' after 48 ns;

						

end tb;
