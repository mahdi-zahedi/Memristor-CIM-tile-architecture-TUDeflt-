-----------------------------------------------------------------------
-- Project: CiM-Tile HW Design/implementation                        --
-- File	  : adder2_tb.vhd                                            --
-- Author : Remon van Duijnen (R.F.J.vanDuijnen@student.tudelft.nl)  --
-- Version: 1.0														 --
-----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity adder2_tb is
end adder2_tb;

architecture behavioural of adder2_tb is

-- constants
	constant size : integer := 8;

-- components
	component adder2 is
		generic(size : integer);
		port   (A : in std_logic_vector(size - 1 downto 0);
				B : in std_logic_vector(size - 1 downto 0);
	
				O : out std_logic_vector(size downto 0));
	end component;

-- signals
	-- inputs
	signal A : std_logic_vector(7 downto 0);
	signal B : std_logic_vector(7 downto 0);

	-- outputs
	signal O : std_logic_vector(8 downto 0);

begin

uut: adder2  generic map(size => size)
			port map(A => A, B => B, O => O);

	A <= "00000000",
		 "00000001" after 10 ns,
		 "00010000" after 20 ns,
		 "01111111" after 30 ns,
		 "11111111" after 40 ns;

	B <= "00000000",
		 "00000001" after 15 ns,
		 "00010000" after 25 ns,
		 "00000001" after 35 ns,
		 "11111111" after 45 ns;

end behavioural;
