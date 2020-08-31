-----------------------------------------------------------------------
-- Project: CiM-Tile HW Design/implementation                        --
-- File	  : decoder.vhd                                            --
-- Author : Remon van Duijnen (R.F.J.vanDuijnen@student.tudelft.nl)  --
-- Version: 1.0														 --
----------------------------------------------------------------------- 

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity decoder is
	generic(number_of_input_bits : integer
	);
	port (input  : in std_logic_vector(number_of_input_bits-1 downto 0);
		  output : out std_logic_vector((2 ** number_of_input_bits) - 1 downto 0)
	);
end decoder;

architecture behavioural of decoder is

begin

	process(input)
	begin
		output <= (others => '0'); -- default
		output(to_integer(unsigned(input))) <= '1';
	end process;

end behavioural;
