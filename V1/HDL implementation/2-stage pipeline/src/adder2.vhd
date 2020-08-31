-----------------------------------------------------------------------
-- Project: CiM-Tile HW Design/implementation                        --
-- File	  : adder2.vhd		                                         --
-- Author : Remon van Duijnen (R.F.J.vanDuijnen@student.tudelft.nl)  --
-- Version: 1.0														 --
-----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity adder2 is
	generic(size : integer);
	port   (A : in std_logic_vector(size - 1 downto 0);
			B : in std_logic_vector(size - 1 downto 0);

			O : out std_logic_vector(size downto 0));
end adder2;

architecture behavioural of adder2 is

begin

	O <= std_logic_vector(resize(unsigned(A), size + 1) + resize(unsigned(B), size + 1));

end behavioural;
