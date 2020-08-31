-----------------------------------------------------------------------
-- Project: CiM-Tile HW Design/implementation                        --
-- File	  : tile_inst_outside.vhd                                    --
-- Author : Remon van Duijnen (R.F.J.vanDuijnen@student.tudelft.nl)  --
-- Version: 1.0														 --
-----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity tile_inst_outside is
	port(i_push_button_L : in std_logic;
	     i_push_button_R : in std_logic;
		 sys_diff_clock_clk_n : in STD_LOGIC;
         sys_diff_clock_clk_p : in STD_LOGIC;
         
         PMOD1_0_LS : in std_logic;
         PMOD1_1_LS : in std_logic;
         PMOD1_2_LS : in std_logic;
         PMOD1_3_LS : in std_logic;
         PMOD2_0_LS : in std_logic;
         PMOD2_1_LS : in std_logic;
         PMOD2_2_LS : in std_logic;
         PMOD2_3_LS : in std_logic;
         
	     o_leds : out std_logic_vector(7 downto 0));
end tile_inst_outside;

architecture tb of tile_inst_outside is

-- NOTE, due to our assumption of no more than 1 ADC per 32 columns for this first version of the hardware, no addition between ADCs is implemented yet
-- This means it is not possible to create configurations with a number of ADCs such that (#columns/ADC) < max_datatype_size!

-- constants
	-- constant clk_period		   : time	 := 2 ns;
	constant results_xplore    : integer := 0; -- 0 for functional test, 1 to omit crossbar model for power/latency exploration
	constant crossbar_rows     : integer := 32; -- 32
	constant crossbar_columns  : integer := 32; -- 32
	constant mem_size_1		   : integer := 1024; --1024;
	constant mem_size_2		   : integer := 1024; --1024;
	constant inst_size		   : integer := 2; -- This constant can be deduced from mem_size_2, fix
	constant WD_bandwidth      : integer := 8; -- 8
	constant WDS_bandwidth     : integer := 8; -- 8 -- should be equal to RDS BW in this version
	constant max_datatype_size : integer := 16;
	constant RS_buffer_type    : integer := 1; -- type 0 not tested with newer versions
	constant RD_bandwidth	   : integer := max_datatype_size; -- equal to max_datatype_size for now
	constant RDS_bandwidth     : integer := 8; -- 8 -- only for RDSb instruction, not tested for values different than WD/WDS bandwidth
	constant num_ADCs          : integer := 2; -- 2
	constant ADC_latency 	   : integer := 0; -- ADC done signal handling not yet implemented in controller (Not sure if we need it anyway)

-- components

COMPONENT output_ila

PORT (
	clk : IN STD_LOGIC;



	probe0 : IN STD_LOGIC_VECTOR(73 DOWNTO 0); 
	probe1 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
	probe2 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
	probe3 : IN STD_LOGIC_VECTOR(0 DOWNTO 0)
);
END COMPONENT  ;

  component design_1 is
  port (
    sys_diff_clock_clk_n : in STD_LOGIC;
    sys_diff_clock_clk_p : in STD_LOGIC;
    clk_out1_0 : out STD_LOGIC;
    reset_rtl : in STD_LOGIC
  );
  end component design_1;

	component tile_top is
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
				ADC_latency 	  : integer);
		port(i_clk : in std_logic;
			 i_rst : in std_logic;
	
			 i_instruction_1 : in std_logic_vector(RDS_bandwidth + 16 - 1 downto 0);
			 i_instruction_2 : in std_logic_vector((inst_size + 1) * 8 - 1 downto 0);
	
			 i_RD			 : in std_logic_vector(max_datatype_size - 1 downto 0);
			 i_RD_buffer_index	: in std_logic_vector(integer(log2(real(crossbar_rows))) - 1 downto 0);
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
			o_WD_reg, o_WDS_reg : out std_logic_vector(crossbar_columns - 1 downto 0);
			test_array_FF_out_signals : out std_logic_vector(crossbar_rows * crossbar_columns - 1  downto 0);
			test_VMM : out std_logic;
			test_stall_1 : out std_logic; 
			test_stall_2 : out std_logic;
			test_array_done : out std_logic;
			test_VRF_flag : out std_logic;
			test_logic_reg_output : out std_logic_vector (crossbar_columns - 1 downto 0);
			test_crossbar_output : out std_logic_vector (crossbar_columns * integer(log2(real(crossbar_rows))) - 1 downto 0);
			test_sampled_data : out std_logic_vector(crossbar_columns * integer(log2(real(crossbar_rows))) - 1 downto 0);
			test_ADC_output : out std_logic_vector(num_ADCs * integer(log2(real(crossbar_rows))) - 1 downto 0);
			test_RD_buffer : out std_logic_vector(crossbar_rows - 1 downto 0);
			test_addition_out : out std_logic_vector(num_ADCs * (2 * max_datatype_size + integer(log2(real(crossbar_rows)))) - 1 downto 0);
			test_return_reg : out std_logic_vector(integer(log2(real(mem_size_1))) - 1 downto 0);
			test_jr_flag : out std_logic

	);
	end component;

	component instruction_memory_1 is
		generic(inst_size : integer;
				PC_size   : integer;
				mem_size  : integer);
		port( i_PC : in std_logic_vector(PC_size - 1 downto 0);
	
			  o_inst : out std_logic_vector(inst_size * 8 - 1 downto 0)
	);
	end component;

	component instruction_memory_2 is
		generic(inst_size : integer;
				PC_size   : integer;
				mem_size  : integer);
		port( i_PC : in std_logic_vector(PC_size - 1 downto 0);
	
			  o_inst : out std_logic_vector(inst_size * 8 - 1 downto 0)
	);
	end component;

	component outside is
		generic(crossbar_rows		: integer;
				crossbar_columns	: integer;
				num_ADCs			: integer;
				max_datatype_size	: integer;
				WD_bandwidth		: integer
	);
		port(i_clk : std_logic;
			 i_rst : std_logic;
			 i_RD_request : std_logic;
			 i_WD_request : std_logic;
			 i_output_request : std_logic;
			 i_output_buffer_out : std_logic_vector(num_ADCs * ((2*max_datatype_size) + integer(log2(real(crossbar_rows)))) - 1 downto 0);
			 i_output_buffer_logic_out : std_logic_vector(crossbar_columns - 1 downto 0);
			 i_buffer_sel : in std_logic;
	
			 o_RD_data : out std_logic_vector(max_datatype_size - 1 downto 0);
			 o_RD_index : out std_logic_vector(integer(log2(real(crossbar_rows))) - 1 downto 0);
			 o_RD_set_val : out std_logic_vector(integer(log2(real(max_datatype_size))) - 0 downto 0);
			 o_RD_E : out std_logic;
			 o_RD_write_done : out std_logic;
	
			 o_WD_data : out std_logic_vector(WD_bandwidth - 1 downto 0);
			 o_WD_E : out std_logic;
			 o_WD_write_done : out std_logic;
	
			 o_output_buffer_read : out std_logic
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
	-- inputs
	signal s_clk, clk 						: std_logic;
	signal rst 								: std_logic;
	signal s_instruction_1 					: std_logic_vector(RDS_bandwidth + 16 - 1 downto 0);
	signal s_instruction_2 					: std_logic_vector((inst_size + 1) * 8 - 1 downto 0);
	signal i_RD 							: std_logic_vector(max_datatype_size - 1 downto 0);
	signal i_RD_buffer_index 				: std_logic_vector(integer(log2(real(crossbar_rows))) - 1 downto 0);
	signal i_RD_outside_E, i_RD_write_done 	: std_logic;
	signal i_WD 							: std_logic_vector(WD_bandwidth - 1 downto 0);
	signal i_WD_outside_E, i_WD_write_done 	: std_logic;
	signal i_output_buffer_read 			: std_logic;
	signal i_RD_set_val 					: std_logic_vector(integer(log2(real(max_datatype_size))) - 0 downto 0);
	
	-- outputs
	-- signal s_led_vector : std_logic_vector(27 downto 0);
	signal o_RD_request, o_WD_request, o_output_request : std_logic;
	signal s_output_buffer_out : std_logic_vector(num_ADCs * ((2*max_datatype_size) + integer(log2(real(crossbar_rows)))) - 1 downto 0);
	signal o_output_buffer_logic_out : std_logic_vector(crossbar_columns - 1 downto 0);
	signal o_buffer_sel : std_logic;
	signal s_PC_1 : std_logic_vector(integer(log2(real(mem_size_1))) - 1 downto 0);
	signal s_PC_2 : std_logic_vector(integer(log2(real(mem_size_2))) - 1 downto 0);
	signal s_tile_done : std_logic;

	-- test signals
	signal test_stall_1, test_stall_2, test_array_done, test_VRF_flag, test_VMM : std_logic;
	signal test_array_FF_out_signals : std_logic_vector(crossbar_rows * crossbar_columns - 1  downto 0);
	signal test_logic_reg_output : std_logic_vector(crossbar_columns - 1 downto 0);
	signal test_crossbar_output : std_logic_vector(crossbar_columns * integer(log2(real(crossbar_rows))) - 1 downto 0);
	signal test_sampled_data : std_logic_vector(crossbar_columns * integer(log2(real(crossbar_rows))) - 1 downto 0);
	signal test_ADC_output : std_logic_vector(num_ADCs * integer(log2(real(crossbar_rows))) - 1 downto 0);
	signal test_RD_buffer : std_logic_vector(crossbar_rows - 1 downto 0);
	signal test_addition_out : std_logic_vector(num_ADCs * (2 * max_datatype_size + integer(log2(real(crossbar_rows)))) - 1 downto 0);
	signal test_return_reg : std_logic_vector(integer(log2(real(mem_size_1))) - 1 downto 0);
	signal test_jr_flag : std_logic;
	
	signal test_FF_D, test_FF_E, test_FF_o : std_logic;
	signal reset_rtl : std_logic;
	signal s_WD_reg, s_WDS_reg : std_logic_vector(crossbar_columns - 1 downto 0);
	
	signal ila_trigger : std_logic_vector(0 downto 0);
	signal o_buffer_sel_ila : std_logic_vector(0 downto 0);
	signal s_clk_vector : std_logic_vector(25 downto 0);
	signal s_bne : std_logic_vector(0 downto 0);
	
	--type s_output_buffer_out_array_type is array (num_ADCs - 1 downto 0) of std_logic_vector(((2*max_datatype_size) + integer(log2(real(crossbar_rows)))) - 1 downto 0);
	--signal s_output_buffer_out_array : s_output_buffer_out_array_type;

	

begin

    reset_rtl <= (NOT i_push_button_R);

---- STUFF TO STOP VIVADO FROM OPTIMIZING PARTS AWAY
-- if you use this then put the signals to 'open' in 'outside' port map

--    i_RD_buffer_index(0) <= PMOD1_0_LS;
--    i_RD_buffer_index(1) <= PMOD1_1_LS;
--    i_RD_buffer_index(2) <= PMOD1_2_LS;
--    i_RD_buffer_index(3) <= PMOD1_3_LS;
--    i_RD_buffer_index(4) <= PMOD2_0_LS;
--    i_RD_buffer_index(5) <= PMOD2_1_LS;
--    i_RD_buffer_index(6) <= PMOD2_2_LS;
--    i_RD_buffer_index(7) <= PMOD2_3_LS;
--    i_RD_buffer_index(8) <= i_push_button_L;
    
--    i_RD(0)  <= PMOD2_3_LS;
--    i_RD(1)  <= PMOD2_2_LS;
--    i_RD(2)  <= PMOD2_1_LS;
--    i_RD(3)  <= PMOD2_0_LS;
--    i_RD(4)  <= PMOD1_3_LS;
--    i_RD(5)  <= PMOD1_2_LS;
--    i_RD(6)  <= PMOD1_1_LS;
--    i_RD(7)  <= PMOD1_0_LS;
--    i_RD(8)  <= PMOD1_3_LS;
--    i_RD(9)  <= PMOD2_2_LS;
--    i_RD(10) <= PMOD1_1_LS;
--    i_RD(11) <= PMOD2_0_LS;
--    i_RD(12) <= PMOD1_0_LS;
--    i_RD(13) <= PMOD2_1_LS;
--    i_RD(14) <= PMOD1_2_LS;
--    i_RD(15) <= PMOD2_3_LS;
--    i_RD(16)  <= PMOD2_3_LS;
--    i_RD(17)  <= PMOD2_2_LS;
--    i_RD(18)  <= PMOD2_1_LS;
--    i_RD(19)  <= PMOD2_0_LS;
--    i_RD(20)  <= PMOD1_3_LS;
--    i_RD(21)  <= PMOD1_2_LS;
--    i_RD(22)  <= PMOD1_1_LS;
--    i_RD(23)  <= PMOD1_0_LS;
--    i_RD(24)  <= PMOD1_3_LS;
--    i_RD(25)  <= PMOD2_2_LS;
--    i_RD(26) <= PMOD1_1_LS;
--    i_RD(27) <= PMOD2_0_LS;
--    i_RD(28) <= PMOD1_0_LS;
--    i_RD(29) <= PMOD2_1_LS;
--    i_RD(30) <= PMOD1_2_LS;
--    i_RD(31) <= PMOD2_3_LS;
    
    
--    i_WD(0) <= PMOD2_0_LS;
--    i_WD(1) <= PMOD2_1_LS;
--    i_WD(2) <= PMOD2_2_LS;
--    i_WD(3) <= PMOD2_3_LS;
--    i_WD(4) <= PMOD1_0_LS;
--    i_WD(5) <= PMOD1_1_LS;
--    i_WD(6) <= PMOD1_2_LS;
--    i_WD(7) <= PMOD1_3_LS;


---- UNTIL HERE


uut: tile_top generic map(	results_xplore      => results_xplore,
                            crossbar_rows		=> crossbar_rows,
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
						i_instruction_1				=> s_instruction_1,
						i_instruction_2				=> s_instruction_2,
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
						o_output_buffer_out			=> s_output_buffer_out,
						o_output_buffer_logic_out	=> o_output_buffer_logic_out,
						o_buffer_sel                => o_buffer_sel,
						o_PC_1						=> s_PC_1,
						o_PC_2						=> s_PC_2,
						o_tile_done					=> s_tile_done,

						-- test signal
						test_BNE => s_BNE(0),
						o_WD_reg => s_WD_reg,
						o_WDS_reg => s_WDS_reg,
						test_array_FF_out_signals => test_array_FF_out_signals,
						test_VMM => test_VMM,
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


uut1:   instruction_memory_1 generic map(inst_size => ((RDS_bandwidth/8)+2), PC_size => integer(log2(real(mem_size_1))), mem_size => mem_size_1)
		      				  port map(i_PC => s_PC_1, o_inst => s_instruction_1);

uut2:   instruction_memory_2 generic map(inst_size => (inst_size+1), PC_size => integer(log2(real(mem_size_2))), mem_size => mem_size_2)
		      				  port map(i_PC => s_PC_2, o_inst => s_instruction_2);

uut3:   outside generic map(   crossbar_rows => crossbar_rows,
		  	   	   		  	   crossbar_columns => crossbar_columns,
						       num_ADCs => num_ADCs,
						  	   max_datatype_size => max_datatype_size,
						  	   WD_bandwidth => WD_bandwidth)
			     port map(	i_clk => clk,
						    i_rst => rst,
						    i_RD_request => o_RD_request,
						    i_WD_request => o_WD_request,
						    i_output_request => o_output_request,
						    i_output_buffer_out => s_output_buffer_out,
						    i_output_buffer_logic_out => o_output_buffer_logic_out,
						    i_buffer_sel => o_buffer_sel,

						    o_RD_data => i_RD,                    --
						    o_RD_index => i_RD_buffer_index,      --
						    o_RD_set_val => i_RD_set_val,
						    o_RD_E => i_RD_outside_E,
						    o_RD_write_done => i_RD_write_done,

						    o_WD_data => i_WD,                    -- 
						    o_WD_E => i_WD_outside_E,
						    o_WD_write_done => i_WD_write_done,

						    o_output_buffer_read => i_output_buffer_read);
						    
						    
						    
-------------- DEBUG STUFF --------------

your_instance_name : output_ila
PORT MAP (
	clk => clk,



	probe0 => s_output_buffer_out, 
	probe1 => o_output_buffer_logic_out, 
	probe2 => o_buffer_sel_ila,
	probe3 => ila_trigger
	
	--probe0 => s_WD_reg, 
	--probe1 => test_sampled_data, 
	--probe2 => s_WDS_reg,
	--probe3 => s_BNE
);

    ila_trigger(0) <= i_output_buffer_read;
    o_buffer_sel_ila(0) <= o_buffer_sel;
    
    --o_tile_done <= s_tile_done;
    rst <= reset_rtl;
    o_leds(7) <= clk;
    o_leds(6) <= test_VMM;
    o_leds(5) <= '0';
    o_leds(4) <= test_array_done;
    o_leds(3) <= test_VRF_flag;
    o_leds(2) <= test_stall_2;
    o_leds(1) <= test_stall_1;
    o_leds(0) <= s_tile_done;
    
-----------------------------------------   
						
-- to slow down clock if required
--process(s_clk) is
--begin

--    if(rising_edge(s_clk)) then
--        s_clk_vector <= s_clk_vector + 1;
--    end if;
--end process;
--clk <= s_clk_vector(23);
						
design_1_i: component design_1
     port map (
      clk_out1_0 => clk,
      reset_rtl => '0',
      sys_diff_clock_clk_n => sys_diff_clock_clk_n,
      sys_diff_clock_clk_p => sys_diff_clock_clk_p
    );

end tb;



