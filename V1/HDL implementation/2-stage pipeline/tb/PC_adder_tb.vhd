-----------------------------------------------------------------------
-- Project: CiM-Tile HW Design/implementation                        --
-- File	  : PC_adder_tb.vhd                                          --
-- Author : Remon van Duijnen (R.F.J.vanDuijnen@student.tudelft.nl)  --
-- Version: 1.0														 --
-----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity PC_adder_tb is
end PC_adder_tb;

architecture behavioural of PC_adder_tb is

-- constants
	constant size_A : integer := 8;
	constant size_B : integer := 3;

-- components
	component PC_adder is
		generic(size_A : integer;
				size_B : integer);
		port   (A : in  std_logic_vector(size_A - 1 downto 0); 
				B : in  std_logic_vector(size_B - 1 downto 0); 
				O : out std_logic_vector(size_A - 1 downto 0));
	end component;

-- signals
	-- inputs
	signal A : std_logic_vector(size_A - 1 downto 0);
	signal B : std_logic_vector(size_B - 1 downto 0);

	-- outputs
	signal O : std_logic_vector(size_A - 1 downto 0);

begin

uut: PC_adder  generic map(size_A => size_A, size_B => size_B)
			port map(A => A, B => B, O => O);

	A <= "00000000",
		 "00000001" after 10 ns,
		 "00010000" after 20 ns,
		 "01111111" after 30 ns,
		 "11111111" after 40 ns;

	B <= "000",
		 "001" after 15 ns,
		 "000" after 25 ns,
		 "001" after 35 ns,
		 "111" after 45 ns;

end behavioural;
