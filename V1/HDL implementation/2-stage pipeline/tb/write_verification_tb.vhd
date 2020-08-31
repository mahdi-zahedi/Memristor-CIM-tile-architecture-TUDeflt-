-----------------------------------------------------------------------
-- Project: CiM-Tile HW Design/implementation                        --
-- File	  : write_verification_tb.vhd                                --
-- Author : Remon van Duijnen (R.F.J.vanDuijnen@student.tudelft.nl)  --
-- Version: 1.0														 --
-----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity write_verification_tb is
end write_verification_tb;

architecture tb of write_verification_tb is

-- constants
	constant crossbar_columns : integer := 16;

-- components
	component write_verification is
		generic (crossbar_columns : integer);
		port (i_data : in std_logic_vector(crossbar_columns - 1 downto 0);
			  i_WD   : in std_logic_vector(crossbar_columns - 1 downto 0);
			  i_WDS  : in std_logic_vector(crossbar_columns - 1 downto 0);
	
			  o_verify_flag : out std_logic);
	end component;

-- signals
	-- inputs
	signal i_data : std_logic_vector(crossbar_columns - 1 downto 0);
	signal i_WD   : std_logic_vector(crossbar_columns - 1 downto 0);
	signal i_WDS  : std_logic_vector(crossbar_columns - 1 downto 0);

	--outputs
	signal o_verify_flag : std_logic;

begin

uut: write_verification generic map(crossbar_columns => crossbar_columns)
						port map   (i_data => i_data,
									i_WD   => i_WD,
									i_WDS  => i_WDS,

									o_verify_flag => o_verify_flag);

	i_data <= "0100110000111100",
			  "0100110100111100" after 10 ns,
			  "0100110000111100" after 12 ns,
			  "0100110000111101" after 20 ns,
			  "0100110000111100" after 22 ns,
			  "1100110000111100" after 30 ns,
			  "0100110000000000" after 50 ns,
			  "0100110100000000" after 60 ns,
			  "0100110000000000" after 62 ns,
			  "0100110000000001" after 70 ns,
			  "0100110000000000" after 72 ns,
			  "1100110000000000" after 80 ns;

	i_WD   <= "0100110000111100";

	i_WDS  <= "1111111111111111",
			  "1111111100000000" after 50 ns;

end tb;