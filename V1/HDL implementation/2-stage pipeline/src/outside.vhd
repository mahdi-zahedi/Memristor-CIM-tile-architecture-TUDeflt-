-----------------------------------------------------------------------
-- Project: CiM-Tile HW Design/implementation                        --
-- File	  : outside.vhd                                      		 --
-- Author : Remon van Duijnen (R.F.J.vanDuijnen@student.tudelft.nl)  --
-- Version: 1.0														 --
----------------------------------------------------------------------- 

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
use ieee.numeric_std.all;

entity outside is
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
		 i_output_buffer_out : std_logic_vector(num_ADCs * ((2*max_datatype_size) + integer(log2(real(crossbar_rows)))) - 1 downto 0); -- not yet connected
		 i_output_buffer_logic_out : std_logic_vector(crossbar_columns - 1 downto 0); -- not yet connected
		 i_buffer_sel : in std_logic; -- not yet connected

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
end outside;

architecture behavioural of outside is

-- constants
    constant WD_buffer_height : integer := crossbar_columns / WD_bandwidth;
    constant WD_elements   : integer := 128;
    constant RD_elements   : integer := 64;
    constant matrix_rows   : integer := 32;
    constant RD_valid_bits : integer := 16;

-- components
	component D_FF port(
		D	: in std_logic;
		E	: in std_logic;
		clk : in std_logic;
		Q	: out std_logic 
		);
	end component;

-- signals
	type RD_data_type    is array (RD_elements - 1 downto 0) of std_logic_vector(max_datatype_size - 1 downto 0);
	type RD_index_type   is array (RD_elements - 1 downto 0) of std_logic_vector(integer(log2(real(crossbar_rows))) - 1 downto 0);
	type RD_set_val_type is array (0 downto 0) of std_logic_vector(integer(log2(real(max_datatype_size))) - 0 downto 0);
	type WD_data_type    is array (WD_elements - 1 downto 0) of std_logic_vector(WD_bandwidth - 1 downto 0);

	constant s_RD_data	 : RD_data_type := (
0 => "0101001101010011",
1 => "1101001111010011",
2 => "0010101000101010",
3 => "1011011110110111",
4 => "1011111010111110",
5 => "1111111011111110",
6 => "1011001010110010",
7 => "0011000000110000",
8 => "0010001100100011",
9 => "1110011111100111",
10 => "1000010010000100",
11 => "0110000001100000",
12 => "0110000001100000",
13 => "1110100111101001",
14 => "1011110110111101",
15 => "1000000110000001",
16 => "1110110011101100",
17 => "1110011111100111",
18 => "1110001011100010",
19 => "1111101011111010",
20 => "1101010011010100",
21 => "1011001110110011",
22 => "1101000111010001",
23 => "0000100000001000",
24 => "0111011001110110",
25 => "1111100011111000",
26 => "0000011000000110",
27 => "0000110100001101",
28 => "0111010101110101",
29 => "1001011110010111",
30 => "1101111011011110",
31 => "1100000011000000",
32 => "0100011101000111",
33 => "1000100010001000",
34 => "0111000001110000",
35 => "0010001000100010",
36 => "1000001010000010",
37 => "0011110000111100",
38 => "1000100010001000",
39 => "1110101111101011",
40 => "1011110010111100",
41 => "0101111101011111",
42 => "0110101101101011",
43 => "0010010000100100",
44 => "0101010001010100",
45 => "0101100001011000",
46 => "1101010011010100",
47 => "1101111111011111",
48 => "1001101010011010",
49 => "0000100000001000",
50 => "1001101110011011",
51 => "1010000110100001",
52 => "0000100000001000",
53 => "1000100010001000",
54 => "0111101101111011",
55 => "1010111110101111",
56 => "1010010110100101",
57 => "1011101010111010",
58 => "0000001100000011",
59 => "1111001111110011",
60 => "0100011001000110",
61 => "0010100000101000",
62 => "1110000111100001",
63 => "1101000011010000"
	);
	constant s_RD_index	 : RD_index_type := (
	
0 => "00000",
1 => "00001",
2 => "00010",
3 => "00011",
4 => "00100",
5 => "00101",
6 => "00110",
7 => "00111",
8 => "01000",
9 => "01001",
10 => "01010",
11 => "01011",
12 => "01100",
13 => "01101",
14 => "01110",
15 => "01111",
16 => "10000",
17 => "10001",
18 => "10010",
19 => "10011",
20 => "10100",
21 => "10101",
22 => "10110",
23 => "10111",
24 => "11000",
25 => "11001",
26 => "11010",
27 => "11011",
28 => "11100",
29 => "11101",
30 => "11110",
31 => "11111",
32 => "00000",
33 => "00001",
34 => "00010",
35 => "00011",
36 => "00100",
37 => "00101",
38 => "00110",
39 => "00111",
40 => "01000",
41 => "01001",
42 => "01010",
43 => "01011",
44 => "01100",
45 => "01101",
46 => "01110",
47 => "01111",
48 => "10000",
49 => "10001",
50 => "10010",
51 => "10011",
52 => "10100",
53 => "10101",
54 => "10110",
55 => "10111",
56 => "11000",
57 => "11001",
58 => "11010",
59 => "11011",
60 => "11100",
61 => "11101",
62 => "11110",
63 => "11111"

	);
	constant s_RD_set_val  : RD_set_val_type := (
	0 => std_logic_vector(to_unsigned(RD_valid_bits, integer(log2(real(max_datatype_size))) + 1))
	);
	constant s_WD_data	 : WD_data_type := (
	
0 => "01001000",
1 => "01011010",
2 => "00010100",
3 => "01001000",
4 => "11100011",
5 => "11001100",
6 => "01110110",
7 => "10010010",
8 => "11101101",
9 => "10101011",
10 => "00111000",
11 => "01001011",
12 => "10000101",
13 => "10010010",
14 => "10001100",
15 => "00100110",
16 => "01100010",
17 => "01000011",
18 => "11100011",
19 => "01001001",
20 => "00110001",
21 => "00011100",
22 => "11110111",
23 => "11001011",
24 => "01011101",
25 => "00100000",
26 => "11110000",
27 => "01110011",
28 => "01001100",
29 => "10101000",
30 => "00111101",
31 => "00000110",
32 => "00000011",
33 => "10011000",
34 => "10110010",
35 => "10100001",
36 => "00111011",
37 => "00110011",
38 => "01001111",
39 => "01000000",
40 => "00111010",
41 => "11110111",
42 => "00111001",
43 => "00000001",
44 => "01111000",
45 => "01100111",
46 => "10111100",
47 => "00111101",
48 => "11010101",
49 => "00000111",
50 => "00011000",
51 => "11100000",
52 => "10010101",
53 => "01100011",
54 => "11000100",
55 => "01101010",
56 => "11101001",
57 => "11111001",
58 => "00000000",
59 => "01010001",
60 => "01011001",
61 => "11101010",
62 => "11110101",
63 => "10001100",
64 => "10010001",
65 => "11000001",
66 => "01001000",
67 => "00100000",
68 => "10000000",
69 => "11001011",
70 => "00101100",
71 => "01100110",
72 => "00001100",
73 => "10100110",
74 => "11001001",
75 => "00111001",
76 => "10001101",
77 => "01001101",
78 => "11000101",
79 => "10010011",
80 => "00000110",
81 => "10001011",
82 => "01001100",
83 => "10111111",
84 => "01001111",
85 => "00010101",
86 => "00110101",
87 => "10100110",
88 => "00001110",
89 => "11110000",
90 => "11111100",
91 => "10110110",
92 => "10101111",
93 => "11010110",
94 => "10001011",
95 => "11101100",
96 => "01000000",
97 => "00101101",
98 => "11101110",
99 => "01101001",
100 => "11010100",
101 => "10011100",
102 => "11110000",
103 => "11000000",
104 => "10011011",
105 => "11101000",
106 => "11011000",
107 => "00111011",
108 => "01100011",
109 => "10100010",
110 => "10110111",
111 => "11101001",
112 => "01010001",
113 => "11101111",
114 => "11101011",
115 => "11110111",
116 => "10000001",
117 => "01110011",
118 => "01010101",
119 => "00010111",
120 => "10010011",
121 => "01101011",
122 => "00001101",
123 => "10011100",
124 => "10101010",
125 => "11010000",
126 => "11000011",
127 => "11100111"

	);
	
	signal read_pulse_1, read_pulse_2 : std_logic;

begin

    -- This dummy assumes its possible to read the data in 1 shot.
    -- The actual reading in this version is performed by the logic analyzer (ila)
    -- the outside just provides a control signal to tell the tile its done reading at the next cycle.
FF0: D_FF port map(D => i_output_request, E => '1', clk => i_clk, Q => read_pulse_1); 
FF1: D_FF port map(D => read_pulse_1, E => '1', clk => i_clk, Q => read_pulse_2); 
	 o_output_buffer_read <= read_pulse_1 AND (NOT read_pulse_2);

	
	-- Typical flow of RD filling
    -- once we receive i_RD_request, we set E (enable) to '1'
    -- then, each cycle we fill the next WD element by setting o_RD_E to '1' 
    -- data is provided to o_RD_data. 
    -- count_element and count_row are used to keep track of how many elements/rows we have stored.
	process(i_clk, i_rst) -- RD process
		variable count_element : integer := 0;
		variable count_row : integer := 0;
		variable E : std_logic := '0';
	begin
		if (rising_edge(i_clk)) then
			if (i_rst = '1') then
				E := '0';
				count_element := 0;
				count_row := 0;
				o_RD_E <= '0';
				o_RD_write_done <= '0';
			else
				
				
				if (i_RD_request = '1' AND E = '0') then
				    if ((count_row * matrix_rows) < RD_elements) then
					   E := '1';
					end if;
				elsif (E = '1') then
					o_RD_E <= '1';
					if (count_element < matrix_rows) then
						o_RD_index <= s_RD_index(count_element + count_row * matrix_rows);
						o_RD_data <= s_RD_data(count_element + count_row * matrix_rows);
					end if;
		
					if (count_element = matrix_rows - 1) then
						o_RD_write_done <= '1';
					end if;
		
					if (count_element = matrix_rows) then
					    count_row := count_row + 1;
					    count_element := -1;
						o_RD_write_done <= '0';
						o_RD_E <= '0';
						E := '0';
					end if;			
						count_element := count_element + 1;
				end if;
				
				
			end if;
		end if;
	end process;


    -- Typical flow of WD filling
    -- once we receive i_WD_request, we set E (enable) to '1'
    -- then, each cycle we fill the next WD element by setting o_WD_E to '1' 
    -- data is provided to o_WD_data. Fill the buffer until its completely full
    -- We use 'count' to keep track of how many elements we filled into the buffer
    -- And we use 'count_2' to keep track of how many times we filled the buffer
	process(i_clk, i_rst) -- WD process
		variable count, count_2 : integer := 0;
		variable E : std_logic := '0';
	begin
		if (rising_edge(i_clk)) then
			if (i_rst = '1') then
				E := '0';
				count := 0;
				count_2 := 0;
				o_WD_E <= '0';
				o_WD_write_done <= '0';
			else		
				if (i_WD_request = '1' AND E = '0') then	
				    if (count_2 * WD_buffer_height < WD_elements) then
					   E := '1';	
					end if;
				elsif (E = '1') then
				
					o_WD_E <= '1';
					
					if (count < WD_buffer_height) then
					   if (count + count_2 * WD_buffer_height < WD_elements) then -- check for zero padding
						  o_WD_data <= s_WD_data(count + count_2 * WD_buffer_height);
					   else
					       o_WD_data <= std_logic_vector(to_unsigned(0, WD_bandwidth));
					   end if;
					end if;
		
					if (count = WD_buffer_height - 1) then
						o_WD_write_done <= '1';
					end if;
		
					if (count = WD_buffer_height) then
						o_WD_write_done <= '0';
						o_WD_E <= '0';
						E := '0';
						count_2 := count_2 + 1;
						count := -1;
					end if;			
					
					count := count + 1;
				end if;			
			end if;
		end if;
	end process;

    -- in this version we only ever do a single MMM, so we only need to set 1 value.
    -- If we want to perform more MMMs on different sizes in one program, this should be extended.
    -- The o_RD_set_val should be changed once we reach the next matrix size.
    o_RD_set_val <= s_RD_set_val(0);

end behavioural;