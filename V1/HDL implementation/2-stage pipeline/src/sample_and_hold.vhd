-----------------------------------------------------------------------
-- Project: CiM-Tile HW Design/implementation                        --
-- File	  : sample_and_hold.vhd                                      --
-- Author : Remon van Duijnen (R.F.J.vanDuijnen@student.tudelft.nl)  --
-- Version: 1.0														 --
-----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity sample_and_hold is
	generic(crossbar_rows     : integer;
			crossbar_columns  : integer);
	port   (i_clk			  : in std_logic;
			i_crossbar_output : in std_logic_vector(crossbar_columns * integer(log2(real(crossbar_rows))) - 1 downto 0);
			i_DoS			  : in std_logic;

			o_sampled_data    : out std_logic_vector(crossbar_columns * integer(log2(real(crossbar_rows))) - 1 downto 0));
end sample_and_hold;

architecture behavioural of sample_and_hold is

-- constants
	constant bits_per_column : integer := integer(log2(real(crossbar_rows)));

-- components
	component D_FF port(
		D	: in std_logic;
		E	: in std_logic;
		clk : in std_logic;
		Q	: out std_logic 
		);
	end component;

-- signals

begin

G0:	for i in crossbar_columns-1 downto 0 generate
G1:		for j in bits_per_column-1 downto 0 generate
U0:			D_FF port map(D   => i_crossbar_output(i * bits_per_column + j), 
						  E   => i_DoS,
						  clk => i_clk, 
						  Q   => o_sampled_data(i * bits_per_column + j));
		end generate;
	end generate;

end behavioural;
