-----------------------------------------------------------------------
-- Project: CiM-Tile HW Design/implementation                        --
-- File	  : ADC_tb.vhd                                               --
-- Author : Remon van Duijnen (R.F.J.vanDuijnen@student.tudelft.nl)  --
-- Version: 1.0														 --
-----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
use ieee.numeric_std.all;


entity ADC_tb is
end ADC_tb;

architecture tb of ADC_tb is

-- constants
	constant crossbar_rows 	  : integer := 8;
	constant crossbar_columns : integer := 8;
	constant num_ADCs		  : integer := 2;
	constant ADC_latency	  : integer := 0; -- additional cycles
	constant clk_period       : time	:= 2 ns;

-- components
	component ADC is
		generic(crossbar_rows    : integer;
				crossbar_columns : integer;
				num_ADCs	     : integer;
				ADC_latency		 : integer);
		port (i_clk				 : in std_logic;
			  i_sampled_data     : in std_logic_vector(crossbar_columns * integer(log2(real(crossbar_rows))) - 1 downto 0);
			  i_CS_index	     : in std_logic_vector(integer(log2(real(crossbar_columns/num_ADCs))) - 1 downto 0);
			  i_activation_bits  : in std_logic_vector(num_ADCs-1 downto 0);
			  i_DoR			     : in std_logic;
			  i_reset			 : in std_logic;
	
			  o_logic_reg_output : out std_logic_vector(crossbar_columns - 1 downto 0);
			  o_ADC_output	     : out std_logic_vector(num_ADCs * integer(log2(real(crossbar_rows))) - 1 downto 0);
			  o_ADC_done		 : out std_logic);
	end component;

-- signals
	-- inputs
	signal i_sampled_data : std_logic_vector(crossbar_columns * integer(log2(real(crossbar_rows))) - 1 downto 0);
	signal i_CS_index : std_logic_vector(integer(log2(real(crossbar_columns/num_ADCs))) - 1 downto 0);
	signal i_activation_bits : std_logic_vector(num_ADCs - 1 downto 0);
	signal i_DoR : std_logic;
	signal i_reset : std_logic;
	signal i_clk : std_logic := '1';

	-- outputs
	signal o_ADC_output       : std_logic_vector(num_ADCs * integer(log2(real(crossbar_rows))) - 1 downto 0);
	signal o_logic_reg_output : std_logic_vector(crossbar_columns - 1 downto 0);
	signal o_ADC_done : std_logic;

begin

	i_clk <= NOT i_clk after clk_period / 2;

uut: ADC generic map(crossbar_rows => crossbar_rows, crossbar_columns => crossbar_columns, 
					 num_ADCs => num_ADCs, ADC_latency => ADC_latency)
		 port map   (i_sampled_data => i_sampled_data,
					 i_CS_index => i_CS_index,
					 i_activation_bits => i_activation_bits,
					 i_DoR => i_DoR,
					 i_reset => i_reset,
					 i_clk => i_clk,
					 o_ADC_output => o_ADC_output,
					 o_logic_reg_output => o_logic_reg_output,
					 o_ADC_done => o_ADC_done);

	i_sampled_data <= "000001010011100101110111";

	i_CS_index	   <= "00",
					  "11" after 78 ns;

	i_activation_bits <= "00",
						 "01" after 38 ns,
						 "10" after 58 ns,
						 "11" after 78 ns;

	i_DoR <= '0',
			 '1' after 20 ns,
			 '0' after 22 ns,
			 '1' after 40 ns,
			 '0' after 42 ns,
			 '1' after 60 ns,
			 '0' after 62 ns,
			 '1' after 80 ns,
			 '0' after 82 ns;

	i_reset <= '0',
			   '1' after 2 ns,
			   '0' after 4 ns;

end tb;
