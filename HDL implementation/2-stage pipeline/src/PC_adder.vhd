-----------------------------------------------------------------------
-- Project: CiM-Tile HW Design/implementation                        --
-- File	  : PC_adder.vhd                                             --
-- Author : Remon van Duijnen (R.F.J.vanDuijnen@student.tudelft.nl)  --
-- Version: 1.0														 --
-----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity PC_adder is
	generic(size_A : integer;
			size_B : integer);
	port   (A : in  std_logic_vector(size_A - 1 downto 0); 
			B : in  std_logic_vector(size_B - 1 downto 0); 
			O : out std_logic_vector(size_A - 1 downto 0));
end PC_adder;

architecture behavioural of PC_adder is

begin

	O <= std_logic_vector(unsigned(A) + resize(unsigned(B), size_A));

end behavioural;


