-----------------------------------------------------------------------
-- Project: CiM-Tile HW Design/implementation                        --
-- File	  : tile_top.vhd                                      		 --
-- Author : Remon van Duijnen (R.F.J.vanDuijnen@student.tudelft.nl)  --
-- Version: 1.0														 --
----------------------------------------------------------------------- 

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity tile_top is
	generic(results_xplore    : integer;
	        crossbar_rows     : integer;
			mem_size_1		  : integer;
			mem_size_2		  : integer;
			inst_size		  : integer;
			crossbar_columns  : integer;
			WD_bandwidth      : integer;
			WDS_bandwidth     : integer; -- should be equal to RDS BW in this version
			max_datatype_size : integer;
			RS_buffer_type    : integer;
		    RD_bandwidth	  : integer; -- equal to max_datatype_size for now
			RDS_bandwidth     : integer; -- only for RDSb instruction 
			num_ADCs          : integer;
			ADC_latency 	  : integer

);
	port(i_clk : in std_logic;
		 i_rst : in std_logic;

		 i_instruction_1 : in std_logic_vector(RDS_bandwidth + 16 - 1 downto 0);
		 i_instruction_2 : in std_logic_vector((inst_size + 1) * 8 - 1 downto 0);

		 i_RD			 : in std_logic_vector(max_datatype_size - 1 downto 0);
		 i_RD_buffer_index		 : in std_logic_vector(integer(log2(real(crossbar_rows))) - 1 downto 0);
		 i_RD_outside_E  : in std_logic;
		 i_RD_write_done : in std_logic;
		 i_WD			 : in std_logic_vector(WD_bandwidth - 1 downto 0);
		 i_WD_outside_E  : in std_logic;
		 i_WD_write_done : in std_logic;
		 i_output_buffer_read : in std_logic;
	
		 i_RD_set_val : in std_logic_vector(integer(log2(real(max_datatype_size))) - 0 downto 0);
		 
		 o_RD_request : out std_logic;
	 	 o_WD_request : out std_logic;
		 o_output_request : out std_logic;

		 o_output_buffer_out 	   : out std_logic_vector(num_ADCs * ((2*max_datatype_size) + integer(log2(real(crossbar_rows)))) - 1 downto 0);
		 o_output_buffer_logic_out : out std_logic_vector(crossbar_columns - 1 downto 0);
		 o_buffer_sel              : out std_logic;
		
		 o_PC_1 : out std_logic_vector(integer(log2(real(mem_size_1))) - 1 downto 0);
		 o_PC_2 : out std_logic_vector(integer(log2(real(mem_size_2))) - 1 downto 0);

		 o_tile_done : out std_logic;

		-- test signals
		test_BNE : out std_logic;
		test_array_FF_out_signals : out std_logic_vector(crossbar_rows * crossbar_columns - 1  downto 0);
		o_WD_reg, o_WDS_reg : out std_logic_vector(crossbar_columns - 1 downto 0);
		test_VMM : out std_logic;
		test_stall_1 : out std_logic; 
		test_stall_2 : out std_logic;
		test_array_done : out std_logic;
		test_VRF_flag : out std_logic;
		test_logic_reg_output : out std_logic_vector (crossbar_columns - 1 downto 0);
		test_crossbar_output : out std_logic_vector (crossbar_columns * integer(log2(real(crossbar_rows))) - 1 downto 0);
		test_sampled_data : out std_logic_vector (crossbar_columns * integer(log2(real(crossbar_rows))) - 1 downto 0);
		test_ADC_output : out std_logic_vector (num_ADCs * integer(log2(real(crossbar_rows))) - 1 downto 0);
		test_RD_buffer : out std_logic_vector(crossbar_rows - 1 downto 0);
		test_addition_out : out std_logic_vector(num_ADCs * (2 * max_datatype_size + integer(log2(real(crossbar_rows)))) - 1 downto 0);
		test_return_reg : out std_logic_vector(integer(log2(real(mem_size_1))) - 1 downto 0);
		test_jr_flag : out std_logic
);
end tile_top;


architecture behavioural of tile_top is

-- constants

	constant WD_reg_num : integer := crossbar_columns / WD_bandwidth;
	constant bits_per_column : integer := integer(log2(real(crossbar_rows)));


-- components

	component tile_controller_top is
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

		 o_tile_done : out std_logic;
		
		-- to outside
	 	 o_RD_request     : out std_logic;
		 o_WD_request     : out std_logic;
		 o_output_request : out std_logic;

		-- test signals;
		test_BNE : out std_logic;
		o_stall_1, o_stall_2 : out std_logic;
		test_return_reg : out std_logic_vector(integer(log2(real(mem_size_1))) - 1 downto 0);
		test_jr_flag : out std_logic);
	end component;

	component WD_buffer  -- STILL NEED TO FINISH DICSUSSION WITH SAID
		generic(bandwidth 	     : integer;
			    crossbar_columns : integer);
		port( i_clk : in std_logic;
			  i_WD  : in std_logic_vector(bandwidth - 1 downto 0);
		  	  shift : in std_logic;
	
		  	  o_WD  : out std_logic_vector(bandwidth - 1 downto 0));
	end component;

	component WD_reg is
		generic(crossbar_columns :  integer;
				WD_bandwidth	 :  integer);
		port(	i_clk 			 :  in std_logic;
				i_WD			 :	in std_logic_vector(WD_bandwidth - 1 downto 0);
				i_index			 :	in std_logic_vector(integer(ceil(log2(real(crossbar_columns/WD_bandwidth)))) - 1 downto 0);
				i_WD_activate	 :	in std_logic;

				o_WD			 :	out std_logic_vector(crossbar_columns - 1 downto 0));
	end component;

	component WD_select is
		generic(crossbar_columns  	: 	integer;
				WD_bandwidth	:	integer);
		port (	i_clk		    :   in std_logic;
				i_WD_reg		:	in std_logic_vector(crossbar_columns-1 downto 0);
			  	i_WD_data	 	:	in std_logic_vector(WD_bandwidth - 1 downto 0);
				i_WD_index		:	in std_logic_vector(integer(ceil(log2(real(crossbar_columns/WD_bandwidth)))) - 1 downto 0);
			  	i_WD_write		:	in std_logic;
				i_WD_set		:	in std_logic;
				i_WD_clear		:	in std_logic;
				
				o_WDS_reg       :   out std_logic_vector(crossbar_columns - 1 downto 0);
			  	o_WD_masked		:	out std_logic_vector(crossbar_columns - 1 downto 0));
	end component;

	component RS_buffer
		generic(max_datatype_size : integer;
			    crossbar_rows	  : integer;
				buffer_type		  : integer);
	    port(	i_clk 			  : in std_logic;
				i_index		      : in std_logic_vector(integer(log2(real(crossbar_rows))) - 1 downto 0);
				i_RS 			  : in std_logic_vector(max_datatype_size - 1 downto 0);
				write_enable 	  : in std_logic;
				read_or_write 	  : in std_logic;
				o_RS 			  : out std_logic_vector(crossbar_rows - 1 downto 0));
	end component;

	component RS_select is
		generic(crossbar_rows  	: 	integer;
				RS_bandwidth	:	integer);
		port (	i_clk			:	in std_logic;
				i_RS_buffer		:	in std_logic_vector(crossbar_rows - 1 downto 0);
			  	i_RS_data	 	:	in std_logic_vector(RS_bandwidth  - 1 downto 0);
				i_RS_index		:	in std_logic_vector(integer(ceil(log2(real(crossbar_rows/RS_bandwidth)))) - 1 downto 0);
			  	i_RS_write		:	in std_logic;
				i_RS_set		:	in std_logic;
				i_RS_clear		:	in std_logic;
				i_FS 			:   in std_logic_vector(3 downto 0);
				
			  	o_RS_masked		:	out std_logic_vector(crossbar_rows - 1 downto 0));
	end component;

	component crossbar_model_top is
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
	
				 o_done			    : out std_logic;
				 o_crossbar_output  : out std_logic_vector(crossbar_columns * integer(log2(real(crossbar_rows))) - 1 downto 0);
				
				test_array_FF_out_signals	:	out std_logic_vector(crossbar_rows * crossbar_columns - 1  downto 0));
	end component;

	component sample_and_hold is
		generic(crossbar_rows     : integer;
				crossbar_columns  : integer);
		port   (i_clk			  : in std_logic;
				i_crossbar_output : in std_logic_vector(crossbar_columns * integer(log2(real(crossbar_rows))) - 1 downto 0);
				i_DoS			  : in std_logic;
	
				o_sampled_data    : out std_logic_vector(crossbar_columns * integer(log2(real(crossbar_rows))) - 1 downto 0));
	end component;

	component ADC is
		generic(crossbar_rows    : integer;
				crossbar_columns : integer;
				num_ADCs	     : integer;
				ADC_latency		 : integer);
		port (i_clk				 : in std_logic;
			  i_sampled_data     : in std_logic_vector(crossbar_columns * integer(log2(real(crossbar_rows))) - 1 downto 0);
			  i_CS_index	     : in std_logic_vector(integer(log2(real(crossbar_columns/num_ADCs))) - 1 downto 0);
			  i_activation_bits  : in std_logic_vector(num_ADCs-1 downto 0);
			  i_DoR			     : in std_logic;
			  i_reset			 : in std_logic;
	
			  o_ADC_output	     : out std_logic_vector(num_ADCs * integer(log2(real(crossbar_rows))) - 1 downto 0);
			  o_logic_reg_output : out std_logic_vector(crossbar_columns - 1 downto 0);
			  o_ADC_done		 : out std_logic);
	end component;

	component write_verification is
		generic (crossbar_columns : integer);
		port (i_data : in std_logic_vector(crossbar_columns - 1 downto 0);
			  i_WD   : in std_logic_vector(crossbar_columns - 1 downto 0);
			  i_WDS  : in std_logic_vector(crossbar_columns - 1 downto 0);
	
			  o_verify_flag : out std_logic);
	end component;

	component addition_unit is
		generic(crossbar_rows 	  : integer;
				crossbar_columns  : integer;
				num_ADCs 		  : integer;
				max_datatype_size : integer);
		port(i_clk			: in std_logic;
			 i_ADC_out 		: in std_logic_vector(num_ADCs * integer(log2(real(crossbar_rows))) - 1 downto 0);
			 i_LS	   		: in std_logic;
			 i_activate		: in std_logic;
			 i_CS_index		: in std_logic_vector(integer(log2(real(crossbar_columns/num_ADCs))) - 1 downto 0);
			 i_IADD			: in std_logic;
			 i_reset		: in std_logic;
			 i_datatype_sel : in std_logic_vector(integer(log2(real(max_datatype_size/8))) -1 downto 0);
	
			 o_addition_out : out std_logic_vector(num_ADCs * (2 * max_datatype_size + integer(log2(real(crossbar_rows)))) - 1 downto 0));
	end component;

	component output_buffer is
		generic(num_ADCs 		 : integer;
				crossbar_columns : integer;
				crossbar_rows    : integer;
				max_datatype_size: integer);
		port(i_clk 				 	   : in  std_logic;
			 i_FS				 	   : in  std_logic_vector(3 downto 0);
			 i_addition_out 	 	   : in  std_logic_vector(num_ADCs * ((2*max_datatype_size) + integer(log2(real(crossbar_rows)))) - 1 downto 0);
			 i_logic_reg_out		   : in  std_logic_vector(crossbar_columns - 1 downto 0);
			 i_activate			 	   : in  std_logic;
			 o_output_buffer_out 	   : out std_logic_vector(num_ADCs * ((2*max_datatype_size) + integer(log2(real(crossbar_rows)))) - 1 downto 0);
			 o_output_buffer_logic_out : out std_logic_vector(crossbar_columns - 1 downto 0);
		     o_buffer_sel : out std_logic);
	end component;


-- signals
	signal s_VRF_flag, s_array_done : std_logic;
	signal s_RDS_data : std_logic_vector(RDS_bandwidth - 1 downto 0);
	signal s_WDS_data : std_logic_vector(WDS_bandwidth - 1 downto 0);
	signal s_FS_reg_1, s_FS_reg_2 : std_logic_vector(3 downto 0);
	signal s_DTS_reg_1_fixed_size, s_DTS_reg_2_fixed_size : std_logic_vector(3 downto 0);
	signal s_DTS_reg_1, s_DTS_reg_2 : std_logic_vector(integer(log2(real(max_datatype_size/8))) - 1 downto 0);
	signal s_WD_index_fixed_size, s_WDS_index_fixed_size, s_RDS_index_fixed_size : std_logic_vector(7 downto 0);
	signal s_WD_index, s_WDS_index : std_logic_vector(integer(ceil(log2(real(crossbar_columns/WD_bandwidth)))) - 1 downto 0);
	signal s_RDS_index : std_logic_vector(integer(ceil(log2(real(crossbar_rows/RDS_bandwidth)))) - 1 downto 0);
	signal s_RDS_E, s_RDS_s, s_RDS_c : std_logic;
	signal s_RD_E, s_RD_empty : std_logic;
	signal s_WDS_E, s_WDS_s, s_WDS_c : std_logic;
	signal s_WD_E : std_logic;
	signal s_DoA, s_DoS : std_logic;
	signal s_CSR_index : std_logic_vector(integer(log2(real(crossbar_columns/num_ADCs))) - 1 downto 0);
	signal s_CSR_data : std_logic_vector(num_ADCs - 1 downto 0);
	signal s_AS_data : std_logic_vector(num_ADCs - 1 downto 0);
	signal s_CSR_E : std_logic;
	signal s_AS_E, s_IADD_E : std_logic; 
	signal s_output_buffer_E : std_logic;
	signal s_CP, s_CB, s_LS : std_logic;

	signal s_WD_buffer_out : std_logic_vector(WD_bandwidth - 1 downto 0);
	signal s_WD_reg_out : std_logic_vector(crossbar_columns - 1 downto 0);
	signal s_WDS_reg : std_logic_vector(crossbar_columns - 1 downto 0);
	signal s_WD_masked : std_logic_vector(crossbar_columns - 1 downto 0);

	signal s_RD_buffer_out : std_logic_vector(crossbar_rows - 1 downto 0);
	signal s_RD_masked : std_logic_vector(crossbar_rows - 1 downto 0);

	signal s_crossbar_output : std_logic_vector(crossbar_columns * integer(log2(real(crossbar_rows))) - 1 downto 0);
	signal s_sampled_data : std_logic_vector(crossbar_columns * integer(log2(real(crossbar_rows))) - 1 downto 0);
	signal s_ADC_output : std_logic_vector(num_ADCs * integer(log2(real(crossbar_rows))) - 1 downto 0);
	signal s_logic_reg_output : std_logic_vector(crossbar_columns - 1 downto 0);
	signal s_ADC_done : std_logic; -- not yet used (ADC assumed single-cycle)
	signal s_addition_out : std_logic_vector(num_ADCs * (2 * max_datatype_size + integer(log2(real(crossbar_rows)))) - 1 downto 0);
	
	signal add_unit_rst, add_unit_activate : std_logic;


begin

    -- test signals
    o_WD_reg <= s_WD_reg_out;
    o_WDS_reg <= s_WDS_reg;
    


U0:  tile_controller_top generic map(bandwidth 		   => WDS_bandwidth, -- maybe different BW for RDS and WD? if X-bar is not square?
									 mem_size_1 	   => mem_size_1,
									 mem_size_2 	   => mem_size_2,
									 inst_size 		   => inst_size,
									 num_ADCs 		   => num_ADCs,
									 crossbar_columns  => crossbar_columns,
									 WD_reg_num 	   => WD_reg_num,
									 max_datatype_size => max_datatype_size)
					     port map   (i_clk 		     => i_clk,
									 i_rst 		     => i_rst,
									 i_instruction_1 => i_instruction_1,
									 i_instruction_2 => i_instruction_2,
									 i_VRF_flag      => s_VRF_flag,
									 i_array_done    => s_array_done,

									 i_RD_outside_E       => i_RD_outside_E,
									 i_WD_outside_E		  => i_WD_outside_E,
									 i_RD_write_done      => i_RD_write_done,
									 i_WD_write_done      => i_WD_write_done,
									 i_RD_set_val         => i_RD_set_val,
									 i_output_buffer_read => i_output_buffer_read,

									 o_RDS_data  => s_RDS_data,
									 o_WDS_data  => s_WDS_data,
									 o_FS_reg_1  => s_FS_reg_1,
									 o_DTS_reg_1 => s_DTS_reg_1_fixed_size,
									 o_FS_reg_2  => s_FS_reg_2,
									 o_DTS_reg_2 => s_DTS_reg_2_fixed_size,

									 o_WD_index  => s_WD_index_fixed_size,
									 o_RDS_index => s_RDS_index_fixed_size,
									 o_WDS_index => s_WDS_index_fixed_size,

									 o_RDS_E    => s_RDS_E,
									 o_RDS_c    => s_RDS_c,
									 o_RDS_s    => s_RDS_s,
									 o_RD_E     => s_RD_E,
									 o_RD_empty => s_RD_empty,
									 o_WDS_E    => s_WDS_E,
									 o_WDS_c    => s_WDS_c,
									 o_WDS_s    => s_WDS_s,
									 o_WD_E     => s_WD_E,
									 o_DoA      => s_DoA,
									 o_DoS      => s_DoS,

									 o_CSR_index => s_CSR_index,
									 o_CSR_data  => s_CSR_data,
									 o_AS_data   => s_AS_data,

									 o_CSR_E   		   => s_CSR_E,
									 o_AS_E    		   => s_AS_E,
									 o_IADD_E  		   => s_IADD_E,
									 o_output_buffer_E => s_output_buffer_E,
									 o_CP   		   => s_CP,
									 o_CB   		   => s_CB,
									 o_LS   		   => s_LS,

									 o_PC_1 => o_PC_1,
									 o_PC_2 => o_PC_2,

									 o_tile_done => o_tile_done,

									 o_RD_request     => o_RD_request,
									 o_WD_request     => o_WD_request,
									 o_output_request => o_output_request,

									 -- test signals
									 test_BNE => test_BNE,
									 o_stall_1 => test_stall_1, --o_stall_1,
									 o_stall_2 => test_stall_2,
									 test_return_reg => test_return_reg,
									 test_jr_flag => test_jr_flag); --o_stall_2);

-- resize index for WD,WDS,RDS,DTS (only because we try to keep it parametrized)
G0: for i in integer(ceil(log2(real(crossbar_columns/WD_bandwidth)))) - 1 downto 0 generate
		s_WD_index(i) <= s_WD_index_fixed_size(i); 
	end generate;

G1:	for i in integer(ceil(log2(real(crossbar_columns/WD_bandwidth)))) - 1 downto 0 generate
		s_WDS_index(i) <= s_WDS_index_fixed_size(i); 
	end generate;

G2:	for i in integer(ceil(log2(real(crossbar_rows/RDS_bandwidth)))) - 1 downto 0 generate
		s_RDS_index(i) <= s_RDS_index_fixed_size(i); 
	end generate;

G3:	for i in integer(log2(real(max_datatype_size/8))) - 1 downto 0 generate
		s_DTS_reg_1(i) <= s_DTS_reg_1_fixed_size(i); 
		s_DTS_reg_2(i) <= s_DTS_reg_2_fixed_size(i);
	end generate;


U1: WD_buffer generic map(bandwidth => WD_bandwidth,
						  crossbar_columns => crossbar_columns)
	 		  port map(	i_clk => i_clk,
						i_WD  => i_WD,
						shift => s_WD_E,
						o_WD  => s_WD_buffer_out);

U2: WD_reg generic map(crossbar_columns => crossbar_columns, 
					   WD_bandwidth     => WD_bandwidth)
			 port map(i_clk         => i_clk, 
					  i_WD          => s_WD_buffer_out, 
					  i_index 		=> s_WD_index, 
					  i_WD_activate => s_WD_E, 
					  o_WD 			=> s_WD_reg_out);

U3: WD_select generic map(crossbar_columns => crossbar_columns, WD_bandwidth => WD_bandwidth)
			  port map(  i_clk			 => i_clk,
						 i_WD_reg     	 => s_WD_reg_out, 
						 i_WD_data       => s_WDS_data, 
						 i_WD_index      => s_WDS_index,
						 i_WD_write      => s_WDS_E,
						 i_WD_set        => s_WDS_s, 
						 i_WD_clear      => s_WDS_c,
						 o_WDS_reg       => s_WDS_reg, 
						 o_WD_masked     => s_WD_masked);

U4: RS_buffer generic map(max_datatype_size => max_datatype_size,
						  crossbar_rows 	=> crossbar_rows,
						  buffer_type       => RS_buffer_type)
	 		  port map(   i_clk 		=> i_clk,
						  i_index       => i_RD_buffer_index,
						  i_RS 		    => i_RD,
						  write_enable  => s_RD_E,
						  read_or_write => s_RD_empty,
						  o_RS 		    => s_RD_buffer_out);

U5:  RS_select generic map(crossbar_rows => crossbar_rows, RS_bandwidth => RDS_bandwidth)
			   port map( i_clk 			 => i_clk,
						 i_RS_buffer     => s_RD_buffer_out, 
						 i_RS_data       => s_RDS_data, 
						 i_RS_index      => s_RDS_index,
						 i_RS_write      => s_RDS_E,
						 i_RS_set        => s_RDS_s, 
						 i_RS_clear      => s_RDS_c, 
						 i_FS  			 => s_FS_reg_1,
						 o_RS_masked     => s_RD_masked);


U6:  crossbar_model_top generic map(results_xplore => results_xplore, crossbar_rows => crossbar_rows, crossbar_columns => crossbar_columns)
						port map   (i_FS    	  => s_FS_reg_1,
									i_DoA   	  => s_DoA,
									i_clk   	  => i_clk,
									i_reset 	  => i_rst,
									i_WD    	  => S_WD_masked,
									i_WDS   	  => s_WDS_reg,
									i_RS    	  => s_RD_masked,

									o_done  	  => s_array_done,
									o_crossbar_output => s_crossbar_output,

								    test_array_FF_out_signals => test_array_FF_out_signals); --test_array_FF_out_signals
								   
U7:  sample_and_hold generic map(crossbar_rows => crossbar_rows, crossbar_columns => crossbar_columns)
					 port map(i_crossbar_output => s_crossbar_output,
							  i_DoS => s_DoS,
							  i_clk => i_clk,
							  o_sampled_data => s_sampled_data);

U8:  ADC generic map(crossbar_rows => crossbar_rows, crossbar_columns => crossbar_columns, 
					 num_ADCs => num_ADCs, ADC_latency => ADC_latency)
		 port map   (i_sampled_data => s_sampled_data,
					 i_CS_index => s_CSR_index,
					 i_activation_bits => s_CSR_data,
					 i_DoR => s_CSR_E,
					 i_reset => i_rst,
					 i_clk => i_clk,
					 o_ADC_output => s_ADC_output,
					 o_logic_reg_output => s_logic_reg_output,
					 o_ADC_done => s_ADC_done); -- not yet used
					 

U9:  write_verification generic map(crossbar_columns => crossbar_columns)
						port map   (i_data => s_logic_reg_output,
									i_WD   => s_WD_reg_out, 
									i_WDS  => s_WDS_reg,

									o_verify_flag => s_VRF_flag);
									
	add_unit_rst <= i_rst OR s_output_buffer_E;
	add_unit_activate <= s_CSR_E AND (s_FS_reg_2(2) AND s_FS_reg_2(1) AND s_FS_reg_2(0)); -- ONLY at VMM

U10: addition_unit  generic map(crossbar_rows	  => crossbar_rows,
								crossbar_columns  => crossbar_columns,
								num_ADCs 		  => num_ADCs,
								max_datatype_size => max_datatype_size)
					port map(	i_clk          => i_clk,
								i_ADC_out      => s_ADC_output,
								i_LS           => s_LS,
								i_activate     => add_unit_activate,
								i_CS_index     => s_CSR_index,
								i_IADD 		   => s_IADD_E,
								i_reset 	   => add_unit_rst,
								i_datatype_sel => s_DTS_reg_2,

								o_addition_out => s_addition_out);

U11: output_buffer  generic map(num_ADCs 		 => num_ADCs,
								crossbar_columns => crossbar_columns,
								crossbar_rows 	 => crossbar_rows,
								max_datatype_size=> max_datatype_size)
					port map(i_clk 				 	   => i_clk,
							 i_FS				 	   => s_FS_reg_2,
							 i_addition_out 	 	   => s_addition_out,
							 i_logic_reg_out	 	   => s_logic_reg_output,
							 i_activate 		 	   => s_output_buffer_E,
							 o_output_buffer_out 	   => o_output_buffer_out,
							 o_output_buffer_logic_out => o_output_buffer_logic_out,
							 o_buffer_sel              => o_buffer_sel);

-- test signals
    test_VMM <= s_FS_reg_1(2) AND s_FS_reg_1(1) AND s_FS_reg_1(0);
	test_array_done <= s_array_done;
	test_VRF_flag <= s_VRF_flag;
	test_logic_reg_output <= s_logic_reg_output;
	test_crossbar_output <= s_crossbar_output;
	test_sampled_data <= s_sampled_data;
	test_ADC_output <= s_ADC_output;
	test_RD_buffer <= s_RD_buffer_out;
	test_addition_out <= s_addition_out;


end behavioural;
