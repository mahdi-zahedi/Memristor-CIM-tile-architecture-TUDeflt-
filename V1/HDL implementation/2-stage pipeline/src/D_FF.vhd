-----------------------------------------------------------------------
-- Project: CiM-Tile HW Design/implementation                        --
-- File	  : D_FF.vhd                                                 --
-- Author : Remon van Duijnen (R.F.J.vanDuijnen@student.tudelft.nl)  --
-- Version: 1.0														 --
-----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity D_FF is
	port(
		D, E, clk : in std_logic;
		Q	 	  : out std_logic 
	);
end entity;

architecture D_FF_arch of D_FF is
	
begin

	process(clk)
	begin
		if(rising_edge(clk)) then
			if (E = '1') then
				Q <= D;
			end if;
		end if;
	end process;
		
end architecture;
