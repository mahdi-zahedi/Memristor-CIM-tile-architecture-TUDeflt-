-----------------------------------------------------------------------
-- Project: CiM-Tile HW Design/implementation                        --
-- File	  : ADC.vhd                                                  --
-- Author : Remon van Duijnen (R.F.J.vanDuijnen@student.tudelft.nl)  --
-- Version: 1.0														 --
-----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
use ieee.numeric_std.all;

entity ADC is
	generic(crossbar_rows    : integer;
			crossbar_columns : integer;
			num_ADCs	     : integer;
			ADC_latency		 : integer);
	port (i_clk 			 : in std_logic;
		  i_sampled_data     : in std_logic_vector(crossbar_columns * integer(log2(real(crossbar_rows))) - 1 downto 0);
		  i_CS_index	     : in std_logic_vector(integer(log2(real(crossbar_columns/num_ADCs))) - 1 downto 0);
		  i_activation_bits  : in std_logic_vector(num_ADCs-1 downto 0);
		  i_DoR			     : in std_logic;
		  i_reset			 : in std_logic;

		  o_ADC_output	     : out std_logic_vector(num_ADCs * integer(log2(real(crossbar_rows))) - 1 downto 0);
		  o_logic_reg_output : out std_logic_vector(crossbar_columns - 1 downto 0);
		  o_ADC_done		 : out std_logic);

end ADC;

architecture behavioural of ADC is

-- constants
	constant cols_per_ADC : integer := crossbar_columns / num_ADCs;
	constant bits_per_column : integer := integer(log2(real(crossbar_rows)));
	constant in_bits_per_mux : integer := bits_per_column * cols_per_ADC;

-- components
	component decoder is
		generic(number_of_input_bits : integer
		);
		port (input  : in std_logic_vector(number_of_input_bits-1 downto 0);
			  output : out std_logic_vector((2 ** number_of_input_bits) - 1 downto 0)
		);
	end component;
	
	component MUX is
		generic( bits_per_column	:	integer;
				 num_in_columns	:	integer
				);
		port(	i_data	: in  std_logic_vector(bits_per_column * num_in_columns - 1 downto 0);
			    i_sel	: in  std_logic_vector(num_in_columns - 1 downto 0);
				o_data	: out std_logic_vector(bits_per_column - 1 downto 0)
				);
	end component;

	component crossbar_model_counter is
		port( i_set_val : in std_logic_vector(8 downto 0);
		 	  i_set : in std_logic;
			  clk : in std_logic;
			  clr : in std_logic;
	
			  o : out std_logic_vector(8 downto 0));
	end component;

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

-- signals
	type MUX_in_array  is array (num_ADCs-1 downto 0) of std_logic_vector(in_bits_per_mux - 1 downto 0);
	type MUX_out_array is array (num_ADCs-1 downto 0) of std_logic_vector(bits_per_column - 1 downto 0);
	type logic_FF_E_type is array (num_ADCs-1 downto 0) of std_logic_vector(cols_per_ADC - 1 downto 0);

	signal logic_FF_E  		   : logic_FF_E_type;
	signal neg_edge  		   : std_logic;
	signal MUX_input 		   : MUX_in_array;
	signal MUX_output		   : MUX_out_array;
	signal ADC_FF_D  		   : MUX_out_array;
	signal s_select_decoded    : std_logic_vector(cols_per_ADC - 1 downto 0);
	signal s_ADC_done 		   : std_logic;
	signal done_FF_C, ADC_FF_C : std_logic;
	signal s_set_val 		   : std_logic_vector(8 downto 0) := std_logic_vector(to_unsigned(ADC_latency, 9));
	signal count_out 		   : std_logic_vector(8 downto 0);
	signal s_done_D, s_done, s_done_pulse_1, s_done_pulse_2 : std_logic;
	signal s_ADC_output		   : std_logic_vector(num_ADCs * integer(log2(real(crossbar_rows))) - 1 downto 0);
	

begin 

----------------------------------------------------------
-- MUXs --------------------------------------------------

U0: decoder generic map(number_of_input_bits => integer(log2(real(cols_per_ADC))))
			port map(input  => i_CS_index,
					 output => s_select_decoded);


G0: for i in num_ADCs - 1 downto 0 generate
G1:		for j in in_bits_per_mux - 1 downto 0 generate
			MUX_input(i)(j) <= i_sampled_data(i * in_bits_per_mux + j);
		end generate;
	end generate;

G2: for i in num_ADCs - 1 downto 0 generate
U1:		mux generic map(bits_per_column => bits_per_column, num_in_columns => cols_per_ADC)
			port map(i_data => MUX_input(i),
					 i_sel  => s_select_decoded,
					 o_data => MUX_output(i));
	end generate;


----------------------------------------------------------
-- ADCs --------------------------------------------------

	ADC_FF_C <= NOT i_DoR;
	done_FF_C <= NOT i_reset;
	neg_edge <= NOT i_clk;

G3: for i in num_ADCs - 1 downto 0 generate
G4:		for j in bits_per_column - 1 downto 0 generate
            s_ADC_output(i * bits_per_column + j) <= i_activation_bits (i) AND MUX_output(i)(j);
--			ADC_FF_D(i)(j) <= i_activation_bits (i) AND MUX_output(i)(j);    -- use this register when CS/DoR are not merged or separate addition stage is used
--U2:			D_FF port map(D => ADC_FF_D(i)(j), E => i_DoR, clk => neg_edge,
--						  Q => s_ADC_output(i * bits_per_column + j));
		end generate;
	end generate;

	o_ADC_output <= s_ADC_output;

G5:	if (ADC_latency = 0) generate -- next cycle done signal
U5:		D_FF_PC port map(D => i_DoR, E => '1', clk => i_clk, P => '1', C => done_FF_C, Q => s_done_pulse_1);
U6:		D_FF_PC port map(D => s_done_pulse_1, E => '1', clk => i_clk, P => '1', C => done_FF_C, Q => o_ADC_done);
	end generate;

G6:	if (ADC_latency > 0) generate -- done signal with timer delay from ADC
U3: 	crossbar_model_counter port map(i_set_val => s_set_val,
										i_set => i_DoR,
										clk => i_clk,
										clr => i_reset,
										o => count_out);
		
		s_done_D <= ((((((((count_out(8)) OR count_out(7)) OR count_out(6)) OR
				  		    count_out(5)) OR count_out(4)) OR count_out(3)) OR
				  		    count_out(2)) OR count_out(1)) NOR count_out(0);
	
U7:		D_FF_PC port map(D => s_done_D, E => '1', clk => i_clk, P => done_FF_C, C => '1', Q => s_done_pulse_1);
U8:		D_FF_PC port map(D => s_done_pulse_1, E => '1', clk => i_clk, P => done_FF_C, C => '1', Q => s_done_pulse_2);
	
		o_ADC_done <= s_done_pulse_1 AND (NOT s_done_pulse_2);
	end generate;


----------------------------------------------------------
-- Logic/read/vrf reg ------------------------------------

G7:	for i in num_ADCs - 1 downto 0 generate
G8:		for j in cols_per_ADC - 1 downto 0 generate
			logic_FF_E(i)(j) <=  i_DoR AND (i_activation_bits(i) AND s_select_decoded(j));
U9:			D_FF port map(D => s_ADC_output(i * bits_per_column), E => logic_FF_E(i)(j), clk => i_clk,
						  Q => o_logic_reg_output(i * cols_per_ADC + j));			
		end generate;
	end generate;


end behavioural;
