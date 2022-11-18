-----------------------------------------------------------------------
-- Project: CiM-Tile HW Design/implementation                        --
-- File	  : crossbar_model_top.vhd                                   --
-- Author : Remon van Duijnen (R.F.J.vanDuijnen@student.tudelft.nl)  --
-- Version: 1.0														 --
-----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

-- THIS ONE
-- FS encoding (may be changed)
-- 000 -> store
-- 001 -> -
-- 010 -> AND
-- 011 -> OR
-- 100 -> READ
-- 101 -> VRF
-- 110 -> XOR
-- 111 -> VMM

entity crossbar_model_top is
	generic (results_xplore   : integer;
	         crossbar_rows    : integer;
			 crossbar_columns : integer);
	port	(i_FS 	  		: in std_logic_vector(3 downto 0);
		 	 i_DoA   		: in std_logic;
			 i_clk	  		: in std_logic;
			 i_reset 		: in std_logic;
			 i_WD			: in std_logic_vector(crossbar_columns-1 downto 0);
			 i_WDS			: in std_logic_vector(crossbar_columns-1 downto 0);
			 i_RS			: in std_logic_vector(crossbar_rows-1 downto 0);

			 o_done				: out std_logic;
			 o_crossbar_output  : out std_logic_vector(crossbar_columns * integer(log2(real(crossbar_rows))) - 1 downto 0);

			test_array_FF_out_signals	:	out std_logic_vector(crossbar_rows * crossbar_columns - 1  downto 0));
end crossbar_model_top;

architecture behavioural of crossbar_model_top is

-- constants

-- components
	component crossbar_model_controller is
		generic(crossbar_rows : integer);
		port( i_FS 	  		: in std_logic_vector(3 downto 0);
		 	  i_DoA   		: in std_logic;
			  i_clk	  		: in std_logic;
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

	component crossbar_array_model is
		generic(results_xplore   :  integer;
		        crossbar_rows	 :	integer;
				crossbar_columns :	integer);
		port(i_clk			:   in std_logic;
			 i_WD			:	in std_logic_vector(crossbar_columns-1 downto 0);
			 i_WDS			:	in std_logic_vector(crossbar_columns-1 downto 0);
			 i_RS			:	in std_logic_vector(crossbar_rows-1 downto 0);
			 i_DoA			:	in std_logic;
			 i_store		:	in std_logic;
			 i_WE			:	in std_logic;
			 i_W_S			:	in std_logic;
	
			 o_array_inter	:	out std_logic_vector(crossbar_columns * integer(log2(real(crossbar_rows))) - 1 downto 0);
			 o_array_AND	:	out std_logic_vector(crossbar_columns-1 downto 0);
	
			-- test outputs
			test_array_FF_out_signals	:	out std_logic_vector(crossbar_rows * crossbar_columns - 1  downto 0));
	end component;

	component crossbar_model_op_filter is
		generic(crossbar_rows    : integer;
				crossbar_columns : integer);
		port   (i_array_inter   : in std_logic_vector(crossbar_columns * integer(log2(real(crossbar_rows))) - 1 downto 0);
				i_array_AND	 	: in std_logic_vector(crossbar_columns - 1 downto 0);
			    i_all_columns   : in std_logic;
				i_mux_select	: in std_logic_vector(1 downto 0);
		
				o_crossbar_output : out std_logic_vector(crossbar_columns * integer(log2(real(crossbar_rows))) - 1 downto 0)
	);
	end component;

-- signals
	signal s_W_S, s_WE, s_store : std_logic;	
	signal s_array_inter 		: std_logic_vector(crossbar_columns * integer(log2(real(crossbar_rows))) - 1 downto 0);
	signal s_array_AND   		: std_logic_vector(crossbar_columns-1 downto 0);
	signal s_all_columns 		: std_logic;
	signal s_mux_select 		: std_logic_vector(1 downto 0);

begin

U0: crossbar_model_controller generic map(crossbar_rows => crossbar_rows)
							  port map(i_FS    => i_FS,
									   i_DoA   => i_DoA,
									   i_clk   => i_clk,
									   i_reset => i_reset,

									   o_all_columns => s_all_columns,
									   o_mux_select => s_mux_select,
									   o_W_S   => s_W_S,
									   o_WE   => s_WE,
									   o_store   => s_store,
									   o_done   => o_done,
									   o_done_pulse   => open
									  );

U1: crossbar_array_model      generic map(results_xplore => results_xplore, crossbar_rows => crossbar_rows, crossbar_columns => crossbar_columns)
							  port map(i_clk		 => i_clk,
									   i_WD          => i_WD,
									   i_WDS         => i_WDS,
									   i_RS          => i_RS,
									   i_DoA         => i_DoA,
									   i_store       => s_store,
									   i_WE          => s_WE,
									   i_W_S         => s_W_S,

									   o_array_inter => s_array_inter,
									   o_array_AND   => s_array_AND,
									   test_array_FF_out_signals => test_array_FF_out_signals -- test sig
									  );

U2: crossbar_model_op_filter  generic map(crossbar_rows => crossbar_rows, crossbar_columns => crossbar_columns)
							  port map(i_array_inter => s_array_inter,
									   i_array_AND	 => s_array_AND,
									   i_all_columns => s_all_columns,
									   i_mux_select  => s_mux_select,
									   
									   o_crossbar_output => o_crossbar_output);

end behavioural;
