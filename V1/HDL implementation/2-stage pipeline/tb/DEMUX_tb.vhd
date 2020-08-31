-----------------------------------------------------------------------
-- Project: CiM-Tile HW Design/implementation                        --
-- File	  : DEMUX_tb.vhd                                         	 --
-- Author : Remon van Duijnen (R.F.J.vanDuijnen@student.tudelft.nl)  --
-- Version: 1.0														 --
----------------------------------------------------------------------- 

library ieee;
use ieee.std_logic_1164.all;


entity DEMUX_tb is
end DEMUX_tb;

architecture tb of DEMUX_tb is

-- constants
	constant num_in_bits : integer := 4;
	constant num_out_blocks : integer := 4;

-- components
	component DEMUX is
		generic( num_in_bits	:	integer;
				 num_out_blocks	:	integer
				);
		port(	i_data	: in  std_logic_vector(num_in_bits - 1 downto 0);
			    i_sel	: in  std_logic_vector(num_out_blocks - 1 downto 0);
				o_data	: out std_logic_vector(num_in_bits * num_out_blocks - 1 downto 0)
				);
	end component;

-- signals
	-- inputs
	signal input  : std_logic_vector(num_in_bits-1 downto 0);
	signal sel	  : std_logic_vector(num_out_blocks-1 downto 0);

	-- outputs
	signal output : std_logic_vector((num_out_blocks * num_in_bits) - 1 downto 0);


begin

uut: DEMUX generic map(num_in_bits => num_in_bits, num_out_blocks => num_out_blocks)
		 port map(i_data => input, i_sel => sel, o_data => output);

-- test for num_in_bits=4, num_out_block=4	
	input <= "0000",
			 "0001" after 10 ns,
			 "0010" after 20 ns,
			 "0011" after 30 ns,
			 "0100" after 40 ns,
			 "0101" after 50 ns,
			 "0110" after 60 ns,
			 "0111" after 70 ns,
			 "1000" after 80 ns,
			 "1001" after 90 ns;

	sel <=   "0001",
			 "0010" after 25 ns,
			 "0100" after 50 ns,
			 "1000" after 75 ns;

end tb;