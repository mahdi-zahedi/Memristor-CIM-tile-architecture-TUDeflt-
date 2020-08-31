-----------------------------------------------------------------------
-- Project: CiM-Tile HW Design/implementation                        --
-- File	  : WD_select.vhd                                            --
-- Author : Remon van Duijnen (R.F.J.vanDuijnen@student.tudelft.nl)  --
-- Version: 1.0														 --
-----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity WD_select is
	generic(crossbar_columns	:	integer;
			WD_bandwidth		:	integer);
	port(	i_clk				:	in std_logic;
			i_WD_reg			:	in std_logic_vector(crossbar_columns-1 downto 0);
			i_WD_data			:	in std_logic_vector(WD_bandwidth-1 downto 0);
			i_WD_index			:	in std_logic_vector(integer(ceil(log2(real(crossbar_columns/WD_bandwidth)))) - 1 downto 0);
			i_WD_write			:	in std_logic;
			i_WD_set			:	in std_logic;
			i_WD_clear			:	in std_logic;

			o_WDS_reg			:   out std_logic_vector(crossbar_columns-1 downto 0);
			o_WD_masked			:	out std_logic_vector(crossbar_columns-1 downto 0));
end WD_select;

architecture behavioural of WD_select is

-- constants

-- components
	component WD_mask is
		generic(crossbar_columns	:	integer;
				WD_bandwidth		:	integer);
		port(	i_clk				:   in std_logic;
				i_WD_data			:	in std_logic_vector(WD_bandwidth-1 downto 0);
				i_WD_index			:	in std_logic_vector(integer(ceil(log2(real(crossbar_columns/WD_bandwidth)))) - 1 downto 0);
				i_WD_write			:	in std_logic;
				i_WD_set			:	in std_logic;
				i_WD_clear			:	in std_logic;
	
				o_WD_mask			:	out std_logic_vector(crossbar_columns-1 downto 0));
	end component;

-- signals
	signal WD_mask_out	:	std_logic_vector(crossbar_columns-1 downto 0);

begin

U0:	WD_mask generic map(crossbar_columns => crossbar_columns, WD_bandwidth => WD_bandwidth)
			port map(i_clk 		=> i_clk,
					 i_WD_data  => i_WD_data,
					 i_WD_index => i_WD_index,
					 i_WD_write => i_WD_write,
					 i_WD_set   => i_WD_set,
					 i_WD_clear => i_WD_clear,
					 o_WD_mask  => WD_mask_out);

	o_WDS_reg <= WD_mask_out;

G1:	for i in crossbar_columns - 1 downto 0 generate
		o_WD_masked(i)	<=	i_WD_reg(i) AND WD_mask_out(i);
	end generate; 

end behavioural;
