-----------------------------------------------------------------------
-- Project: CiM-Tile HW Design/implementation                        --
-- File	  : PC_LUT.vhd                                               --
-- Author : Remon van Duijnen (R.F.J.vanDuijnen@student.tudelft.nl)  --
-- Version: 1.0														 --
-----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity PC_LUT is
generic(val_00   : integer;
		val_01   : integer;
		val_10   : integer;
		val_11   : integer;
		bit_size : integer);
port   (sel : in  std_logic_vector(1 downto 0);
		O   : out std_logic_vector(bit_size - 1 downto 0));
end PC_LUT;

architecture behavioural of PC_LUT is

begin
	
	process(sel) 
	begin
		if (sel = "00") then
			O <= std_logic_vector(to_unsigned(val_00, bit_size));
		elsif (sel = "01") then
			O <= std_logic_vector(to_unsigned(val_01, bit_size));
		elsif (sel = "10") then
			O <= std_logic_vector(to_unsigned(val_10, bit_size));
		elsif (sel = "11") then
			O <= std_logic_vector(to_unsigned(val_11, bit_size));
		else
		    O <= std_logic_vector(to_unsigned(val_11, bit_size)); 
		end if;
	end process; 

end behavioural;
