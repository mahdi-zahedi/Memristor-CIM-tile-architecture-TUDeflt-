-----------------------------------------------------------------------
-- Project: CiM-Tile HW Design/implementation                        --
-- File	  : RS_select.vhd                                            --
-- Author : Remon van Duijnen (R.F.J.vanDuijnen@student.tudelft.nl)  --
-- Version: 1.0														 --
-----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity RS_select is
	generic(crossbar_rows  	: 	integer;
			RS_bandwidth	:	integer);
	port (	i_clk			: 	in std_logic;
			i_RS_buffer		:	in std_logic_vector(crossbar_rows-1 downto 0);
		  	i_RS_data	 	:	in std_logic_vector(RS_bandwidth -1 downto 0);
			i_RS_index		:	in std_logic_vector(integer(ceil(log2(real(crossbar_rows/RS_bandwidth)))) - 1 downto 0);
		  	i_RS_write		:	in std_logic;
			i_RS_set		:	in std_logic;
			i_RS_clear		:	in std_logic;
			i_FS 			:   in std_logic_vector(3 downto 0);
			
		  	o_RS_masked		:	out std_logic_vector(crossbar_rows-1 downto 0));
end RS_select;

architecture behavioural of RS_select is

-- constants

-- components
	component RS_mask is
		generic(crossbar_rows  	: 	integer;
				RS_bandwidth 	: 	integer);
		port(	i_clk			:	in std_logic;
				i_RS_data		:	in std_logic_vector(RS_bandwidth-1 downto 0);
				i_RS_index		:	in std_logic_vector(integer(ceil(log2(real(crossbar_rows/RS_bandwidth)))) - 1 downto 0);
				i_RS_write		:	in std_logic;
				i_RS_set		:	in std_logic;
				i_RS_clear		:	in std_logic;
	
				o_RS_mask		:	out std_logic_vector(crossbar_rows-1 downto 0));
	end component;

-- signals
	signal RS_mask_out	  :	std_logic_vector(crossbar_rows-1 downto 0);
	signal RSi_OR_RSb	  :	std_logic_vector(crossbar_rows-1 downto 0);
	signal s_RS_immediate : std_logic;

begin

U0:	RS_mask generic map(crossbar_rows => crossbar_rows, RS_bandwidth => RS_bandwidth)
			port map(i_clk 		=> i_clk,
					 i_RS_data  => i_RS_data,
					 i_RS_index => i_RS_index,
					 i_RS_write => i_RS_write,
					 i_RS_set   => i_RS_set,
					 i_RS_clear => i_RS_clear,
					 o_RS_mask  => RS_mask_out);

	s_RS_immediate <= NOT ((    i_FS(2)) AND (    i_FS(1)) AND (    i_FS(0))); -- all except VMM

G0:	for i in crossbar_rows - 1 downto 0 generate
		RSi_OR_RSb(i)  <= i_RS_buffer(i) OR s_RS_immediate;
		o_RS_masked(i) <= RS_mask_out(i) AND RSi_OR_RSb(i);
	end generate;

end behavioural;
