-----------------------------------------------------------------------
-- Project: CiM-Tile HW Design/implementation                        --
-- File	  : logic_read_vrf_reg.vhd                                   --
-- Author : Remon van Duijnen (R.F.J.vanDuijnen@student.tudelft.nl)  --
-- Version: 1.0														 --
-----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity logic_read_vrf_reg is
	generic(crossbar_columns : integer;
		    num_ADCs		 : integer);
	port(i_ADC_bit_0 : std_logic_vector(num_ADCs - 1 downto 0);
		 i_CS_index	     : in std_logic_vector(integer(log2(real(crossbar_columns/num_ADCs))) - 1 downto 0);
		 o_logic_read_vrf_reg_out : std_logic_vector(crossbar_columns - 1 downto 0));
end logic_read_vrf_reg;

architecture behavioural of logic_read_vrf_reg is


begin



end behavioural;