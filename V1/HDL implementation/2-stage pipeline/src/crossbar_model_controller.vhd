-----------------------------------------------------------------------
-- Project: CiM-Tile HW Design/implementation                        --
-- File	  : crossbar_model_controller.vhd                            --
-- Author : Remon van Duijnen (R.F.J.vanDuijnen@student.tudelft.nl)  --
-- Version: 1.0														 --
-----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity crossbar_model_controller is
	generic(crossbar_rows : integer);
	port( i_clk			: in std_logic;
		  i_FS 	  		: in std_logic_vector(3 downto 0);
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
end crossbar_model_controller;

architecture behavioural of crossbar_model_controller is

-- constants

-- components
	component crossbar_model_counter is
		port( i_set_val : in std_logic_vector(8 downto 0);
		 	  i_set : in std_logic;
			  clk : in std_logic;
			  clr : in std_logic;
	
			  o : out std_logic_vector(8 downto 0));
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

	component D_latch is
		port(
			D, E	: in std_logic;
			Q	 	: out std_logic 
		);
	end component;


-- signals
 	signal WE_FF_D, WE_FF_C, WE_FF_out : std_logic;
	signal s_done, s_done_D, s_done_pulse_1,  s_done_pulse_2 : std_logic;
	signal NOT_done, NOT_DoA, NOT_clk : std_logic;
	signal s_set_value : std_logic_vector (8 downto 0) := std_logic_vector(to_unsigned(crossbar_rows, 9));
	signal count_out : std_logic_vector(8 downto 0);

begin

-- done signal -------------------------------------------------

	s_done_D <= ((((((((count_out(8)) OR count_out(7)) OR count_out(6)) OR
			  		    count_out(5)) OR count_out(4)) OR count_out(3)) OR
			  		    count_out(2)) OR count_out(1)) NOR count_out(0);

	NOT_clk <= NOT i_clk;
	WE_FF_C <= NOT i_reset; -- NOR s_done;

FF0: D_FF_PC port map(D => s_done_D, E => '1', P => WE_FF_C, C => '1', clk => i_clk, Q => s_done);

	o_done <= s_done_D AND s_done;	-- continuous high when done

	-- pulse generation
FF1: D_FF_PC port map(D => s_done, E => '1', P => WE_FF_C, C => '1', clk => i_clk, Q => s_done_pulse_1);
FF2: D_FF_PC port map(D => s_done_pulse_1, E => '1', P => WE_FF_C, C => '1', clk => i_clk, Q => s_done_pulse_2);

	o_done_pulse <= s_done_pulse_1 AND (NOT s_done_pulse_2);

----------------------------------------------------------------
-- Write_enable ------------------------------------------------
	WE_FF_D <= i_DoA OR (WE_FF_out AND (NOT s_done_D));

FF3: D_FF_PC port map(D => WE_FF_D, E => '1', P => '1', C => WE_FF_C, clk => i_clk, Q => WE_FF_out);

	o_WE <= WE_FF_out;
	o_W_S <= WE_FF_out;

----------------------------------------------------------------
-- counter -----------------------------------------------------

U0: crossbar_model_counter port map(i_set_val => s_set_value,
									i_set => i_DoA,
									clk => i_clk,
									clr => i_reset,
									o => count_out);

----------------------------------------------------------------
-- FS signals --------------------------------------------------

	o_store 	   <= ((NOT i_FS(2)) AND (NOT i_FS(1)) AND (NOT i_FS(0)));
	o_all_columns  <= ((    i_FS(2)) AND (    i_FS(1)) AND (    i_FS(0)));
	o_mux_select(0) <= i_FS(0);
	o_mux_select(1) <= i_FS(2);


----------------------------------------------------------------
----------------------------------------------------------------




end behavioural;
