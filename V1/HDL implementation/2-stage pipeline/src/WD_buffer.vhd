-----------------------------------------------------------------------
-- Project: CiM-Tile HW Design/implementation                        --
-- File	  : WD_Buffer.vhd                                            --
-- Author : Remon van Duijnen (R.F.J.vanDuijnen@student.tudelft.nl)  --
-- Version: 1.0														 --
-----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity WD_buffer is
generic(bandwidth : integer;
		crossbar_columns: integer
);
port( i_clk : in std_logic;
	  i_WD  : in std_logic_vector(bandwidth - 1 downto 0);
	  shift : in std_logic;

	  o_WD  : out std_logic_vector(bandwidth - 1 downto 0)
);
end WD_buffer;

architecture behavioural of WD_buffer is

	component D_FF port(
		D	: in std_logic;
		E	: in std_logic;
		clk	: in std_logic;
		Q	: out std_logic 
		);
	end component;

type WD_buffer_signal_array is array ((crossbar_columns / bandwidth) - 2 downto 0) of std_logic_vector(bandwidth - 1 downto 0);
signal WD_array : WD_buffer_signal_array; 

begin

-- in this case the buffer is 1 row of width equal to #columns
WD0:	if (bandwidth = crossbar_columns) generate
			G01: for i in (crossbar_columns - 1) downto 0 generate
				DFF_1: D_FF port map( D   => i_WD(i),
									  E   => shift,
									  clk => i_clk,
									  Q   => o_WD(i));
			end generate;
		end generate;

-- NOTE: For now it is assumed everything is powers of 2
-- The total buffer size is always equal to the #columns, but split according to bandwidth
WD1:	if (bandwidth < crossbar_columns) generate
			G11: for i in ((crossbar_columns / bandwidth) - 1) downto 0 generate


				-- top row of buffer (input)
				BUF_TOP: if (i = ((crossbar_columns / bandwidth) - 1)) generate 
						G12: for j in (bandwidth - 1) downto 0 generate
							  	DFF_2: D_FF port map( D => i_WD(j),
									  				  E => shift,
													  clk => i_clk,
									  				  Q => WD_array(i-1)(j));
							  end generate;
				end generate;


				-- middle section of buffer
				BUF_MID: if (i /= ((crossbar_columns / bandwidth) - 1) and i /= 0) generate 
						G13: for j in (bandwidth - 1) downto 0 generate
							  	DFF_3: D_FF port map( D => WD_array(i)(j),
									  				  E => shift,
													  clk => i_clk,
									  				  Q => WD_array(i-1)(j));
							  end generate;
				end generate;


				-- bottom row of buffer (output)
				BUF_BOT: if (i = 0) generate 
						G14: for j in (bandwidth - 1) downto 0 generate
							  	DFF_4: D_FF port map( D => WD_array(i)(j),
									  				  E => shift,
													  clk => i_clk,
									  				  Q => o_WD(j));
							  end generate;
				end generate;

				
			end generate;
		end generate;

end behavioural;
