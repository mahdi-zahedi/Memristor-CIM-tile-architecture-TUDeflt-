-----------------------------------------------------------------------
-- Project: CiM-Tile HW Design/implementation                        --
-- File	  : RS_Buffer.vhd                                            --
-- Author : Remon van Duijnen (R.F.J.vanDuijnen@student.tudelft.nl)  --
-- Version: 1.0														 --
----------------------------------------------------------------------- 

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity RS_buffer is
generic(max_datatype_size : integer;
		crossbar_rows 	  : integer;
		buffer_type       : integer -- 0 is shift, 1 is addressable
);
port(	i_clk 			: in std_logic;
		i_index		    : in std_logic_vector(integer(log2(real(crossbar_rows))) - 1 downto 0);
		i_RS 			: in std_logic_vector(max_datatype_size - 1 downto 0);
		write_enable 	: in std_logic;
		read_or_write 	: in std_logic;
		o_RS			: out std_logic_vector(crossbar_rows - 1 downto 0));
end RS_buffer;

architecture RS_buffer_arch of RS_buffer is

	-- constants
	constant log2_rows : integer := integer(log2(real(crossbar_rows)));

	-- components
	component D_FF port(
		D	: in std_logic;
		E	: in std_logic;
		clk : in std_logic;
		Q	: out std_logic 
		);
	end component;

	component MUX2 port( 
		  A : in std_logic;
		  B	: in std_logic;
		  sel : in std_logic;
		  O : out std_logic);
	end component;

	component decoder is
		generic(number_of_input_bits : integer
		);
		port (input  : in std_logic_vector(number_of_input_bits-1 downto 0);
			  output : out std_logic_vector((2 ** number_of_input_bits) - 1 downto 0)
		);
	end component;
		
-- internal signals
type RS_DFF_out_signal_array is array (crossbar_rows - 1 downto 0) of std_logic_vector(max_datatype_size - 1 downto 0);
type RS_MUX_out_signal_array is array (crossbar_rows - 1 downto 0) of std_logic_vector(max_datatype_size - 2 downto 0);
signal RS_DFF_out : RS_DFF_out_signal_array;
signal RS_MUX_out : RS_MUX_out_signal_array;
signal FF_E : std_logic_vector(crossbar_rows - 1 downto 0);
signal s_read_or_write : std_logic;

signal decoder_output : std_logic_vector(crossbar_rows - 1 downto 0);
signal i_final_col    : std_logic_vector(crossbar_rows - 1 downto 0);

-- Some assumptions:
-- The crossbar has more than 1 row
begin


G00:if (buffer_type = 0) generate -- shift version
		-- This is for max_datatype_size = 1, which will probably never be the case
RS0:	if (max_datatype_size = 1) generate

DFF0: 		D_FF port map(D=>i_RS(0), E=>write_enable, clk => i_clk, Q=>RS_DFF_out(crossbar_rows-1)(0)); -- top FF
			o_RS(crossbar_rows-1) <= RS_DFF_out(crossbar_rows-1)(0);

G01: 		for i in (crossbar_rows-2) downto 0 generate
DFF1:			D_FF port map(D=>RS_DFF_out(i+1)(0), E=>write_enable, clk => i_clk, Q=>RS_DFF_out(i)(0)); 
				o_RS(i) <= RS_DFF_out(i)(0);
			end generate;
		end generate;

		-- This is for max_datatype_size > 1
RS1:	if (max_datatype_size > 1) generate
DFF2:		D_FF port map(D=>i_RS(max_datatype_size - 1), E=>write_enable, clk => i_clk, Q=>RS_DFF_out(0)(max_datatype_size - 1)); -- top left-most FF
G11:		for j in max_datatype_size - 2 downto 0 generate -- remaining top row FFs/MUXs
MUX0:				MUX2 port map(A=>i_RS(j), B=>RS_DFF_out(0)(j+1), sel=>read_or_write, O=>RS_MUX_out(0)(j));	
DFF3:				D_FF port map(D=>RS_MUX_out(0)(j), E=>write_enable, clk => i_clk, Q=>RS_DFF_out(0)(j)); 
			end generate;
			o_RS(0) <= RS_DFF_out(0)(0);
			
G12:		for i in 1 to crossbar_rows-1 generate -- remaining rows
DFF4:			D_FF port map(D=>RS_DFF_out(i-1)(max_datatype_size - 1), E=>write_enable, clk => i_clk, Q=>RS_DFF_out(i)(max_datatype_size - 1)); -- left-most FF
G13:			for j in max_datatype_size - 2 downto 0 generate -- remaining row FFs/MUXs
MUX1:				MUX2 port map(A=>RS_DFF_out(i-1)(j), B=>RS_DFF_out(i)(j+1), sel=>read_or_write, O=>RS_MUX_out(i)(j));
DFF5:				D_FF port map(D=>RS_MUX_out(i)(j), E=>write_enable, clk => i_clk, Q=>RS_DFF_out(i)(j)); 
				end generate;
				o_RS(i) <= RS_DFF_out(i)(0);
			end generate;
		end generate;
	end generate;

G14:if (buffer_type = 1) generate -- addressable version

U0:		decoder generic map(number_of_input_bits => log2_rows)
				port map(input => i_index, output => decoder_output);

		s_read_or_write <= NOT read_or_write;

G15:		for i in 0 to crossbar_rows-1 generate
				FF_E(i) <= write_enable AND (decoder_output(i) OR s_read_or_write);
U1:				D_FF port map(D => i_RS(max_datatype_size - 1), E => FF_E(i), clk => i_clk, Q=>RS_DFF_out(i)(max_datatype_size - 1)); -- left-most FF
G16:			for j in max_datatype_size - 2 downto 0 generate -- remaining row FFs/MUXs
U2: 				MUX2 port map(A => i_RS(j), B => RS_DFF_out(i)(j+1), sel => s_read_or_write, O => RS_MUX_out(i)(j));
U3: 				D_FF port map(D => RS_MUX_out(i)(j), E => FF_E(i), clk => i_clk, Q => RS_DFF_out(i)(j)); 
				end generate;
				i_final_col(i) <= RS_DFF_out(i)(0);
U4:				D_FF port map(D => i_final_col(i), E => FF_E(i), clk => i_clk, Q=>o_RS(i)); -- right-most extra column
			end generate;

	end generate;

end RS_buffer_arch;
