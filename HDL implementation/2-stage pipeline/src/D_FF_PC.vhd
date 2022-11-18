-----------------------------------------------------------------------
-- Project: CiM-Tile HW Design/implementation                        --
-- File	  : D_FF_PC.vhd                                              --
-- Author : Remon van Duijnen (R.F.J.vanDuijnen@student.tudelft.nl)  --
-- Version: 1.0														 --
-----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity D_FF_PC is
	port(
		D, E	: in std_logic;
		P, C	: in std_logic;
		clk		: in std_logic;
		Q	 	: out std_logic 
	);
end entity;

architecture behavioural of D_FF_PC is
	
begin

	process(clk, P, C)
	begin
		if(P = '0') then
			Q <= '1';
		elsif (C = '0') then
			Q <= '0';
		elsif(rising_edge(clk)) then
			if (E = '1') then
				Q <= D;
			end if;		
		end if;
	end process;
		
end behavioural;
