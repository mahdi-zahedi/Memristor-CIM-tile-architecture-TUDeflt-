-----------------------------------------------------------------------
-- Project: CiM-Tile HW Design/implementation                        --
-- File	  : WD_reg.vhd                                              --
-- Author : Remon van Duijnen (R.F.J.vanDuijnen@student.tudelft.nl)  --
-- Version: 1.0														 --
-----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use IEEE.math_real.all;

entity WD_reg is
generic(crossbar_columns :  integer;
		WD_bandwidth	 :  integer);
port(	i_clk			 :	in std_logic;
		i_WD			 :	in std_logic_vector(WD_bandwidth - 1 downto 0);
		i_index			 :	in std_logic_vector(integer(ceil(log2(real(crossbar_columns/WD_bandwidth)))) - 1 downto 0);
		i_WD_activate	 :	in std_logic;

		o_WD			 :	out std_logic_vector(crossbar_columns - 1 downto 0)
);

end WD_reg;

architecture behavioural of WD_reg is

-- constants
	constant num_of_blocks : integer := crossbar_columns / WD_bandwidth;
	constant log2_num_of_blocks : integer := integer(log2(real(num_of_blocks)));

-- components
	component D_FF port(
		D	: in std_logic;
		E	: in std_logic;
		clk : in std_logic;
		Q	 	: out std_logic 
		);
	end component;

	component decoder is
		generic(number_of_input_bits : integer
		);
		port (input  : in std_logic_vector(number_of_input_bits-1 downto 0);
			  output : out std_logic_vector((2 ** number_of_input_bits) - 1 downto 0)
		);
	end component;

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
	signal decoder_out	:	std_logic_vector(num_of_blocks - 1 downto 0);
	signal DEMUX_out  	:	std_logic_vector(crossbar_columns - 1 downto 0);
	signal activation  	:	std_logic_vector(num_of_blocks - 1 downto 0);

begin

U0: decoder generic map(number_of_input_bits => log2_num_of_blocks)
			port map(input => i_index, output => decoder_out);

U1: DEMUX  generic map(num_in_bits => WD_bandwidth, num_out_blocks => num_of_blocks)
		 port map(i_data => i_WD, i_sel => decoder_out, o_data => DEMUX_out);

G0: for i in num_of_blocks - 1 downto 0 generate
		activation(i) <= decoder_out(i) AND i_WD_activate;
	end generate;

G1: for i in num_of_blocks - 1 downto 0 generate
G2:		for j in WD_bandwidth - 1 downto 0 generate
DFF:		D_FF port map(D=>DEMUX_out(i*WD_bandwidth + j), clk => i_clk, E=>activation(i), Q=>o_WD(i*WD_bandwidth + j)); 	
		end generate;
	end generate;


end behavioural;




