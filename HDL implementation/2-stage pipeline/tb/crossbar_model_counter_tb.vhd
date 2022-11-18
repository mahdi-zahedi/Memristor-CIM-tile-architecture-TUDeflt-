-----------------------------------------------------------------------
-- Project: CiM-Tile HW Design/implementation                        --
-- File	  : crossbar_model_counter_tb.vhd                            --
-- Author : Remon van Duijnen (R.F.J.vanDuijnen@student.tudelft.nl)  --
-- Version: 1.0														 --
-----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity crossbar_model_counter_tb is
end crossbar_model_counter_tb;

architecture tb of crossbar_model_counter_tb is

-- constants
	constant clk_period : time := 2 ns;

-- components
	component crossbar_model_counter is
		port( i_set_val : in std_logic_vector(8 downto 0);
		 	  i_set 	: in std_logic;
			  clk 		: in std_logic;
			  clr 		: in std_logic;
	
			  o 		: out std_logic_vector(8 downto 0)
	);
	end component;

-- signals
	--inputs
	signal i_set_val : std_logic_vector(8 downto 0);
	signal i_set	 : std_logic;
	signal clk		 : std_logic := '0';
	signal clr		 : std_logic;

	-- outputs
	signal o : std_logic_vector (8 downto 0);

begin

uut: crossbar_model_counter port map(i_set_val => i_set_val, i_set => i_set, clk => clk, clr => clr, o => o);

	clk <= not clk after clk_period/2;

	clr <= '0',
		   '1' after 4 ns,
 		   '0' after 6 ns;

	i_set_val   <= "000000000",
				   "100000000" after 20 ns,
				   "000000001" after 600 ns;

	i_set		<= '0',
				   '1' after 10 ns,
				   '0' after 12 ns,
				   '1' after 22 ns,
				   '0' after 24 ns,
				   '1' after 603 ns,
				   '0' after 604 ns;


end tb;
