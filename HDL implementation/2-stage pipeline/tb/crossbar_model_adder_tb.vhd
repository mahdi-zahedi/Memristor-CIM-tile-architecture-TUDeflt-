-----------------------------------------------------------------------
-- Project: CiM-Tile HW Design/implementation                        --
-- File	  : crossbar_model_adder_tb.vhd                              --
-- Author : Remon van Duijnen (R.F.J.vanDuijnen@student.tudelft.nl)  --
-- Version: 1.0														 --
-----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity crossbar_model_adder_tb is 
end crossbar_model_adder_tb;

architecture tb of crossbar_model_adder_tb is

-- constants
	constant num_output_bits : integer := 9;

-- components
	component crossbar_model_adder is
		generic(num_output_bits	:	integer);
		port(A	:	in std_logic;
			 B	:	in std_logic_vector(num_output_bits-1 downto 0);
			 O	:	out std_logic_vector(num_output_bits-1 downto 0));
	end component;

-- signals
	--inputs
	signal A	:	std_logic;
	signal B	:	std_logic_vector(num_output_bits-1 downto 0);
	--outputs
	signal O	:	std_logic_vector(num_output_bits-1 downto 0);

begin

uut: crossbar_model_adder 	generic map(num_output_bits => num_output_bits)
							port map(A => A, B => B, O => O);

-- test for num_output_bits = 9 (256 row crossbar)
	A <= '0',
		 '1' after 20 ns,
		 '0' after 40 ns,
		 '1' after 60 ns;

	B <= "000000000",
		 "000000001" after 25 ns,
		 "000000010" after 30 ns,
		 "011111111" after 50 ns;

end tb;