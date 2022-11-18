-----------------------------------------------------------------------
-- Project: CiM-Tile HW Design/implementation                        --
-- File	  : RS_mask_tb.vhd                                          --
-- Author : Remon van Duijnen (R.F.J.vanDuijnen@student.tudelft.nl)  --
-- Version: 1.0														 --
-----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity RS_mask_tb is
end RS_mask_tb;

architecture tb of RS_mask_tb is

-- constants
	constant clk_period		:	time	:= 2 ns;
	constant crossbar_rows	:	integer	:= 16;
	constant RS_bandwidth	:	integer	:= 4;
	constant RS_index_bits	:	integer := integer(ceil(log2(real(crossbar_rows/RS_bandwidth))));

-- components
	component RS_mask is
		generic(crossbar_rows  	: 	integer;
				RS_bandwidth 	: 	integer);
		port(	i_clk			:   in std_logic;
				i_RS_data		:	in std_logic_vector(RS_bandwidth-1 downto 0);
				i_RS_index		:	in std_logic_vector(integer(ceil(log2(real(crossbar_rows/RS_bandwidth)))) - 1 downto 0);
				i_RS_write		:	in std_logic;
				i_RS_set		:	in std_logic;
				i_RS_clear		:	in std_logic;
	
				o_RS_mask		:	out std_logic_vector(crossbar_rows-1 downto 0));
	end component;


-- signals
	-- inputs
	signal i_RS_data	: std_logic_vector(RS_bandwidth - 1 downto 0);
	signal i_RS_index	: std_logic_vector(RS_index_bits - 1 downto 0);
	signal i_RS_write	: std_logic;
	signal i_set		: std_logic;
	signal i_clear		: std_logic;
	signal clk 			: std_logic := '0'; 

	-- outputs
	signal o_RS_mask    :	std_logic_vector(crossbar_rows - 1 downto 0);

begin

	clk <= NOT clk after clk_period / 2;

uut: RS_mask generic map(crossbar_rows => crossbar_rows, RS_bandwidth => RS_bandwidth)
			 port map(i_clk			 => clk,
					  i_RS_data 	 => i_RS_data,
					  i_RS_index	 => i_RS_index,
					  i_RS_write	 => i_RS_write,
					  i_RS_set		 => i_set,
					  i_RS_clear 	 => i_clear,
					  o_RS_mask      => o_RS_mask);

-- test for 16 rows, BW=4 (4 blocks, 2 index bits)
	i_RS_data <= "0000",
				 "1000" after 10 ns,
				 "1111" after 20 ns,
				 "0011" after 30 ns;

	i_RS_index <= "00",
				  "01" after 15 ns,
				  "10" after 25 ns;

	i_RS_write <= '0',
				  '1' after  5 ns,
				  '0' after  7 ns,
				  '1' after 11 ns,
				  '0' after 13 ns,
				  '1' after 21 ns,
				  '0' after 23 ns,
				  '1' after 31 ns,
				  '0' after 33 ns,
				  '1' after 35 ns,
				  '0' after 37 ns;

	i_set <= '0',
			 '1' after 35 ns,
			 '0' after 37 ns;

	i_clear <= '0',
			   '1' after 5 ns,
			   '0' after 7 ns;
--
	
end tb;

