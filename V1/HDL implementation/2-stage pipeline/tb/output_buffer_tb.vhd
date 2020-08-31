-----------------------------------------------------------------------
-- Project: CiM-Tile HW Design/implementation                        --
-- File	  : output_buffer_tb.vhd                                     --
-- Author : Remon van Duijnen (R.F.J.vanDuijnen@student.tudelft.nl)  --
-- Version: 1.0														 --
-----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
--use ieee.numeric_std.all;

entity output_buffer_tb is
end output_buffer_tb;

architecture tb of output_buffer_tb is

-- constants
	constant num_ADCs 		  : integer := 2;
	constant crossbar_columns : integer := 64;
	constant crossbar_rows    : integer := 256;
	constant clk_period		  : time    := 2 ns;

-- components
	component output_buffer is
		generic(num_ADCs 		 : integer;
				crossbar_columns : integer;
				crossbar_rows    : integer);
		port(i_clk 				 	   : in  std_logic;
			 i_FS				 	   : in  std_logic_vector(3 downto 0);
			 i_addition_out 	 	   : in  std_logic_vector(num_ADCs * ((2*crossbar_columns/num_ADCs) + integer(log2(real(crossbar_rows)))) - 1 downto 0);
			 i_logic_reg_out		   : in  std_logic_vector(crossbar_columns - 1 downto 0);
			 i_activate			 	   : in  std_logic;
			 o_output_buffer_out 	   : out std_logic_vector(num_ADCs * ((2*crossbar_columns/num_ADCs) + integer(log2(real(crossbar_rows)))) - 1 downto 0);
			 o_output_buffer_logic_out : out std_logic_vector(crossbar_columns - 1 downto 0));
	end component;

-- signals
	-- inputs
		signal i_addition_out  : std_logic_vector(num_ADCs * ((2*crossbar_columns/num_ADCs) + integer(log2(real(crossbar_rows)))) - 1 downto 0);
		signal i_FS			   : std_logic_vector(3 downto 0);
	    signal i_logic_reg_out : std_logic_vector(crossbar_columns - 1 downto 0);
		signal i_activate	   : std_logic;
		signal clk			   : std_logic := '0';
	
	-- outputs
		signal o_output_buffer_out : std_logic_vector(num_ADCs * ((2*crossbar_columns/num_ADCs) + integer(log2(real(crossbar_rows)))) - 1 downto 0);
	    signal o_output_buffer_logic_out : std_logic_vector(crossbar_columns - 1 downto 0); 

begin

	clk <= NOT clk after clk_period / 2;

uut: output_buffer  generic map(num_ADCs 		 => num_ADCs,
								crossbar_columns => crossbar_columns,
								crossbar_rows 	 => crossbar_rows)
					port map(i_clk 				 	   => clk,
							 i_FS				 	   => i_FS,
							 i_addition_out 	 	   => i_addition_out,
							 i_logic_reg_out	 	   => i_logic_reg_out,
							 i_activate 		 	   => i_activate,
							 o_output_buffer_out 	   => o_output_buffer_out,
							 o_output_buffer_logic_out => o_output_buffer_logic_out);

	i_addition_out <= "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
					  "000000000000000000000000000000000000000000000000000000000000000000000000101010101010101010101010101010101010101010101010101010101010101010101010" after 10 ns,
					  "000000000000000000000000000000000000000000000000000000000000000000000000101010101010101010101010101010101010101010101010101010101010101010101010" after 20 ns,
					  "111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111" after 30 ns;

	i_logic_reg_out <= "0000000000000000000000000000000000000000000000000000000000000000",
					   "1111111111111111111111111111111111111111111111111111111111111111" after 20 ns,
					   "0000000000000000000000000000000000000000000000000000000000000000" after 40 ns,
					   "1010101010101010101010101010101010101010101010101010101010101010" after 60 ns;

	i_FS <= "0111",
			"0000" after 40 ns;
	
	i_activate <= '0',
				  '1' after 5 ns,
				  '0' after 7 ns,
				  '1' after 15 ns,
				  '0' after 17 ns,
				  '1' after 35 ns,
				  '0' after 37 ns,
				  '1' after 45 ns,
				  '0' after 47 ns,
				  '1' after 65 ns,
				  '0' after 67 ns;

end tb;


