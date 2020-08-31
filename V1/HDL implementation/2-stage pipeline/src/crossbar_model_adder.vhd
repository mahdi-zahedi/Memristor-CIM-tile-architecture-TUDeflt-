-----------------------------------------------------------------------
-- Project: CiM-Tile HW Design/implementation                        --
-- File	  : crossbar_model_adder.vhd                                 --
-- Author : Remon van Duijnen (R.F.J.vanDuijnen@student.tudelft.nl)  --
-- Version: 1.0														 --
-----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity crossbar_model_adder is
	generic(num_output_bits	:	integer);
	port(A	:	in std_logic;
		 B	:	in std_logic_vector(num_output_bits-1 downto 0);
		 O	:	out std_logic_vector(num_output_bits-1 downto 0));
end crossbar_model_adder;

architecture behavioural of crossbar_model_adder is

-- signals
	signal A_vec : std_logic_vector(0 downto 0);

begin

	A_vec(0) <= A;
	O <= std_logic_vector(resize(unsigned(A_vec), num_output_bits) + unsigned(B));

end behavioural;