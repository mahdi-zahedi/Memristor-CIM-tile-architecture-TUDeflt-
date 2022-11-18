-----------------------------------------------------------------------
-- Project: CiM-Tile HW Design/implementation                        --
-- File	  : D_FF_PC_tb.vhd                                           --
-- Author : Remon van Duijnen (R.F.J.vanDuijnen@student.tudelft.nl)  --
-- Version: 1.0														 --
-----------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

entity D_FF_PC_tb is
end D_FF_PC_tb;


architecture tb of D_FF_PC_tb is

	constant clk_period : time := 2 ns;

	component D_FF_PC port(
		D	: in std_logic;
		E	: in std_logic;
		P	: in std_logic;
		C	: in std_logic;
		clk : in std_logic;
		Q	 	: out std_logic 
		);
	end component;

	-- inputs
	signal D   : std_logic;
	signal E   : std_logic;
	signal P   : std_logic;
	signal C   : std_logic;
	signal clk : std_logic := '0';
	
	--outputs
	signal Q : std_logic;

begin

	clk <= NOT clk after clk_period / 2;

uut: D_FF_PC port map(
		D   => D,
		E   => E,
		P   => P,
		C   => C,
		clk => clk,
		Q   => Q
	);

--	D <= '1' after 25 ns, '0' after 35 ns;
--	E <= '1' after 10 ns, '0' after 11 ns, '1' after 30 ns, '0' after 31 ns, '1' after 50 ns, '0' after 51 ns;
--	P <= '0' after 55 ns, '1' after 56 ns; 
--	C <= '0' after 58 ns, '1' after 59 ns;

	D <= '1';

	E <= '0',
		 '1' after 4 ns,
		 '0' after 6 ns;

	P <= '1',
		 '0' after 20 ns,
		 '1' after 21 ns;

	C <= '1',
		 '0' after 10 ns,
		 '1' after 11 ns;

end tb;
