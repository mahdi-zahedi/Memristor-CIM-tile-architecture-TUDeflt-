-----------------------------------------------------------------------
-- Project: CiM-Tile HW Design/implementation                        --
-- File	  : crossbar_array_model.vhd                                 --
-- Author : Remon van Duijnen (R.F.J.vanDuijnen@student.tudelft.nl)  --
-- Version: 1.0														 --
-----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;


entity crossbar_array_model is
	generic(results_xplore   :  integer;
	        crossbar_rows	 :	integer;
			crossbar_columns :	integer);
	port(i_clk          :   in std_logic;
		 i_WD			:	in std_logic_vector(crossbar_columns-1 downto 0);
		 i_WDS			:	in std_logic_vector(crossbar_columns-1 downto 0);
		 i_RS			:	in std_logic_vector(crossbar_rows-1 downto 0);
		 i_DoA			:	in std_logic;
		 i_store		:	in std_logic;
		 i_WE			:	in std_logic;
		 i_W_S			:	in std_logic;

		 o_array_inter	:	out std_logic_vector(crossbar_columns * integer(log2(real(crossbar_rows))) - 1 downto 0);
		 o_array_AND	:	out std_logic_vector(crossbar_columns-1 downto 0);

		-- test outputs
		test_array_FF_out_signals	:	out std_logic_vector(crossbar_rows * crossbar_columns - 1  downto 0));
end crossbar_array_model;

architecture behavioural of crossbar_array_model is

-- constants
	constant num_output_bits	:	integer	:= integer(log2(real(crossbar_rows)));

-- components
	component D_FF port(
		D	: in std_logic;
		E	: in std_logic;
		clk : in std_logic;
		Q	: out std_logic 
		);
	end component;

	component D_FF_PC port(
		D	: in std_logic;
		E	: in std_logic;
		P	: in std_logic;
		C	: in std_logic;
		clk : in std_logic;
		Q	: out std_logic 
		);
	end component;

	component MUX2 port( 
		  A   : in std_logic;
		  B	  : in std_logic;
		  sel : in std_logic;
		  O   : out std_logic);
	end component;

	component crossbar_model_adder is
		generic(num_output_bits	:	integer);
		port(A	:	in std_logic;
			 B	:	in std_logic_vector(num_output_bits-1 downto 0);
			 O	:	out std_logic_vector(num_output_bits-1 downto 0));
	end component;

-- signals
	type   crossbar_array_signals is array (crossbar_rows    - 1 downto 0) of std_logic_vector(crossbar_columns - 1 downto 0);
	type   o_array_signals        is array (crossbar_columns - 1 downto 0) of std_logic_vector(num_output_bits - 1 downto 0);
	
	signal cell_write_activation :  crossbar_array_signals;
	signal cell_output			 :	crossbar_array_signals;
	signal shift_reg_write_in	 :	crossbar_array_signals;
	signal shift_mux_out		 :	crossbar_array_signals;
	signal shift_reg_out		 :	crossbar_array_signals;
	signal RS_shift_out			 :	std_logic_vector(crossbar_rows-1 downto 0);
	signal RS_MUX_out			 :	std_logic_vector(crossbar_rows-1 downto 0);
	signal col_AND_op_out		 :	std_logic_vector(crossbar_rows-1 downto 0);
	signal DoA_OR_WE			 :	std_logic;
	signal adder_out			 :  o_array_signals;
	signal o_array_inter_sig	 :  o_array_signals;
	signal o_array_AND_sig		 :	std_logic_vector(crossbar_columns-1 downto 0);	
	signal NOT_DoA				 :  std_logic;

begin

	NOT_DoA <= NOT i_DoA;

-- RS shift regsiter ----------------

		
		DoA_OR_WE <= i_DoA OR i_WE; 

		--first row (shift in '0' through mux)
MX0:	MUX2 port map(A => i_RS(0), B => '0', sel => i_W_S, O => RS_MUX_out(0));
FF0:	D_FF port map(D => RS_MUX_out(0), E => DoA_OR_WE, clk => i_clk, Q => RS_shift_out(0)); 

G0:		for i in 1 to crossbar_rows-1 generate
MX1:		MUX2 port map(A => i_RS(i), B => RS_shift_out(i-1), sel => i_W_S, O => RS_MUX_out(i));
FF1:		D_FF port map(D => RS_MUX_out(i), E => DoA_OR_WE, clk => i_clk, Q => RS_shift_out(i));
		end generate;
-------------------------------------
-- Crossbar cells -------------------
G99: if results_xplore = 0 generate ---------------------------------------------------------------------------- use model

G1: for i in 0 to crossbar_rows-1 generate
G2:		for j in 0 to crossbar_columns-1 generate
			cell_write_activation(i)(j) <= i_DoA AND i_RS(i) AND i_WDS(j) AND i_store;
FF2:		D_FF port map(D => i_WD(j), E => cell_write_activation(i)(j), clk => i_clk, Q => cell_output(i)(j));		
		end generate;
	end generate;
	

-------------------------------------
-- Column shift register ------------
	
	-- first row (shift in '0' through MUX)
G3:	for j in 0 to crossbar_columns-1 generate
		shift_reg_write_in(0)(j) <= cell_output(0)(j) AND i_RS(0);
MX2:	MUX2 port map(A => shift_reg_write_in(0)(j), B => '0', sel => i_W_S, O => shift_MUX_out(0)(j));
FF3:	D_FF port map(D => shift_MUX_out(0)(j), E=> DoA_OR_WE, clk => i_clk, Q => shift_reg_out(0)(j));
	end generate;

	-- other rows
G4: for i in 1 to crossbar_rows-1 generate
G5:		for j in 0 to crossbar_columns-1 generate
			shift_reg_write_in(i)(j) <= cell_output(i)(j) AND i_RS(i);
MX2:		MUX2 port map(A => shift_reg_write_in(i)(j), B => shift_reg_out(i-1)(j), sel => i_W_S, O => shift_MUX_out(i)(j));
FF4:		D_FF port map(D => shift_MUX_out(i)(j), E=> DoA_OR_WE, clk => i_clk, Q => shift_reg_out(i)(j));	
		end generate;
	end generate;

-------------------------------------
-- Addition per column --------------

G7: for j in 0 to crossbar_columns -1 generate
A0:		crossbar_model_adder generic map(num_output_bits => num_output_bits) 
							 port map   (A => shift_reg_out(crossbar_rows-1)(j), B => o_array_inter_sig(j), O => adder_out(j));
G8:		for k in 0 to num_output_bits - 1 generate
FF6:			D_FF_PC port map(D => adder_out(j)(k), E => i_WE, P => '1', C => NOT_DoA, clk => i_clk, Q => o_array_inter_sig(j)(k));
		end generate;
	end generate;

G9: for j in 0 to crossbar_columns -1 generate
G10:	for k in 0 to num_output_bits - 1 generate
			o_array_inter(j*num_output_bits + k) <= o_array_inter_sig(j)(k);
		end generate;
	end generate;
	
end generate; ---------------------------------------------------------------------------- END use model

G98: if results_xplore = 1 generate ----------------------------------------------------- DONT use model

G97:    for i in crossbar_columns - 1 downto 0 generate
            cell_write_activation(0)(i) <= i_DoA AND i_WDS(i) AND i_store;
FF99:		D_FF port map(D => i_WD(i), E => cell_write_activation(0)(i), clk => i_clk, Q => cell_output(0)(i));

G96:        for j in num_output_bits - 1 downto 0 generate
                o_array_inter(i*num_output_bits + j) <= cell_output(0)(i);
            end generate;

        end generate;

     end generate; ----------------------------------------------------------------------- END DONT use model

-------------------------------------
-- AND operation reg per column------

G6: for j in 0 to crossbar_columns-1 generate
		col_AND_op_out(j) <= ((NOT shift_reg_out(crossbar_rows-1)(j)) AND RS_shift_out(crossbar_rows-1)) OR o_array_AND_sig(j);
FF5:	D_FF_PC port map(D => col_AND_op_out(j), E => i_WE, P => '1', C => NOT_DoA, clk => i_clk, Q => o_array_AND_sig(j));
		o_array_AND(j) <= NOT o_array_AND_sig(j);
	end generate;

-------------------------------------
-- OR operation reg per column ------

-- to be written if required

-------------------------------------
-- test

G11: for j in 0 to crossbar_rows -1 generate
G12:	for k in 0 to crossbar_columns - 1 generate
			test_array_FF_out_signals(j*crossbar_columns + k) <= cell_output(j)(k);
		end generate;
	end generate;

end behavioural;
