-----------------------------------------------------------------------
-- Project: CiM-Tile HW Design/implementation                        --
-- File	  : RS_mask.vhd                                              --
-- Author : Remon van Duijnen (R.F.J.vanDuijnen@student.tudelft.nl)  --
-- Version: 1.0														 --
-----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity RS_mask is
	generic(crossbar_rows  	: 	integer;
			RS_bandwidth 	: 	integer);
	port(	i_clk  			:	in std_logic;
			i_RS_data		:	in std_logic_vector(RS_bandwidth-1 downto 0);
			i_RS_index		:	in std_logic_vector(integer(ceil(log2(real(crossbar_rows/RS_bandwidth)))) - 1 downto 0);
			i_RS_write		:	in std_logic;
			i_RS_set		:	in std_logic;
			i_RS_clear		:	in std_logic;

			o_RS_mask		:	out std_logic_vector(crossbar_rows-1 downto 0));
end RS_mask;


architecture behavioural of RS_mask is

-- constants
	constant num_of_RS_blocks : integer := crossbar_rows / RS_bandwidth;
	constant log2_num_of_RS_blocks : integer := integer(log2(real(num_of_RS_blocks)));

-- components
	component D_FF port(
		D	: in std_logic;
		E	: in std_logic;
		clk	: in std_logic;
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
	signal RS_decoder_out	:	std_logic_vector(num_of_RS_blocks - 1 downto 0);
	signal RS_activation  	:	std_logic_vector(num_of_RS_blocks - 1 downto 0);
	signal RS_DEMUX_out  	:	std_logic_vector(crossbar_rows - 1 downto 0);
	signal mask_FF_D		:	std_logic_vector(crossbar_rows - 1 downto 0);

begin

U0: decoder generic map(number_of_input_bits => log2_num_of_RS_blocks)
			port map(input => i_RS_index, output => RS_decoder_out);

U1: DEMUX  generic map(num_in_bits => RS_bandwidth, num_out_blocks => num_of_RS_blocks)
		 port map(i_data => i_RS_data, i_sel => RS_decoder_out, o_data => RS_DEMUX_out);

G0: for i in num_of_RS_blocks - 1 downto 0 generate
		RS_activation(i) <= (RS_decoder_out(i) OR (i_RS_set OR i_RS_clear)) AND i_RS_write;
	end generate;

G1: for i in num_of_RS_blocks - 1 downto 0 generate
G2:		for j in RS_bandwidth - 1 downto 0 generate
			mask_FF_D(i*RS_bandwidth + j) <= (RS_DEMUX_out(i*RS_bandwidth + j) AND (NOT i_RS_clear)) OR i_RS_set;
		
DFF:		D_FF port map(D => mask_FF_D(i*RS_bandwidth + j), 
						  E => RS_activation(i), 
						  clk => i_clk,
						  Q => o_RS_mask(i*RS_bandwidth + j)); 	
		end generate;
	end generate;

end behavioural;