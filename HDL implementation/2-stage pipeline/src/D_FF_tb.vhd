-----------------------------------------------------------------------
-- Project: CiM-Tile HW Design/implementation                        --
-- File	  : D_FF_tb.vhd                                              --
-- Author : Remon van Duijnen (R.F.J.vanDuijnen@student.tudelft.nl)  --
-- Version: 1.0														 --
-----------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

entity D_FF_tb is
end D_FF_tb;


architecture tb of D_FF_tb is

	constant clk_period : time := 2 ns;
	
	component D_FF port(
		D	: in std_logic;
		E	: in std_logic;
		clk : in std_logic;
		Q	: out std_logic 
		);
	end component;

	-- inputs
	signal D   : std_logic := '0';
	signal E   : std_logic := '0';
	signal clk : std_logic := '0';
	
	--outputs
	signal Q : std_logic;

begin

	clk <= NOT clk after clk_period / 2;

	uut: D_FF port map(
		D => D,
		E => E,
		Q => Q,
		clk => clk
	);

	D <=  '1' after 25 ns, '0' after 35 ns;
	E <= '1' after 10 ns, '0' after 20 ns, '1' after 29 ns, '0' after 40 ns, '1' after 50 ns, '0' after 60 ns;

end tb;