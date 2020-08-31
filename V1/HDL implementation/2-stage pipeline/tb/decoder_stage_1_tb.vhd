-----------------------------------------------------------------------
-- Project: CiM-Tile HW Design/implementation                        --
-- File	  : decoder_stage_1_tb.vhd                                   --
-- Author : Remon van Duijnen (R.F.J.vanDuijnen@student.tudelft.nl)  --
-- Version: 1.0														 --
-----------------------------------------------------------------------

-- NOTE: This file is outdated due to changes when testing the top tb. 
--       This file should be checked/changed

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity decoder_stage_1_tb is
end entity;

architecture tb of decoder_stage_1_tb is

-- constants
	constant clk_period : time 	  := 2 ns;
	constant bandwidth  : integer := 8;
	constant mem_size   : integer := 1024; -- bytes
-- components
	component decoder_stage_1 is
	generic(bandwidth : integer;
			mem_size  : integer -- in bytes
	);
	port(i_clk, i_rst  : in std_logic; 
		 i_instruction : in std_logic_vector(bandwidth + 8 - 1 downto 0);
		 i_stall	   : in std_logic;
		 i_branch	   : in std_logic;
	
		-- Data to fill in register
		 o_RDS_data : out std_logic_vector(bandwidth - 1 downto 0);
		 o_WDS_data : out std_logic_vector(bandwidth - 1 downto 0);
		 o_FS_data  : out std_logic_vector(3 downto 0);
		 o_DTS_data : out std_logic_vector(3 downto 0);
		 
		-- index bits to MUXs
		 o_WD_index   : out std_logic_vector(3 downto 0); 
		 o_RDS_index  : out std_logic_vector(3 downto 0);
		 o_WDS_index  : out std_logic_vector(3 downto 0);
	
		-- register activation signals
		 o_RDS_E : out std_logic;
		 o_RDS_c : out std_logic;
		 o_RDS_s : out std_logic;
		 o_RD_E  : out std_logic;
		 o_WDS_E : out std_logic;
		 o_WDS_c : out std_logic;
		 o_WDS_s : out std_logic;
		 o_WD_E  : out std_logic;
		 o_FS_E  : out std_logic;
		 o_DoA_S : out std_logic;
		 o_DTS_E : out std_logic;
		 o_DoS_E : out std_logic;
		 
		 o_PC : out std_logic_vector(integer(log2(real(mem_size))) - 1 downto 0)
	);
	end component;
-- signals
	-- inputs
	signal clk   	  	 : std_logic := '0';
	signal i_rst 	     : std_logic;
	signal i_instruction : std_logic_vector(bandwidth + 8 - 1 downto 0);
	signal i_stall	     : std_logic;
	signal i_branch	  	 : std_logic;


	-- outputs
	-- Data to fill in register
	signal o_RDS_data : std_logic_vector(bandwidth - 1 downto 0);
	signal o_WDS_data : std_logic_vector(bandwidth - 1 downto 0);
	signal o_FS_data  : std_logic_vector(3 downto 0);
	signal o_DTS_data : std_logic_vector(3 downto 0);
		 
	-- index bits to MUXs
	signal o_WD_index   : std_logic_vector(3 downto 0); 
	signal o_RDS_index  : std_logic_vector(3 downto 0);
	signal o_WDS_index  : std_logic_vector(3 downto 0);
	
	-- register activation signals
	signal o_RDS_E : std_logic;
	signal o_RDS_c : std_logic;
	signal o_RDS_s : std_logic;
	signal o_RD_E  : std_logic;
	signal o_WDS_E : std_logic;
	signal o_WDS_c : std_logic;
	signal o_WDS_s : std_logic;
	signal o_WD_E  : std_logic;
	signal o_FS_E  : std_logic;
	signal o_DoA_S : std_logic;
	signal o_DTS_E : std_logic;
	signal o_DoS_E : std_logic;
		 
	signal o_PC : std_logic_vector(integer(log2(real(mem_size))) - 1 downto 0);

begin

	clk <= NOT clk after clk_period / 2;

uut: decoder_stage_1 generic map(bandwidth => bandwidth, mem_size => mem_size)
					 port map   (i_clk => clk, i_rst => i_rst,
								 i_instruction => i_instruction,
								 i_stall => i_stall,
								 i_branch => i_branch,

								 o_RDS_data => o_RDS_data,
								 o_WDS_data => o_WDS_data,
								 o_FS_data => o_FS_data,
								 o_DTS_data => o_DTS_data,

								 o_WD_index => o_WD_index,
								 o_RDS_index => o_RDS_index,
								 o_WDS_index => o_WDS_index,

								 o_RDS_E => o_RDS_E,
								 o_RDS_c => o_RDS_c,
								 o_RDS_s => o_RDS_s,
								 o_RD_E => o_RD_E,
								 o_WDS_E => o_WDS_E,
								 o_WDS_c => o_WDS_c,
								 o_WDS_s => o_WDS_s,
								 o_WD_E => o_WD_E,
								 o_FS_E => o_FS_E,
								 o_DoA_S => o_DoA_S,
								 o_DTS_E => o_DTS_E,
								 o_DoS_E => o_DoS_E,

								 o_PC => o_PC);

	i_rst <= '0',
			 '1' after   2 ns,
			 '0' after   4 ns,
			 '1' after 102 ns,
			 '0' after 104 ns;


	i_stall <= '0',
			   '1' after   4 ns,
			   '0' after  10 ns,
			   '1' after  30 ns,
			   '0' after  32 ns,
			   '1' after  42 ns,
			   '1' after 105 ns,
			   '0' after 107 ns,
			   '1' after 115 ns,
			   '0' after 117 ns,
			   '1' after 125 ns,
			   '0' after 127 ns,
			   '1' after 135 ns,
			   '0' after 137 ns,
			   '1' after 145 ns,
			   '0' after 147 ns,
			   '1' after 155 ns,
			   '0' after 157 ns,
			   '1' after 165 ns,
			   '0' after 167 ns,
			   '1' after 175 ns,
			   '0' after 177 ns,
			   '1' after 185 ns,
			   '0' after 187 ns,
			   '1' after 195 ns,
			   '0' after 197 ns,
			   '1' after 205 ns,
			   '0' after 207 ns,
			   '1' after 215 ns,
			   '0' after 217 ns,
			   '1' after 225 ns,
			   '0' after 227 ns,
			   '1' after 235 ns,
			   '0' after 237 ns,
			   '1' after 245 ns,
			   '0' after 247 ns,
			   '1' after 255 ns,
			   '0' after 257 ns,
			   '1' after 265 ns,
			   '0' after 267 ns;

	i_branch <= '0',
				'1' after  44 ns,
			    '0' after  46 ns,
				'1' after 270 ns,
			    '0' after 272 ns;

	i_instruction <= "0000000010101010",
					 "0101100110101010" after   4 ns, -- FS
					 "0100100110101010" after  12 ns, -- DTS
					 "0001100110101010" after  14 ns, -- RDSb
					 "1100100110101010" after  16 ns, -- RSDs
					 "1101100110101010" after  18 ns, -- RDSc
					 "1010100110101010" after  20 ns, -- WDSs
					 "1011100110101010" after  22 ns, -- WDSc
					 "0011100110101010" after  24 ns, -- WDSb
					 "0110100110101010" after  26 ns, -- WDb
					 "1000100110101010" after  28 ns, -- DoA
					 "1001100110101010" after  30 ns, -- DoS
					 "1110100110101010" after  34 ns, -- RDsh
					 "0101100110101010" after  36 ns, -- FS
					 "1000100110101010" after  38 ns, -- DoA
					 "1001100110101010" after  40 ns, -- DoS
					 "0101100110101010" after  42 ns, -- FS
					 "0000100110101010" after 110 ns,
					 "0001100110101010" after 120 ns,
					 "0010100110101010" after 130 ns,
					 "0011100110101010" after 140 ns,
					 "0100100110101010" after 150 ns,
					 "0101100110101010" after 160 ns,
					 "0110100110101010" after 170 ns,
					 "0111100110101010" after 180 ns,
					 "1000100110101010" after 190 ns,
					 "1001100110101010" after 200 ns,
					 "1010100110101010" after 210 ns,
					 "1011100110101010" after 220 ns,
					 "1100100110101010" after 230 ns,
					 "1101100110101010" after 240 ns,
					 "1110100110101010" after 250 ns,
					 "1111100110101010" after 260 ns;
								 
---- OPCODES ----- First bit sorts length
--		 		-- Then sorted by combination per type
-- 0000 - NOP 	-- 
-- 0001 - RDSb	--
-- 0010 - X     --
-- 0011 - WDSb 	--
-- 0100 - DTS	--
-- 0101 - FS	--
-- 0110 - WDb	--
-- 0111 - X		--
-- 1000 - DoA	--
-- 1001 - DoS	--
-- 1010 - WDSs	--
-- 1011 - WDSc	--
-- 1100 - RDSs	--
-- 1101 - RDSc	--
-- 1110 - RDsh	--
-- 1111 - X		--
--				--
------------------
				     

end tb;
