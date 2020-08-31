-----------------------------------------------------------------------
-- Project: CiM-Tile HW Design/implementation                        --
-- File	  : WD_buffer_counter_tb.vhd                                 --
-- Author : Remon van Duijnen (R.F.J.vanDuijnen@student.tudelft.nl)  --
-- Version: 1.0														 --
-----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity WD_buffer_counter_tb is
end WD_buffer_counter_tb;

architecture behavioural of WD_buffer_counter_tb is

-- constants
	constant bit_size   : integer := 3;
	constant clk_period : time    := 2 ns;

-- components

	component WD_buffer_counter is
		generic(bit_size : integer);
		port( up_down 	: in std_logic;
			  E         : in std_logic;
			  clk 		: in std_logic;
			  clr 		: in std_logic;
	
			  o 		: out std_logic_vector(bit_size - 1 downto 0));
	end component;

-- signals
	-- inputs
	signal clk    : std_logic := '0';
	signal up_down : std_logic;
	signal E       : std_logic;
	signal clr     : std_logic;

	-- outputs
	signal o : std_logic_vector(bit_size - 1 downto 0);

begin

	clk <= NOT clk after clk_period / 2;

uut: WD_buffer_counter generic map(bit_size => bit_size)
					   port map   (up_down => up_down,
								   E => E,
								   clr => clr,
								   clk => clk,
								   o => o);

	clr <= '0',
		   '1' after 2 ns,
	       '0' after 4 ns;

    up_down <= '0',
			   '1' after 4 ns,
			   '0' after 10 ns,
			   '1' after 16 ns;

	E <= '0',
		 '1' after 6 ns,
		 '0' after 10 ns,
		 '1' after 12 ns,
		 '0' after 48 ns; 

end behavioural;
