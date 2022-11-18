-----------------------------------------------------------------------
-- Project: CiM-Tile HW Design/implementation                        --
-- File	  : addition_per_ADC.vhd                                     --
-- Author : Remon van Duijnen (R.F.J.vanDuijnen@student.tudelft.nl)  --
-- Version: 1.0														 --
-----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
use ieee.numeric_std.all;

entity addition_per_ADC is
	generic(crossbar_rows     : integer;
			crossbar_columns  : integer;
			num_ADCs          : integer;
			max_datatype_size : integer);
	port   (i_clk		   : in std_logic;
			i_ADC_output   : in std_logic_vector(integer(log2(real(crossbar_rows))) - 1 downto 0);
			i_activate     : in std_logic;
			i_CS_index	   : in std_logic_vector(integer(log2(real(crossbar_columns/num_ADCs))) - 1 downto 0);
			i_LS		   : in std_logic;
			i_IADD	       : in std_logic;
			i_reg_clear    : in std_logic;
			i_datatype_sel : in std_logic_vector(integer(log2(real(max_datatype_size/8))) -1 downto 0);

			o_R4_temp      : out std_logic_vector(2*max_datatype_size + integer(log2(real(crossbar_rows))) - 1 downto 0);
			
			-- testing outputs
			o_R2_mux_in  : out std_logic_vector(max_datatype_size + integer(log2(real(crossbar_rows))) - 1 downto 7);
			o_R2_mux_sel : out std_logic_vector(max_datatype_size + integer(log2(real(crossbar_rows))) - 1 downto 7);
			o_R4_mux_in	 : out std_logic_vector(2 * max_datatype_size + integer(log2(real(crossbar_rows))) - 1 downto 7);
			o_R4_mux_sel : out std_logic_vector(2 * max_datatype_size + integer(log2(real(crossbar_rows))) - 1 downto 7);
			o_stage_demux_1    : out std_logic_vector(integer(log2(real(crossbar_rows))) - 1 downto 0);
			o_stage_demux_2    : out std_logic_vector(integer(log2(real(crossbar_rows))) - 1 downto 0);
			o_R2_demux	 : out std_logic_vector(max_datatype_size / 8 * (integer(log2(real(crossbar_rows))) + 1) - 1 downto 0);
			o_R4_demux	 : out std_logic_vector(max_datatype_size / 8 * (max_datatype_size + integer(log2(real(crossbar_rows))) + 1) - 1 downto 0);
			o_R1_temp    : out std_logic_vector(integer(log2(real(crossbar_rows))) - 1 downto 0);
			o_R2_temp	 : out std_logic_vector(max_datatype_size + integer(log2(real(crossbar_rows))) - 1 downto 0 );
			o_R3_temp	 : out std_logic_vector(max_datatype_size + integer(log2(real(crossbar_rows))) - 1 downto 0));
end addition_per_ADC;

architecture behavioural of addition_per_ADC is

-- constants
	constant bits_per_column : integer := integer(log2(real(crossbar_rows)));
	constant cols_per_ADC : integer := crossbar_columns / num_ADCs;
	constant num_datatypes : integer := max_datatype_size / 8;
	constant R4_demux_in_bits : integer := max_datatype_size + bits_per_column + 1;

-- components
	component adder is
		generic(size : integer);
		port   (A : in std_logic_vector(size - 1 downto 0);
				B : in std_logic_vector(size - 1 downto 0);
	
				O : out std_logic_vector(size - 1 downto 0));
	end component;

	component adder2 is
		generic(size : integer);
		port   (A : in std_logic_vector(size - 1 downto 0);
				B : in std_logic_vector(size - 1 downto 0);
	
				O : out std_logic_vector(size - 0 downto 0));
	end component;

	component MUX2 is
		port( A : in std_logic;
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

	component DEMUX is
	generic( num_in_bits	:	integer;
			 num_out_blocks		:	integer
		);
	port(	i_data	: in  std_logic_vector(num_in_bits - 1 downto 0);
		    i_sel	: in  std_logic_vector(num_out_blocks - 1 downto 0);
			o_data	: out std_logic_vector(num_in_bits * num_out_blocks - 1 downto 0)
		);
	end component;

	component MUX is
	generic( num_in_columns	  :	integer;
			 bits_per_column  :	integer
		);
	port(	i_data	: in  std_logic_vector(num_in_columns * bits_per_column - 1 downto 0);
		    i_sel	: in  std_logic_vector(num_in_columns - 1 downto 0);
			o_data	: out std_logic_vector(bits_per_column - 1 downto 0)
		);
	end component;

	component D_FF port(
		D	: in std_logic;
		E	: in std_logic;
		clk : in std_logic;
		Q	: out std_logic 
		);
	end component;

-- signals
	signal s_reg_clear : std_logic;
	-- first stage
	type   columns_by_bits is array (cols_per_ADC - 1 downto 0) of std_logic_vector(bits_per_column - 1 downto 0);
	type   two_by_bits is array (1 downto 0) of std_logic_vector(bits_per_column - 1 downto 0);

	signal primary_adder_output			: std_logic_vector(bits_per_column - 1 downto 0);
	signal primary_select				: std_logic_vector(2 ** integer(log2(real(cols_per_ADC))) - 1 downto 0);	
	signal primary_demux_output			: std_logic_vector(cols_per_ADC * bits_per_column -1 downto 0);
	signal primary_demux_out_array		: columns_by_bits;
	signal column_FF_D		            : columns_by_bits;
	signal column_FF_E					: std_logic_vector(cols_per_ADC - 1 downto 0);
	signal column_FF_out_array			: columns_by_bits;
	signal column_FF_out				: std_logic_vector(cols_per_ADC * bits_per_column -1 downto 0);
	signal primary_mux_output			: std_logic_vector(bits_per_column -1 downto 0);
	signal mux_to_secondary_out			: std_logic_vector(2 * bits_per_column -1 downto 0);
	signal mux_to_secondary_out_array	: two_by_bits;
	signal s_LS							: std_logic_vector(0 downto 0);
	signal s_LS_decoded					: std_logic_vector(1 downto 0);
	-- second stage
	signal secondary_adder_output		: std_logic_vector(bits_per_column - 0 downto 0);
	signal R1_temp_D		            : std_logic_vector(bits_per_column - 0 downto 0);
	signal R1_temp_out					: std_logic_vector(bits_per_column - 1 downto 0);
	signal R1_temp_E, R2_temp_E			: std_logic;
	signal R2_temp_out					: std_logic_vector(max_datatype_size + bits_per_column - 1 downto 0);
	signal R2_temp_D					: std_logic_vector(max_datatype_size + bits_per_column - 1 downto 0);	
	signal R2_mux_in					: std_logic_vector(max_datatype_size + bits_per_column - 1 downto 7);
	signal R2_mux_out					: std_logic_vector(max_datatype_size + bits_per_column - 1 downto 7);
	signal R2_mux_D    					: std_logic_vector(max_datatype_size + bits_per_column - 1 downto 7);
	signal R2_mux_sel					: std_logic_vector(max_datatype_size + bits_per_column - 1 downto 7);
	signal R2_demux_out					: std_logic_vector(num_datatypes * (bits_per_column + 1) - 1 downto 0);
	signal datatype_sel_decoded		    : std_logic_vector(num_datatypes - 1 downto 0);
	

	-- third stage
	signal third_adder_output			: std_logic_vector(max_datatype_size + bits_per_column - 0 downto 0);
	signal R3_temp_D         			: std_logic_vector(max_datatype_size + bits_per_column - 0 downto 0);
	signal R3_temp_E, R4_temp_E			: std_logic;
	signal R4_temp_D 					: std_logic_vector(2 * max_datatype_size + bits_per_column - 1 downto 0);
	signal R3_temp_out					: std_logic_vector(max_datatype_size + bits_per_column - 1 downto 0);
	signal R4_demux_out					: std_logic_vector(max_datatype_size / 8 * (max_datatype_size + bits_per_column + 1) - 1 downto 0);
	signal R4_mux_in					: std_logic_vector(2 * max_datatype_size + bits_per_column - 1 downto 7);
	signal R4_mux_sel					: std_logic_vector(2 * max_datatype_size + bits_per_column - 1 downto 7);
	signal R4_mux_out					: std_logic_vector(2 * max_datatype_size + bits_per_column - 1 downto 7);
	signal R4_temp_out					: std_logic_vector(2 * max_datatype_size + bits_per_column - 1 downto 0);
	

begin

	s_reg_clear <= NOT i_reg_clear;

--=========================== FIRST STAGE ============================================
-- first adder
U0: adder generic map(size => bits_per_column)
		  port map(A => i_ADC_output,
				   B => primary_mux_output,
				   O => primary_adder_output);

-- primary demux

U1: decoder generic map(number_of_input_bits => integer(log2(real(cols_per_ADC))))
			port map   (input  => i_CS_index, 
						output => primary_select);

U2: DEMUX generic map(num_in_bits => bits_per_column, num_out_blocks => cols_per_ADC)
		  port map   (i_data => mux_to_secondary_out_array(0),
					  i_sel  => primary_select,
					  o_data => primary_demux_output);	

G0:	for i in cols_per_ADC - 1 downto 0 generate
G1:		for j in bits_per_column - 1 downto 0 generate
			primary_demux_out_array(i)(j) <= primary_demux_output(i * bits_per_column + j);
		end generate;
	end generate;

-- column registers

G2:	for i in cols_per_ADC - 1 downto 0 generate

		column_FF_E(i) <= (primary_select(i) AND i_activate AND (NOT i_LS)) OR i_reg_clear OR i_IADD; -- WHAT SHOULD IT BE? SOMETHING WITH primary_select(i)

G3:		for j in bits_per_column - 1 downto 0 generate
            column_FF_D(i)(j) <= primary_demux_out_array(i)(j) AND (NOT i_reg_clear) AND (NOT i_IADD);
U3:			D_FF port map(D => column_FF_D(i)(j), 
							 E => column_FF_E(i), 
							 clk => i_clk,
							 Q => column_FF_out_array(i)(j));
		end generate;
	end generate;

G4:	for i in cols_per_ADC - 1 downto 0 generate
G5:		for j in bits_per_column - 1 downto 0 generate
			column_FF_out(i * bits_per_column + j) <= column_FF_out_array(i)(j);
		end generate;
	end generate;


-- primary mux

U4: MUX   generic map(num_in_columns => cols_per_ADC, bits_per_column => bits_per_column)
		  port map   (i_data => column_FF_out,
					  i_sel  => primary_select,
					  o_data => primary_mux_output);

-- demux between primary and secondary stage
	s_LS(0) <= i_LS;

U5: decoder generic map(number_of_input_bits => 1)
			port map   (input  => s_LS, 
						output => s_LS_decoded);

U6: DEMUX generic map(num_in_bits => bits_per_column, num_out_blocks => 2)
		  port map   (i_data => primary_adder_output,
					  i_sel  => s_LS_decoded,
					  o_data => mux_to_secondary_out);

G6:	for i in 1 downto 0 generate
G7:		for j in bits_per_column - 1 downto 0 generate
			mux_to_secondary_out_array(i)(j) <= mux_to_secondary_out(i * bits_per_column + j);
		end generate;
	end generate;

	o_stage_demux_1 <= mux_to_secondary_out_array(0); -- test
 	o_stage_demux_2 <= mux_to_secondary_out_array(1); -- test


--=========================== SECOND STAGE ===========================================

-- adder
U7: adder2 generic map(size => bits_per_column)
		  port map(A => mux_to_secondary_out_array(1),
				   B => R1_temp_out,
				   O => secondary_adder_output);

-- R1 temp
	R1_temp_E <= (i_LS AND i_activate) OR i_reg_clear OR i_IADD;
G8: for i in bits_per_column - 1 downto 0 generate
        R1_temp_D(i+1) <= secondary_adder_output(i + 1) AND (NOT i_reg_clear) AND (NOT i_IADD);
U8:		D_FF port map(D => R1_temp_D(i + 1), 
						 E => R1_temp_E, 
						 clk => i_clk,
						 Q => R1_temp_out(i));	
	end generate;

	o_R1_temp <= R1_temp_out; -- test

-- demux from adder to R2 temp
U9: decoder generic map(number_of_input_bits => integer(log2(real(max_datatype_size/8))) )
			port map   (input  => i_datatype_sel, 
						output => datatype_sel_decoded);

U10:DEMUX generic map(num_in_bits	    => (bits_per_column + 1),
			    	  num_out_blocks	=> num_datatypes)
		  port map(	  i_data			=> secondary_adder_output,
		    		  i_sel				=> datatype_sel_decoded,
					  o_data			=> R2_demux_out);

	o_R2_demux <= R2_demux_out; -- test

-- mux signal generation

process(datatype_sel_decoded, R2_demux_out)

	variable R2_mux_sel_temp : std_logic_vector(max_datatype_size + bits_per_column - 1 downto 7);
	variable R2_mux_in_temp : std_logic_vector(max_datatype_size + bits_per_column - 1 downto 7);

begin

	R2_mux_sel_temp := (others => '0'); -- default
	R2_mux_in_temp  := (others => '0'); -- default

	for i in 0 to num_datatypes - 1 loop
		for j in 0 to bits_per_column - 0 loop
				
			--R2_mux_sel(i * 8 + j) <=  datatype_sel_decoded(i) OR R2_mux_sel_temp(i * 8 + j);
			R2_mux_sel_temp(i * 8 + j + 7) := datatype_sel_decoded(i) OR R2_mux_sel_temp(i * 8 + j + 7);
			R2_mux_in_temp(i * 8 + j + 7) := R2_demux_out(i * (bits_per_column) + j) OR R2_mux_in_temp(i * 8 + j + 7);
	
		end loop;
	end loop;

	R2_mux_sel <= R2_mux_sel_temp;
	R2_mux_in  <= R2_mux_in_temp;

end process;

	o_R2_mux_in  <= R2_mux_in; -- test
	o_R2_mux_sel <= R2_mux_sel; -- test
	

-- R2 temp
	R2_temp_E <= (i_LS AND i_activate) or i_reg_clear;

G15:for i in 6 downto 0 generate
        R2_temp_D(i+1) <= R2_temp_out(i+1) AND (NOT i_reg_clear);
U11:	D_FF port map(D => R2_temp_D(i+1), 
						 E => R2_temp_E, 
						 clk => i_clk,
						 Q => R2_temp_out(i));	
	end generate;

G16:for i in max_datatype_size + bits_per_column - 1 downto 7 generate
        R2_mux_D(i) <= R2_mux_out(i) AND (NOT i_reg_clear);
U12:	D_FF    port map(D => R2_mux_D(i), 
						 E => R2_temp_E,  
						 clk => i_clk,
						 Q => R2_temp_out(i));	

G17:	if (i = max_datatype_size + bits_per_column - 1) generate
U13:		MUX2 port map (A   => '0',
						   B   => R2_mux_in(i), 
						   sel => R2_mux_sel(i),
						   O   => R2_mux_out(i));
		end generate;

G18:	if (i < max_datatype_size + bits_per_column - 1) generate
U14:		MUX2 port map (A   => R2_temp_out(i + 1),
						   B   => R2_mux_in(i), 
						   sel => R2_mux_sel(i),
						   O   => R2_mux_out(i));
		end generate;

	end generate;

	o_R2_temp <= R2_temp_out;

	



--=========================== THIRD STAGE ============================================


-- adder
U15: adder2 generic map(size => max_datatype_size + bits_per_column)
		  port map(A => R2_temp_out,
				   B => R3_temp_out,
				   O => third_adder_output);

-- R3 temp
	R3_temp_E <= i_IADD OR i_reg_clear;
G19: for i in max_datatype_size + bits_per_column - 1 downto 0 generate
        R3_temp_D(i+1) <= third_adder_output(i + 1) AND (NOT i_reg_clear);
U16:	D_FF port map(D => R3_temp_D(i + 1), 
						 E => R3_temp_E, 
						 clk => i_clk,
						 Q => R3_temp_out(i));	
	end generate;

	o_R3_temp <= R3_temp_out; -- test

-- demux from adder to R2 temp

-- use the same decoded datatype from second stage for select (datatype_sel_decoded)

U17:DEMUX generic map(num_in_bits	    => R4_demux_in_bits,
			    	  num_out_blocks	=> num_datatypes)
		  port map(	  i_data			=> third_adder_output,
		    		  i_sel				=> datatype_sel_decoded,
					  o_data			=> R4_demux_out);

	o_R4_demux <= R4_demux_out; -- test

process(datatype_sel_decoded, R4_demux_out)

	variable R4_mux_sel_temp : std_logic_vector(2 * max_datatype_size + bits_per_column - 1 downto 7);
	variable R4_mux_in_temp : std_logic_vector(2 * max_datatype_size + bits_per_column - 1 downto 7);

begin

	R4_mux_sel_temp := (others => '0'); -- default
	R4_mux_in_temp  := (others => '0'); -- default

	for i in 0 to num_datatypes - 1 loop
		for j in 0 to max_datatype_size + bits_per_column - 0 loop
				
			R4_mux_sel_temp(i * 8 + j + 7) := datatype_sel_decoded(i) OR R4_mux_sel_temp(i * 8 + j + 7);
			R4_mux_in_temp(i * 8 + j + 7) := R4_demux_out(i * (max_datatype_size + bits_per_column) + j) OR R4_mux_in_temp(i * 8 + j + 7);
	
		end loop;
	end loop;

	R4_mux_sel <= R4_mux_sel_temp;
	R4_mux_in  <= R4_mux_in_temp;

end process;

	o_R4_mux_in  <= R4_mux_in; -- test
	o_R4_mux_sel <= R4_mux_sel; -- test


-- R4 temp

	R4_temp_E <= i_IADD OR i_reg_clear;

G26:for i in 6 downto 0 generate
		R4_temp_D(i) <= R4_temp_out(i+1) AND (NOT i_reg_clear);
U18:	D_FF port map(D => R4_temp_D(i), 
						 E => R4_temp_E, 
						 clk => i_clk,
						 Q => R4_temp_out(i));	
	end generate;

G27:for i in 2 * max_datatype_size + bits_per_column - 1 downto 7 generate
		R4_temp_D(i) <= R4_mux_out(i) AND (NOT i_reg_clear);
U19:	D_FF port map(D => R4_temp_D(i), 
						 E => R4_temp_E, 
						 clk => i_clk,
						 Q => R4_temp_out(i));	

G28:	if (i = 2 * max_datatype_size + bits_per_column - 1) generate
U20:		MUX2 port map (A   => '0',
						   B   => R4_mux_in(i), 
						   sel => R4_mux_sel(i),
						   O   => R4_mux_out(i));
		end generate;

G29:	if (i < 2 * max_datatype_size + bits_per_column - 1) generate
U21:		MUX2 port map (A   => R4_temp_out(i + 1),
						   B   => R4_mux_in(i), 
						   sel => R4_mux_sel(i),
						   O   => R4_mux_out(i));
		end generate;

	end generate;

	o_R4_temp <= R4_temp_out;



end behavioural;
