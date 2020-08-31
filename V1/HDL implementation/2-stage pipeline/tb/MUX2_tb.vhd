-----------------------------------------------------------------------
-- Project: CiM-Tile HW Design/implementation                        --
-- File	  : MUX2_tb.vhd                                            --
-- Author : Remon van Duijnen (R.F.J.vanDuijnen@student.tudelft.nl)  --
-- Version: 1.0														 --
-----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity MUX2_tb is
end MUX2_tb;

architecture tb of MUX2_tb is

	-- components
	component MUX2 port( 
		  A : in std_logic;
		  B	: in std_logic;
		  sel : in std_logic;
		  O : out std_logic);
	end component;
	
	-- inputs
	signal A, B, sel : std_logic := '0';
	
	-- outputs
	signal O : std_logic := '0';

	-- constants
	constant period : time := 10 ns;

begin

	uut: MUX2 port map(
				A => A,
				B => B,
				sel => sel,
				O => O
			);

	A <= not A after period/2;
	B <= not B after period;
	sel <= not sel after period*2;

end tb;