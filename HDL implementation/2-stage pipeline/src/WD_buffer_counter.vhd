-----------------------------------------------------------------------
-- Project: CiM-Tile HW Design/implementation                        --
-- File	  : WD_buffer_counter.vhd                                    --
-- Author : Remon van Duijnen (R.F.J.vanDuijnen@student.tudelft.nl)  --
-- Version: 1.0														 --
-----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity WD_buffer_counter is
	generic(bit_size : integer);
	port( up_down 	: in std_logic;
		  E         : in std_logic;
		  clk 		: in std_logic;
		  clr 		: in std_logic;

		  o 		: out std_logic_vector(bit_size - 1 downto 0)
);
end WD_buffer_counter;

architecture behavioural of WD_buffer_counter is

	signal tmp : std_logic_vector(bit_size - 1 downto 0);

begin

	process(clk, clr)
	begin
		if(clr = '1') then
			tmp <= std_logic_vector(to_unsigned(0, bit_size));
		elsif(rising_edge(clk)) then
			if (E = '1') then
				if (up_down = '1') then
					tmp <= tmp + 1;
				else
					tmp <= tmp - 1;
				end if;
			else
				tmp <= tmp;	
			end if;			
		end if;
	end process;

	o <= tmp;

end behavioural;
