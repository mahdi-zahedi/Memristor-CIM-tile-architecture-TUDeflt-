-----------------------------------------------------------------------
-- Project: CiM-Tile HW Design/implementation                        --
-- File	  : output_buffer.vhd                                        --
-- Author : Remon van Duijnen (R.F.J.vanDuijnen@student.tudelft.nl)  --
-- Version: 1.0														 --
-----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
--use ieee.numeric_std.all;

entity output_buffer is
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
end output_buffer;

architecture behavioural of output_buffer is

-- constants
	constant num_regs : integer := num_ADCs;
	constant reg_size : integer := (2*max_datatype_size) + integer(log2(real(crossbar_rows)));

-- components
	component D_FF port(
		D	: in std_logic;
		E	: in std_logic;
		clk : in std_logic;
		Q	: out std_logic 
		);
	end component;

-- signals
	signal VMM_E, COL_E : std_logic;
	signal buffer_sel_D, buffer_sel_E, buffer_sel_R, buffer_sel_S : std_logic;

begin
	
	VMM_E <= i_FS(2) AND i_FS(1) AND i_FS(0) AND i_activate;
	COL_E <= (NOT VMM_E) AND i_activate;
	
    -- signal indicating which buffer should be read. '0' = column buffer, '1' = VMM buffer
    buffer_sel_S <= VMM_E;
    buffer_sel_R <= COL_E;
    buffer_sel_D <= buffer_sel_S;
    buffer_sel_E <= buffer_sel_S OR buffer_sel_R;
U0: D_FF port map(D => buffer_sel_D, E => buffer_sel_E, clk => i_clk, Q => o_buffer_sel);


	-- VMM buffer
G0:	for i in num_regs - 1 downto 0 generate
G1:		for j in reg_size - 1 downto 0 generate
U1:			D_FF port map(D => i_addition_out(i * reg_size + j), E => VMM_E, clk => i_clk, Q => o_output_buffer_out(i * reg_size + j));
		end generate;
	end generate; 


	-- column buffer
G2: for i in crossbar_columns - 1 downto 0 generate
U2:		D_FF port map(D => i_logic_reg_out(i), E => COL_E, clk => i_clk, Q => o_output_buffer_logic_out(i));
	end generate;

end behavioural;
