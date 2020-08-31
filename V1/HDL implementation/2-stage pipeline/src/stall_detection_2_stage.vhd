-----------------------------------------------------------------------
-- Project: CiM-Tile HW Design/implementation                        --
-- File	  : stall_detection_2_stage.vhd                              --
-- Author : Remon van Duijnen (R.F.J.vanDuijnen@student.tudelft.nl)  --
-- Version: 1.0														 --
-----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity stall_detection_2_stage is
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
	 i_NOP_1			 : in std_logic;
	 i_NOP_2			 : in std_logic;
	 i_RDSh_op			 : in std_logic;

	 -- operation signals
	 i_VRF : in std_logic;
	 i_VMM : in std_logic;
	
	 -- buffer status signals
	 i_WD_buffer_empty    : in  std_logic;
	 i_RD_buffer_empty    : in std_logic;
	 i_output_buffer_full : in std_logic;

	 -- done signals
	 i_array_done : in std_logic;
	 -- i_ADC_done   : in std_logic; -- assumed to be single cycle

	 -- output stall signals
	 o_stall_1   : out std_logic;
	 o_stall_2   : out std_logic;
	 o_flag_1    : out std_logic;
	 o_flag_2    : out std_logic;

	 o_tile_done : out std_logic);
end entity;

architecture behavioural of stall_detection_2_stage is

-- constants

-- components
	component D_FF port(
		D	: in std_logic;
		E	: in std_logic;
		clk : in std_logic;
		Q	: out std_logic 
		);
	end component;

-- signals
	signal stage_1_S, stage_1_R, stage_1_E, stage_1_flag : std_logic;
	signal stage_2_S, stage_2_R, stage_2_E, stage_2_flag : std_logic;
	signal DoS_exec 			              : std_logic;
	signal VRF_FF_S, VRF_FF_R, VRF_FF_E 	  : std_logic;
	signal s_stall_1, s_stall_2               : std_logic;
	signal VRF_stall 			              : std_logic;
	signal RF_FF_S, RF_FF_R, RF_FF_E		  : std_logic;
	signal stage_2_next_section               : std_logic;
	signal RF_flag				              : std_logic;


begin

	o_tile_done <= i_NOP_1 AND i_NOP_2;

-- busy flag generation
	DoS_exec <= i_DoS_op AND (NOT s_stall_1);

	stage_1_S <= i_FS_op AND (NOT i_rst);
	stage_1_R <= DoS_exec OR i_rst;
	stage_1_E <= stage_1_S OR stage_1_R;
	
	stage_2_S <= stage_1_R AND (NOT i_rst);
	stage_2_R <= stage_2_next_section OR i_rst;
	stage_2_E <= stage_2_S OR stage_2_R;

U0: D_FF  port map(D => stage_1_S, E => stage_1_E, clk => i_clk, Q => stage_1_flag);
--U0: SR_FF port map(S => stage_1_S, R => stage_1_R, E => i_clk, Q => stage_1_flag);

U1: D_FF  port map(D => stage_2_S, E => stage_2_E, clk => i_clk, Q => stage_2_flag);
--U1: SR_FF port map(S => stage_2_S, R => stage_2_R, E => i_clk, Q => stage_2_flag);

	o_flag_1 <= stage_1_flag;
	o_flag_2 <= stage_2_flag;


-- stall detection
	VRF_FF_S <= (i_VRF AND DoS_exec) AND (NOT i_rst);
	VRF_FF_R <= i_BNE_op OR i_rst;
	VRF_FF_E <= VRF_FF_S OR VRF_FF_R;

U2: D_FF  port map(D => VRF_FF_S, E => VRF_FF_E, clk => i_clk, Q => VRF_stall);
-- U2: SR_FF port map(S => VRF_FF_S, R => VRF_FF_R, E => i_clk, Q => VRF_stall);

s_stall_1 <= (i_WD_buffer_empty AND i_WD_op ) OR
			 (i_RD_buffer_empty AND i_RDSh_op) OR --(i_DoA_op AND i_VMM)) OR
			 ((stage_2_flag OR (NOT i_array_done)) AND  i_DoS_op) OR
			 ((NOT i_array_done) AND i_DoA_op) OR
			 (VRF_stall) OR
			 i_NOP_1;

s_stall_2 <= (NOT stage_2_flag) OR 
			 (i_output_buffer_op AND i_output_buffer_full) OR
			 stage_2_next_section OR
			 i_NOP_2;

o_stall_1 <= s_stall_1;
o_stall_2 <= s_stall_2;

-- RF flag
U3: D_FF  port map(D => RF_FF_S, E => RF_FF_E, clk => i_clk, Q => RF_flag);
--U3: SR_FF port map(S => RF_FF_S, R => RF_FF_R, E => i_clk, Q => RF_flag);

	RF_FF_S <= i_RF_op AND (NOT i_rst);
	RF_FF_R <= stage_2_next_section OR i_rst;
	RF_FF_E <= RF_FF_S OR RF_FF_R;

	stage_2_next_section <= (i_LS_op OR i_CSR_op) AND RF_flag;


end behavioural;
