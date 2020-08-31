-----------------------------------------------------------------------
-- Project: CiM-Tile HW Design/implementation                        --
-- File	  : tile_controller_top.vhd                                  --
-- Author : Remon van Duijnen (R.F.J.vanDuijnen@student.tudelft.nl)  --
-- Version: 1.0														 --
-----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity tile_controller_top is
generic(bandwidth  		  : integer;
		mem_size_1 		  : integer;
		mem_size_2 		  : integer;
		inst_size         : integer; -- stage 2 inst size in bytes excl first byte
		num_ADCs   		  : integer;
	 	crossbar_columns  : integer;
		WD_reg_num		  : integer;
		max_datatype_size : integer);
port(i_clk 			 : in std_logic;
	 i_rst 			 : in std_logic;
	 i_instruction_1 : in std_logic_vector(bandwidth + 16 - 1 downto 0);
	 i_instruction_2 : in std_logic_vector((inst_size + 1) * 8 - 1 downto 0);
	 i_VRF_flag      : in std_logic;
	 i_array_done    : in std_logic;
	 -- i_ADC_done : in std_logic;

	 -- from outside
	 i_RD_outside_E 	  : in std_logic;
	 i_WD_outside_E		  : in std_logic;
	 i_RD_write_done 	  : in std_logic;
	 i_WD_write_done 	  : in std_logic;
	 i_RD_set_val    	  : in std_logic_vector(integer(log2(real(max_datatype_size))) - 0 downto 0);
	 i_output_buffer_read : in std_logic;

	 o_RDS_data  : out std_logic_vector(bandwidth - 1 downto 0);
	 o_WDS_data  : out std_logic_vector(bandwidth - 1 downto 0);
	 o_FS_reg_1  : out std_logic_vector(3 downto 0);
	 o_DTS_reg_1 : out std_logic_vector(3 downto 0);
	 o_FS_reg_2  : out std_logic_vector(3 downto 0); -- for stage 2
	 o_DTS_reg_2 : out std_logic_vector(3 downto 0); -- for stage 2

	 o_WD_index   : out std_logic_vector(7 downto 0); 
	 o_RDS_index  : out std_logic_vector(7 downto 0);
	 o_WDS_index  : out std_logic_vector(7 downto 0);

	 o_RDS_E    : out std_logic;
	 o_RDS_c    : out std_logic;
	 o_RDS_s    : out std_logic;
	 o_RD_E     : out std_logic;
	 o_RD_empty : out std_logic;
	 o_WDS_E    : out std_logic;
	 o_WDS_c    : out std_logic;
	 o_WDS_s    : out std_logic;
	 o_WD_E     : out std_logic;
	 o_DoA      : out std_logic;
	 o_DoS      : out std_logic;

	 o_CSR_index : out std_logic_vector(integer(log2(real(crossbar_columns/num_ADCs))) - 1 downto 0);
	 o_CSR_data  : out std_logic_vector(num_ADCs - 1 downto 0); 
	 o_AS_data   : out std_logic_vector(num_ADCs - 1 downto 0);

	 o_CSR_E		   : out std_logic;
	 o_AS_E			   : out std_logic;
	 o_IADD_E		   : out std_logic;
	 o_output_buffer_E : out std_logic;
	 o_CP			   : out std_logic;
	 o_CB   		   : out std_logic;	
	 o_LS 			   : out std_logic;
	
	 o_PC_1 : out std_logic_vector(integer(log2(real(mem_size_1))) - 1 downto 0);
	 o_PC_2 : out std_logic_vector(integer(log2(real(mem_size_2))) - 1 downto 0);
	
	-- to outside
	 o_tile_done      : out std_logic;
 	 o_RD_request     : out std_logic;
	 o_WD_request     : out std_logic;
	 o_output_request : out std_logic;

	-- test signals;
	test_BNE : out std_logic;
	o_stall_1, o_stall_2 : out std_logic;
	test_return_reg : out std_logic_vector(integer(log2(real(mem_size_1))) - 1 downto 0);
	test_jr_flag : out std_logic
	);
end entity;

architecture behavioural of tile_controller_top is

-- constants

-- components
	component decoder_stage_1 is
	generic(bandwidth : integer;
			mem_size  : integer -- in bytes
	);
	port(i_clk, i_rst  : in std_logic; 
		 i_instruction : in std_logic_vector(bandwidth + 16 - 1 downto 0);
		 i_stall	   : in std_logic;
		 i_branch	   : in std_logic;
	
		-- Data to fill in register
		 o_RDS_data : out std_logic_vector(bandwidth - 1 downto 0);
		 o_WDS_data : out std_logic_vector(bandwidth - 1 downto 0);
		 o_FS_data  : out std_logic_vector(3 downto 0);
		 o_DTS_data : out std_logic_vector(3 downto 0);
		 
		-- index bits to MUXs
		 o_WD_index   : out std_logic_vector(7 downto 0); 
		 o_RDS_index  : out std_logic_vector(7 downto 0);
		 o_WDS_index  : out std_logic_vector(7 downto 0);
	
		-- register activation signals
		 o_RDS_E   : out std_logic;
		 o_RDS_c   : out std_logic;
		 o_RDS_s   : out std_logic;
		 o_RD_E    : out std_logic;
		 o_WDS_E   : out std_logic;
		 o_WDS_c   : out std_logic;
		 o_WDS_s   : out std_logic;
		 o_WD_E    : out std_logic;
		 o_WD_op   : out std_logic;
		 o_FS_E    : out std_logic;
	 	 o_FS_op   : out std_logic;
		 o_DoA_S   : out std_logic;
		 o_DoA_op  : out std_logic;
		 o_DTS_E   : out std_logic;
		 o_DoS_E   : out std_logic;
		 o_DoS_op  : out std_logic;
	 	 o_NOP_1   : out std_logic;
		 o_RDsh_op : out std_logic;
		 
		 o_PC : out std_logic_vector(integer(log2(real(mem_size))) - 1 downto 0)
	);
	end component;
	
	component decoder_stage_2 is
	generic(inst_size : integer; -- in bytes, excluding first byte
			mem_size  : integer; -- in bytes
			num_ADCs  : integer;
			crossbar_columns : integer
	);
	port(i_clk, i_rst  : in std_logic; 
		 i_instruction : in std_logic_vector((inst_size + 1) * 8 - 1 downto 0);
		 i_stall	   : in std_logic;
		 i_VRF_flag    : in std_logic;
		 i_FS		   : in std_logic_vector(3 downto 0);
	
		 -- index bits to MUXs
		 o_CSR_index : out std_logic_vector(integer(log2(real(crossbar_columns/num_ADCs))) - 1 downto 0);
		 o_CSR_data   : out std_logic_vector(num_ADCs - 1 downto 0); 
		 o_AS_data  : out std_logic_vector(num_ADCs - 1 downto 0);
	
		 o_CSR_E		   : out std_logic;
		 o_CSR_op          : out std_logic;
		 o_LS_E  		   : out std_logic;
		 o_RF_op		   : out std_logic;
		 o_AS_E			   : out std_logic;
		 o_IADD_E		   : out std_logic;
		 o_BNE   		   : out std_logic;
		 o_BNE_op		   : out std_logic;
		 o_output_buffer_E : out std_logic;
	 	 o_output_buffer_op: out std_logic;
		 o_CP			   : out std_logic;
		 o_CB   		   : out std_logic;
		 o_NOP_2		   : out std_logic;
	
		 o_LS : out std_logic;
	
		 o_PC : out std_logic_vector(integer(log2(real(mem_size))) - 1 downto 0);
	
		-- test signals
		o_jr_reg    : out std_logic_vector(integer(log2(real(mem_size))) - 1 downto 0);
		test_jr_flag : out std_logic;
		o_branch_reg : out std_logic_vector(integer(log2(real(mem_size))) - 1 downto 0)
	);
	end component;

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
		 o_stall_1 : out std_logic;
		 o_stall_2 : out std_logic;
		 o_flag_1  : out std_logic;
		 o_flag_2  : out std_logic;

		 o_tile_done : out std_logic);
	end component;

	component buffer_management is
	generic(WD_reg_num        : integer;
			max_datatype_size : integer);
	port(i_clk, i_rst    	  : in std_logic;
		 i_RD_E          	  : in std_logic;
		 i_RD_write_done 	  : in std_logic;
		 i_WD_E          	  : in std_logic;
		 i_WD_write_done      : in std_logic;
		 i_RD_set_val 		  : in std_logic_vector(integer(log2(real(max_datatype_size)))-0 downto 0);
	     i_output_buffer_E 	  : in std_logic;
	 	 i_output_buffer_read : in std_logic;
	
		 o_RD_request     : out std_logic;
		 o_WD_request     : out std_logic;
		 o_RD_empty       : out std_logic;
		 o_WD_empty       : out std_logic;
	     o_output_request : out std_logic;
		 o_output_full    : out std_logic);
	end component;

	component D_FF_PC port(
		D	: in std_logic;
		E	: in std_logic;
		P	: in std_logic;
		C	: in std_logic;
		clk : in std_logic;
		Q	: out std_logic);
	end component;


-- signals
	signal s_stall_1, s_stall_2, s_branch_1 : std_logic;
	signal FS_reg_D, s_FS_reg_1, s_FS_reg_2    : std_logic_vector(3 downto 0);
	signal DTS_reg_D, s_DTS_reg_1, s_DTS_reg_2 : std_logic_vector(3 downto 0);
	signal s_FS_is_VRF, s_FS_is_VMM : std_logic;
	signal s_FS_op, s_DoS_op, s_DoA_op, s_WD_op, s_output_buffer_op, s_BNE_op, s_RDsh_op : std_logic;
	signal s_WD_buffer_empty, s_RD_buffer_empty, s_output_buffer_full : std_logic;

	signal s_RD_inside_E, s_WD_inside_E, s_output_buffer_E : std_logic;
	signal s_RD_E, s_WD_E : std_logic;
	signal s_FS_E, s_DoA_S, s_DoS_E, s_DTS_E : std_logic;
	signal s_CSR_E, s_CSR_op, s_LS_E, s_RF_op : std_logic;
	signal reg_clr : std_logic;

	signal s_NOP_1, s_NOP_2 : std_logic;
	

begin

	reg_clr <= NOT i_rst;

-- FS register ---

G0:	for i in 3 downto 0 generate
U0:		D_FF_PC port map(D => FS_reg_D(i), E => s_FS_E, P => '1', C => reg_clr, clk => i_clk, Q => s_FS_reg_1(i));
U1:		D_FF_PC port map(D => s_FS_reg_1(i), E => s_DoS_E, P => '1', C => reg_clr, clk => i_clk, Q => s_FS_reg_2(i));
	end generate;

	o_FS_reg_1 <= s_FS_reg_1;
	o_FS_reg_2 <= s_FS_reg_2;
	s_FS_is_VRF <= (    s_FS_reg_1(2)) AND (NOT s_FS_reg_1(1)) AND (    s_FS_reg_1(0));
	s_FS_is_VMM <= (    s_FS_reg_1(2)) AND (    s_FS_reg_1(1)) AND (    s_FS_reg_1(0));

-- DTS register --

G1:	for i in 3 downto 0 generate
U2:		D_FF_PC port map(D => DTS_reg_D(i), E => s_DTS_E, P => '1', C => reg_clr, clk => i_clk, Q => s_DTS_reg_1(i));
U3:		D_FF_PC port map(D => s_DTS_reg_1(i), E => s_DoS_E, P => '1', C => reg_clr, clk => i_clk, Q => s_DTS_reg_2(i));
	end generate;

	o_DTS_reg_1 <= s_DTS_reg_1;
	o_DTS_reg_2 <= s_DTS_reg_2;

-- DoS/DoA registers???

-- decoder 1 ------------------------------------------------------------------

U0:  decoder_stage_1 generic map(bandwidth => bandwidth, mem_size => mem_size_1)
					 port map   (i_clk => i_clk, i_rst => i_rst,
								 i_instruction => i_instruction_1,
								 i_stall => s_stall_1,
								 i_branch => s_branch_1,

								 o_RDS_data => o_RDS_data,
								 o_WDS_data => o_WDS_data,
								 o_FS_data => FS_reg_D,
								 o_DTS_data => DTS_reg_D,

								 o_WD_index => o_WD_index,
								 o_RDS_index => o_RDS_index,
								 o_WDS_index => o_WDS_index,

								 o_RDS_E => o_RDS_E,
								 o_RDS_c => o_RDS_c,
								 o_RDS_s => o_RDS_s,
								 o_RD_E  => s_RD_inside_E,
								 o_WDS_E => o_WDS_E,
								 o_WDS_c => o_WDS_c,
								 o_WDS_s => o_WDS_s,
								 o_WD_E  => s_WD_inside_E,
								 o_WD_op => s_WD_op,
								 o_FS_E  => s_FS_E,
								 o_FS_op => s_FS_op,
								 o_DoA_S => s_DoA_S,
								 o_DoA_op=> s_DoA_op,
								 o_DTS_E => s_DTS_E,
								 o_DoS_E => s_DoS_E,
							     o_DoS_op=> s_DoS_op,
								 o_NOP_1 => s_NOP_1,
								 o_RDsh_op => s_RDsh_op,

								 o_PC => o_PC_1);

	s_RD_E <= s_RD_inside_E OR i_RD_outside_E;
	s_WD_E <= s_WD_inside_E OR i_WD_outside_E;
	o_RD_E <= s_RD_E;
	o_WD_E <= s_WD_E;
	o_DoA <= s_DoA_S;
	o_DoS <= s_DoS_E;

-- decoder 2 ------------------------------------------------------------------

U1:  decoder_stage_2 generic map (inst_size => inst_size,
								  mem_size => mem_size_2,
								  num_ADCs => num_ADCs,
								  crossbar_columns => crossbar_columns)
					 port map(i_clk => i_clk, i_rst => i_rst,
							  i_instruction => i_instruction_2,
							  i_stall 	    => s_stall_2,
							  i_VRF_flag    => i_VRF_flag,
							  i_FS		    => s_FS_reg_2,

							  o_CSR_index => o_CSR_index,
							  o_CSR_data  => o_CSR_data,
							  o_AS_data   => o_AS_data,

							  o_CSR_E 			=> s_CSR_E,
						 	  o_CSR_op			=> s_CSR_op,
						      o_LS_E            => s_LS_E,
						      o_RF_op           => s_RF_op,
							  o_AS_E 			=> o_AS_E,
							  o_IADD_E 			=> o_IADD_E,
							  o_BNE 			=> s_branch_1,
							  o_BNE_op		    => s_BNE_op,
							  o_output_buffer_E => s_output_buffer_E,
							  o_output_buffer_op=> s_output_buffer_op,
					   	      o_CP 			    => o_CP,
							  o_CB 			    => o_CB,
							  o_NOP_2 			=> s_NOP_2,

							  o_LS => o_LS,

							  o_PC => o_PC_2,

							  -- test signals
							  o_branch_reg => open,
							  o_jr_reg     => test_return_reg,
							  test_jr_flag => test_jr_flag);

	o_output_buffer_E <= s_output_buffer_E;
	o_CSR_E <= s_CSR_E;
	
	test_BNE <= s_BNE_op;

-- stall detection ------------------------------------------------------------

U2:  stall_detection_2_stage port map(i_clk 			 => i_clk,
									  i_rst				 => i_rst,
									  i_FS_op 			 => s_FS_op,
									  i_DoS_op 			 => s_DoS_op,
									  i_DoA_op 			 => s_DoA_op,
									  i_WD_op 		     => s_WD_op,
									  i_output_buffer_op => s_output_buffer_op,
									  i_BNE_op			 => s_BNE_op,
									  i_LS_op			 => s_LS_E,
									  i_RF_op			 => s_RF_op,
									  i_CSR_op			 => s_CSR_op,
									  i_NOP_1			 => s_NOP_1,
									  i_NOP_2			 => s_NOP_2,
									  i_RDsh_op 		 => s_RDsh_op, 

									  i_VRF => s_FS_is_VRF,
									  i_VMM => s_FS_is_VMM,

									  i_WD_buffer_empty    => s_WD_buffer_empty,
									  i_RD_buffer_empty    => s_RD_buffer_empty,
									  i_output_buffer_full => s_output_buffer_full,
									
									  i_array_done => i_array_done,

									  o_stall_1 => s_stall_1,
									  o_stall_2 => s_stall_2,
									  o_flag_1  => open,
								      o_flag_2  => open,

									  o_tile_done => o_tile_done);

	o_stall_1 <= s_stall_1; --test signal
	o_stall_2 <= s_stall_2; --test signal 

-- buffer management ----------------------------------------------------------

U3:  buffer_management generic map(WD_reg_num => WD_reg_num,
								   max_datatype_size => max_datatype_size)
					   port map(i_clk 				 => i_clk,
								i_rst 				 => i_rst,
								i_RD_E 		    	 => s_RD_E,
								i_RD_write_done 	 => i_RD_write_done,
								i_WD_E 	        	 => s_WD_E,
								i_WD_write_done 	 => i_WD_write_done,
								i_RD_set_val    	 => i_RD_set_val,
								i_output_buffer_E    => s_output_buffer_E,
								i_output_buffer_read => i_output_buffer_read,

								o_RD_request     => o_RD_request,
								o_WD_request     => o_WD_request,
								o_RD_empty       => s_RD_buffer_empty,
								o_WD_empty       => s_WD_buffer_empty,
							    o_output_request => o_output_request,
								o_output_full    => s_output_buffer_full);

	o_RD_empty <= s_RD_buffer_empty;

end behavioural;
