-----------------------------------------------------------------------
-- Project: CiM-Tile HW Design/implementation                        --
-- File	  : RD_buffer_counter_tb.vhd                                 --
-- Author : Remon van Duijnen (R.F.J.vanDuijnen@student.tudelft.nl)  --
-- Version: 1.0														 --
-----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity RD_buffer_counter_tb is
end RD_buffer_counter_tb;

architecture tb of RD_buffer_counter_tb is

-- constants
	constant bit_size    : integer := 5;
	constant clk_period : time    := 2 ns;

-- components

	component RD_buffer_counter is
		generic(bit_size : integer);
		port( set_or_decrease : in std_logic;
			  E        		  : in std_logic;
			  set_val         : in std_logic_vector(bit_size - 1 downto 0);
			  clk 			  : in std_logic;
			  clr 			  : in std_logic;
	
			  o 			  : out std_logic_vector(bit_size - 1 downto 0)
	);
	end component;

-- signals
	-- inputs
	signal clk				: std_logic := '0';
	signal rst				: std_logic;
	signal set_or_decrease  : std_logic;
	signal E 			    : std_logic;
	signal set_val 			: std_logic_vector(bit_size - 1 downto 0);

	-- outputs
	signal o : std_logic_vector(bit_size -1 downto 0);

begin 

	clk <= NOT clk after clk_period /2 ;

uut: RD_buffer_counter generic map(bit_size => bit_size)
					   port map(   set_or_decrease => set_or_decrease,
								   E 			   => E,
								   set_val 		   => set_val,
								   clk 			   => clk,
								   clr 			   => rst,

								   o => o);

	set_or_decrease <= '1',
					   '0' after 14 ns,
					   '1' after 50 ns,
				 	   '0' after 52 ns;

	E <= '0',
		 '1' after 10 ns,
		 '0' after 14 ns,
		 '1' after 20 ns,
		 '0' after 22 ns,
		 '1' after 30 ns,
		 '0' after 32 ns,
		 '1' after 50 ns,
		 '0' after 52 ns,
		 '1' after 60 ns,
		 '0' after 76 ns;
		
	set_val <= "00000",
			   "00010" after 10 ns,
			   "01000" after 50 ns;

	rst <= '0',
		   '1' after 2 ns,
		   '0' after 4 ns;

end tb;

