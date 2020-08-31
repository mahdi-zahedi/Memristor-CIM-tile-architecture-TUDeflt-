-----------------------------------------------------------------------
-- Project: CiM-Tile HW Design/implementation                        --
-- File	  : MUX2.vhd                                                 --
-- Author : Remon van Duijnen (R.F.J.vanDuijnen@student.tudelft.nl)  --
-- Version: 1.0														 --
-----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity MUX2 is
port( A : in std_logic;
	  B	: in std_logic;
	  sel : in std_logic;
	  O : out std_logic);
end MUX2;

architecture behavioural of MUX2 is

begin

	process(A, B, sel)
	begin
		case sel is
			when '0' => O <= A;
			when '1' => O <= B;
			when others => O <= 'U';
		end case;
	end process;
end behavioural;