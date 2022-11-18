-----------------------------------------------------------------------
-- Project: CiM-Tile HW Design/implementation                        --
-- File	  : write_verification.vhd                                   --
-- Author : Remon van Duijnen (R.F.J.vanDuijnen@student.tudelft.nl)  --
-- Version: 1.0														 --
-----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity write_verification is
	generic (crossbar_columns : integer);
	port (i_data : in std_logic_vector(crossbar_columns - 1 downto 0);
		  i_WD   : in std_logic_vector(crossbar_columns - 1 downto 0);
		  i_WDS  : in std_logic_vector(crossbar_columns - 1 downto 0);

		  o_verify_flag : out std_logic);
end write_verification;

architecture behavioural of write_verification is

	--signal column_XOR : std_logic_vector(crossbar_columns - 1 downto 0);
	--signal column_AND : std_logic_vector(crossbar_columns - 1 downto 0);
	--signal column_OR  : std_logic_vector(crossbar_columns - 1 downto 0);
	
	--constant test_WD   : std_logic_vector(crossbar_columns - 1 downto 0) := (others => '0');
	--constant test_WDS  : std_logic_vector(crossbar_columns - 1 downto 0) := (others => '0');
	--constant test_data : std_logic_vector(crossbar_columns - 1 downto 0) := (others => '0');

begin

--    column_OR(0) <= (i_data(0) XOR i_WD(0)) AND i_WDS(0);


	process(i_data, i_WD, i_WDS) is
		variable s_vrf_flag : std_logic := '0';
	begin
		s_vrf_flag := '0';
		for i in crossbar_columns-1 downto 0 loop
			if ((i_data(i) /= i_WD(i)) AND (i_WDS(i)='1')) then
				s_vrf_flag := '1';
			end if;
		end loop;

		o_verify_flag <= s_vrf_flag;
	
	end process;

--G0: for i in 1 to crossbar_columns-1 generate
--		column_XOR(i) <= i_data(i) XOR i_WD(i); -- i_data(i) XOR i_WD(i);
--        column_AND(i) <= column_XOR(i) AND i_WDS(i);
--        column_OR(i)  <= column_AND(i) OR column_OR(i-1);
--	end generate;
--
--	o_verify_flag <= column_OR(crossbar_columns - 1);
 
end behavioural;
