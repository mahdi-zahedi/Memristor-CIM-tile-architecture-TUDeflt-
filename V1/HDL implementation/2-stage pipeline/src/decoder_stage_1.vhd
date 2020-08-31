-----------------------------------------------------------------------
-- Project: CiM-Tile HW Design/implementation                        --
-- File	  : decoder_stage_1.vhd                                      --
-- Author : Remon van Duijnen (R.F.J.vanDuijnen@student.tudelft.nl)  --
-- Version: 1.0														 --
-----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity decoder_stage_1 is
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
end entity;

architecture behavioural of decoder_stage_1 is

-- constants
	constant PC_reg_size : integer := integer(log2(real(mem_size)));
	constant large_instruction_size_bytes : integer := (bandwidth / 8) + 2;
	constant max_inc_bits : integer := integer(ceil(log2(real((bandwidth/8)+2)))); -- +2 (1 for opcode byte
																				   -- and 1 for correct round) 
																				   -- CHECK IF THIS IS PROPER SOLUTION!

-- components
	component MUX2 is
	port( A : in std_logic;
		  B	: in std_logic;
		  sel : in std_logic;
		  O : out std_logic);
	end component;

	component D_FF_PC port(
		D	: in std_logic;
		E	: in std_logic;
		P	: in std_logic;
		C	: in std_logic;
		clk : in std_logic;
		Q	: out std_logic);
	end component;

	component PC_LUT is
	generic(val_00   : integer;
			val_01   : integer;
			val_10   : integer;
			val_11   : integer;
			bit_size : integer);
	port   (sel : in  std_logic_vector(1 downto 0);
			O   : out std_logic_vector(bit_size - 1 downto 0));
	end component;

	component PC_adder is
	generic(size_A : integer;
			size_B : integer);
	port   (A : in  std_logic_vector(size_A - 1 downto 0); 
			B : in  std_logic_vector(size_B - 1 downto 0); 
			O : out std_logic_vector(size_A - 1 downto 0));
	end component;

	component DEMUX is
		generic( num_in_bits	:	integer;
				 num_out_blocks	:	integer
				);
		port(	i_data	: in  std_logic_vector(num_in_bits - 1 downto 0);
			    i_sel	: in  std_logic_vector(num_out_blocks - 1 downto 0);
				o_data	: out std_logic_vector(num_in_bits * num_out_blocks - 1 downto 0)
				);
	end component;
	
	component D_FF port(
		D	: in std_logic;
		E	: in std_logic;
		clk : in std_logic;
		Q	: out std_logic 
		);
	end component;

-- signals
	signal opcode : std_logic_vector(3 downto 0);
	signal index  : std_logic_vector(7 downto 0);
	signal data   : std_logic_vector(bandwidth - 1 downto 0);

	signal PC_inc, PC_set, PC_reg_D, PC_reg_out : std_logic_vector(PC_reg_size - 1 downto 0);
	signal PC_inc_or_set, PC_reg_E, reg_C  : std_logic;
	signal PC_LUT_sel : std_logic_vector(1 downto 0);
	signal PC_lut_val : std_logic_vector(max_inc_bits - 1 downto 0);
	signal s_FS_E : std_logic;
	signal s_branch_reg_E : std_logic;
	signal branch_flag_S, branch_flag_R, branch_flag_E, branch_flag : std_logic;
	signal s_FS_data : std_logic_vector(3 downto 0); 
	signal s_DTS_data : std_logic_vector(3 downto 0);

	signal data_bytes_DEMUX_sel : std_logic_vector(3 downto 0);
	signal data_bytes_DEMUX_out : std_logic_vector(4 * bandwidth - 1 downto 0);
	type   data_bytes_DEMUX_out_array_type is array (3 downto 0) of std_logic_vector(bandwidth - 1 downto 0);
	signal data_bytes_DEMUX_out_array : data_bytes_DEMUX_out_array_type;

	signal data_bits_DEMUX_sel : std_logic_vector(4 downto 0);
	signal data_bits_DEMUX_out : std_logic_vector(5 * 8 - 1 downto 0);
	type   data_bits_DEMUX_out_array_type is array (4 downto 0) of std_logic_vector(7 downto 0);
	signal data_bits_DEMUX_out_array : data_bits_DEMUX_out_array_type;

	signal RDS_op, RD_op, DoA_op, DoS_op, WDS_op, WD_op, FS_op, DTS_op : std_logic;
	signal no_stall : std_logic;

begin

-- split instruction into signals for opcode, index, data
-- first byte: 4 bits opcode, 4 bits index
-- then other bytes are data, size depends on bandwidth

G0: for i in 3 downto 0 generate
		opcode(i) <= i_instruction(bandwidth + 8 + 4 + i);
	end generate; 

G1: for i in 7 downto 0 generate
		index(i) <= i_instruction(bandwidth + i);
	end generate;

G2: for i in bandwidth - 1 downto 0 generate
		data(i) <= i_instruction(i);
	end generate;


-- PC register
G3: for i in PC_reg_size - 1 downto 0 generate
U0:		MUX2 port map(A => PC_inc(i), B => PC_set(i), sel => PC_inc_or_set, O => PC_reg_D(i));
U1:		D_FF_PC port map(D => PC_reg_D(i), E => PC_reg_E,
						 P => '1', C => reg_C, clk => i_clk,
						 Q => PC_reg_out(i));
	end generate;

	PC_inc_or_set <= i_branch;

	PC_reg_E <= (NOT i_stall) OR i_branch;
	reg_C <= NOT i_rst;
	o_PC <= PC_reg_out;

-- PC LUT + increment adder
	PC_LUT_sel(0) <= opcode(2); 
	PC_LUT_sel(1) <= opcode(3);

U2:	PC_LUT   generic map(val_00 => large_instruction_size_bytes,
						 val_01 => 2, 
						 val_10 => 1, 
						 val_11 => 1, 
						 bit_size => max_inc_bits)
			 port map   (sel => PC_LUT_sel, O => PC_LUT_val);

U3:	PC_adder generic map(size_A => PC_reg_size, size_B => max_inc_bits)
		  	 port map   (A => PC_reg_out, B=> PC_LUT_val, O => PC_inc);


-- branch reg + branch flag
s_branch_reg_E <= s_FS_E AND ((NOT s_FS_data(2)) AND (NOT s_FS_data(1)) AND (NOT s_FS_data(0))); -- only on FS store

G4: for i in PC_reg_size - 1 downto 0 generate
U4:		D_FF_PC port map(D => PC_reg_out(i), E => s_branch_reg_E,
						 P => '1', C => reg_C, clk => i_clk,
						 Q => PC_set(i));
	end generate;
	
	branch_flag_S <= i_branch AND (not i_rst);
	branch_flag_R <= DoS_op OR i_rst;
	branch_flag_E <= branch_flag_S OR branch_flag_R;

U99: D_FF  port map(D => branch_flag_S, E => branch_flag_E, clk => i_clk, Q => branch_flag);
	

-- Data bytes demux 

	-- NOTE: AS size requirement is dependent on ADC number
	-- Maybe add different sized instruction: add LUT value 
	-- AS not used in this initial version due to simpler addition unit

U5: DEMUX generic map(num_in_bits => bandwidth, num_out_blocks => 4)
		   port map   (i_data => data, i_sel => data_bytes_DEMUX_sel, o_data => data_bytes_DEMUX_out);

G5: for i in 3 downto 0 generate
G6:		for j in bandwidth - 1 downto 0 generate
			data_bytes_DEMUX_out_array(i)(j) <= data_bytes_DEMUX_out(i * bandwidth + j);
		end generate;
	end generate;

	o_RDS_data <= data_bytes_DEMUX_out_array(0);
	o_WDS_data <= data_bytes_DEMUX_out_array(1);

	data_bytes_DEMUX_sel(0) <= RDS_op;
	data_bytes_DEMUX_sel(1) <= WDS_op;

-- Data bits demux (index/FS/Datatype) 

U6: DEMUX generic map(num_in_bits => 8, num_out_blocks => 5)
		   port map   (i_data => index, i_sel => data_bits_DEMUX_sel, o_data => data_bits_DEMUX_out);

G7: for i in 4 downto 0 generate
G8:		for j in 7 downto 0 generate
			data_bits_DEMUX_out_array(i)(j) <= data_bits_DEMUX_out(i * 8 + j);
		end generate;
	end generate;
	
-- this loop is for creating extra index bits for the result exploration.
G10:    for j in 3 downto 0 generate
			s_FS_data(j)  <= data_bits_DEMUX_out_array(3)(j);
	        s_DTS_data(j) <= data_bits_DEMUX_out_array(4)(j);
		end generate;

	
	o_RDS_index <= data_bits_DEMUX_out_array(0);
	o_WDS_index <= data_bits_DEMUX_out_array(1);
	o_WD_index  <= data_bits_DEMUX_out_array(2);
	o_FS_data  <= s_FS_data; --data_bits_DEMUX_out_array(3);
	o_DTS_data <= s_DTS_data; --data_bits_DEMUX_out_array(4);

	data_bits_DEMUX_sel(0) <= RDS_op;
	data_bits_DEMUX_sel(1) <= WDS_op;
	data_bits_DEMUX_sel(2) <= WD_op;
	data_bits_DEMUX_sel(3) <= FS_op;
	data_bits_DEMUX_sel(4) <= DTS_op;

-- control signal generation (opcodes at bottom of file)

	RDS_op <= ((    opcode(3)) AND (    opcode(2)) AND (NOT opcode(1))) OR
			  ((NOT opcode(3)) AND (NOT opcode(2)) AND (NOT opcode(1)));
	o_RDS_c  <= (    opcode(3)) AND (    opcode(2)) AND (NOT opcode(1)) AND (    opcode(0));
	o_RDS_s  <= (    opcode(3)) AND (    opcode(2)) AND (NOT opcode(1)) AND (NOT opcode(0));

	RD_op   <= opcode(3) AND opcode (2) AND opcode (1);

	WDS_op  <= ((    opcode(3)) AND (NOT opcode(2)) AND (    opcode(1))) OR
			   ((NOT opcode(3)) AND (NOT opcode(2)) AND (    opcode(1)));
	o_WDS_c  <=     opcode(3)  AND (NOT opcode(2)) AND      opcode(1)   AND      opcode(0);
	o_WDS_s  <=     opcode(3)  AND (NOT opcode(2)) AND      opcode(1)   AND (NOT opcode(0));

	WD_op   <= (NOT opcode(3)) AND (    opcode(2)) and (    opcode(1)) and (NOT opcode(0));
	FS_op   <= (NOT opcode(3)) AND (    opcode(2)) and (NOT opcode(1)) and (    opcode(0));
	DTS_op  <= (NOT opcode(3)) AND (    opcode(2)) and (NOT opcode(1)) and (NOT opcode(0));
	DoA_op  <= (    opcode(3)) AND (NOT opcode(2)) and (NOT opcode(1)) and (NOT opcode(0));
	DoS_op  <= (    opcode(3)) AND (NOT opcode(2)) and (NOT opcode(1)) and (    opcode(0));
	
	o_NOP_1   <= (NOT opcode(3)) AND (NOT opcode(2)) and (NOT opcode(1)) and (NOT opcode(0));
	o_RDsh_op <= (    opcode(3)) AND (    opcode(2)) and (    opcode(1)) and (NOT opcode(0));

    -- When we stall the stage, the actual control signal should be kept at zero
    -- the 'op' signals are sent to stall detection
    -- the other signals (ending on _E or _S) are sent to the tile hardware
    -- branch flag is used to skip WD instructions if we rewrite a value due to write verify
	no_stall <= NOT i_stall;
	o_RDS_E  <= RDS_op AND no_stall;
	o_RD_E   <= RD_op  AND no_stall;
	o_WDS_E  <= WDS_op AND no_stall;
	o_WD_E   <= WD_op  AND no_stall AND (NOT branch_flag);
	o_WD_op  <= WD_op;
	s_FS_E   <= FS_op  AND no_stall;
	o_FS_E   <= s_FS_E;
	o_FS_op  <= FS_op;
	o_DoA_S  <= DoA_op AND no_stall;
	o_DoA_op <= DoA_op;
	o_DTS_E  <= DTS_op AND no_stall;
	o_DoS_E  <= DoS_op AND no_stall;
	o_DoS_op <= DoS_op; 

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

end behavioural;
