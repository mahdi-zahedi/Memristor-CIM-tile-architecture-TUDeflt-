-----------------------------------------------------------------------
-- Project: CiM-Tile HW Design/implementation                        --
-- File	  : buffer_managements_tb.vhd                                --
-- Author : Remon van Duijnen (R.F.J.vanDuijnen@student.tudelft.nl)  --
-- Version: 1.0														 --
-----------------------------------------------------------------------

-- NOTE: This file is outdated due to changes when testing the top tb. 
--       This file should be checked/changed

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity buffer_management_tb is
end buffer_management_tb;

architecture tb of buffer_management_tb is

-- constants
	constant clk_period : time := 2 ns;
	constant WD_reg_num : integer := 8;
	constant max_datatype_size : integer := 32;

-- components
	component buffer_management is
	generic(WD_reg_num        : integer;
			max_datatype_size : integer);
	port(i_clk, i_rst    	  : in std_logic;
		 i_RD_E          	  : in std_logic;
		 i_RD_write_done 	  : in std_logic;
		 i_WD_E          	  : in std_logic;
		 i_WD_write_done      : in std_logic;
		 i_RD_set_val 		  : in std_logic_vector(integer(log2(real(max_datatype_size)))-1 downto 0);
	     i_output_buffer_E 	  : in std_logic;
	 	 i_output_buffer_read : in std_logic;
	
		 o_RD_request     : out std_logic;
		 o_WD_request     : out std_logic;
		 o_RD_empty       : out std_logic;
		 o_WD_empty       : out std_logic;
	     o_output_request : out std_logic;
		 o_output_full    : out std_logic);
	end component;
	
-- signals
	-- inputs
	signal clk : std_logic := '0';
	signal rst : std_logic;
	signal i_RD_E : std_logic;
	signal i_RD_write_done : std_logic;
	signal i_WD_E : std_logic;
	signal i_WD_write_done : std_logic;
	signal i_RD_set_val : std_logic_vector(integer(log2(real(max_datatype_size)))-1 downto 0);
	signal i_output_buffer_E : std_logic;
	signal i_output_buffer_read : std_logic;

	-- outputs
	signal o_RD_request     : std_logic;
	signal o_WD_request     : std_logic;
	signal o_RD_empty       : std_logic;
	signal o_WD_empty       : std_logic;
	signal o_output_full    : std_logic;
	signal o_output_request : std_logic;
begin

	clk <= NOT clk after clk_period / 2;

uut: buffer_management generic map(WD_reg_num => WD_reg_num,
								   max_datatype_size => max_datatype_size)
					   port map(i_clk 				 => clk,
								i_rst 				 => rst,
								i_RD_E 		    	 => i_RD_E,
								i_RD_write_done 	 => i_RD_write_done,
								i_WD_E 	        	 => i_WD_E,
								i_WD_write_done 	 => i_WD_write_done,
								i_RD_set_val    	 => i_RD_set_val,
								i_output_buffer_E    => i_output_buffer_E,
								i_output_buffer_read => i_output_buffer_read,

								o_RD_request     => o_RD_request,
								o_WD_request     => o_WD_request,
								o_RD_empty       => o_RD_empty,
								o_WD_empty       => o_WD_empty,
							    o_output_request => o_output_request,
								o_output_full    => o_output_full);

	rst <= '0',
		   '1' after 2 ns,
		   '0' after 4 ns;

	i_output_buffer_E <= '0',
					     '1' after 90 ns,
					     '0' after 92 ns;

	i_output_buffer_read <= '0',
					        '1' after 94 ns,
					        '0' after 96 ns;

	i_RD_E <= '0',
			  '1' after 50 ns,
			  '0' after 52 ns,
			  '1' after 54 ns,
			  '0' after 58 ns,
			  '1' after 60 ns,
			  '0' after 64 ns,
			  '1' after 70 ns,
			  '0' after 72 ns,
			  '1' after 74 ns,
			  '0' after 82 ns;

	i_RD_write_done <= '0',
					   '1' after 56 ns,
					   '0' after 58 ns,
					   '1' after 70 ns,
					   '0' after 72 ns;

	i_WD_E <= '0',
			  '1' after 10 ns,
			  '0' after 14 ns, 
			  '1' after 16 ns,
			  '0' after 18 ns,
			  '1' after 20 ns,
			  '0' after 22 ns,
			  '1' after 30 ns,
			  '0' after 38 ns;
	
	i_WD_write_done <= '0',
					   '1' after 20 ns,
					   '0' after 22 ns;

	i_RD_set_val <= "00010",
					"00100" after 70 ns;

end tb;