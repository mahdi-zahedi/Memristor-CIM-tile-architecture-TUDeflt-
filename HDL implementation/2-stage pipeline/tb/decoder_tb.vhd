-----------------------------------------------------------------------
-- Project: CiM-Tile HW Design/implementation                        --
-- File	  : decoder_tb.vhd                                           --
-- Author : Remon van Duijnen (R.F.J.vanDuijnen@student.tudelft.nl)  --
-- Version: 1.0														 --
----------------------------------------------------------------------- 

library ieee;
use ieee.std_logic_1164.all;

entity decoder_tb is
end decoder_tb;

architecture tb of decoder_tb is

-- constants
	constant number_of_input_bits : integer := 3;

-- components
	component decoder is
		generic(number_of_input_bits : integer
		);
		port (input  : in std_logic_vector(number_of_input_bits-1 downto 0);
			  output : out std_logic_vector((2 ** number_of_input_bits) - 1 downto 0)
		);
	end component;
	
-- signals
	-- inputs
	signal input  : std_logic_vector(number_of_input_bits-1 downto 0);
	
	-- outputs
	signal output : std_logic_vector((2 ** number_of_input_bits) - 1 downto 0);


begin

uut: decoder generic map(number_of_input_bits => number_of_input_bits)
			 port map(input => input, output => output);

-- test for 1:2 decoder
--	input <= "0", "1" after 50 ns;


-- test for 3:8 decoder
	input <= "000", 
			 "001" after 10 ns,
			 "010" after 20 ns,
			 "011" after 30 ns,
			 "100" after 40 ns,
			 "101" after 50 ns,
			 "110" after 60 ns,
			 "111" after 70 ns;

end tb;
