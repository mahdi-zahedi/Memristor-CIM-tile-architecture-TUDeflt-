-----------------------------------------------------------------------
-- Project: CiM-Tile HW Design/implementation                        --
-- File	  : crossbar_model_controller_tb.vhd                         --
-- Author : Remon van Duijnen (R.F.J.vanDuijnen@student.tudelft.nl)  --
-- Version: 1.0														 --
-----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity crossbar_model_controller_tb is
end crossbar_model_controller_tb;

architecture tb of crossbar_model_controller_tb is

-- constants
	constant clk_period    : time    := 2 ns;
	constant crossbar_rows : integer := 8;

-- components
	component crossbar_model_controller is
		generic(crossbar_rows : integer);
		port( i_clk	  		: in std_logic;
			  i_FS 	  		: in std_logic_vector(2 downto 0);
		 	  i_DoA   		: in std_logic;
			  i_reset 		: in std_logic;
	
			  -- outputs to operation filter
			  o_mux_select  : out std_logic_vector(1 downto 0);
			  o_all_columns : out std_logic;
	
			  -- output to model array
			  o_W_S   		: out std_logic;
			  o_WE 	  		: out std_logic;
			  o_store 		: out std_logic;
	
			  -- outputs to tile controller
			  o_done  		: out std_logic;
			  o_done_pulse  : out std_logic
	);
	end component;

-- signals
	-- inputs
	signal s_FS    : std_logic_vector(2 downto 0);
	signal s_DoA   : std_logic;
	signal s_clk   : std_logic := '1';
	signal s_reset : std_logic;

	-- outputs
	signal s_mux_select  : std_logic_vector(1 downto 0);
	signal s_all_columns : std_logic;
	signal s_W_S   		 : std_logic;
	signal s_WE    		 : std_logic;
	signal s_store 		 : std_logic;
	signal s_done  		 : std_logic;
	signal s_done_pulse  : std_logic;

begin

	s_clk <= NOT s_clk after clk_period / 2;

uut: crossbar_model_controller  generic map(crossbar_rows => crossbar_rows)
								port map(i_clk   => s_clk,
										 i_FS    => s_FS,
										 i_DoA   => s_DoA,
										 i_reset => s_reset,

										 o_mux_select  => s_mux_select,
										 o_all_columns => s_all_columns,
										 o_W_S   	   => s_W_S,
										 o_WE    	   => s_WE,
										 o_store 	   => s_store,
										 o_done  	   => s_done,
									     o_done_pulse  => s_done_pulse
										);

-- test for crossbar_rows = 8. 
-- TEST SHOULD BE APPENDED WITH FS SIGNALS TO CHECK OPERATION FILTER OUTPUTS	
	s_reset <= '1',
			   '0' after 1 ns;	

	s_FS <= "000",
			"101" after 50 ns;
	
	s_DoA <= 	'0',
				'1' after 10 ns,
				'0' after 12 ns,
				'1' after 60 ns,
				'0' after 62 ns;		

	

end tb;