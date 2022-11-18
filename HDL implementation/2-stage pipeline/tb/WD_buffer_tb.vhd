-----------------------------------------------------------------------
-- Project: CiM-Tile HW Design/implementation                        --
-- File	  : WD_Buffer_tb.vhd                                         --
-- Author : Remon van Duijnen (R.F.J.vanDuijnen@student.tudelft.nl)  --
-- Version: 1.0														 --
-----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity WD_buffer_tb is
end WD_buffer_tb;

architecture tb of WD_buffer_tb is

-- constants
constant clk_period  	  : time := 2 ns;
constant bandwidth 		  : integer := 4;
constant crossbar_columns : integer := 16;

-- components
component WD_buffer
	generic(bandwidth 	     : integer;
		    crossbar_columns : integer);
	port( i_clk : in std_logic;
		  i_WD  : in std_logic_vector(bandwidth - 1 downto 0);
	  	  shift : in std_logic;

	  	  o_WD  : out std_logic_vector(bandwidth - 1 downto 0));
end component;

-- signals
	-- inputs
	signal i_WD  : std_logic_vector(bandwidth - 1 downto 0) := (others => '0');
	signal shift : std_logic := '0';
	signal clk   : std_logic := '0';
	
	--outputs
	signal o_WD : std_logic_vector(bandwidth - 1 downto 0);

begin

	clk <= NOT clk after clk_period / 2;

uut: WD_buffer 
	 generic map(
		bandwidth => bandwidth,
		crossbar_columns => crossbar_columns)
	 port map(	i_clk => clk,
				i_WD  => i_WD,
				shift => shift,
				o_WD  => o_WD);

-- test for BW=4, #cols=8
	i_WD <= "0001" after 10 ns, "0011" after 20 ns, "0111" after 30 ns, "1111" after 40 ns;
	shift <= '1' after 15 ns, '0' after 16 ns, 
		     '1' after 25 ns, '0' after 26 ns, 
		     '1' after 35 ns, '0' after 36 ns,
			 '1' after 45 ns, '0' after 46 ns, 
		     '1' after 55 ns, '0' after 56 ns, 
		     '1' after 65 ns, '0' after 66 ns,
			 '1' after 75 ns, '0' after 76 ns;

-- test for BW=4, #cols=4
--	i_WD <= "0000" after 10ns, "0101" after 20ns, "1111" after 30ns;
--	shift <= '1' after 15 ns, '0' after 16 ns, 
--			 '1' after 25 ns, '0' after 26 ns, 
--			 '1' after 35 ns, '0' after 36 ns;


end tb;