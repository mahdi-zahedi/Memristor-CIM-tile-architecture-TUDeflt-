-----------------------------------------------------------------------
-- Project: CiM-Tile HW Design/implementation                        --
-- File	  : D_latch.vhd                                              --
-- Author : Remon van Duijnen (R.F.J.vanDuijnen@student.tudelft.nl)  --
-- Version: 1.0														 --
-----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity D_latch is
	port(
		D, E	: in std_logic;
		Q	 	: out std_logic 
	);
end entity;

architecture behavioural of D_latch is
	
begin

	process(E, D)
	begin
		if (E = '1') then
			Q <= D;
		end if;
	end process;
		
end behavioural;
