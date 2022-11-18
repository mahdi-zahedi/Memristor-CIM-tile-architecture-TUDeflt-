-----------------------------------------------------------------------
-- Project: CiM-Tile HW Design/implementation                        --
-- File	  : stall_detection_2_stage_tb.vhd                           --
-- Author : Remon van Duijnen (R.F.J.vanDuijnen@student.tudelft.nl)  --
-- Version: 1.0														 --
-----------------------------------------------------------------------

-- NOTE: This file is outdated due to changes when testing the top tb. 
--       This file should be checked/changed

library ieee;
use ieee.std_logic_1164.all;

entity stall_detection_2_stage_tb is
end entity;

architecture tb of stall_detection_2_stage_tb is

-- constants
	constant clk_period : time := 2 ns;

-- components
	component stall_detection_2_stage is
	port(i_clk : in std_logic;
		 i_rst : in std_logic;
	
		 -- instruction signals
		 i_FS_op  			 : in std_logic;
		 i_DoS_op  			 : in std_logic;
		 i_DoA_op  			 : in std_logic;
		 i_WD_op  			 : in std_logic;
		 i_output_buffer_op  : in std_logic;
		 i_BNE_op			 : in std_logic;
	 	 i_LS_op			 : in std_logic;
	  	 i_RF_op			 : in std_logic;
	  	 i_CSR_op			 : in std_logic;

	 	 -- operation signals
	 	 i_VRF : in std_logic;
		
		 -- buffer status signals
		 i_WD_buffer_empty    : in  std_logic;
		 i_RD_buffer_empty    : in std_logic;
		 i_output_buffer_full : in std_logic;

	 	 -- done signals
	 	 i_array_done : in std_logic;
	 	 -- i_ADC_done   : in std_logic; -- assumed to be single cycle
	
		 -- output stall signals
		 o_stall_1 : out std_logic;
		 o_stall_2 : out std_logic;
		 o_flag_1  : out std_logic;
		 o_flag_2  : out std_logic);
	end component;

-- signals
	-- inputs
	signal clk 		 		  	 : std_logic := '1';
	signal rst					 : std_logic;
	signal i_array_done			 : std_logic;
	signal i_FS_op 			  	 : std_logic;
	signal i_DoS_op 		  	 : std_logic;
	signal i_DoA_op 		  	 : std_logic;
	signal i_WD_op 			  	 : std_logic;
	signal i_output_buffer_op 	 : std_logic;
	signal i_BNE_op				 : std_logic;
	signal i_VRF				 : std_logic;
	signal i_WD_buffer_empty  	 : std_logic;
	signal i_RD_buffer_empty  	 : std_logic;
	signal i_output_buffer_full  : std_logic;
	signal i_LS_op			 	 : std_logic;
	signal i_RF_op			  	 : std_logic;
	signal i_CSR_op			  	 : std_logic;

	-- outputs
	signal o_stall_1 : std_logic;
	signal o_stall_2 : std_logic;
	signal o_flag_1  : std_logic;
	signal o_flag_2  : std_logic;

begin

	clk <= NOT clk after clk_period / 2;

	rst <= '1',
		   '0' after 2 ns;

uut: stall_detection_2_stage port map(i_clk 			 => clk,
									  i_rst				 => rst,
									  i_FS_op 			 => i_FS_op,
									  i_DoS_op 			 => i_DoS_op,
									  i_DoA_op 			 => i_DoA_op,
									  i_WD_op 		     => i_WD_op,
									  i_output_buffer_op => i_output_buffer_op,
									  i_BNE_op			 => i_BNE_op,
									  i_LS_op 			 => i_LS_op,
									  i_RF_op 			 => i_RF_op,
									  i_CSR_op			 => i_CSR_op,
									

									  i_VRF => i_VRF,

									  i_WD_buffer_empty    => i_WD_buffer_empty,
									  i_RD_buffer_empty    => i_RD_buffer_empty,
									  i_output_buffer_full => i_output_buffer_full,
									
									  i_array_done => i_array_done,

									  o_stall_1 => o_stall_1,
									  o_stall_2 => o_stall_2,
									  o_flag_1  => o_flag_1,
								      o_flag_2  => o_flag_2);

	i_FS_op 		   <= '0',
						  '1' after  2 ns,
						  '0' after  4 ns,
						  '1' after 20 ns,
						  '0' after 22 ns,
						  '1' after 34 ns,
						  '0' after 36 ns;

	i_array_done	   <= '1',
						  '0' after 60 ns,
						  '1' after 64 ns;

	i_DoS_op 		   <= '0',
						  '1' after 18 ns,
						  '0' after 20 ns,
						  '1' after 26 ns,
						  '0' after 34 ns,
						  '1' after 44 ns,
						  '0' after 46 ns,
						  '1' after 62 ns,
						  '0' after 66 ns;

	i_DoA_op 		   <= '0',
						  '1' after 12 ns,
						  '0' after 16 ns;

	i_WD_op 		   <= '0',
						  '1' after  6 ns,
						  '0' after 10 ns;

	i_output_buffer_op <= '0',
						  '1' after 24 ns,
						  '0' after 28 ns;

	i_BNE_op 		   <= '0',
						  '1' after 50 ns,
						  '0' after 52 ns;

	i_VRF    		   <= '0',
						  '1' after  36 ns;

	i_LS_op    		   <= '0',
						  '1' after 30 ns,
						  '0' after 36 ns,
						  '1' after 52 ns;
						  --'0' after 36 ns;

	i_CSR_op    		   <= '0',
						  '1' after 20 ns,
						  '0' after 22 ns,
						  '1' after 36 ns,
						  '0' after 38 ns,
						  '1' after 40 ns,
						  '0' after 48 ns;

	i_RF_op    		   <= '0',
						  '1' after 22 ns,
						  '0' after 24 ns,
						  '1' after 38 ns,
						  '0' after 40 ns,
						  '1' after 48 ns,
						  '0' after 50 ns;

	i_WD_buffer_empty  <= '1',
						  '0' after 8 ns;

	i_RD_buffer_empty  <= '1',
						  '0' after 14 ns;
 
	i_output_buffer_full  <= '1',
						  	 '0' after 26 ns;
	


end tb;
