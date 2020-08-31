-----------------------------------------------------------------------
-- Project: CiM-Tile HW Design/implementation                        --
-- File	  : adder_tb.vhd                                             --
-- Author : Remon van Duijnen (R.F.J.vanDuijnen@student.tudelft.nl)  --
-- Version: 1.0														 --
-----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity adder_tb is
end adder_tb;

architecture behavioural of adder_tb is

-- constants
	constant size : integer := 9;

-- components
	component adder is
		generic(size : integer);
		port   (A : in std_logic_vector(size - 1 downto 0);
				B : in std_logic_vector(size - 1 downto 0);
	
				O : out std_logic_vector(size - 1 downto 0));
	end component;

-- signals
	-- inputs
	signal A : std_logic_vector(8 downto 0);
	signal B : std_logic_vector(8 downto 0);

	-- outputs
	signal O : std_logic_vector(8 downto 0);

begin

uut: adder  generic map(size => size)
			port map(A => A, B => B, O => O);

	A <= "000000000",
		 "000000001" after 10 ns,
		 "000010000" after 20 ns,
		 "011111111" after 30 ns;

	B <= "000000000",
		 "000000001" after 15 ns,
		 "000010000" after 25 ns,
		 "000000001" after 35 ns;

end behavioural;
