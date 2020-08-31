-----------------------------------------------------------------------
-- Project: CiM-Tile HW Design/implementation                        --
-- File	  : tile_controller_top_tb.vhd                               --
-- Author : Remon van Duijnen (R.F.J.vanDuijnen@student.tudelft.nl)  --
-- Version: 1.0														 --
-----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity tile_controller_top_tb is
end tile_controller_top_tb;

architecture tb of tile_controller_top_tb is

-- constants
	constant clk_period 	   : time	 := 2 ns;
	constant bandwidth  	   : integer :=    8;
	constant mem_size_1 	   : integer := 1024;
	constant mem_size_2 	   : integer := 1024;
	constant inst_size         : integer :=    2; -- stage 2 inst size in bytes excl first byte
	constant num_ADCs          : integer :=    8;
	constant crossbar_columns  : integer :=  256;
	constant WD_reg_num		   : integer :=    8;
	constant max_datatype_size : integer :=   32;

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
		 i_instruction_1 : in std_logic_vector(bandwidth + 8 - 1 downto 0);
		 i_instruction_2 : in std_logic_vector((inst_size + 1) * 8 - 1 downto 0);
		 i_VRF_flag      : in std_logic;
		 i_array_done    : in std_logic;
		 -- i_ADC_done : in std_logic;
	
		 -- from outside
	 	 i_RD_outside_E 	  : in std_logic;
	  	 i_WD_outside_E		  : in std_logic;
		 i_RD_write_done 	  : in std_logic;
		 i_WD_write_done 	  : in std_logic;
		 i_RD_set_val    	  : in std_logic_vector(integer(log2(real(max_datatype_size))) - 1 downto 0);
		 i_output_buffer_read : in std_logic;
	
		 o_RDS_data  : out std_logic_vector(bandwidth - 1 downto 0);
		 o_WDS_data  : out std_logic_vector(bandwidth - 1 downto 0);
		 o_FS_reg_1  : out std_logic_vector(3 downto 0);
		 o_DTS_reg_1 : out std_logic_vector(3 downto 0);
		 o_FS_reg_2  : out std_logic_vector(3 downto 0); -- for stage 2
		 o_DTS_reg_2 : out std_logic_vector(3 downto 0); -- for stage 2
	
		 o_WD_index   : out std_logic_vector(3 downto 0); 
		 o_RDS_index  : out std_logic_vector(3 downto 0);
		 o_WDS_index  : out std_logic_vector(3 downto 0);
	
		 o_RDS_E : out std_logic;
		 o_RDS_c : out std_logic;
		 o_RDS_s : out std_logic;
		 o_RD_E  : out std_logic;
		 o_WDS_E : out std_logic;
		 o_WDS_c : out std_logic;
		 o_WDS_s : out std_logic;
		 o_WD_E  : out std_logic;
		 o_DoA : out std_logic;
		 o_DoS : out std_logic;
	
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
	 	 o_RD_request     : out std_logic;
		 o_WD_request     : out std_logic;
		 o_output_request : out std_logic;

		-- test signals;
		o_stall_1, o_stall_2 : out std_logic);
	end component;

-- signals
	-- inputs
	signal clk 			   : std_logic := '1';
	signal rst 			   : std_logic;
	signal i_instruction_1 : std_logic_vector(bandwidth + 8 - 1 downto 0);
	signal i_instruction_2 : std_logic_vector((inst_size + 1) * 8 - 1 downto 0);
	signal i_VRF_flag      : std_logic;
	signal i_array_done    : std_logic;
	-- signal i_ADC_done   : std_logic;
	
	-- from outside
	signal i_RD_outside_E, i_WD_outside_E : std_logic;
	signal i_RD_write_done 	     : std_logic;
	signal i_WD_write_done 	     : std_logic;
	signal i_RD_set_val    	     : std_logic_vector(integer(log2(real(max_datatype_size))) - 1 downto 0);
	signal i_output_buffer_read  : std_logic;

	-- outputs
	signal o_RDS_data, o_WDS_data  : std_logic_vector(bandwidth - 1 downto 0);
	signal o_FS_reg_1, o_FS_reg_2    : std_logic_vector(3 downto 0);
	signal o_DTS_reg_1, o_DTS_reg_2  : std_logic_vector(3 downto 0);
	
	signal o_WD_index   : std_logic_vector(3 downto 0); 
	signal o_RDS_index  : std_logic_vector(3 downto 0);
	signal o_WDS_index  : std_logic_vector(3 downto 0);
	
	signal o_RDS_E,o_RDS_c, o_RDS_s, o_RD_E  : std_logic;
	signal o_WDS_E, o_WDS_c, o_WDS_s, o_WD_E : std_logic;
	signal o_DoA, o_DoS 				     : std_logic;
	
	signal o_CSR_index : std_logic_vector(integer(log2(real(crossbar_columns/num_ADCs))) - 1 downto 0);
	signal o_CSR_data  : std_logic_vector(num_ADCs - 1 downto 0); 
	signal o_AS_data   : std_logic_vector(num_ADCs - 1 downto 0);
	
	signal o_CSR_E, o_AS_E, o_IADD_E, o_output_buffer_E, o_CP, o_CB, o_LS : std_logic;
		
	signal o_PC_1 : std_logic_vector(integer(log2(real(mem_size_1))) - 1 downto 0);
	signal o_PC_2 : std_logic_vector(integer(log2(real(mem_size_2))) - 1 downto 0);
		
	-- to outside
	signal o_RD_request, o_WD_request, o_output_request : std_logic;

	-- test signals
	signal o_stall_1, o_stall_2 : std_logic;

begin

	clk <= NOT clk after clk_period / 2;

	rst <= '0',
		   '1' after 2 ns,
		   '0' after 4 ns;

	i_VRF_flag <= '0',
				  '1' after 72 ns;

	i_array_done <= '1'; -- EXTEND TEST TO STALL DUE TO ARRAY

    i_RD_outside_E <= '0',
					  '1' after 6 ns,
					  '0' after 8 ns;
	i_RD_write_done <= '0',
					  '1' after 6 ns,
					  '0' after 8 ns;

    i_WD_outside_E <= '0',
					  '1' after 6 ns,
					  '0' after 8 ns;
	i_WD_write_done <= '0',
					  '1' after 6 ns,
					  '0' after 8 ns;

	i_RD_set_val <= "00010";

	i_output_buffer_read <= '0',
							'1' after 52 ns,
							'0' after 54 ns;

	i_instruction_1 <=  "0000000000000000",
						"0100000101010111" after  2 ns, --DTS 001 (1 byte?)
						"0101011111010000" after  6 ns, --FS VMM
						"1101000011000000" after  8 ns, --RDSc
						"1100000000010001" after 10 ns, --RDSs
						"0001000110101010" after 12 ns, --RDSb at index 1
						"1110000010110000" after 14 ns, --RDsh
						"1011000010100000" after 16 ns, --WDSc
						"1010000000110010" after 18 ns, --WDSs
						"0011001001010101" after 20 ns, --WDSb index 2
						"0110001110000000" after 22 ns, --WDb index 3
						"1000000010010000" after 24 ns, --DoA
						"1001000001010001" after 26 ns, --DoS
						"0101000110000000" after 28 ns, --FS VMM
						"1000000010010000" after 30 ns, --DoA
						"1001000001010101" after 32 ns, --DoS
						"0101010110000000" after 40 ns, --FS VRF
						"1000000010010000" after 42 ns, --DoA
						"1001000001010101" after 44 ns, --DoS
						"0101010110000000" after 60 ns, --FS VRF
						"1000000010010000" after 70 ns, --DoA
						"1001000000000000" after 72 ns, --DoS
					    "0101011111010000" after 74 ns; --FS VMM

	i_instruction_2 <=  "000000000000000000000000",
						"000100001111111100000000" after 2 ns,--CSR
						"000100001111111100000001" after 30 ns,--CSR
						"100000001101000011000000" after 32 ns,--jr/RF
						"110100001100000001000000" after 34 ns,--IADD
						"110000000100000000010000" after 36 ns,--LS
						"010000000001000000000000" after 42 ns,--jal to PC 64
						"000100001111000000000010" after 44 ns,--CSR
						"000100000000111100000011" after 46 ns,--CSR
						"100000001110000001100000" after 48 ns,--jr/RF
						"111000000110000010101010" after 50 ns,--CP
						"011000001010101011110000" after 52 ns,--AS
						"111100000001000010101010" after 54 ns,--CB
						"000100001010101000000100" after 56 ns,--CSR
						"000100000101010100000101" after 62 ns,--CSR
						"100000001001000000010000" after 64 ns,--jr/RF
						"100100000001000000000000" after 66 ns,--BNE
						"000100000000000000000110" after 68 ns,--CSR
						"000100000000000000000111" after 76 ns,--CSR
						"100000001001000000000000" after 78 ns,--jr/RF
						"100100000000000000000000" after 80 ns,--BNE
						"110000000100000000010000" after 82 ns;--LS

	

uut: tile_controller_top generic map(bandwidth 		   => bandwidth,
									 mem_size_1 	   => mem_size_1,
									 mem_size_2 	   => mem_size_2,
									 inst_size 		   => inst_size,
									 num_ADCs 		   => num_ADCs,
									 crossbar_columns  => crossbar_columns,
									 WD_reg_num 	   => WD_reg_num,
									 max_datatype_size => max_datatype_size)
					     port map   (i_clk 		     => clk,
									 i_rst 		     => rst,
									 i_instruction_1 => i_instruction_1,
									 i_instruction_2 => i_instruction_2,
									 i_VRF_flag      => i_VRF_flag,
									 i_array_done    => i_array_done,

									 i_RD_outside_E       => i_RD_outside_E,
									 i_WD_outside_E		  => i_WD_outside_E,
									 i_RD_write_done      => i_RD_write_done,
									 i_WD_write_done      => i_WD_write_done,
									 i_RD_set_val         => i_RD_set_val,
									 i_output_buffer_read => i_output_buffer_read,

									 o_RDS_data  => o_RDS_data,
									 o_WDS_data  => o_WDS_data,
									 o_FS_reg_1   => o_FS_reg_1,
									 o_DTS_reg_1   => o_DTS_reg_1,
									 o_FS_reg_2  => o_FS_reg_2,
									 o_DTS_reg_2 => o_DTS_reg_2,

									 o_WD_index  => o_WD_index,
									 o_RDS_index => o_RDS_index,
									 o_WDS_index => o_WDS_index,

									 o_RDS_E => o_RDS_E,
									 o_RDS_c => o_RDS_c,
									 o_RDS_s => o_RDS_s,
									 o_RD_E  => o_RD_E,
									 o_WDS_E => o_WDS_E,
									 o_WDS_c => o_WDS_c,
									 o_WDS_s => o_WDS_s,
									 o_WD_E  => o_WD_E,
									 o_DoA   => o_DoA,
									 o_DoS   => o_DoS,

									 o_CSR_index => o_CSR_index,
									 o_CSR_data  => o_CSR_data,
									 o_AS_data   => o_AS_data,

									 o_CSR_E   		   => o_CSR_E,
									 o_AS_E    		   => o_AS_E,
									 o_IADD_E  		   => o_IADD_E,
									 o_output_buffer_E => o_output_buffer_E,
									 o_CP   		   => o_CP,
									 o_CB   		   => o_CB,
									 o_LS   		   => o_LS,

									 o_PC_1 => o_PC_1,
									 o_PC_2 => o_PC_2,

									 o_RD_request     => o_RD_request,
									 o_WD_request     => o_WD_request,
									 o_output_request => o_output_request,

									 -- test signals
									 o_stall_1 => o_stall_1,
									 o_stall_2 => o_stall_2);

end tb;


