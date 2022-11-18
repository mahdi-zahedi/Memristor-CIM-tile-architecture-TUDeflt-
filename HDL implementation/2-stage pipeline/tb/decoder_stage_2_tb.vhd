-----------------------------------------------------------------------
-- Project: CiM-Tile HW Design/implementation                        --
-- File	  : decoder_stage_2_tb.vhd                                   --
-- Author : Remon van Duijnen (R.F.J.vanDuijnen@student.tudelft.nl)  --
-- Version: 1.0														 --
-----------------------------------------------------------------------

-- NOTE: This file is outdated due to changes when testing the top tb. 
--       This file should be checked/changed

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity decoder_stage_2_tb is
end entity;

architecture tb of decoder_stage_2_tb is

-- constants
	constant clk_period 	  : time	:= 2 ns;
	constant inst_size		  : integer := 2;
	constant num_ADCs		  : integer := 8;
	constant mem_size		  : integer := 1024;
	constant crossbar_columns : integer := 256;

-- components
	component decoder_stage_2 is
	generic(inst_size : integer; -- in bits, excluding first byte
			mem_size  : integer; -- in bytes
			num_ADCs  : integer;
			crossbar_columns : integer
	);
	port(i_clk, i_rst  : in std_logic; 
		 i_instruction : in std_logic_vector((inst_size + 1) * 8 - 1 downto 0);
		 i_stall	   : in std_logic;
		 i_VRF_flag    : in std_logic;
	
		 -- index bits to MUXs
		 o_CSR_index : out std_logic_vector(integer(log2(real(crossbar_columns/num_ADCs))) - 1 downto 0);
		 o_CSR_data   : out std_logic_vector(num_ADCs - 1 downto 0); 
		 o_AS_data  : out std_logic_vector(num_ADCs - 1 downto 0);
	
		 o_CSR_E		   : out std_logic;
		 o_AS_E			   : out std_logic;
		 o_IADD_E		   : out std_logic;
		 o_BNE   		   : out std_logic;
		 o_output_buffer_E : out std_logic;
		 o_CP			   : out std_logic;
	     o_CB			   : out std_logic;
	
		 o_LS : out std_logic;
	
		 o_PC : out std_logic_vector(integer(log2(real(mem_size))) - 1 downto 0);

		 -- test signals
		 o_jr_reg    : out std_logic_vector(integer(log2(real(mem_size))) - 1 downto 0);
		 o_branch_reg : out std_logic_vector(integer(log2(real(mem_size))) - 1 downto 0)
	);
	end component;


-- signals
	-- inputs
	signal clk  		 : std_logic := '0'; 
	signal i_rst  		 : std_logic; 
	signal i_instruction : std_logic_vector((inst_size + 1) * 8 - 1 downto 0);
	signal i_stall	   	 : std_logic;
	signal i_VRF_flag    : std_logic; 
	
	-- outputs
	signal o_CSR_index 	  	 : std_logic_vector(integer(log2(real(crossbar_columns/num_ADCs))) - 1 downto 0);
	signal o_CSR_data   	 : std_logic_vector(num_ADCs - 1 downto 0); 
	signal o_AS_data  		 : std_logic_vector(num_ADCs - 1 downto 0);
	signal o_CSR_E		   	 : std_logic;
	signal o_AS_E			 : std_logic;
	signal o_IADD_E		  	 : std_logic;
	signal o_BNE   		     : std_logic;
	signal o_output_buffer_E : std_logic;
	signal o_LS 		     : std_logic;
	signal o_PC 			 : std_logic_vector(integer(log2(real(mem_size))) - 1 downto 0);
	signal o_jr_reg  		 : std_logic_vector(integer(log2(real(mem_size))) - 1 downto 0);
	signal o_branch_reg		 : std_logic_vector(integer(log2(real(mem_size))) - 1 downto 0);

begin

	clk <= NOT clk after clk_period / 2;

uut: decoder_stage_2 generic map (inst_size => inst_size,
								  mem_size => mem_size,
								  num_ADCs => num_ADCs,
								  crossbar_columns => crossbar_columns)
					 port map(i_clk => clk, i_rst => i_rst,
							  i_instruction => i_instruction,
							  i_stall 	    => i_stall,
							  i_VRF_flag    => i_VRF_flag,

							  o_CSR_index => o_CSR_index,
							  o_CSR_data  => o_CSR_data,
							  o_AS_data   => o_AS_data,

							  o_CSR_E 			=> o_CSR_E,
							  o_AS_E 			=> o_AS_E,
							  o_IADD_E 			=> o_IADD_E,
							  o_BNE 			=> o_BNE,
							  o_output_buffer_E => o_output_buffer_E,

							  o_LS => o_LS,

							  o_PC => o_PC,

							  -- test signals
							  o_branch_reg => o_branch_reg,
							  o_jr_reg     => o_jr_reg);

	i_rst <= '0',
			 '1' after 2 ns,
			 '0' after 4 ns,
			 '1' after 48 ns,
			 '0' after 50 ns;

	i_instruction <= "000000001010101001010101",
					 "000010011010101001010101" after 10 ns,
					 "000110011010101001010101" after 12 ns,
					 "001010011010101001010101" after 14 ns,
					 "001110011010101001010101" after 16 ns,
					 "010000000000000001000000" after 18 ns,
					 "010110011010101001010101" after 20 ns,
					 "011010011010101001010101" after 22 ns,
					 "011110011010101001010101" after 24 ns,
					 "100010011010101001010101" after 26 ns,
					 "100110011010101001010101" after 28 ns,
					 "101010011010101001010101" after 30 ns,
					 "101110011010101001010101" after 32 ns,
					 "110010011010101001010101" after 34 ns,
					 "110110011010101001010101" after 36 ns,
					 "111010011010101001010101" after 38 ns,
					 "111110011010101001010101" after 40 ns,
					 "000100001111000000000001" after 50 ns, --CSR
					 "000100000000111100010000" after 56 ns, --CSR
					 "010000001000000001011111" after 58 ns, --jal
					 "110010011010101001010101" after 60 ns, --LS
					 "000110011010101001010101" after 62 ns, --CSR
					 "000110010101010110101010" after 64 ns, --CSR
					 "100010011010101001010101" after 66 ns, --jr
					 "100110011010101001010101" after 68 ns, --BNE VRF=0
					 "110110011010101001010101" after 70 ns, --IADD
					 "111010011010101001010101" after 72 ns, --CP
					 "110110011010101001010101" after 74 ns, --IADD
					 "111110011010101001010101" after 76 ns, --CB
					 "000100001111111100001110" after 80 ns, --CSR
			     	 "011000001010101011111111" after 84 ns, --AS
					 "011000000101010111111111" after 86 ns, --AS
					 "100110011010101001010101" after 88 ns, --BNE VRF=1
					 "000100000000000000011111" after 90 ns; --CSR 

	i_stall <= '0',
			   '1' after 4 ns,
			   '0' after 10 ns,
			   '1' after 50 ns,
			   '0' after 54 ns,
			   '1' after 76 ns,
			   '0' after 78 ns,
			   '1' after 80 ns,
			   '0' after 82 ns,
			   '1' after 92 ns;

	i_VRF_flag <= '0',
				  '1' after 72 ns;

end tb;

---- OPCODES ----- First bit sorts length
--		 		-- Then sorted by combination per type
-- 0000 - NOP 	-- 
-- 0001 - CSR	--
-- 0010 - X     --
-- 0011 - X 	--
-- 0100 - jal	--
-- 0101 - X	    --
-- 0110 - AS    --
-- 0111 - X		--
-- 1000 - jr  	--
-- 1001 - BNE	--
-- 1010 - X  	--
-- 1011 - X 	--
-- 1100 - LS	--
-- 1101 - IADD	--
-- 1110 - CP	--
-- 1111 - CB	--
--				--
------------------