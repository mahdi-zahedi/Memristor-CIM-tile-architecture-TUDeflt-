-----------------------------------------------------------------------
-- Project: CiM-Tile HW Design/implementation                        --
-- File	  : WD_mask.vhd                                              --
-- Author : Remon van Duijnen (R.F.J.vanDuijnen@student.tudelft.nl)  --
-- Version: 1.0														 --
-----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity WD_mask is
	generic(crossbar_columns	:	integer;
			WD_bandwidth		:	integer);
	port(	i_clk				:   in std_logic;
			i_WD_data			:	in std_logic_vector(WD_bandwidth-1 downto 0);
			i_WD_index			:	in std_logic_vector(integer(ceil(log2(real(crossbar_columns/WD_bandwidth)))) - 1 downto 0);
			i_WD_write			:	in std_logic;
			i_WD_set			:	in std_logic;
			i_WD_clear			:	in std_logic;

			o_WD_mask			:	out std_logic_vector(crossbar_columns-1 downto 0));
end WD_mask;

architecture behavioural of WD_mask is

-- constants
	constant num_of_WD_blocks : integer := crossbar_columns / WD_bandwidth;
	constant log2_num_of_WD_blocks : integer := integer(log2(real(num_of_WD_blocks)));

-- components
	component D_FF port(
		D	: in std_logic;
		E	: in std_logic;
		clk : in std_logic;
		Q	: out std_logic 
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
	signal WD_decoder_out	:	std_logic_vector(num_of_WD_blocks - 1 downto 0);
	signal WD_activation  	:	std_logic_vector(num_of_WD_blocks - 1 downto 0);
	signal WD_DEMUX_out  	:	std_logic_vector(crossbar_columns - 1 downto 0);
	signal mask_FF_D		:	std_logic_vector(crossbar_columns - 1 downto 0);

begin

U0: decoder generic map(number_of_input_bits => log2_num_of_WD_blocks)
			port map(input => i_WD_index, output => WD_decoder_out);

U1: DEMUX  generic map(num_in_bits => WD_bandwidth, num_out_blocks => num_of_WD_blocks)
		 port map(i_data => i_WD_data, i_sel => WD_decoder_out, o_data => WD_DEMUX_out);

G0: for i in num_of_WD_blocks - 1 downto 0 generate
		WD_activation(i) <= (WD_decoder_out(i) OR (i_WD_set OR i_WD_clear)) AND i_WD_write;
	end generate;

G1: for i in num_of_WD_blocks - 1 downto 0 generate
G2:		for j in WD_bandwidth - 1 downto 0 generate
		
			mask_FF_D(i*WD_bandwidth + j) <= (WD_DEMUX_out(i*WD_bandwidth + j) AND (NOT i_WD_clear)) OR i_WD_set;

DFF:		D_FF port map(D   => mask_FF_D(i*WD_bandwidth + j), 
					      E   => WD_activation(i), 
						  clk => i_clk,
						  Q   => o_WD_mask(i*WD_bandwidth + j)); 	
		end generate;
	end generate;

end behavioural;
