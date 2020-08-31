-----------------------------------------------------------------------
-- Project: CiM-Tile HW Design/implementation                        --
-- File	  : tile-top_tb.vhd                                          --
-- Author : Remon van Duijnen (R.F.J.vanDuijnen@student.tudelft.nl)  --
-- Version: 1.0														 --
-----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity tile_top_tb is
end tile_top_tb;

architecture tb of tile_top_tb is

-- constants
	constant clk_period		   : time	 := 2 ns;
	constant crossbar_rows     : integer := 32;
	constant crossbar_columns  : integer := 32;
	constant mem_size_1		   : integer := 1024;
	constant mem_size_2		   : integer := 1024;
	constant inst_size		   : integer := 2;
	constant WD_bandwidth      : integer := 8;
	constant WDS_bandwidth     : integer := 8; -- should be equal to RDS BW in this version
	constant max_datatype_size : integer := 16;
	constant RS_buffer_type    : integer := 1;
	constant RD_bandwidth	   : integer := max_datatype_size; -- equal to max_datatype_size for now
	constant RDS_bandwidth     : integer := 8; -- only for RDSb instruction 
	constant num_ADCs          : integer := 2;
	constant ADC_latency 	   : integer := 0;

-- components
	component tile_top is
		generic(crossbar_rows     : integer;
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
				ADC_latency 	  : integer);
		port(i_clk : in std_logic;
			 i_rst : in std_logic;
	
			 i_instruction_1 : in std_logic_vector(RDS_bandwidth + 8 - 1 downto 0);
			 i_instruction_2 : in std_logic_vector((inst_size + 1) * 8 - 1 downto 0);
	
			 i_RD			 : in std_logic_vector(max_datatype_size - 1 downto 0);
			 i_RD_buffer_index	: in std_logic_vector(integer(log2(real(crossbar_rows))) - 1 downto 0);
			 i_RD_outside_E  : in std_logic;
			 i_RD_write_done : in std_logic;
			 i_WD			 : in std_logic_vector(WD_bandwidth - 1 downto 0);
			 i_WD_outside_E  : in std_logic;
			 i_WD_write_done : in std_logic;
			 i_output_buffer_read : in std_logic;
		
			 i_RD_set_val : in std_logic_vector(integer(log2(real(max_datatype_size))) - 1 downto 0);
			 
			 o_RD_request : out std_logic;
		 	 o_WD_request : out std_logic;
			 o_output_request : out std_logic;
	
			 o_output_buffer_out 	   : out std_logic_vector(num_ADCs * ((2*crossbar_columns/num_ADCs) + integer(log2(real(crossbar_rows)))) - 1 downto 0);
			 o_output_buffer_logic_out : out std_logic_vector(crossbar_columns - 1 downto 0);
			
			 o_PC_1 : out std_logic_vector(integer(log2(real(mem_size_1))) - 1 downto 0);
			 o_PC_2 : out std_logic_vector(integer(log2(real(mem_size_2))) - 1 downto 0);

			-- test signals
			test_array_FF_out_signals : out std_logic_vector(crossbar_rows * crossbar_columns - 1  downto 0);
			test_stall_1 : out std_logic; 
			test_stall_2 : out std_logic;
			test_array_done : out std_logic;
			test_VRF_flag : out std_logic;
			test_logic_reg_output : out std_logic_vector (crossbar_columns - 1 downto 0);
			test_crossbar_output : out std_logic_vector (crossbar_columns * integer(log2(real(crossbar_rows))) - 1 downto 0);
			test_sampled_data : out std_logic_vector(crossbar_columns * integer(log2(real(crossbar_rows))) - 1 downto 0);
			test_ADC_output : out std_logic_vector(crossbar_columns * integer(log2(real(crossbar_rows))) - 1 downto 0);
			test_RD_buffer : out std_logic_vector(crossbar_rows - 1 downto 0);
			test_addition_out : out std_logic_vector(num_ADCs * (2 * crossbar_columns / num_ADCs + integer(log2(real(crossbar_rows)))) - 1 downto 0);
			test_return_reg : out std_logic_vector(integer(log2(real(mem_size_1))) - 1 downto 0);
			test_jr_flag : out std_logic

	);
	end component;

-- signals
	-- inputs
	signal clk 								: std_logic := '1';
	signal rst 								: std_logic;
	signal i_instruction_1 					: std_logic_vector(RDS_bandwidth + 8 - 1 downto 0);
	signal i_instruction_2 					: std_logic_vector((inst_size + 1) * 8 - 1 downto 0);
	signal i_RD 							: std_logic_vector(max_datatype_size - 1 downto 0);
	signal i_RD_buffer_index 				: std_logic_vector(integer(log2(real(crossbar_rows))) - 1 downto 0);
	signal i_RD_outside_E, i_RD_write_done 	: std_logic;
	signal i_WD 							: std_logic_vector(WD_bandwidth - 1 downto 0);
	signal i_WD_outside_E, i_WD_write_done 	: std_logic;
	signal i_output_buffer_read 			: std_logic;
	signal i_RD_set_val 					: std_logic_vector(integer(log2(real(max_datatype_size))) - 1 downto 0);
	
	-- outputs
	signal o_RD_request, o_WD_request, o_output_request : std_logic;
	signal o_output_buffer_out : std_logic_vector(num_ADCs * ((2*crossbar_columns/num_ADCs) + integer(log2(real(crossbar_rows)))) - 1 downto 0);
	signal o_output_buffer_logic_out : std_logic_vector(crossbar_columns - 1 downto 0);
	signal o_PC_1 : std_logic_vector(integer(log2(real(mem_size_1))) - 1 downto 0);
	signal o_PC_2 : std_logic_vector(integer(log2(real(mem_size_2))) - 1 downto 0);

	-- test signals
	signal test_stall_1, test_stall_2, test_array_done, test_VRF_flag : std_logic;
	signal test_array_FF_out_signals : std_logic_vector(crossbar_rows * crossbar_columns - 1  downto 0);
	signal test_logic_reg_output : std_logic_vector(crossbar_columns - 1 downto 0);
	signal test_crossbar_output : std_logic_vector(crossbar_columns * integer(log2(real(crossbar_rows))) - 1 downto 0);
	signal test_sampled_data : std_logic_vector(crossbar_columns * integer(log2(real(crossbar_rows))) - 1 downto 0);
	signal test_ADC_output : std_logic_vector(num_ADCs * integer(log2(real(crossbar_rows))) - 1 downto 0);
	signal test_RD_buffer : std_logic_vector(crossbar_rows - 1 downto 0);
	signal test_addition_out : std_logic_vector(num_ADCs * (2 * crossbar_columns / num_ADCs + integer(log2(real(crossbar_rows)))) - 1 downto 0);
	signal test_return_reg : std_logic_vector(integer(log2(real(mem_size_1))) - 1 downto 0);
	signal test_jr_flag : std_logic;
	

begin

	clk <= NOT clk after clk_period/2;

	rst <= 	 '0',
			 '1' after 2 ns,
			 '0' after 4 ns;
 
	i_instruction_1 <= 	"0000000000000000",
					   	"0100000000000000" after 4 ns,		-- DTS 0000 (8-bit)
					   	"0101000000000000" after 8 ns,		-- FS write ------------------
					   	"1101000000000000" after 10 ns,		--RDSc
					   	"0001000000000001" after 12 ns,		--RDSb 0 00000001
					   	"1010000000000000" after 14 ns,		--WDSs
					   	"0110000000000000" after 16 ns,		--WDb 0
					   	"0110000100000000" after 20 ns,		--WDb 1
						"0110001000000000" after 22 ns,		--WDb 2
					   	"0110001100000000" after 24 ns,		--WDb 3
					   	"1000000000000000" after 26 ns,		--DoA
					   	"0101000000000000" after 28 ns,		-- FS write -----------------
					   	"1101000000000000" after 30 ns,		--RDSc
					   	"0001001100010000" after 32 ns,		--RDSb 3 00010000
					   	"1011000000000000" after 34 ns,		--WDSc
					   	"0011000011111111" after 36 ns,		--WDSb 0 11111111
					   	"0110000000000000" after 38 ns,		--WDb 0
					   	"1000000000000000" after 40 ns,		--DoA
					   	"0101000000000000" after 96 ns,		-- FS write -------------------
					   	"1101000000000000" after 98 ns,		--RDSc
					   	"0001001100100000" after 100 ns,		--RDSb 3 00100000
					   	"1011000000000000" after 102 ns,		--WDSc
					   	"0011000011111111" after 104 ns,		--WDSb 0 11111111
					   	"0110000000000000" after 106 ns,		--WDb 0
					   	"1000000000000000" after 108 ns,		--DoA
					   	"0101000000000000" after 164 ns,		-- FS write -------------------
					   	"1101000000000000" after 166 ns,		--RDSc
					   	"0001001101000000" after 168 ns,		--RDSb 3 01000000
					   	"1011000000000000" after 170 ns,		--WDSc
					   	"0011000011111111" after 172 ns,		--WDSb 0 11111111
					   	"0110000000000000" after 174 ns,		--WDb 0
					   	"1000000000000000" after 176 ns,		--DoA
					   	"0101000000000000" after 232 ns,		-- FS write ------------------
					   	"1101000000000000" after 234 ns,		--RDSc
					   	"0001001110000000" after 236 ns,		--RDSb 3 10000000
					   	"1011000000000000" after 238 ns,		--WDSc
					   	"0011000011111111" after 240 ns,		--WDSb 0 11111111
					   	"0110000000000000" after 242 ns,		--WDb 0
					   	"1000000000000000" after 244 ns,		--DoA
						"0101010100000000" after 300 ns,		-- FS VRF ------------------
					   	"1101000000000000" after 302 ns,		--RDSc			  -- normally theres no RS here just for test
					   	"0001001110000000" after 304 ns,		--RDSb 3 10000000 -- normally theres no RS here just for test
					   	"1000000000000000" after 306 ns,		--DoA
					   	"1001000000000000" after 368 ns,		--DoS
						"0101010000000000" after 436 ns,		-- FS read ------------------
					   	"1101000000000000" after 458 ns,		--RDSc			  
					   	"0001001110000000" after 460 ns,		--RDSb 3 10000000
					   	"1000000000000000" after 462 ns,		--DoA
					   	"1001000000000000" after 464 ns,		--DoS
						"0101001000000000" after 532 ns,		-- FS AND ------------------
					   	"1101000000000000" after 534 ns,		--RDSc			  
					   	"0001001111110000" after 536 ns,		--RDSb 3 11110000
					   	"1000000000000000" after 538 ns,		--DoA
					   	"1001000000000000" after 554 ns,		--DoS
						"0101001100000000" after 622 ns,		-- FS OR ------------------
					   	"1101000000000000" after 624 ns,		--RDSc			  
					   	"0001001111110000" after 626 ns,		--RDSb 3 11110000
					   	"1000000000000000" after 628 ns,		--DoA
					   	"1001000000000000" after 630 ns,		--DoS
						"0101011000000000" after 698 ns,		-- FS XOR ------------------
					   	"1101000000000000" after 700 ns,		--RDSc			  
					   	"0001001111110000" after 702 ns,		--RDSb 3 11110000
					   	"1000000000000000" after 704 ns,		--DoA
					   	"1001000000000000" after 706 ns,		--DoS
						"0101011100000000" after 774 ns,		-- FS VMM ------------------- 1
					   	"1101000000000000" after 776 ns,		--RDSc			  
					   	"0001001111110000" after 778 ns,		--RDSb 3 11110000
					   	"1000000000000000" after 780 ns,		--DoA
					   	"1001000000000000" after 782 ns,		--DoS
						"0101011100000000" after 850 ns,		-- FS VMM ------------------- 2
					   	"1110000000000000" after 852 ns,		--RDsh	
					   	"1101000000000000" after 854 ns,		--RDSc			  
					   	"0001001111110000" after 856 ns,		--RDSb 3 11110000
					   	"1000000000000000" after 858 ns,		--DoA
					   	"1001000000000000" after 860 ns,		--DoS
						"0101011100000000" after 928 ns,		-- FS VMM ------------------- 3
					   	"1110000000000000" after 930 ns,		--RDsh	
					   	"1101000000000000" after 932 ns,		--RDSc			  
					   	"0001001111110000" after 934 ns,		--RDSb 3 11110000
					   	"1000000000000000" after 936 ns,		--DoA
					   	"1001000000000000" after 938 ns,		--DoS
						"0101011100000000" after 1006 ns,		-- FS VMM ------------------- 4
					   	"1110000000000000" after 1008 ns,		--RDsh	
					   	"1101000000000000" after 1010 ns,		--RDSc			  
					   	"0001001111110000" after 1012 ns,		--RDSb 3 11110000
					   	"1000000000000000" after 1014 ns,		--DoA
					   	"1001000000000000" after 1016 ns,		--DoS
						"0101011100000000" after 1084 ns,		-- FS VMM ------------------- 5
					   	"1110000000000000" after 1086 ns,		--RDsh	
					   	"1101000000000000" after 1088 ns,		--RDSc			  
					   	"0001001111110000" after 1090 ns,		--RDSb 3 11110000
					   	"1000000000000000" after 1092 ns,		--DoA
					   	"1001000000000000" after 1094 ns,		--DoS
						"0101011100000000" after 1162 ns,		-- FS VMM ------------------- 6
					   	"1110000000000000" after 1164 ns,		--RDsh	
					   	"1101000000000000" after 1166 ns,		--RDSc			  
					   	"0001001111110000" after 1168 ns,		--RDSb 3 11110000
					   	"1000000000000000" after 1170 ns,		--DoA
					   	"1001000000000000" after 1172 ns,		--DoS
						"0101011100000000" after 1240 ns,		-- FS VMM ------------------- 7
					   	"1110000000000000" after 1242 ns,		--RDsh	
					   	"1101000000000000" after 1244 ns,		--RDSc			  
					   	"0001001111110000" after 1246 ns,		--RDSb 3 11110000
					   	"1000000000000000" after 1248 ns,		--DoA
					   	"1001000000000000" after 1250 ns,		--DoS
						"0101011100000000" after 1318 ns,		-- FS VMM ------------------- 8
					   	"1110000000000000" after 1320 ns,		--RDsh
					   	"1101000000000000" after 1322 ns,		--RDSc			  
					   	"0001001111110000" after 1324 ns,		--RDSb 3 11110000
					   	"1000000000000000" after 1326 ns,		--DoA
					   	"1001000000000000" after 1328 ns,		--DoS
						"0101011100000000" after 1396 ns;		-- FS VMM ------------------- END

	i_instruction_2 <= 	"000000000000000000000000",
						"000100000100000000000000" after 4 ns,   -- CSR 01 - 0000 (activation - index)  VRF
						"000100000100000000000001" after 438 ns, -- CSR 01 - 0001
						"000100000100000000000010" after 440 ns, -- CSR 01 - 0010
						"000100000100000000000011" after 442 ns, -- CSR 01 - 0011
						"000100000100000000000100" after 444 ns, -- CSR 01 - 0100
						"000100000100000000000101" after 446 ns, -- CSR 01 - 0101
						"000100000100000000000110" after 448 ns, -- CSR 01 - 0110
						"000100000100000000000111" after 450 ns, -- CSR 01 - 0111
						"100000000000000000000000" after 452 ns, -- jr
						"100100000000000000000000" after 454 ns, -- BNE
						"000100000100000000000000" after 456 ns, -- CSR 01 - 0000 (activation - index)  READ
						"000100000100000000000001" after 534 ns, -- CSR 01 - 0001
						"000100000100000000000010" after 536 ns, -- CSR 01 - 0010
						"000100000100000000000011" after 538 ns, -- CSR 01 - 0011
						"000100000100000000000100" after 540 ns, -- CSR 01 - 0100
						"000100000100000000000101" after 542 ns, -- CSR 01 - 0101
						"000100000100000000000110" after 544 ns, -- CSR 01 - 0110
						"000100000100000000000111" after 546 ns, -- CSR 01 - 0111
						"100000000000000000000000" after 548 ns, -- jr
						"000100000100000000000000" after 550 ns, -- CSR 01 - 0000 (activation - index) AND
						"000100000100000000000001" after 610 ns, -- CSR 01 - 0001
						"000100000100000000000010" after 612 ns, -- CSR 01 - 0010
						"000100000100000000000011" after 614 ns, -- CSR 01 - 0011
						"000100000100000000000100" after 616 ns, -- CSR 01 - 0100
						"000100000100000000000101" after 618 ns, -- CSR 01 - 0101
						"000100000100000000000110" after 620 ns, -- CSR 01 - 0110
						"000100000100000000000111" after 622 ns, -- CSR 01 - 0111
						"100000000000000000000000" after 624 ns, -- jr
						"000100000100000000000000" after 626 ns, -- CSR 01 - 0000 (activation - index) OR
						"000100000100000000000001" after 700 ns, -- CSR 01 - 0001
						"000100000100000000000010" after 702 ns, -- CSR 01 - 0010
						"000100000100000000000011" after 704 ns, -- CSR 01 - 0011
						"000100000100000000000100" after 706 ns, -- CSR 01 - 0100
						"000100000100000000000101" after 708 ns, -- CSR 01 - 0101
						"000100000100000000000110" after 710 ns, -- CSR 01 - 0110
						"000100000100000000000111" after 712 ns, -- CSR 01 - 0111
						"100000000000000000000000" after 714 ns, -- jr
						"000100000100000000000000" after 716 ns, -- CSR 01 - 0000 (activation - index) XOR
						"000100000100000000000001" after 776 ns, -- CSR 01 - 0001
						"000100000100000000000010" after 778 ns, -- CSR 01 - 0010
						"000100000100000000000011" after 780 ns, -- CSR 01 - 0011
						"000100000100000000000100" after 782 ns, -- CSR 01 - 0100
						"000100000100000000000101" after 784 ns, -- CSR 01 - 0101
						"000100000100000000000110" after 786 ns, -- CSR 01 - 0110
						"000100000100000000000111" after 788 ns, -- CSR 01 - 0111
						"100000000000000000000000" after 790 ns, -- jr
						"110000000000000000000000" after 792 ns, -- LS ----------------- 1
						"000100000100000000000000" after 852 ns, -- CSR 01 - 0000
						"000100000100000000000001" after 854 ns, -- CSR 01 - 0001
						"000100000100000000000010" after 856 ns, -- CSR 01 - 0010
						"000100000100000000000011" after 858 ns, -- CSR 01 - 0011
						"000100000100000000000100" after 860 ns, -- CSR 01 - 0100
						"000100000100000000000101" after 862 ns, -- CSR 01 - 0101
						"000100000100000000000110" after 864 ns, -- CSR 01 - 0110
						"000100000100000000000111" after 866 ns, -- CSR 01 - 0111
						"100000000000000000000000" after 868 ns, -- jr 
						"110100000000000000000000" after 870 ns, -- IADD 
						"110000000000000000000000" after 872 ns, -- LS ----------------- 2
						"000100000100000000000000" after 930 ns, -- CSR 01 - 0000
						"000100000100000000000001" after 932 ns, -- CSR 01 - 0001
						"000100000100000000000010" after 934 ns, -- CSR 01 - 0010
						"000100000100000000000011" after 936 ns, -- CSR 01 - 0011
						"000100000100000000000100" after 938 ns, -- CSR 01 - 0100
						"000100000100000000000101" after 940 ns, -- CSR 01 - 0101
						"000100000100000000000110" after 942 ns, -- CSR 01 - 0110
						"000100000100000000000111" after 944 ns, -- CSR 01 - 0111
						"100000000000000000000000" after 946 ns, -- jr 
						"110100000000000000000000" after 948 ns, -- IADD 
						"110000000000000000000000" after 950 ns, -- LS ----------------- 3
						"000100000100000000000000" after 1008 ns, -- CSR 01 - 0000
						"000100000100000000000001" after 1010 ns, -- CSR 01 - 0001
						"000100000100000000000010" after 1012 ns, -- CSR 01 - 0010
						"000100000100000000000011" after 1014 ns, -- CSR 01 - 0011
						"000100000100000000000100" after 1016 ns, -- CSR 01 - 0100
						"000100000100000000000101" after 1018 ns, -- CSR 01 - 0101
						"000100000100000000000110" after 1020 ns, -- CSR 01 - 0110
						"000100000100000000000111" after 1022 ns, -- CSR 01 - 0111
						"100000000000000000000000" after 1024 ns, -- jr 
						"110100000000000000000000" after 1026 ns, -- IADD 
						"110000000000000000000000" after 1028 ns, -- LS ----------------- 4
						"000100000100000000000000" after 1086 ns, -- CSR 01 - 0000
						"000100000100000000000001" after 1088 ns, -- CSR 01 - 0001
						"000100000100000000000010" after 1090 ns, -- CSR 01 - 0010
						"000100000100000000000011" after 1092 ns, -- CSR 01 - 0011
						"000100000100000000000100" after 1094 ns, -- CSR 01 - 0100
						"000100000100000000000101" after 1096 ns, -- CSR 01 - 0101
						"000100000100000000000110" after 1098 ns, -- CSR 01 - 0110
						"000100000100000000000111" after 1100 ns, -- CSR 01 - 0111
						"100000000000000000000000" after 1102 ns, -- jr 
						"110100000000000000000000" after 1104 ns, -- IADD 
						"110000000000000000000000" after 1106 ns, -- LS ----------------- 5
						"000100000100000000000000" after 1164 ns, -- CSR 01 - 0000
						"000100000100000000000001" after 1166 ns, -- CSR 01 - 0001
						"000100000100000000000010" after 1168 ns, -- CSR 01 - 0010
						"000100000100000000000011" after 1170 ns, -- CSR 01 - 0011
						"000100000100000000000100" after 1172 ns, -- CSR 01 - 0100
						"000100000100000000000101" after 1174 ns, -- CSR 01 - 0101
						"000100000100000000000110" after 1176 ns, -- CSR 01 - 0110
						"000100000100000000000111" after 1178 ns, -- CSR 01 - 0111
						"100000000000000000000000" after 1180 ns, -- jr 
						"110100000000000000000000" after 1182 ns, -- IADD 
						"110000000000000000000000" after 1184 ns, -- LS ----------------- 6
						"000100000100000000000000" after 1242 ns, -- CSR 01 - 0000
						"000100000100000000000001" after 1244 ns, -- CSR 01 - 0001
						"000100000100000000000010" after 1246 ns, -- CSR 01 - 0010
						"000100000100000000000011" after 1248 ns, -- CSR 01 - 0011
						"000100000100000000000100" after 1250 ns, -- CSR 01 - 0100
						"000100000100000000000101" after 1252 ns, -- CSR 01 - 0101
						"000100000100000000000110" after 1254 ns, -- CSR 01 - 0110
						"000100000100000000000111" after 1256 ns, -- CSR 01 - 0111
						"100000000000000000000000" after 1258 ns, -- jr 
						"110100000000000000000000" after 1260 ns, -- IADD 
						"110000000000000000000000" after 1262 ns, -- LS ----------------- 7
						"000100000100000000000000" after 1320 ns, -- CSR 01 - 0000
						"000100000100000000000001" after 1322 ns, -- CSR 01 - 0001
						"000100000100000000000010" after 1324 ns, -- CSR 01 - 0010
						"000100000100000000000011" after 1326 ns, -- CSR 01 - 0011
						"000100000100000000000100" after 1328 ns, -- CSR 01 - 0100
						"000100000100000000000101" after 1330 ns, -- CSR 01 - 0101
						"000100000100000000000110" after 1332 ns, -- CSR 01 - 0110
						"000100000100000000000111" after 1334 ns, -- CSR 01 - 0111
						"100000000000000000000000" after 1336 ns, -- jr 
						"110100000000000000000000" after 1338 ns, -- IADD 
						"110000000000000000000000" after 1340 ns, -- LS ----------------- 8
						"000100000100000000000000" after 1398 ns, -- CSR 01 - 0000
						"000100000100000000000001" after 1400 ns, -- CSR 01 - 0001
						"000100000100000000000010" after 1402 ns, -- CSR 01 - 0010
						"000100000100000000000011" after 1404 ns, -- CSR 01 - 0011
						"000100000100000000000100" after 1406 ns, -- CSR 01 - 0100
						"000100000100000000000101" after 1408 ns, -- CSR 01 - 0101
						"000100000100000000000110" after 1410 ns, -- CSR 01 - 0110
						"000100000100000000000111" after 1412 ns, -- CSR 01 - 0111
						"100000000000000000000000" after 1414 ns, -- jr 
						"110100000000000000000000" after 1416 ns, -- IADD 
						"111000000000000000000000" after 1418 ns, -- CP
						"110000000000000000000000" after 1420 ns; -- LS ----------------- END



	i_RD <= "1111111111111111";

	i_RD_buffer_index <= "11100",
						 "11101" after 13 ns,
						 "11110" after 15 ns,
						 "11111" after 17 ns;
						 --"00100" after 21 ns,
						 --"00101" after 23 ns,
						 --"00110" after 25 ns,
						 --"00111" after 27 ns,
						 --"01000" after 29 ns,
						 --"01001" after 31 ns,
						 --"01010" after 33 ns,
						 --"01011" after 35 ns,
						 --"01100" after 37 ns,
						 --"01101" after 39 ns,
						 --"01110" after 41 ns,
						 --"01111" after 43 ns,
						 --"10000" after 45 ns,
						 --"10001" after 47 ns,
						 --"10010" after 49 ns,
						 --"10011" after 51 ns,
						 --"10100" after 53 ns,
						 --"10101" after 55 ns,
						 --"10110" after 57 ns,
						 --"10111" after 59 ns,
						 --"11000" after 61 ns,
						 --"11001" after 63 ns,
						 --"11010" after 65 ns,
						 --"11011" after 67 ns,
						 --"11100" after 69 ns,
						 --"11101" after 71 ns,
						 --"11110" after 73 ns,
						 --"11111" after 75 ns;

	i_RD_outside_E <= '0',
					  '1' after 11 ns,
					  '0' after 19 ns;

	i_RD_write_done <= '0',
					   '1' after 17 ns,
					   '0' after 19 ns;

	i_WD <= "00000000",
			"00000001" after 11 ns,
			"00000010" after 13 ns,
			"00000011" after 15 ns,
			"00000100" after 17 ns,
			"00000010" after 29 ns,
			"00000011" after 31 ns,
			"00000111" after 33 ns,
			"00001111" after 35 ns;

	i_WD_outside_E <= '0',
					  '1' after 11 ns,
					  '0' after 19 ns,
					  '1' after 29 ns,
					  '0' after 37 ns;

	i_WD_write_done <=  '0',
						'1' after 17 ns,
						'0' after 19 ns,
						'1' after 35 ns,
						'0' after 37 ns;

	i_output_buffer_read <= '0',
							'1' after 600 ns,
							'0' after 602 ns,
							'1' after 700 ns,
							'0' after 702 ns,
							'1' after 780 ns,
							'0' after 782 ns,
							'1' after 800 ns,
							'0' after 802 ns;

	i_RD_set_val <= "1111";

uut: tile_top generic map(	crossbar_rows		=> crossbar_rows,
						    crossbar_columns	=> crossbar_columns,
							mem_size_1			=> mem_size_1,
							mem_size_2			=> mem_size_2,
							inst_size			=> inst_size,
							WD_bandwidth		=> WD_bandwidth,
							WDS_bandwidth		=> WDS_bandwidth,
							max_datatype_size	=> max_datatype_size,
							RS_buffer_type		=> RS_buffer_type,
							RD_bandwidth		=> RD_bandwidth,
							RDS_bandwidth		=> RDS_bandwidth,
							num_ADCs			=> num_ADCs,
							ADC_latency			=> ADC_latency)
			  port map(	i_clk						=> clk,
						i_rst						=> rst,
						i_instruction_1				=> i_instruction_1,
						i_instruction_2				=> i_instruction_2,
						i_RD						=> i_RD,
						i_RD_buffer_index			=> i_RD_buffer_index,
						i_RD_outside_E				=> i_RD_outside_E,
						i_RD_write_done				=> i_RD_write_done,
						i_WD						=> i_WD,
						i_WD_outside_E				=> i_WD_outside_E,
						i_WD_write_done				=> i_WD_write_done,
						i_output_buffer_read		=> i_output_buffer_read,
						i_RD_set_val				=> i_RD_set_val,
						o_RD_request				=> o_RD_request,
						o_WD_request				=> o_WD_request,
						o_output_request			=> o_output_request,
						o_output_buffer_out			=> o_output_buffer_out,
						o_output_buffer_logic_out	=> o_output_buffer_logic_out,
						o_PC_1						=> o_PC_1,
						o_PC_2						=> o_PC_2,

						-- test signal
						test_array_FF_out_signals => test_array_FF_out_signals,
						test_stall_1 => test_stall_1,
						test_stall_2 => test_stall_2,
						test_array_done => test_array_done,
						test_VRF_flag => test_VRF_flag,
						test_logic_reg_output => test_logic_reg_output,
						test_crossbar_output => test_crossbar_output,
						test_sampled_data => test_sampled_data,
						test_ADC_output => test_ADC_output,
						test_RD_buffer => test_RD_buffer,
						test_addition_out => test_addition_out,
						test_return_reg => test_return_reg,
						test_jr_flag => test_jr_flag);

end tb;
