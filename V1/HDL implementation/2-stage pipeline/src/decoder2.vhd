-----------------------------------------------------------------------
-- Project: CiM-Tile HW Design/implementation                        --
-- File	  : decoder2.vhd                                             --
-- Author : Remon van Duijnen (R.F.J.vanDuijnen@student.tudelft.nl)  --
-- Version: 1.0														 --
----------------------------------------------------------------------- 

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity decoder2 is
	generic(number_of_input_bits : integer
	);
	port (input  : in std_logic_vector(number_of_input_bits-1 downto 0);
		  output : out std_logic_vector((2 ** number_of_input_bits) - 1 downto 0)
	);
end decoder2;

architecture behavioural of decoder2 is

begin

-- 1:2 decoder
D0: if (number_of_input_bits = 1) generate
		output(0) <= not input(0);
		output(1) <= input (0);
	end generate;

-- 2:4 decoder
D1: if (number_of_input_bits = 2) generate
		output(0) <= not input(0) and not input(1);
		output(1) <=     input(0) and not input(1);
		output(2) <= not input(0) and     input(1);
		output(3) <=     input(0) and     input(1);
	end generate;

-- 3:8 decoder
D2: if (number_of_input_bits = 3) generate
		output(0) <= not input(0) and not input(1) and not input(2);
		output(1) <=     input(0) and not input(1) and not input(2);
		output(2) <= not input(0) and     input(1) and not input(2);
		output(3) <=     input(0) and     input(1) and not input(2);
		output(4) <= not input(0) and not input(1) and     input(2);
		output(5) <=     input(0) and not input(1) and     input(2);
		output(6) <= not input(0) and     input(1) and     input(2);
		output(7) <=     input(0) and     input(1) and     input(2);
	end generate;

-- 4:16 decoder
D3: if (number_of_input_bits = 4) generate
		output(0)  <= not input(0) and not input(1) and not input(2) and not input(3);
		output(1)  <=     input(0) and not input(1) and not input(2) and not input(3);
		output(2)  <= not input(0) and     input(1) and not input(2) and not input(3);
		output(3)  <=     input(0) and     input(1) and not input(2) and not input(3);
		output(4)  <= not input(0) and not input(1) and     input(2) and not input(3);
		output(5)  <=     input(0) and not input(1) and     input(2) and not input(3);
		output(6)  <= not input(0) and     input(1) and     input(2) and not input(3);
		output(7)  <=     input(0) and     input(1) and     input(2) and not input(3);
		output(8)  <= not input(0) and not input(1) and not input(2) and     input(3);
		output(9)  <=     input(0) and not input(1) and not input(2) and     input(3);
		output(10) <= not input(0) and     input(1) and not input(2) and     input(3);
		output(11) <=     input(0) and     input(1) and not input(2) and     input(3);
		output(12) <= not input(0) and not input(1) and     input(2) and     input(3);
		output(13) <=     input(0) and not input(1) and     input(2) and     input(3);
		output(14) <= not input(0) and     input(1) and     input(2) and     input(3);
		output(15) <=     input(0) and     input(1) and     input(2) and     input(3);
	end generate;

-- 5:32 decoder
D4: if (number_of_input_bits = 5) generate
		output(0)   <= not input(0) and not input(1) and not input(2) and not input(3) and not input(4);
		output(1)   <=     input(0) and not input(1) and not input(2) and not input(3) and not input(4);
		output(2)   <= not input(0) and     input(1) and not input(2) and not input(3) and not input(4);
		output(3)   <=     input(0) and     input(1) and not input(2) and not input(3) and not input(4);
		output(4)   <= not input(0) and not input(1) and     input(2) and not input(3) and not input(4);
		output(5)   <=     input(0) and not input(1) and     input(2) and not input(3) and not input(4);
		output(6)   <= not input(0) and     input(1) and     input(2) and not input(3) and not input(4);
		output(7)   <=     input(0) and     input(1) and     input(2) and not input(3) and not input(4);
		output(8)   <= not input(0) and not input(1) and not input(2) and     input(3) and not input(4);
		output(9)   <=     input(0) and not input(1) and not input(2) and     input(3) and not input(4);
		output(10)  <= not input(0) and     input(1) and not input(2) and     input(3) and not input(4);
		output(11)  <=     input(0) and     input(1) and not input(2) and     input(3) and not input(4);
		output(12)  <= not input(0) and not input(1) and     input(2) and     input(3) and not input(4);
		output(13)  <=     input(0) and not input(1) and     input(2) and     input(3) and not input(4);
		output(14)  <= not input(0) and     input(1) and     input(2) and     input(3) and not input(4);
		output(15)  <=     input(0) and     input(1) and     input(2) and     input(3) and not input(4);
		output(16)  <= not input(0) and not input(1) and not input(2) and not input(3) and     input(4);
		output(17)  <=     input(0) and not input(1) and not input(2) and not input(3) and     input(4);
		output(18)  <= not input(0) and     input(1) and not input(2) and not input(3) and     input(4);
		output(19)  <=     input(0) and     input(1) and not input(2) and not input(3) and     input(4);
		output(20)  <= not input(0) and not input(1) and     input(2) and not input(3) and     input(4);
		output(21)  <=     input(0) and not input(1) and     input(2) and not input(3) and     input(4);
		output(22)  <= not input(0) and     input(1) and     input(2) and not input(3) and     input(4);
		output(23)  <=     input(0) and     input(1) and     input(2) and not input(3) and     input(4);
		output(24)  <= not input(0) and not input(1) and not input(2) and     input(3) and     input(4);
		output(25)  <=     input(0) and not input(1) and not input(2) and     input(3) and     input(4);
		output(26)  <= not input(0) and     input(1) and not input(2) and     input(3) and     input(4);
		output(27)  <=     input(0) and     input(1) and not input(2) and     input(3) and     input(4);
		output(28)  <= not input(0) and not input(1) and     input(2) and     input(3) and     input(4);
		output(29)  <=     input(0) and not input(1) and     input(2) and     input(3) and     input(4);
		output(30)  <= not input(0) and     input(1) and     input(2) and     input(3) and     input(4);
		output(31)  <=     input(0) and     input(1) and     input(2) and     input(3) and     input(4);
	end generate;

end behavioural;
