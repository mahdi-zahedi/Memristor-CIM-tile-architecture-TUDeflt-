-----------------------------------------------------------------------
-- Project: CiM-Tile HW Design/implementation                        --
-- File	  : sample_and_hold_tb.vhd                                      --
-- Author : Remon van Duijnen (R.F.J.vanDuijnen@student.tudelft.nl)  --
-- Version: 1.0														 --
-----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity sample_and_hold_tb is
end sample_and_hold_tb;


architecture tb of sample_and_hold_tb is

-- constants
	constant crossbar_rows	  : integer := 16;
	constant crossbar_columns : integer := 4;
	constant clk_period		  : time	:= 2 ns;

-- components

	component sample_and_hold is
		generic(crossbar_rows     : integer;
				crossbar_columns  : integer);
		port   (i_clk			  : in std_logic;
				i_crossbar_output : in std_logic_vector(crossbar_columns * (integer(log2(real(crossbar_rows))) + 1) - 1 downto 0);
				i_DoS			  : in std_logic;
	
				o_sampled_data    : out std_logic_vector(crossbar_columns * (integer(log2(real(crossbar_rows))) + 1) - 1 downto 0));
	end component;

-- signals
	-- inputs
	signal s_crossbar_output : std_logic_vector(crossbar_columns * (integer(log2(real(crossbar_rows))) + 1) - 1 downto 0);
	signal s_DoS			 : std_logic;
	signal clk				 : std_logic := '0';
 
	-- outputs
	signal s_sampled_data    : std_logic_vector(crossbar_columns * (integer(log2(real(crossbar_rows))) + 1) - 1 downto 0);

begin

	clk <= NOT clk after clk_period / 2;

uut: sample_and_hold generic map(crossbar_rows => crossbar_rows, crossbar_columns => crossbar_columns)
					 port map(i_crossbar_output => s_crossbar_output,
							  i_DoS => s_DoS,
							  i_clk => clk,
							  o_sampled_data => s_sampled_data);

	s_crossbar_output <= "00000000000000000000",
						 "11111111111111111111" after 20 ns,
						 "10101010101010101010" after 30 ns,
				 		 "01010101010101010101" after 40 ns;

	s_DoS			  <= '0',
						 '1' after 5 ns,
						 '0' after 6 ns,
						 '1' after 25 ns,
						 '0' after 26 ns,
						 '1' after 45 ns,
						 '0' after 46 ns;

end tb;
