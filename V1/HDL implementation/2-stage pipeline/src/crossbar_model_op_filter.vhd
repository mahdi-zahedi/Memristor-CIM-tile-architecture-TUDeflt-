-- Project: CiM-Tile HW Design/implementation                        --
-- File	  : crossbar_model_op_filter.vhd                             --
-- Author : Remon van Duijnen (R.F.J.vanDuijnen@student.tudelft.nl)  --
-- Version: 1.0														 --
-----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity crossbar_model_op_filter is
	generic(crossbar_rows    : integer;
			crossbar_columns : integer);
	port   (i_array_inter   : in std_logic_vector(crossbar_columns * integer(log2(real(crossbar_rows))) - 1 downto 0);
			i_array_AND	 	: in std_logic_vector(crossbar_columns - 1 downto 0);
		    i_all_columns   : in std_logic;
			i_mux_select	: in std_logic_vector(1 downto 0);
	
			o_crossbar_output : out std_logic_vector(crossbar_columns * integer(log2(real(crossbar_rows))) - 1 downto 0)
);
end crossbar_model_op_filter;


architecture behavioural of crossbar_model_op_filter is

-- constants
	constant bits_per_column : integer := integer(log2(real(crossbar_rows)));

-- components
	component MUX4 is
		port(A, B, C, D : in  std_logic;
			 sel		: in std_logic_vector(1 downto 0);
			 O			: out std_logic);
	end component;

-- signals
	type   OR_signal_type is array (crossbar_columns - 1 downto 0) of std_logic_vector(bits_per_column - 2 downto 0);

	signal OR_signals : OR_signal_type;

begin

G0:	for i in crossbar_columns-1 downto 0 generate

G1:		for j in bits_per_column-1 downto 1 generate
			o_crossbar_output(i * bits_per_column + j) <= i_array_inter(i * bits_per_column + j) AND i_all_columns; 
		end generate;

		-- OR output generation. This can also be done sequentially like the AND output if required for whatever reason.
		OR_signals(i)(0) <= i_array_inter(i * bits_per_column + 0) OR i_array_inter(i * bits_per_column + 1); -- first OR
G2:		for j in 1 to bits_per_column-2 generate -- remaining OR gates
			OR_signals(i)(j) <= OR_signals(i)(j-1) OR i_array_inter(i * bits_per_column + j+1);
		end generate;

		-- LSB select for different operations
U0:		MUX4 port map(A => i_array_AND(i),
					  B => OR_signals(i)(bits_per_column - 2),
					  C => i_array_inter(i * bits_per_column + 0),
					  D => i_array_inter(i * bits_per_column + 0),
					  sel => i_mux_select,
					  O => o_crossbar_output(i * bits_per_column + 0));

	end generate;

end behavioural;