-----------------------------------------------------------------------
-- Project: CiM-Tile HW Design/implementation                        --
-- File	  : addition_unit.vhd                                        --
-- Author : Remon van Duijnen (R.F.J.vanDuijnen@student.tudelft.nl)  --
-- Version: 1.0														 --
-----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity addition_unit is
	generic(crossbar_rows 	  : integer;
			crossbar_columns  : integer;
			num_ADCs 		  : integer;
			max_datatype_size : integer);
	port(i_clk			: in std_logic;
		 i_ADC_out 		: in std_logic_vector(num_ADCs * integer(log2(real(crossbar_rows))) - 1 downto 0);
		 i_LS	   		: in std_logic;
		 i_activate		: in std_logic;
		 i_CS_index		: in std_logic_vector(integer(log2(real(crossbar_columns/num_ADCs))) - 1 downto 0);
		 i_IADD			: in std_logic;
		 i_reset		: in std_logic;
		 i_datatype_sel : in std_logic_vector(integer(log2(real(max_datatype_size/8))) -1 downto 0);

		 o_addition_out : out std_logic_vector(num_ADCs * (2 * max_datatype_size + integer(log2(real(crossbar_rows)))) - 1 downto 0));
end addition_unit;

architecture behavioural of addition_unit is


-- constants
	constant log_rows : integer := integer(log2(real(crossbar_rows)));

-- components
	component addition_per_ADC is
		generic(crossbar_rows     : integer;
				crossbar_columns  : integer;
				num_ADCs          : integer;
				max_datatype_size : integer);
		port   (i_clk			: in std_logic;
				i_ADC_output 	: in std_logic_vector(integer(log2(real(crossbar_rows))) - 1 downto 0);
				i_activate   	: in std_logic;
				i_CS_index	    : in std_logic_vector(integer(log2(real(crossbar_columns/num_ADCs))) - 1 downto 0);
				i_LS		 	: in std_logic;
				i_IADD	     	: in std_logic;
				i_reg_clear  	: in std_logic;
				i_datatype_sel	: in std_logic_vector(integer(log2(real(max_datatype_size/8))) -1 downto 0);
	
				o_R4_temp    	: out std_logic_vector(2*max_datatype_size + integer(log2(real(crossbar_rows))) - 1 downto 0);
				
				-- testing outputs
				o_R2_mux_in  	: out std_logic_vector(max_datatype_size + integer(log2(real(crossbar_rows))) - 1 downto 7);
				o_R2_mux_sel 	: out std_logic_vector(max_datatype_size + integer(log2(real(crossbar_rows))) - 1 downto 7);
				o_R4_mux_in	 	: out std_logic_vector(2 * max_datatype_size + integer(log2(real(crossbar_rows))) - 1 downto 7);
				o_R4_mux_sel 	: out std_logic_vector(2 * max_datatype_size + integer(log2(real(crossbar_rows))) - 1 downto 7);
				o_stage_demux_1 : out std_logic_vector(integer(log2(real(crossbar_rows))) - 1 downto 0);
				o_stage_demux_2 : out std_logic_vector(integer(log2(real(crossbar_rows))) - 1 downto 0);
				o_R2_demux	 	: out std_logic_vector(max_datatype_size / 8 * (integer(log2(real(crossbar_rows))) + 1) - 1 downto 0);
				o_R4_demux	 	: out std_logic_vector(max_datatype_size / 8 * (max_datatype_size + integer(log2(real(crossbar_rows))) + 1) - 1 downto 0);
				o_R1_temp    	: out std_logic_vector(integer(log2(real(crossbar_rows))) - 1 downto 0);
				o_R2_temp	 	: out std_logic_vector(max_datatype_size + integer(log2(real(crossbar_rows))) - 1 downto 0 );
				o_R3_temp	 	: out std_logic_vector(max_datatype_size + integer(log2(real(crossbar_rows))) - 1 downto 0));
	end component;

-- signals
	type R4_array  is array (num_ADCs - 1 downto 0) of std_logic_vector(2*max_datatype_size + log_rows - 1 downto 0);
	type ADC_array is array (num_ADCs - 1 downto 0) of std_logic_vector(log_rows - 1 downto 0);

	signal o_R4_temp_array : R4_array;
	signal i_ADC_out_array : ADC_array;
	signal o_R4_temp : std_logic_vector(num_ADCs * (2 * max_datatype_size + log_rows) - 1 downto 0);
	
begin


G0: for i in num_ADCs - 1 downto 0 generate

G1:		for j in log_rows - 1 downto 0 generate
			i_ADC_out_array(i)(j) <= i_ADC_out(i * log_rows + j);
		end generate;

U0: 	addition_per_ADC generic map(crossbar_rows 	   => crossbar_rows, 
									 crossbar_columns  => crossbar_columns,
									 num_ADCs 		   => num_ADCs, 
									 max_datatype_size => max_datatype_size)
						 port map(	i_clk		   => i_clk,
									i_ADC_output   => i_ADC_out_array(i),
									i_activate     => i_activate,
									i_CS_index     => i_CS_index,
									i_LS 		   => i_LS,
									i_IADD 		   => i_IADD,
									i_reg_clear    => i_reset,
									i_datatype_sel => i_datatype_sel,

									o_R4_temp => o_R4_temp_array(i),

									-- testing outputs
									o_R2_mux_in => open,
									o_R2_mux_sel => open,
									o_R4_mux_in => open,
									o_R4_mux_sel => open,
									o_stage_demux_1 => open,
									o_stage_demux_2 => open,
									o_R2_demux => open,
									o_R4_demux => open,
									o_R1_temp => open,
									o_R2_temp => open,
									o_R3_temp => open);		

G2:		for j in 2 * max_datatype_size + log_rows - 1 downto 0 generate
			o_R4_temp(i * (2 * max_datatype_size + log_rows) + j) <= o_R4_temp_array(i)(j);
		end generate;
	end generate;

	o_addition_out <= o_R4_temp;


G99:if max_datatype_size > crossbar_columns/num_ADCs generate
		
		-- Here the addition_between_ADCs should be implemented
		-- for this version, we assume no addition between ADCs is required

	end generate;

end behavioural;
