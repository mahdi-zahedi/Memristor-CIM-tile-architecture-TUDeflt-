-----------------------------------------------------------------------
-- Project: CiM-Tile HW Design/implementation                        --
-- File	  : decoder_stage_2.vhd                                      --
-- Author : Remon van Duijnen (R.F.J.vanDuijnen@student.tudelft.nl)  --
-- Version: 1.0														 --
-----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity decoder_stage_2 is
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
end entity;

architecture behavioural of decoder_stage_2 is

-- constants
	constant inst_size_bits : integer := inst_size * 8; 
	constant CSR_bits       : integer := integer(log2(real(crossbar_columns/num_ADCs)));
	constant num_ADC_bytes  : integer := integer(ceil(real(num_ADCs) / real(8)));
	constant PC_reg_size    : integer := integer(log2(real(mem_size)));
	constant num_PC_bytes   : integer := integer(ceil(real(PC_reg_size)/real(8)));
	constant jal_bits       : integer := integer(ceil(log2(real(num_PC_bytes + 2))));
	constant max_inc_bits   : integer := integer(ceil(log2(real(inst_size + 2)))); -- +2 (1 for opcode byte
																				   -- and 1 for correct round) 
																				   -- CHECK IF THIS IS PROPER SOLUTION!

-- components
	component MUX4 is
	port( A   : in std_logic;
		  B	  : in std_logic;
		  C	  : in std_logic;
		  D	  : in std_logic;
		  sel : in std_logic_vector(1 downto 0);
		  O   : out std_logic);
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

-- signals
	signal opcode : std_logic_vector(3 downto 0);
	signal index  : std_logic_vector(3 downto 0);
	signal data   : std_logic_vector(inst_size_bits - 1 downto 0);

	signal PC_inc, PC_branch, PC_jal, PC_jr, PC_jr_inter, PC_reg_D, PC_reg_out : std_logic_vector(PC_reg_size - 1 downto 0);
	signal PC_reg_E, reg_C  : std_logic;
	signal PC_sel  : std_logic_vector(1 downto 0);

	signal PC_LUT_sel : std_logic_vector(1 downto 0);
	signal PC_LUT_val : std_logic_vector(max_inc_bits - 1 downto 0);
	signal branch_reg_E : std_logic;
	signal i_stall_delayed : std_logic;

	signal s_CSR_index			 : std_logic_vector(CSR_bits - 1 downto 0);
	signal s_AS_data, s_CSR_data : std_logic_vector(num_ADCs - 1 downto 0);
	signal s_PC_jal				 : std_logic_vector(PC_reg_size - 1 downto 0);
	signal s_jal_size_bytes      : std_logic_vector(jal_bits - 1 downto 0);

	signal CSR_op, jal_op, AS_op, jr_op, BNE_op, LS_op, IADD_op, CP_op, CB_op : std_logic;
	signal LS_reg_E : std_logic;
	signal no_stall : std_logic;

	signal jr_flag, jr_flag_E : std_logic;
	signal column_reg_output_E, column_reg_FS : std_logic;
	

begin

-- split instruction into signals for opcode, index, data
-- first byte: 4 bits opcode, 4 bits index
-- then other bytes are data

G0: for i in 3 downto 0 generate
		opcode(i) <= i_instruction(inst_size_bits + 4 + i);
	end generate; 

G1: for i in 3 downto 0 generate
		index(i) <= i_instruction(inst_size_bits + i);
	end generate;

G2: for i in inst_size_bits - 1 downto 0 generate
		data(i) <= i_instruction(i);
	end generate;

-- PC register -----------------------------------------------------------
G3: for i in PC_reg_size - 1 downto 0 generate
U0:		MUX4 port map(A => PC_inc(i), B => PC_jal(i), 
					  C => PC_jr(i), D => PC_branch(i),
					  sel => PC_sel, O => PC_reg_D(i));
U1:		D_FF_PC port map(D => PC_reg_D(i), E => PC_reg_E,
						 P => '1', C => reg_C, clk => i_clk,
						 Q => PC_reg_out(i));
	end generate;

	PC_sel(0) <=  ((NOT opcode(3)) AND (    opcode(2)) and (NOT opcode(1)) and (NOT opcode(0))) OR
				 (((    opcode(3)) AND (NOT opcode(2)) and (NOT opcode(1)) and (    opcode(0))) AND i_VRF_flag);
	PC_sel(1) <= (((    opcode(3)) AND (NOT opcode(2)) and (NOT opcode(1)) and (    opcode(0))) AND i_VRF_flag) OR
				 (((    opcode(3)) AND (NOT opcode(2)) and (NOT opcode(1)) and (NOT opcode(0))) AND jr_flag);

	PC_reg_E <= NOT i_stall;
	reg_C    <= NOT i_rst;

	o_PC     <= PC_reg_out;

-- PC LUT + increment adder
	PC_LUT_sel(0) <= opcode(2); 
	PC_LUT_sel(1) <= opcode(3);

U2:	PC_LUT   generic map(val_00 => 1 + num_ADC_bytes + 1,
						 val_01 => 1 + num_ADC_bytes, 
						 val_10 => 1, 
						 val_11 => 1, 
						 bit_size => max_inc_bits)
			 port map   (sel => PC_LUT_sel, O => PC_LUT_val);

U3:	PC_adder generic map(size_A => PC_reg_size, size_B => max_inc_bits)
		  	 port map   (A => PC_reg_out, B=> PC_LUT_val, O => PC_inc);

-- branch reg -------------------------------------------------------------
G4: for i in PC_reg_size - 1 downto 0 generate
U4:		D_FF_PC port map(D => PC_reg_out(i), E => branch_reg_E,
						 P => '1', C => reg_C, clk => i_clk,
						 Q => PC_branch(i));
	end generate;

	branch_reg_E <= NOT i_stall AND ( i_stall_delayed);
	o_branch_reg <= PC_branch; -- test signal

U5:	D_FF_PC port map(D => i_stall, E => '1',
					 P => reg_C, C => '1', clk => i_clk,
					 Q => i_stall_delayed);
	

-- return reg ----------------------------------------------------------
G5: for i in PC_reg_size - 1 downto 0 generate
U6:		D_FF_PC port map(D => PC_reg_out(i), E => jal_op,
						 P => '1', C => reg_C, clk => i_clk,
						 Q => PC_jr_inter(i));
	end generate;

	process(i_rst) -- maybe this can be done without process? (NO HARDCODING!)
	begin
		s_jal_size_bytes <= std_logic_vector(to_unsigned(num_PC_bytes, jal_bits) + 1);
	end process;

U7:	PC_adder generic map(size_A => PC_reg_size, size_B => jal_bits)
		  	 port map   (A => PC_jr_inter, B=> s_jal_size_bytes, O => PC_jr);

	-- jr flag
U8:		D_FF_PC port map(D => jal_op, E => jr_flag_E,
						 P => '1', C => reg_C, clk => i_clk,
						 Q => jr_flag);
	jr_flag_E <= (jal_op or jr_op) AND no_stall;

	test_jr_flag <= jr_flag;
	o_jr_reg <= PC_jr; -- test signal

-- data bits -------------------------------------------------------------
	-- not used for this stage decoder

-- data bytes -----------------------------------------------------------
-- maybe use de-multiplexer in future version (Does it save energy/time?)
-- the masking (using AND XX_E) is not necessary but makes simulation functionality easier to see
-- it can be removed later.
G6:	for i in CSR_bits - 1 downto 0 generate
		s_CSR_index(i) <= data(i);
		o_CSR_index(i) <= s_CSR_index(i) AND CSR_op;
	end generate;

G7: for i in num_ADCs - 1 downto 0 generate
		s_AS_data(i)  <= data(inst_size_bits - num_ADCs + i);
	    s_CSR_data(i) <= data(inst_size_bits - num_ADCs + i);
		o_AS_data(i)  <= s_AS_data(i)  AND AS_op;
		o_CSR_data(i) <= s_CSR_data(i) AND CSR_op;
	end generate;

G8:	for i in PC_reg_size - 1 downto 0 generate
		s_PC_jal(i) <= data(i); -- If address is prepended instead of appended use data(inst_size_bits - PC_reg_size + i);
		PC_jal(i) <= s_PC_jal(i) AND jal_op;
	end generate; 

-- control signal generation ------------------------------------------------

	CSR_op  <= (NOT opcode(3)) AND (NOT opcode(2)) and (NOT opcode(1)) and (    opcode(0));
	jal_op  <= (NOT opcode(3)) AND (    opcode(2)) and (NOT opcode(1)) and (NOT opcode(0));
	AS_op   <= (NOT opcode(3)) AND (    opcode(2)) and (    opcode(1)) and (NOT opcode(0));
	jr_op   <= (    opcode(3)) AND (NOT opcode(2)) and (NOT opcode(1)) and (NOT opcode(0));
	BNE_op  <= (    opcode(3)) AND (NOT opcode(2)) and (NOT opcode(1)) and (    opcode(0));
	LS_op   <= (    opcode(3)) AND (    opcode(2)) and (NOT opcode(1)) and (NOT opcode(0));
	IADD_op <= (    opcode(3)) AND (    opcode(2)) and (NOT opcode(1)) and (    opcode(0));
	CP_op   <= (    opcode(3)) AND (    opcode(2)) and (    opcode(1)) and (NOT opcode(0));
	CB_op   <= (    opcode(3)) AND (    opcode(2)) and (    opcode(1)) and (    opcode(0));
	o_NOP_2 <= (NOT opcode(3)) AND (NOT opcode(2)) and (NOT opcode(1)) and (NOT opcode(0));

 	column_reg_FS       <= ((    i_FS(2)) AND (NOT i_FS(1)) AND (NOT i_FS(0))) OR -- read
						   ((NOT i_FS(2)) AND (    i_FS(1)) AND (NOT i_FS(0))) OR -- AND
						   ((NOT i_FS(2)) AND (    i_FS(1)) AND (    i_FS(0))) OR -- OR
						   ((    i_FS(2)) AND (    i_FS(1)) AND (NOT i_FS(0)));    -- XOR

	column_reg_output_E <= column_reg_FS AND jr_op;

	no_stall 		  <= NOT i_stall;
	o_CSR_E  		  <= CSR_op AND no_stall;
	o_CSR_op		  <= CSR_op;
	o_AS_E   		  <= AS_op;
	o_BNE    		  <= BNE_op AND i_VRF_flag;
	o_BNE_op		  <= BNE_op;
	o_IADD_E 		  <= IADD_op;
	o_output_buffer_op<= (CB_op OR CP_op OR column_reg_output_E);
	o_output_buffer_E <= (CB_op OR CP_op OR column_reg_output_E) AND no_stall;
	o_RF_op <= jr_op;
	o_CP <= CP_op;
	o_CB <= CB_op;

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

-- LS control -----------------------------------------------------------------

U9:	D_FF_PC port map(D => LS_op, E => LS_reg_E,
					 P => '1', C => reg_C, clk => i_clk,
					 Q => o_LS);

	LS_reg_E <= (LS_op OR IADD_op) AND (NOT i_stall);
	o_LS_E <= LS_op;


end behavioural;
