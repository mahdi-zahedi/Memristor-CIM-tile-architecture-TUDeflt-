-----------------------------------------------------------------------
-- Project: CiM-Tile HW Design/implementation                        --
-- File	  : decoder2.vhd                                             --
-- Author : Remon van Duijnen (R.F.J.vanDuijnen@student.tudelft.nl)  --
-- Version: 1.0														 --
----------------------------------------------------------------------- 

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity decoder2_tb is
end decoder2_tb;

architecture behavioural of decoder2_tb is

-- constants
	constant number_of_input_bits : integer := 8;

-- components
	component decoder2 is
		generic(number_of_input_bits : integer
		);
		port (input  : in std_logic_vector(number_of_input_bits-1 downto 0);
			  output : out std_logic_vector((2 ** number_of_input_bits) - 1 downto 0)
		);
	end component;

-- signals
	-- inputs
	signal input : std_logic_vector(number_of_input_bits - 1 downto 0);

	-- outputs
	signal output : std_logic_vector((2 ** number_of_input_bits) - 1 downto 0);

begin

uut: decoder2 generic map(number_of_input_bits => number_of_input_bits)
			  port map(input => input, output => output);

	input <= "00000000",
			 "00000001" after 10 ns,
			 "00000010" after 20 ns,
			 "00000011" after 30 ns,
			 "00000100" after 40 ns,
			 "00000101" after 50 ns,
			 "00000110" after 60 ns,
			 "00000111" after 70 ns,
			 "00001000" after 80 ns,
			 "11111111" after 90 ns;

end behavioural;
