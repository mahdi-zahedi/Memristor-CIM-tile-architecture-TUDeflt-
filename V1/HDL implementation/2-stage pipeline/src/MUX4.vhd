-----------------------------------------------------------------------
-- Project: CiM-Tile HW Design/implementation                        --
-- File	  : MUX4.vhd                                                 --
-- Author : Remon van Duijnen (R.F.J.vanDuijnen@student.tudelft.nl)  --
-- Version: 1.0														 --
-----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity MUX4 is
port( A   : in std_logic;
	  B	  : in std_logic;
	  C	  : in std_logic;
	  D	  : in std_logic;
	  sel : in std_logic_vector(1 downto 0);
	  O   : out std_logic);
end MUX4;

architecture behavioural of MUX4 is

begin

	process(A, B, C, D, sel)
	begin
		case sel is
			when "00" => O <= A;
			when "01" => O <= B;
			when "10" => O <= C;
			when "11" => O <= D;
			when others => O <= 'U';
		end case;
	end process;

end behavioural;
