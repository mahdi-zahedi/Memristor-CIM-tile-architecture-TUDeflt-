-----------------------------------------------------------------------
-- Project: CiM-Tile HW Design/implementation                        --
-- File	  : adder.vhd		                                         --
-- Author : Remon van Duijnen (R.F.J.vanDuijnen@student.tudelft.nl)  --
-- Version: 1.0														 --
-----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity adder is
	generic(size : integer);
	port   (A : in std_logic_vector(size - 1 downto 0);
			B : in std_logic_vector(size - 1 downto 0);

			O : out std_logic_vector(size - 1 downto 0));
end adder;

architecture behavioural of adder is

begin

	O <= std_logic_vector(unsigned(A) + unsigned(B));

end behavioural;
