-----------------------------------------------------------------------
-- Project: CiM-Tile HW Design/implementation                        --
-- File	  : DEMUX.vhd                                            		 --
-- Author : Remon van Duijnen (R.F.J.vanDuijnen@student.tudelft.nl)  --
-- Version: 1.0														 --
----------------------------------------------------------------------- 

library ieee;
use ieee.std_logic_1164.all;
use IEEE.math_real.all;

-- NOTE: This MUX uses an already decoded select signal. 
--       In the WD/RS mask, this decoded select is readily available

entity DEMUX is
generic( num_in_bits	:	integer;
		 num_out_blocks		:	integer
	);
port(	i_data	: in  std_logic_vector(num_in_bits - 1 downto 0);
	    i_sel	: in  std_logic_vector(num_out_blocks - 1 downto 0);
		o_data	: out std_logic_vector(num_in_bits * num_out_blocks - 1 downto 0)
	);
end DEMUX;

architecture behavioural of DEMUX is

begin

G0: for i in num_out_blocks - 1 downto 0 generate
G1: 	for j in  num_in_bits - 1 downto 0 generate
	
		o_data(i * num_in_bits + j) <= i_data(j) AND i_sel(i);
	
		end generate;
	end generate;

end behavioural;
