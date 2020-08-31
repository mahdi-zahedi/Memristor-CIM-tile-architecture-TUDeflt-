-----------------------------------------------------------------------
-- Project: CiM-Tile HW Design/implementation                        --
-- File	  : SR_FF.vhd                                                --
-- Author : Remon van Duijnen (R.F.J.vanDuijnen@student.tudelft.nl)  --
-- Version: 1.0														 --
-----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity SR_FF is
	port(
		S, R, E	: in std_logic;
		Q	 	: out std_logic 
	);
end entity;

architecture SR_FF_arch of SR_FF is
	
	signal AND_1, AND_2, NOR_1, NOR_2 : std_logic;
	-- signal tmp : std_logic;
	
	
begin

	process(S, R, E)
	begin
		if(rising_edge(E)) then
		  if (S /= R) then
		      Q <= S;
		  elsif (S = '1' AND R = '1') then 
		      Q <= 'Z';
		  end if;
		
		
--			if(S='1' AND R='1') then
--				tmp <= 'Z';
--			elsif(S='1' AND R='0') then
--				tmp <= '1';
--			elsif(S='0' AND R='1') then
--				tmp <= '0';
--			elsif(S='0' AND R='0') then
--				tmp <= tmp;
--			end if;
--			Q <= tmp;
		end if;
	end process;
		
end architecture;