-----------------------------------------------------------------------
-- Project: CiM-Tile HW Design/implementation                        --
-- File	  : crossbar_model_counter.vhd                               --
-- Author : Remon van Duijnen (R.F.J.vanDuijnen@student.tudelft.nl)  --
-- Version: 1.0														 --
-----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity crossbar_model_counter is
	port( i_set_val : in std_logic_vector(8 downto 0);
	 	  i_set 	: in std_logic;
		  clk 		: in std_logic;
		  clr 		: in std_logic;

		  o 		: out std_logic_vector(8 downto 0)
);
end crossbar_model_counter;

architecture behavioural of crossbar_model_counter is

	signal tmp : std_logic_vector(8 downto 0);

begin

	process(clk, clr)
	begin
		if(clr = '1') then
			tmp <= "000000000";
		elsif(rising_edge(clk)) then
			if (i_set = '1') then
				tmp <= i_set_val;
			elsif(tmp /= "000000000") then
			 	tmp <= tmp - 1;
			end if;
			
		end if;
	end process;
	o <= tmp;
end behavioural;