-----------------------------------------------------------------------
-- Project: CiM-Tile HW Design/implementation                        --
-- File	  : buffer_management.vhd                                    --
-- Author : Remon van Duijnen (R.F.J.vanDuijnen@student.tudelft.nl)  --
-- Version: 1.0														 --
-----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity buffer_management is
generic(WD_reg_num        : integer;
		max_datatype_size : integer);
port(i_clk, i_rst         : in std_logic;
	 i_RD_E               : in std_logic;
	 i_RD_write_done      : in std_logic;
	 i_WD_E            	  : in std_logic;
	 i_WD_write_done   	  : in std_logic;
	 i_RD_set_val      	  : in std_logic_vector(integer(log2(real(max_datatype_size)))-0 downto 0);
	 i_output_buffer_E 	  : in std_logic;
	 i_output_buffer_read : in std_logic;

	 o_RD_request     : out std_logic;
	 o_WD_request     : out std_logic;
	 o_RD_empty       : out std_logic;
	 o_WD_empty       : out std_logic;
	 o_output_request : out std_logic;
	 o_output_full    : out std_logic);
end entity;

architecture behavioural of buffer_management is

-- constants
	constant WD_bit_size : integer := integer(log2(real(WD_reg_num)));
	constant RD_bit_size : integer := integer(log2(real(max_datatype_size))) + 1;

-- components

	component WD_buffer_counter is
		generic(bit_size : integer);
		port( up_down 	: in std_logic;
			  E         : in std_logic;
			  clk 		: in std_logic;
			  clr 		: in std_logic;
	
			  o 		: out std_logic_vector(bit_size - 1 downto 0));
	end component;

	component RD_buffer_counter is
		generic(bit_size : integer);
		port( set_or_decrease : in std_logic;
			  E        		  : in std_logic;
			  set_val         : in std_logic_vector(bit_size - 1 downto 0);
			  clk 			  : in std_logic;
			  clr 			  : in std_logic;
	
			  o 			  : out std_logic_vector(bit_size - 1 downto 0)
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
	signal WD_count_out, WD_OR_signals : std_logic_vector(WD_bit_size - 1 downto 0);
	signal WD_last_element, WD_empty : std_logic;
	signal WD_FF_S, WD_FF_R, WD_FF_E : std_logic;

	signal RD_count_out, RD_OR_signals : std_logic_vector(RD_bit_size - 1 downto 0);
	signal RD_last_bit, RD_empty : std_logic;
	signal RD_FF_S, RD_FF_R, RD_FF_E : std_logic;

	signal out_FF_S, out_FF_R, out_FF_E : std_logic;
	signal output_full : std_logic;

begin


-- WD buffer management -------------------------------

U0:  WD_buffer_counter generic map(bit_size => WD_bit_size)
					   port map   (up_down => WD_empty,
								   E => i_WD_E,
								   clr => i_rst,
								   clk => i_clk,
								   o => WD_count_out);

G0:	if WD_reg_num = 1 generate
		WD_last_element <= WD_count_out(0);
	end generate;

G1:	if WD_reg_num > 1 generate
		WD_OR_signals(1) <= WD_count_out(1);
	
G2:		for i in WD_bit_size - 1 downto 2 generate
			WD_OR_signals(i) <= WD_OR_signals(i-1) OR WD_count_out(i);
		end generate;

		WD_last_element <= WD_count_out(0) AND (NOT WD_OR_signals(WD_bit_size - 1));
	end generate;

U1: D_FF  port map(D => WD_FF_S, E => WD_FF_E, clk => i_clk, Q => WD_empty);
--U1:	SR_FF port map(S => WD_FF_S, R => WD_FF_R, E => i_clk, Q => WD_empty); -- SR FF not allowed in synthesis?
	WD_FF_S <= (WD_last_element AND i_WD_E) OR  i_rst;
	WD_FF_R <= i_WD_write_done AND (NOT i_rst);
    WD_FF_E <= WD_FF_S OR WD_FF_R;
	o_WD_request <= WD_empty;
	o_WD_empty <= WD_empty;


-- RD buffer management -------------------------------

U2:  RD_buffer_counter generic map(bit_size => RD_bit_size)
					   port map(   set_or_decrease => RD_empty,
								   E 			   => i_RD_E,
								   set_val 		   => i_RD_set_val,
								   clk 			   => i_clk,
								   clr 			   => i_rst,

								   o => RD_count_out);

G3: if max_datatype_size = 1 generate
		-- this will probably never happen
	end generate;

G4:	if max_datatype_size > 1 generate	
		RD_OR_signals(1) <= RD_count_out(1);

G5:		for i in RD_bit_size - 1 downto 2 generate
			RD_OR_signals(i) <= RD_OR_signals(i - 1) OR RD_count_out(i);
		end generate; 

		RD_last_bit <= (NOT RD_count_out(1)) AND (NOT RD_OR_signals(RD_bit_size - 1)); 
	end generate;

U3: D_FF  port map(D => RD_FF_S, E => RD_FF_E, clk => i_clk, Q => RD_empty);
-- U3:	SR_FF port map(S => RD_FF_S, R => RD_FF_R, E => i_clk, Q => RD_empty);
	RD_FF_S <= (RD_last_bit AND i_RD_E) OR  i_rst;
	RD_FF_R <= i_RD_write_done AND (NOT i_rst);
	RD_FF_E <= RD_FF_S OR RD_FF_R;
	o_RD_request <= RD_empty;
	o_RD_empty   <= RD_empty;

-- output buffer management ---------------------------
U4: D_FF  port map(D => out_FF_S, E => out_FF_E, clk => i_clk, Q => output_full);
--U4:	SR_FF port map(S => out_FF_S, R => out_FF_R, E => i_clk, Q => output_full);
	out_FF_S <= i_output_buffer_E AND (NOT i_rst);
	out_FF_R <= i_output_buffer_read OR i_rst;
	out_FF_E <= out_FF_R OR out_FF_S;
	o_output_full <= output_full;
	o_output_request <= output_full;

end behavioural;
