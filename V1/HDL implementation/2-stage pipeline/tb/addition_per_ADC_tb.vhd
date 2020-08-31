-----------------------------------------------------------------------
-- Project: CiM-Tile HW Design/implementation                        --
-- File	  : addition_per_ADC_tb.vhd                                  --
-- Author : Remon van Duijnen (R.F.J.vanDuijnen@student.tudelft.nl)  --
-- Version: 1.0														 --
-----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity addition_per_ADC_tb is
end addition_per_ADC_tb;

architecture tb of addition_per_ADC_tb is

-- constants
	constant clk_period		   : time	 := 2 ns; 
	constant crossbar_rows 	   : integer := 256;  -- 256
	constant crossbar_columns  : integer := 256;  -- 256
	constant num_ADCs 		   : integer := 8;    -- 8
	constant max_datatype_size : integer := 32;   -- 32

-- components
	component addition_per_ADC is
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
	
				o_R4_temp      : out std_logic_vector(2*crossbar_columns / num_ADCs + integer(log2(real(crossbar_rows))) - 1 downto 0);
				
				-- testing outputs
				o_R2_mux_in  : out std_logic_vector(crossbar_columns / num_ADCs + integer(log2(real(crossbar_rows))) - 1 downto 7);
				o_R2_mux_sel : out std_logic_vector(crossbar_columns / num_ADCs + integer(log2(real(crossbar_rows))) - 1 downto 7);
				o_R4_mux_in	 : out std_logic_vector(2 * crossbar_columns / num_ADCs + integer(log2(real(crossbar_rows))) - 1 downto 7);
				o_R4_mux_sel : out std_logic_vector(2 * crossbar_columns / num_ADCs + integer(log2(real(crossbar_rows))) - 1 downto 7);
				o_stage_demux_1    : out std_logic_vector(integer(log2(real(crossbar_rows))) - 1 downto 0);
				o_stage_demux_2    : out std_logic_vector(integer(log2(real(crossbar_rows))) - 1 downto 0);
				o_R2_demux	 : out std_logic_vector(crossbar_columns / num_ADCs / 8 * (integer(log2(real(crossbar_rows))) + 1) - 1 downto 0);
				o_R4_demux	 : out std_logic_vector(crossbar_columns / num_ADCs / 8 * (crossbar_columns / num_ADCs + integer(log2(real(crossbar_rows))) + 1) - 1 downto 0);
				o_R1_temp    : out std_logic_vector(integer(log2(real(crossbar_rows))) - 1 downto 0);
				o_R2_temp	 : out std_logic_vector(crossbar_columns / num_ADCs + integer(log2(real(crossbar_rows))) - 1 downto 0 );
				o_R3_temp	 : out std_logic_vector(crossbar_columns / num_ADCs + integer(log2(real(crossbar_rows))) - 1 downto 0));
	end component;


-- signals
	-- inputs
	signal clk					: std_logic := '0';
	signal i_ADC_output			: std_logic_vector(integer(log2(real(crossbar_rows))) - 1 downto 0);
	signal i_activate			: std_logic;
	signal i_CS_index			: std_logic_vector(integer(log2(real(crossbar_columns/num_ADCs))) - 1 downto 0);
	signal i_LS					: std_logic;
	signal i_IADD				: std_logic;
	signal i_reg_clear			: std_logic;
	signal i_datatype_sel		: std_logic_vector(integer(log2(real(max_datatype_size/8))) -1 downto 0);

	-- outputs	
	signal o_R4_temp    : std_logic_vector(2*crossbar_columns / num_ADCs + integer(log2(real(crossbar_rows))) - 1 downto 0);

	-- test outputs
	signal o_R2_demux : std_logic_vector(max_datatype_size / 8 * (integer(log2(real(crossbar_rows))) + 1) - 1 downto 0);
	signal o_R1_temp : std_logic_vector(integer(log2(real(crossbar_rows))) - 1 downto 0);
	signal o_stage_demux_1 : std_logic_vector(integer(log2(real(crossbar_rows))) - 1 downto 0);
	signal o_stage_demux_2 : std_logic_vector(integer(log2(real(crossbar_rows))) - 1 downto 0);
	signal o_R2_mux_in  :  std_logic_vector(crossbar_columns / num_ADCs + integer(log2(real(crossbar_rows))) - 1 downto 7);
	signal o_R2_mux_sel  : std_logic_vector(crossbar_columns / num_ADCs + integer(log2(real(crossbar_rows))) - 1 downto 7);
	signal o_R4_demux	: std_logic_vector(max_datatype_size / 8 * (crossbar_columns / num_ADCs + integer(log2(real(crossbar_rows))) + 1) - 1 downto 0);
	signal o_R3_temp	 : std_logic_vector(crossbar_columns / num_ADCs + integer(log2(real(crossbar_rows))) - 1 downto 0);
	signal o_R2_temp : std_logic_vector(crossbar_columns / num_ADCs + integer(log2(real(crossbar_rows))) - 1 downto 0 );
	signal o_R4_mux_in	 : std_logic_vector(2 * crossbar_columns / num_ADCs + integer(log2(real(crossbar_rows))) - 1 downto 7);
	signal o_R4_mux_sel : std_logic_vector(2 * crossbar_columns / num_ADCs + integer(log2(real(crossbar_rows))) - 1 downto 7);
				

begin

	clk <= NOT clk after clk_period / 2;

uut: addition_per_ADC generic map(crossbar_rows 	=> crossbar_rows, 
								  crossbar_columns 	=> crossbar_columns, 
								  num_ADCs			=> num_ADCs, 
								  max_datatype_size => max_datatype_size)
					  port map(i_clk 	      => clk, 
							   i_ADC_output   => i_ADC_output, 
							   i_activate 	  => i_activate, 
							   i_CS_index 	  => i_CS_index, 
							   i_LS 		  => i_LS, 
							   i_IADD 		  => i_IADD, 
							   i_reg_clear 	  => i_reg_clear, 
							   i_datatype_sel => i_datatype_sel,

							   o_R2_mux_in => o_R2_mux_in,
							   o_R2_mux_sel => o_R2_mux_sel,
							   o_R4_mux_in => o_R4_mux_in,
							   o_R4_mux_sel => o_R4_mux_sel,
							   o_R2_demux => o_R2_demux,
							   o_stage_demux_1 => o_stage_demux_1,
							   o_stage_demux_2 => o_stage_demux_2,
							   o_R1_temp => o_R1_temp,
							   o_R2_temp      => o_R2_temp,
								o_R4_demux => o_R4_demux,
								o_R3_temp => o_R3_temp,
								o_R4_temp => o_R4_temp);


	i_ADC_output   <= "00000000",
					  --"11111111" after 28 ns;
					  "00000010" after 10 ns,
					  "00000001" after 15 ns,
					  "00000001" after 20 ns,
					  "00000000" after 25 ns,
					  "00000010" after 30 ns,
					  "00000010" after 35 ns,
					  "00000001" after 40 ns,
					  "00000001" after 45 ns,
					  "00000000" after 50 ns;

	i_activate	   <= '0',
					  '1' after 11 ns,
					  '0' after 13 ns,
					  '1' after 16 ns,
					  '0' after 18 ns,
					  '1' after 21 ns,
					  '0' after 23 ns,
					  '1' after 26 ns,
					  '0' after 28 ns,
					  '1' after 31 ns,
					  '0' after 33 ns,
					  '1' after 36 ns,
					  '0' after 38 ns,
					  '1' after 41 ns,
					  '0' after 43 ns,
					  '1' after 46 ns,
					  '0' after 48 ns,
					  '1' after 51 ns,
					  '0' after 53 ns,
					  '1' after 56 ns,
					  '0' after 58 ns,
					  '1' after 61 ns,
					  '0' after 63 ns,
					  '1' after 66 ns,
					  '0' after 68 ns;
		
	i_CS_index	   <= "00000",
					  "00001" after 15 ns,
					  "00010" after 20 ns,
					  "00011" after 25 ns,
					  "00000" after 30 ns,
					  "00001" after 35 ns,
					  "00010" after 40 ns,
					  "00011" after 45 ns,
					  "00100" after 50 ns,
					  "00101" after 55 ns,
					  "00110" after 60 ns,
					  "00111" after 65 ns,
					  "01000" after 70 ns;
	
	i_LS		   <= '0',
					  '1' after 28 ns;

			
	i_IADD   	   <= '0',
					  '1' after 75 ns,
					  --'0' after 76 ns,
					  --'1' after 77 ns,
					  --'0' after 78 ns,
					  --'1' after 79 ns,
					  --'0' after 80 ns,
					  --'1' after 81 ns,
					  --'0' after 82 ns,
					  --'1' after 83 ns,
					  --'0' after 84 ns,
					  --'1' after 85 ns,
					  --'0' after 86 ns,
					  --'1' after 87 ns,
					  --'0' after 88 ns,
					  --'1' after 89 ns,
					  '0' after 91 ns;
		
		
	i_reg_clear	   <= '0',
					  '1' after 1 ns,
					  '0' after 3 ns;
	
	i_datatype_sel <= "00", --  "00" = 1 byte datatype
					  "01" after 92 ns,
					  "10" after 94 ns,
					  "11" after 96 ns; 



end tb;


