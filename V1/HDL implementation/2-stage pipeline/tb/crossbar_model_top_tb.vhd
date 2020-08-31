-----------------------------------------------------------------------
-- Project: CiM-Tile HW Design/implementation                        --
-- File	  : crossbar_top_tb.vhd                                      --
-- Author : Remon van Duijnen (R.F.J.vanDuijnen@student.tudelft.nl)  --
-- Version: 1.0														 --
-----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity crossbar_model_top_tb is
end crossbar_model_top_tb;

architecture tb of crossbar_model_top_tb is

-- constants
	constant crossbar_rows 		: integer := 32;
	constant crossbar_columns 	: integer := 32;
	constant clk_period			: time    := 2 ns;

-- components
	component crossbar_model_top is
		generic (crossbar_rows    : integer;
				 crossbar_columns : integer);
		port	(i_FS 	  		: in std_logic_vector(3 downto 0);
			 	 i_DoA   		: in std_logic;
				 i_clk	  		: in std_logic;
				 i_reset 		: in std_logic;
				 i_WD			: in std_logic_vector(crossbar_columns-1 downto 0);
				 i_WDS			: in std_logic_vector(crossbar_columns-1 downto 0);
				 i_RS			: in std_logic_vector(crossbar_rows-1 downto 0);
	
				 o_done			    : out std_logic;
				 o_crossbar_output  : out std_logic_vector(crossbar_columns * integer(log2(real(crossbar_rows))) - 1 downto 0);
				
				test_array_FF_out_signals	:	out std_logic_vector(crossbar_rows * crossbar_columns - 1  downto 0));
	end component;

-- signals
	-- inputs
	signal i_FS			:	std_logic_vector(3 downto 0);	
	signal i_DoA		:	std_logic;
	signal i_clk		:	std_logic := '1';
	signal i_reset		:	std_logic;
	signal i_WD			: 	std_logic_vector(crossbar_columns-1 downto 0);
	signal i_WDS		:	std_logic_vector(crossbar_columns-1 downto 0);
	signal i_RS			:	std_logic_vector(crossbar_rows-1 downto 0);
	
	-- outputs
	signal o_done			:	std_logic;
	signal o_crossbar_output	:	std_logic_vector(crossbar_columns * integer(log2(real(crossbar_rows))) - 1 downto 0);

	signal test_array_FF_out_signals : std_logic_vector(crossbar_rows * crossbar_columns - 1  downto 0);
	

begin

	i_clk <= NOT i_clk after clk_period / 2;

uut: crossbar_model_top generic map(crossbar_rows => crossbar_rows, crossbar_columns => crossbar_columns)
						port map   (i_FS    	  => i_FS,
									i_DoA   	  => i_DoA,
									i_clk   	  => i_clk,
									i_reset 	  => i_reset,
									i_WD    	  => i_WD,
									i_WDS   	  => i_WDS,
									i_RS    	  => i_RS,

									o_done  	  => o_done,
									o_crossbar_output => o_crossbar_output,

								    test_array_FF_out_signals => test_array_FF_out_signals
								   );

	i_reset <= '1',
			   '0' after 2 ns;

	i_FS <= "0000", -- store
			"0100" after 40 ns; -- read

	i_WDS <= "00000000000000000000000011111111";

	i_WD  <= "00000000000000000000000000000001",
			 "00000000000000000000000000000011" after 10 ns,
			 "00000000000000000000000000000111" after 20 ns,
			 "00000000000000000000000000001111" after 30 ns;

	i_RS  <= "00000000000000000000000000000001",
			 "00000000000000000000000000000010" after 10 ns,
			 "00000000000000000000000000000100" after 20 ns,
			 "00000000000000000000000000001000" after 30 ns;

	i_DoA <= '0',
			 '1' after 4 ns,
			 '0' after 6 ns,
			 '1' after 14 ns,
			 '0' after 16 ns,
			 '1' after 24 ns,
			 '0' after 26 ns,
			 '1' after 34 ns,
			 '0' after 36 ns,
			 '1' after 144 ns,
			 '0' after 146 ns;





-- test for row = columns = 4
	--i_reset <= '1',
	--		   '0' after 2 ns;
--
	--i_FS <= "000", -- store
	--		"111" after 80 ns,
	--		"010" after 100 ns,
	--		"011" after 110 ns,
	--		"100" after 120 ns,
	--		"101" after 130 ns,
	--		"110" after 140 ns;
--
	--i_WD <= "0000",
	--		"0111"	after 2 ns,
	--		"0111"	after 22 ns,
	--		"0011"	after 42 ns,
	--		"0001"	after 62 ns;
--
	--i_WDS <= "1111";
--
--
--
	--i_RS <=  "1111",
	--		 "0001"	after 2 ns,
	--		 "0010"	after 22 ns,
	--		 "0100"	after 42 ns,
	--		 "1000"	after 62 ns,
	--		 "1111"	after 66 ns;
--
	--i_DoA   <=  '0',
	--		 	'1' after 4 ns,
	--		 	'0' after 6 ns,
	--		 	'1' after 24 ns,
	--		 	'0' after 26 ns,
	--		 	'1' after 44 ns,
	--		 	'0' after 46 ns,
	--		 	'1' after 64 ns,
	--			'0' after 66 ns,
	--			'1' after 84 ns,
	--			'0' after 86 ns;

						

end tb;
