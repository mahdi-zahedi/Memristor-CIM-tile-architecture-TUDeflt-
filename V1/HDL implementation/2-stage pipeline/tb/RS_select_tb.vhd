-----------------------------------------------------------------------
-- Project: CiM-Tile HW Design/implementation                        --
-- File	  : RS_select_tb.vhd                                         --
-- Author : Remon van Duijnen (R.F.J.vanDuijnen@student.tudelft.nl)  --
-- Version: 1.0														 --
-----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity RS_select_tb is
end RS_select_tb;

architecture tb of RS_select_tb is

-- constants
	constant clk_period	   : time	 := 2 ns;
	constant crossbar_rows : integer := 16;
	constant RS_bandwidth  : integer := 4;

-- components
	component RS_select is
		generic(crossbar_rows  	: 	integer;
				RS_bandwidth	:	integer);
		port (	i_clk			:	in std_logic;
				i_RS_buffer		:	in std_logic_vector(crossbar_rows-1 downto 0);
			  	i_RS_data	 	:	in std_logic_vector(RS_bandwidth -1 downto 0);
				i_RS_index		:	in std_logic_vector(integer(ceil(log2(real(crossbar_rows/RS_bandwidth)))) - 1 downto 0);
			  	i_RS_write		:	in std_logic;
				i_RS_set		:	in std_logic;
				i_RS_clear		:	in std_logic;
				i_RS_immediate 	:   in std_logic;
				
			  	o_RS_masked		:	out std_logic_vector(crossbar_rows-1 downto 0));
	end component;

-- signals
	-- inputs
	signal clk				: std_logic := '0';
	signal i_RS_buffer	  	: std_logic_vector(crossbar_rows-1 downto 0);
	signal i_RS_data	 	: std_logic_vector(RS_bandwidth -1 downto 0);
	signal i_RS_index		: std_logic_vector(integer(ceil(log2(real(crossbar_rows/RS_bandwidth)))) - 1 downto 0);
	signal i_RS_write		: std_logic;
	signal i_RS_set			: std_logic;
	signal i_RS_clear		: std_logic;
	signal i_RS_immediate 	: std_logic;
	
	-- outputs
	signal o_RS_masked	  :	std_logic_vector(crossbar_rows-1 downto 0);

begin

	clk <= NOT clk after clk_period / 2;

uut: RS_select generic map(crossbar_rows => crossbar_rows, RS_bandwidth => RS_bandwidth)
			   port map( i_clk 			 => clk,
						 i_RS_buffer     => i_RS_buffer, 
						 i_RS_data       => i_RS_data, 
						 i_RS_index      => i_RS_index,
						 i_RS_write      => i_RS_write,
						 i_RS_set        => i_RS_set, 
						 i_RS_clear      => i_RS_clear, 
						 i_RS_immediate  => i_RS_immediate,
						 o_RS_masked     => o_RS_masked);

-- test for 16 rows, BW = 4
	i_RS_buffer    <= "XXXXXXXXXXXXXXXX",
					  "0101010101010101" after 10 ns;

	i_RS_data  	   <= "0000",
					  "1100" after 5 ns,
					  "1111" after 15 ns;

	i_RS_index     <= "00",
					  "01" after 10 ns,
					  "10" after 20 ns,
					  "11" after 30 ns;

	i_RS_write     <= '0',
					  '1' after 2 ns,
					  '0' after 4 ns,
					  '1' after 6 ns,
					  '0' after 8 ns,
					  '1' after 16 ns,
					  '0' after 18 ns,
					  '1' after 26 ns,
					  '0' after 28 ns,
					  '1' after 36 ns,
					  '0' after 38 ns,
					  '1' after 45 ns,
					  '0' after 47 ns,
					  '1' after 55 ns,
					  '0' after 57 ns;

	i_RS_clear	   <= '0',
					  '1' after 2 ns,
					  '0' after 4 ns,
					  '1' after 55 ns,
					  '0' after 57 ns;

	i_RS_set	   <= '0',
					  '1' after 45 ns,
					  '0' after 47 ns;

	i_RS_immediate <= '0',
					  '1' after 40 ns,
					  '0' after 50 ns;


end tb;
