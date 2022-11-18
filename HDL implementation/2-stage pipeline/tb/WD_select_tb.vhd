-----------------------------------------------------------------------
-- Project: CiM-Tile HW Design/implementation                        --
-- File	  : WD_select_tb.vhd                                         --
-- Author : Remon van Duijnen (R.F.J.vanDuijnen@student.tudelft.nl)  --
-- Version: 1.0														 --
-----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity WD_select_tb is
end WD_select_tb;

architecture tb of WD_select_tb is

-- constants
	constant clk_period		  : time	:= 2 ns;
	constant crossbar_columns : integer := 16;
	constant WD_bandwidth  	  : integer := 4;

-- components
	component WD_select is
		generic(crossbar_columns  	: 	integer;
				WD_bandwidth	:	integer);
		port (	i_clk		    :   in std_logic;
				i_WD_reg		:	in std_logic_vector(crossbar_columns-1 downto 0);
			  	i_WD_data	 	:	in std_logic_vector(WD_bandwidth -1 downto 0);
				i_WD_index		:	in std_logic_vector(integer(ceil(log2(real(crossbar_columns/WD_bandwidth)))) - 1 downto 0);
			  	i_WD_write		:	in std_logic;
				i_WD_set		:	in std_logic;
				i_WD_clear		:	in std_logic;
				
			  	o_WD_masked		:	out std_logic_vector(crossbar_columns-1 downto 0));
	end component;

-- signals
	-- inputs
	signal i_WD_reg		  	: std_logic_vector(crossbar_columns-1 downto 0);
	signal i_WD_data	 	: std_logic_vector(WD_bandwidth -1 downto 0);
	signal i_WD_index		: std_logic_vector(integer(ceil(log2(real(crossbar_columns/WD_bandwidth)))) - 1 downto 0);
	signal i_WD_write		: std_logic;
	signal i_WD_set			: std_logic;
	signal i_WD_clear		: std_logic;
	signal clk				: std_logic := '0';
	
	-- outputs
	signal o_WD_masked	  :	std_logic_vector(crossbar_columns-1 downto 0);

begin

	clk <= NOT clk after clk_period / 2;

uut: WD_select generic map(crossbar_columns => crossbar_columns, WD_bandwidth => WD_bandwidth)
			   port map( i_clk			 => clk,
						 i_WD_reg     	 => i_WD_reg, 
						 i_WD_data       => i_WD_data, 
						 i_WD_index      => i_WD_index,
						 i_WD_write      => i_WD_write,
						 i_WD_set        => i_WD_set, 
						 i_WD_clear      => i_WD_clear, 
						 o_WD_masked     => o_WD_masked);

-- test for 16 rows, BW = 4
	i_WD_reg	    <= "0000000000000000",
					  "0101010101010101" after 10 ns;

	i_WD_data  	   <= "0000",
					  "1100" after 5 ns,
					  "1111" after 15 ns;

	i_WD_index     <= "00",
					  "01" after 10 ns,
					  "10" after 20 ns,
					  "11" after 30 ns;

	i_WD_write     <= '0',
					  '1' after 6 ns,
					  '0' after 8 ns,
					  '1' after 16 ns,
					  '0' after 18 ns,
					  '1' after 26 ns,
					  '0' after 28 ns,
					  '1' after 36 ns,
					  '0' after 38 ns;

	i_WD_clear	   <= '1',
					  '0' after 2 ns,
					  '1' after 3 ns,
					  '0' after 55 ns,
					  '1' after 56 ns;

	i_WD_set	   <= '1',
					  '0' after 45 ns,
					  '1' after 46 ns;

end tb;
