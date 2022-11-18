-----------------------------------------------------------------------
-- Project: CiM-Tile HW Design/implementation                        --
-- File	  : WD_reg_tb.vhd                                            --
-- Author : Remon van Duijnen (R.F.J.vanDuijnen@student.tudelft.nl)  --
-- Version: 1.0														 --
-----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use IEEE.math_real.all;

entity WD_reg_tb is
end WD_reg_tb;

architecture tb of WD_reg_tb is

-- constants
	constant clk_period			: 	time	:= 2 ns;
	constant crossbar_columns	:	integer	:= 16;
	constant WD_bandwidth		:	integer	:= 4;
	constant index_bits			:	integer := integer(ceil(log2(real(crossbar_columns/WD_bandwidth))));

-- components
	component WD_reg is
		generic(crossbar_columns :  integer;
				WD_bandwidth	 :  integer
				);
		port(	i_clk 			 :  in std_logic;
				i_WD			 :	in std_logic_vector(WD_bandwidth - 1 downto 0);
				i_index			 :	in std_logic_vector(integer(ceil(log2(real(crossbar_columns/WD_bandwidth)))) - 1 downto 0);
				i_WD_activate	 :	in std_logic;

				o_WD			 :	out std_logic_vector(crossbar_columns - 1 downto 0)
			);
	end component;

-- signals
	-- inputs
	signal i_data	  :	std_logic_vector(WD_bandwidth - 1 downto 0);
	signal i_index	  :	std_logic_vector(index_bits - 1 downto 0);
	signal i_activate :	std_logic;
	signal clk 		  : std_logic := '0';

	-- outputs
	signal output	  :	std_logic_vector(crossbar_columns - 1 downto 0);

begin

	clk <= NOT clk after clk_period / 2;

uut: WD_reg generic map(crossbar_columns => crossbar_columns, WD_bandwidth => WD_bandwidth)
			 port map(i_clk => clk, i_WD => i_data, i_index => i_index, i_WD_activate => i_activate, o_WD => output);

-- test for crossbar_columns = 16, WD_bandwidth = 4. (index_bits = 2)
	i_data <= 	"0000",
				"0001" after 10 ns,
				"0010" after 20 ns,
				"0011" after 30 ns,
				"0100" after 40 ns,
				"0101" after 50 ns,
				"0110" after 60 ns,
				"0111" after 70 ns,
				"1000" after 80 ns,
				"1001" after 90 ns;

	i_index <=	"00",
				"01" after 22 ns,
				"10" after 47 ns,
				"11" after 72 ns;

	i_activate <= '0',
				  '1' after 5 ns,
			      '0' after 7 ns,
				  '1' after 15 ns,
			      '0' after 17 ns,
				  '1' after 25 ns,
			      '0' after 27 ns,
				  '1' after 35 ns,
			      '0' after 37 ns,
				  '1' after 45 ns,
			      '0' after 47 ns,
				  '1' after 55 ns,
			      '0' after 57 ns,
				  '1' after 65 ns,
			      '0' after 67 ns,
				  '1' after 75 ns,
			      '0' after 77 ns,
				  '1' after 85 ns,
			      '0' after 87 ns,
				  '1' after 95 ns,
			      '0' after 97 ns;

end tb;
