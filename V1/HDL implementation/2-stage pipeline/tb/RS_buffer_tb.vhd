-----------------------------------------------------------------------
-- Project: CiM-Tile HW Design/implementation                        --
-- File	  : RS_Buffer_tb.vhd                                         --
-- Author : Remon van Duijnen (R.F.J.vanDuijnen@student.tudelft.nl)  --
-- Version: 1.0														 --
-----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity RS_buffer_tb is
end RS_buffer_tb;

architecture tb of RS_buffer_tb is

-- constants
	constant clk_period		   : time	 := 2 ns;
	constant max_datatype_size : integer := 4;
	constant crossbar_rows 	   : integer := 4;
	constant buffer_type	   : integer := 1; -- 0 is shift input, 1 is addressable

-- components
component RS_buffer
	generic(max_datatype_size : integer;
		    crossbar_rows	  : integer;
			buffer_type		  : integer);
    port(	i_clk 			  : in std_logic;
			i_index		      : in std_logic_vector(integer(log2(real(crossbar_rows))) - 1 downto 0);
			i_RS 			  : in std_logic_vector(max_datatype_size - 1 downto 0);
			write_enable 	  : in std_logic;
			read_or_write 	  : in std_logic;
			o_RS 			  : out std_logic_vector(crossbar_rows-1 downto 0));
end component;

-- signals
	-- inputs
	signal clk 			 : std_logic := '0';
	signal i_index		 : std_logic_vector(integer(log2(real(crossbar_rows))) - 1 downto 0);
	signal i_RS  		 : std_logic_vector(max_datatype_size - 1 downto 0) := (others => '0');
	signal write_enable  : std_logic := '0';
	signal read_or_write : std_logic := '0';
	
	--outputs
	signal o_RS : std_logic_vector(crossbar_rows - 1 downto 0);

begin

	clk <= NOT clk after clk_period / 2;

uut: RS_buffer 
	 generic map(
		max_datatype_size => max_datatype_size,
		crossbar_rows 	  => crossbar_rows,
		buffer_type       => buffer_type)
	 port map(  i_clk 		  => clk,
				i_index       => i_index,
				i_RS 		  => i_RS,
				write_enable  => write_enable,
				read_or_write => read_or_write,
				o_RS 		  => o_RS);

-- test for max datatype size = 4, #rows = 4
	i_index <= "11",
			   "10" after 10 ns,
			   "01" after 20 ns,
			   "00" after 30 ns;

	i_RS <= "1000", 
			"1101" after 10 ns, 
			"1110" after 20 ns, 
			"0111" after 30 ns;

	write_enable <= '1' after 5 ns, '0'  after 7 ns, 
		     		'1' after 15 ns, '0' after 17 ns, 
		     		'1' after 25 ns, '0' after 27 ns,
			 		'1' after 35 ns, '0' after 37 ns,
					'1' after 45 ns, '0' after 47 ns, 
		     		'1' after 55 ns, '0' after 57 ns,
			 		'1' after 65 ns, '0' after 67 ns;

	read_or_write <= '0', '1' after 40 ns;



end tb;
