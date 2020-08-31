/***************************************************************************
 * @project: Translation of Micro to nano-instruction (micro2nano compiler)
 * @version: -
 * @author: Remon van Duijnen (R.F.J.vanDuijnen@student.tudelft.nl)
 *
 * Based on:
 * micro2nano version 3.3(17/11/2019)- API2.
 * Authored by Mahdi Zahedi (m.z.zahedi@tudelft.nl)
 ***************************************************************************/

 /****************************description******************************
 Changes in this subversion:

 - Added RSshift (RSsh) and Adder config (ACFG) instructions.

 - Changed re-ordering to be done on stages instead of operations
 
 - Added option to toggle of rowwise as its not implemented in hardware due to large decoders and routing.

 - Removed data from WD and RDS instructions, instead write the data to different files for outside controller.
   WD now only provides the index for the demultiplexer, RDS also provides the RD mask bits

 - added flag to only change the RDS reg contents once during MMM.

 - Added option for combining CS and DoR into signle CSR instruction

 - Changed instruction names
		RSc  -> RDSc
		RSs  -> RDSs
		RSbi -> RDSb
		WD   -> WDb
		WDS  -> WDSb

 - Removed END instruction (Not used by hardware)

 - Changed ENDC instruction for NOP (indicates end of program)

 - bugfixes regarding nano_line_counter

 - Added time multiplexing for smaller datatypes
   (This does assume that the number of selected columns is an integer multiple of the datattype size! 
    Which is only due to using the old version of micro-instructions (selecting columns instead of elements))

 - inverted index of WDb and WDSb due to hardware implementation (so the block '0' is the block on the far right of the crossbar)

 - Added creation of bufferfile which contains data required by the outside controller
   For now, this only supports 1 MMM instruction from micro-format! It should be extended in the future when designing the outside controller

 TODO ------------------------------------------------------------------------
 - Add multiple read_stage files to allow for jumping to multiple different read stages for VMM operations (for time multiplexing)
   The number of read_stage files is thus equal to cols_per_ADC/8 bit (assume 8 bit is smallest used for VMM)

 - make reordering support 3 or 4 stage pipelines (not necessary now as hardware doesnt support it, maybe for need it for sim?)
 - Add support for 'weird' datatypes for the RD buffer copies (it now assumes the rs_bandwidth is an integer multiple of the datatype size)

 clean up code? 
	- remove the i+1, j+1 stuff that changes the row/column indices, they should always start from 0 for consistency!
	  Check thoroughly for +1 and -1's throughout the entire code
	- lots of repetition -> use functions
	- logical operations can at least be collapsed into a single case statement
 ***************************************************************************/

#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <map>
#include <cstdlib>
#include <ctime>
#include <math.h>
#include <vector>
#include<algorithm>
#include "inst2hdl.h"
#include "data2hdl.h"

using namespace std;

static enum s_opcode {
	store,
	read,
	MMM,
	logical_and,
	logical_or,
	logical_xor
};

static enum s_nano_opcode {
	// -- stage 1 ---
	ACFG,
	FS,
	RDSb,
	RDSs,
	RDSc,
	RDsh,
	WDSb,
	WDSs,
	WDSc,
	WDb,
	DoA,
	DoS,
	// --------------
	// -- stage 2 ---
	CS,
	DoR,
	CSR,
	jal,
	jr,
	BNE,
	AS,
	CP,
	CB,
	LS,
	IADD
	// --------------
};

static map<std::string, s_opcode> opcode;
static map<std::string, s_nano_opcode> nano_opcode;

const int mem1_row_size = 2000; const int mem1_column_size = 2000;
const int mem2_row_size = 2000; const int mem2_column_size = 2000;
const int memristor_level = 2; const int num_of_crossbar = 1; const int crossbar_row = 256; const int crossbar_column = 256;
const int num_of_ADC = 16; const char WDS_for_all_operations = 'n'; int Max_row_select = 128; const int datatype_size = 16; const int max_datatype_size = 16;
const int rs_bandwidth = 32, wd_bandwidth = 32, wds_bandwidth = 32; const int no_of_rs_chunks = crossbar_row / rs_bandwidth; const int no_of_wds_chunks = crossbar_column / wds_bandwidth;
const int num_pipeline_counters = 2; const char pipeline_rearrange = 'y'; const char write_verify = 'y';
const bool allow_rowwise = 0; // 0 = dis-allow (row-wise is not supported in hardware)
const bool combine_CS_DoR = 1; // 1 for CSR, 0 for separate CS and DoR
const int time_mux_const = (crossbar_column / num_of_ADC) / datatype_size;
const char toHDL = 'n';

void Initialize(void);
void intMem_init(int*);
void dispMem(int*, ofstream&);

int main()
{
	int time_mux;
	if (datatype_size < crossbar_column / num_of_ADC)
		time_mux = time_mux_const;
	else
		time_mux = 1;

	//********** micro-instruction file ********************
	ifstream infile("D:/Phd/simulators/sim_compiler_arch2/benchmarks/medium/gemm.txt");

	//ifstream infile("D:/Studie/Thesis/Sim/sim_compiler_v3/benchmarks/medium/gemm.txt");
	//ifstream infile("gemm_test.txt");
	//ifstream infile("D:/Studie/Thesis/Sim/sim_compiler_v3/benchmarks/medium/gemm.txt");
	//********** nano-isntruction file *********************
	ofstream nanofile;
	ofstream WDfile;
	ofstream RDfile;
	ofstream bufferfile_tmp;
	ifstream bufferfile_tmp_i;
	ofstream bufferfile;
	ifstream jumpinfile;
	ofstream jumpoutfile;
	jumpoutfile.open("jumpFile.txt");
	jumpoutfile.close();

	ifstream readstageinfile;
	ofstream readstageoutfile;
	//string nanoInst = "nanoInst_" + to_string(rs_bandwidth) + "_" + to_string(Max_row_select) + "_logic.txt";
	//string nanoInst = "nanoInst_gemm_" + to_string(num_of_ADC) + "_" + to_string(Max_row_select) + ".txt";

	nanofile.open("nanoInst.txt");
	WDfile.open("WDfile.txt");
	RDfile.open("RDfile.txt");
	bufferfile_tmp.open("bufferfile_tmp.txt");
	bufferfile.open("bufferfile.txt");
	//readstagefile.open("readStageFile.txt");
	//nanofile.open(nanoInst);
	//********** memory content file *********************
	ofstream memfile1;
	ofstream memfile2;
	memfile1.open("dispMem1.txt");
	memfile2.open("dispMem2.txt");
	//******************************************************
	Initialize();

	string line;
	string readstageline;
	string jumpfileline;
	string string_opcode;
	string op1_address;
	string Add_D_string, Add_S_string, logic_row_string;
	int* intMem1 = new int[mem1_column_size * mem1_row_size];
	int* intMem2 = new int[mem2_column_size * mem2_row_size];

	int Add_D = 0, i = 0, j = 0, Add_S = 0, p = 0, q = 0;
	int Add_M = 0, Add_Cross = 0, e = 0;
	int micro_line_counter = 0; int nano_line_counter = 0;
	int WD_element_count = 0, RD_element_count = 0;
	int output_read_counter = 0;
	int matrix_rows = 0;
	int jal_jump_to = 0;
	bool wds_init = 0;
	bool readstage_jump = 0;
	bool RDsh_flag = 0;
	string FS_ref = "";
	string WDS_temp = "";
	string WDS_ref = "";

	intMem_init(intMem1);
	intMem_init(intMem2);
	dispMem(intMem1, memfile1);
	dispMem(intMem2, memfile2);

	//******************************************************

	// Addition unit configuration should be dependent on the microinstruction? 
	// This version does not allow run-time datatype changes as the micro format should be changed first
	// instead, thisa version justs starts the program with a single ACFG instruction to set up the addition unit.
	int addition_config_val = (int)ceil((float)datatype_size / (float)8); 
	string addition_config_bits;
	for (int k = max((int)ceil(log2(addition_config_val)) - 1, 0); k >= 0; k--)
	{
		(addition_config_val - 1 >> k) & 1 ? addition_config_bits += '1' : addition_config_bits += '0';
	}
	//nanofile << "ACFG" << "\t" << addition_config_bits << endl; nano_line_counter++;

	while (getline(infile, line))
	{
		micro_line_counter++;
		cout << micro_line_counter << endl;

		istringstream iss(line);
		iss >> string_opcode;

		switch (opcode[string_opcode])
		{

			//"store" -- "Add_S" --row starting point "i" --column starting point "j" --number of rows to write "p" --number of columns to write "q"
		case store:
		{
			//------------------------------------------------
			//------------------------------------------------
			int i;
			string temp_string;
			iss >> op1_address;
			for (i = 3; i < op1_address.size(); i++)
				if (op1_address.at(i) == ']')
					break;
				else
					temp_string.push_back(op1_address.at(i));
			int d1 = stoi(temp_string);
			temp_string.clear();

			for (i = i + 2; i < op1_address.size(); i++)
				if (op1_address.at(i) == ']')
					break;
				else
					temp_string.push_back(op1_address.at(i));

			int d2 = stoi(temp_string);


			//------------------------------------------------
			//------------------------------------------------
			Add_S = d1 * mem1_row_size + d2;

			iss >> i >> j >> p >> q;
			i = i + 1; j = j + 1; // in micro instruction format, row and columns start from 0, but here they strat from 1.

			
			
			for (int row = i; row <= i + p - 1; row++)
			{
				nanofile << "FS" << "\t" << "WR" << endl; nano_line_counter++;

				if (allow_rowwise) {
					nanofile << "RSri" << "\t";

					for (int k = (int)ceil(log2((float)rs_bandwidth / log2((float)crossbar_row))) - 1; k >= 0; k--)
						nanofile << 0;

					nanofile << '\t';

					for (int k = (int)ceil(log2(crossbar_row)) - 1; k >= 0; k--)
						((row - 1) >> k) & 1 ? nanofile << 1 : nanofile << 0;

					for (int k = 0; k < rs_bandwidth - (int)ceil(log2(crossbar_row)); k++)
						nanofile << 0;

					nanofile << endl; nano_line_counter++;
				}
				else // else blockwise
				{
					nanofile << "RDSc" << endl; nano_line_counter++;
					nanofile << "RDSb" << "\t";

					int RD_chunk = (row-1) / rs_bandwidth;
					int RD_index = (row-1) % rs_bandwidth;

					for (int k = (int)ceil(log2((float)crossbar_row / (float)rs_bandwidth)) - 1; k >= 0; k--)
						(RD_chunk >> k) & 1 ? nanofile << 1 : nanofile << 0;

					nanofile << "\t";

					for (int rd_cnt = 0; rd_cnt < rs_bandwidth; rd_cnt++)
					{
						if (rd_cnt == RD_index)
						{
							nanofile << 1;
						}
						else
							nanofile << 0;
					}
					nanofile << endl; nano_line_counter++;
				}

				for (int wd_cnt = 1; wd_cnt <= crossbar_column / wd_bandwidth; wd_cnt++)
				{
					if ((j <= wd_cnt * wd_bandwidth) && ((j + q - 1) > (wd_cnt - 1)* wd_bandwidth))
					{
						nanofile << "WDb" << "\t";

						for (int k = (int)ceil(log2((float)crossbar_column / (float)wd_bandwidth)) - 1; k >= 0; k--)
							(((crossbar_column / wd_bandwidth) - wd_cnt) >> k) & 1 ? nanofile << 1 : nanofile << 0;

						nanofile << endl; nano_line_counter++;

						for (int wd_index = 1; wd_index <= wd_bandwidth; wd_index++)
						{
							int column = wd_index + wd_bandwidth * (wd_cnt - 1);
							if (column >= j && column < j + q)
								WDfile << *(intMem1 + Add_S + (column - j) + (row - i) * mem1_column_size);
							else
								WDfile << 0;
						}
						WDfile << endl;
						WD_element_count++;
					}
				}

				// WDS start ------------------------------------------------------------------------------

				WDS_temp.clear();

				bool WDS_chunk_0_flags[no_of_wds_chunks] = { };
				bool WDS_chunk_1_flags[no_of_wds_chunks] = { };
				bool WDS_chunk_copy_flags[no_of_wds_chunks] = { };
				int WDS_set_or_clear_counter = 0;
				bool WDS_set_or_clear = false; // true = set, false = clear
				int WDS_chunks_to_write_counter = 0;

				for (int t = 0; t < no_of_wds_chunks; t++)
				{
					for (int k = 1; k <= wds_bandwidth; k++)
					{
						if (t * wds_bandwidth + k >= j && t * wds_bandwidth + k < j + q)
						{
							WDS_chunk_1_flags[t] = 1;

						}
						else
						{
							WDS_chunk_0_flags[t] = 1;
						}
					}

					if (WDS_chunk_1_flags[t] && WDS_chunk_0_flags[t])
						WDS_chunks_to_write_counter++;
					else if (WDS_chunk_1_flags[t] && !WDS_chunk_0_flags[t])
						WDS_set_or_clear_counter++;
					else if (WDS_chunk_0_flags[t] && !WDS_chunk_1_flags[t])
						WDS_set_or_clear_counter--;
				}

				// >0 means more blocks have all 1's so set. simillarly <0 means clear. ==0 means all blocks should be written so no set or clear
				if (WDS_chunks_to_write_counter < no_of_wds_chunks && WDS_set_or_clear_counter > 0)
				{
					nanofile << "WDSs" << endl; nano_line_counter++;
					WDS_set_or_clear = true;
				}
				else if (WDS_chunks_to_write_counter < no_of_wds_chunks && WDS_set_or_clear_counter <= 0)
				{
					nanofile << "WDSc" << endl; nano_line_counter++;
					WDS_set_or_clear = false;
				}

				for (int WDS_chunk = 0; WDS_chunk < crossbar_column / wd_bandwidth; WDS_chunk++)
				{
					WDS_temp.clear();
					if (WDS_chunks_to_write_counter == no_of_wds_chunks ||
						(WDS_set_or_clear && WDS_chunk_0_flags[WDS_chunk]) ||
						(!WDS_set_or_clear && WDS_chunk_1_flags[WDS_chunk])) // this chunk should be written
					{
						for (int t = 1; t <= wds_bandwidth; t++)
						{
							if (t + WDS_chunk * wds_bandwidth >= j && t + WDS_chunk * wds_bandwidth < j + q)
							{
								WDS_temp += '1';
							}
							else
							{
								WDS_temp += '0';
							}
						}

						nanofile << "WDSb" << "\t";

						for (int k = (int)ceil(log2((float)crossbar_column / (float)wds_bandwidth)) - 1; k >= 0; k--)
							((crossbar_column / wd_bandwidth) - (WDS_chunk + 1) >> k) & 1 ? nanofile << 1 : nanofile << 0;

						nanofile << "\t";

						nanofile << WDS_temp << endl; nano_line_counter++;

					}
				}

				// WDS end --------------------------------------------------------------------------------

				nanofile << "DoA" << endl; nano_line_counter++;
				//nanofile << "END" << endl; nano_line_counter++;

				if (write_verify == 'y')
				{
					nanofile << "FS" << '\t' << "VRF" << endl; nano_line_counter++;

					// no RS is needed as it has not yet been changed by next ops due to always stalling
					nanofile << "DoA" << endl; nano_line_counter++;
					nanofile << "DoS" << endl; nano_line_counter++;

					// This next section is used to write the read-out stage to the readStageFile. Afterwards it is compared with the jump file.
					// if it matches we use jump, if it doesnt match we overwrite the jumpfile and append a jr
					bool total_activation = 0;
					int activation = 0;
					string CS_activation_bits = "";
					readstageoutfile.open("readStageFile.txt");
					for (int CS = 0; CS < crossbar_column / num_of_ADC; CS++)
					{

						//-------------------- before issuing next CS, it has to be checked if we are done with columns or not ----------  
						total_activation = 0;
						CS_activation_bits.clear();
						for (int ADC_cnt = 0; ADC_cnt < num_of_ADC; ADC_cnt++)
						{
							if ((crossbar_column / num_of_ADC - CS) + ADC_cnt * crossbar_column / num_of_ADC >= j && (crossbar_column / num_of_ADC - CS) + ADC_cnt * crossbar_column / num_of_ADC < j + q)
							{
								CS_activation_bits += '1';
								total_activation = 1;
							}
							else
							{
								CS_activation_bits += '0';
							}
						}

						//-----------------------------------------------------------------------------------------------

						if (total_activation)
						{
							//nanofile << "CS" << '\t';
							if (combine_CS_DoR)
								readstageoutfile << "CSR" << '\t';
							else
								readstageoutfile << "CS" << '\t';

							for (int k = (int)ceil(log2((float)crossbar_column / (float)num_of_ADC)) - 1; k >= 0; k--)
							{
								//(CS >> k) & 1 ? nanofile << 1 : nanofile << 0;
								(CS >> k) & 1 ? readstageoutfile << 1 : readstageoutfile << 0;
							}

							//nanofile << '\t';
							readstageoutfile << '\t';

							//nanofile << CS_activation_bits << endl << "DoR" << endl;
							if (combine_CS_DoR)
								readstageoutfile << CS_activation_bits << endl;
							else
								readstageoutfile << CS_activation_bits << endl << "DoR" << endl;
							

						}
					}

					readstageoutfile.close();
					readstageinfile.open("readStageFile.txt");
					jumpinfile.open("jumpFile.txt");
					readstage_jump = 1;
					int test_counter = 0;

					while (true) // check if readfile and jumpfile are identical
					{
						getline(readstageinfile, readstageline);
						getline(jumpinfile, jumpfileline);

						if (readstageinfile.eof() || jumpinfile.eof())
							break;

						test_counter++;

						if (readstageline != jumpfileline)
						{
							readstage_jump = 0;
							break;
						}
					}

					if (!readstageinfile.eof() || !jumpinfile.eof()) // dont jump if one file is longer than the other
						readstage_jump = 0;

					jumpinfile.close();

					if (!readstage_jump)
					{
						//readstageinfile.open("readStageFile.txt");
						readstageinfile.clear();
						readstageinfile.seekg(0, ios::beg);
						remove("jumpFile.txt");
						jumpoutfile.open("jumpFile.txt");

						jal_jump_to = nano_line_counter + 1; // point to line containing first CS (+1 because it is the next line to write here)

						while (getline(readstageinfile, readstageline))
						{
							nanofile << readstageline << endl; nano_line_counter++;
							jumpoutfile << readstageline << endl;
						}
						nanofile << "jr" << '\t' << jal_jump_to << '\t' << nano_line_counter + 1 - jal_jump_to << endl; nano_line_counter++; // jr instruction to return to value stored in register by jal
						jumpoutfile.close();
					}
					else
					{
						nanofile << "jal" << '\t' << jal_jump_to << endl; nano_line_counter++;
					}

					readstageinfile.close();
					remove("readStageFile.txt");

					// On this instruction the sim should perform comparison and reset counters to rewrite if necessary
					nanofile << "BNE" << endl; nano_line_counter++;

					//nanofile << "END" << endl; nano_line_counter++;
				}

			}

			break;
		}

		//********************************************************
		//********************************************************

		//"read" -- "Add_D" -- "Add_S" --row starting point "i" --column starting point "j" --number of rows to read "p" --number of columns to read "q"
		case read:
		{
			iss >> Add_D_string >> Add_S_string >> i >> j >> p >> q; // Note: I don't use ADD_S and Add_D, since we do not know how crossbar is going to communicate with outside  
			i = i + 1; j = j + 1; // in micro instruction format, row and columns start from 0, but here they start from 1.


			for (int row = i; row <= i + p - 1; row++)
			{
				output_read_counter++;
				nanofile << "FS" << "\t" << "RD" << endl; nano_line_counter++;

				if (allow_rowwise) {
					nanofile << "RSri" << "\t";

					for (int k = (int)ceil(log2((float)rs_bandwidth / log2((float)crossbar_row))) - 1; k >= 0; k--)
						nanofile << 0;

					nanofile << '\t';

					for (int k = (int)ceil(log2(crossbar_row)) - 1; k >= 0; k--)
						((row - 1) >> k) & 1 ? nanofile << 1 : nanofile << 0;

					for (int k = 0; k < rs_bandwidth - (int)ceil(log2(crossbar_row)); k++)
						nanofile << 0;

					nanofile << endl; nano_line_counter++;
				}
				else // else blockwise
				{
					nanofile << "RDSc" << endl; nano_line_counter++;
					nanofile << "RDSb" << "\t";

					int RD_chunk = (row - 1) / rs_bandwidth;
					int RD_index = (row - 1) % rs_bandwidth;

					for (int k = (int)ceil(log2((float)crossbar_row / (float)rs_bandwidth)) - 1; k >= 0; k--)
						(RD_chunk >> k) & 1 ? nanofile << 1 : nanofile << 0;

					nanofile << "\t";

					for (int rd_cnt = 0; rd_cnt < rs_bandwidth; rd_cnt++)
					{
						if (rd_cnt == RD_index)
						{
							nanofile << 1;
						}
						else
							nanofile << 0;
					}
					nanofile << endl; nano_line_counter++;
				}

				if (WDS_for_all_operations == 'y')
				{
					// WDS start ------------------------------------------------------------------------------

					WDS_temp.clear();

					bool WDS_chunk_0_flags[no_of_wds_chunks] = { };
					bool WDS_chunk_1_flags[no_of_wds_chunks] = { };
					bool WDS_chunk_copy_flags[no_of_wds_chunks] = { };
					int WDS_set_or_clear_counter = 0;
					bool WDS_set_or_clear = false; // true = set, false = clear
					int WDS_chunks_to_write_counter = 0;

					for (int t = 0; t < no_of_wds_chunks; t++)
					{
						for (int k = 1; k <= wds_bandwidth; k++)
						{
							if (t * wds_bandwidth + k >= j && t * wds_bandwidth + k < j + q)
							{
								WDS_chunk_1_flags[t] = 1;

							}
							else
							{
								WDS_chunk_0_flags[t] = 1;
							}
						}

						if (WDS_chunk_1_flags[t] && WDS_chunk_0_flags[t])
							WDS_chunks_to_write_counter++;
						else if (WDS_chunk_1_flags[t] && !WDS_chunk_0_flags[t])
							WDS_set_or_clear_counter++;
						else if (WDS_chunk_0_flags[t] && !WDS_chunk_1_flags[t])
							WDS_set_or_clear_counter--;
					}

					// >0 means more blocks have all 1's so set. simillarly <0 means clear. ==0 means all blocks should be written so no set or clear
					if (WDS_chunks_to_write_counter < no_of_wds_chunks && WDS_set_or_clear_counter > 0)
					{
						nanofile << "WDSs" << endl; nano_line_counter++;
						WDS_set_or_clear = true;
					}
					else if (WDS_chunks_to_write_counter < no_of_wds_chunks && WDS_set_or_clear_counter <= 0)
					{
						nanofile << "WDSc" << endl; nano_line_counter++;
						WDS_set_or_clear = false;
					}

					for (int WDS_chunk = 0; WDS_chunk < crossbar_column / wd_bandwidth; WDS_chunk++)
					{
						WDS_temp.clear();
						if (WDS_chunks_to_write_counter == no_of_wds_chunks ||
							(WDS_set_or_clear && WDS_chunk_0_flags[WDS_chunk]) ||
							(!WDS_set_or_clear && WDS_chunk_1_flags[WDS_chunk])) // this chunk should be written
						{
							for (int t = 1; t <= wds_bandwidth; t++)
							{
								if (t + WDS_chunk * wds_bandwidth >= j && t + WDS_chunk * wds_bandwidth < j + q)
								{
									WDS_temp += '1';
								}
								else
								{
									WDS_temp += '0';
								}
							}

							nanofile << "WDSb" << "\t";

							for (int k = (int)ceil(log2((float)crossbar_column / (float)wds_bandwidth)) - 1; k >= 0; k--)
								((crossbar_column / wd_bandwidth) - (WDS_chunk + 1) >> k) & 1 ? nanofile << 1 : nanofile << 0;

							nanofile << "\t";

							nanofile << WDS_temp << endl; nano_line_counter++;

						}
					}

					// WDS end --------------------------------------------------------------------------------
				}

				/*
				if (FS_ref != "RD")
				{
					nanofile << "FS" << "\t" << "RD" << endl; nano_line_counter++;
					FS_ref = "RD";
				}*/

				nanofile << "DoA" << endl; nano_line_counter++;
				nanofile << "DoS" << endl; nano_line_counter++;

				// This next section is used to write the read-out stage to the readStageFile. Afterwards it is compared with the jump file.
				// if it matches we use jump, if it doesnt match we overwrite the jumpfile and append a jr
				bool total_activation = 0;
				int activation = 0;
				string CS_activation_bits = "";
				readstageoutfile.open("readStageFile.txt");
				for (int CS = 0; CS < crossbar_column / num_of_ADC; CS++)
				{

					//-------------------- before issuing next CS, it has to be checked if we are done with columns or not ----------  
					total_activation = 0;
					CS_activation_bits.clear();
					for (int ADC_cnt = 0; ADC_cnt < num_of_ADC; ADC_cnt++)
					{
						if ((crossbar_column / num_of_ADC - CS) + ADC_cnt * crossbar_column / num_of_ADC >= j && (crossbar_column / num_of_ADC - CS) + ADC_cnt * crossbar_column / num_of_ADC < j + q)
						{
							CS_activation_bits += '1';
							total_activation = 1;
						}
						else
						{
							CS_activation_bits += '0';
						}
					}

					//-----------------------------------------------------------------------------------------------

					if (total_activation)
					{
						//nanofile << "CS" << '\t';
						if (combine_CS_DoR)
							readstageoutfile << "CSR" << '\t';
						else
							readstageoutfile << "CS" << '\t';

						for (int k = (int)ceil(log2((float)crossbar_column / (float)num_of_ADC)) - 1; k >= 0; k--)
						{
							//(CS >> k) & 1 ? nanofile << 1 : nanofile << 0;
							(CS >> k) & 1 ? readstageoutfile << 1 : readstageoutfile << 0;
						}

						//nanofile << '\t';
						readstageoutfile << '\t';

						//nanofile << CS_activation_bits << endl << "DoR" << endl;
						if (combine_CS_DoR)
							readstageoutfile << CS_activation_bits << endl;
						else
							readstageoutfile << CS_activation_bits << endl << "DoR" << endl;

					}
				}

				readstageoutfile.close();
				readstageinfile.open("readStageFile.txt");
				jumpinfile.open("jumpFile.txt");
				readstage_jump = 1;
				int test_counter = 0;

				while (true) // check if readfile and jumpfile are identical
				{
					getline(readstageinfile, readstageline);
					getline(jumpinfile, jumpfileline);

					if (readstageinfile.eof() || jumpinfile.eof())
						break;

					test_counter++;

					if (readstageline != jumpfileline)
					{
						readstage_jump = 0;
						break;
					}
				}

				if (!readstageinfile.eof() || !jumpinfile.eof()) // dont jump if one file is longer than the other
					readstage_jump = 0;

				jumpinfile.close();

				if (!readstage_jump)
				{
					//readstageinfile.open("readStageFile.txt");
					readstageinfile.clear();
					readstageinfile.seekg(0, ios::beg);
					remove("jumpFile.txt");
					jumpoutfile.open("jumpFile.txt");

					jal_jump_to = nano_line_counter + 1; // point to line containing first CS (+1 because it is the next line to write here)

					while (getline(readstageinfile, readstageline))
					{
						nanofile << readstageline << endl; nano_line_counter++;
						jumpoutfile << readstageline << endl;
					}
					nanofile << "jr" << '\t' << jal_jump_to << '\t' << nano_line_counter + 1 - jal_jump_to << endl; nano_line_counter++; // jr instruction to return to value stored in register by jal
					jumpoutfile.close();
				}
				else
				{
					nanofile << "jal" << '\t' << jal_jump_to << endl; nano_line_counter++;
				}

				readstageinfile.close();
				remove("readStageFile.txt");

				//nanofile << "END" << endl; nano_line_counter++;
			}
			break;
		}

		//********************************************************
		//********************************************************

		//MMM Add_M i j e q p
		case MMM:
		{
			//------------------------------------------------
			//------------------------------------------------
			int i;
			string temp_string;
			iss >> op1_address;
			for (i = 3; i < op1_address.size(); i++)
				if (op1_address.at(i) == ']')
					break;
				else
					temp_string.push_back(op1_address.at(i));
			int d1 = stoi(temp_string);
			temp_string.clear();

			for (i = i + 2; i < op1_address.size(); i++)
				if (op1_address.at(i) == ']')
					break;
				else
					temp_string.push_back(op1_address.at(i));

			int d2 = stoi(temp_string);

			bool RDS_flag = 1; // this flag is used to only set the RS mask once as it doesnt change during a single MMM

			//------------------------------------------------
			//------------------------------------------------

			Add_M = d1 * mem2_row_size + d2 * datatype_size;
			iss >> i >> j >> e >> q >> p; // we do not use Add_D at least in this version
			i = i + 1; j = j + 1; // in micro instruction format, row and columns start from 0, but here they start from 1.

			matrix_rows = p; // This is used for the outside unit, only supports 1 MMM in the micro instructions! Should be extended for executing more MMMs

			// retrieve the correct data elements from mem and put it in RDfile together with index to let outside controller fill the buffer
			for (int in_row = 1; in_row <= e; in_row++)
			{
				for (int r = i; r < i + p; r++) {

					// index for the outside unit to know ehere to put it in the RD buffer
					for (int k = (int)ceil(log2((float)crossbar_row)) - 1; k >= 0; k--)
						((r-1) >> k) & 1 ? RDfile << 1 : RDfile << 0;
					RDfile << '\t';

					for (int RD_copies = 0; RD_copies < max_datatype_size / datatype_size; RD_copies++)
					{
						for (int datatype_stride = 0; datatype_stride < datatype_size; datatype_stride++)
						{
							RDfile << *(intMem2 + Add_M + (in_row - 1) * (mem2_column_size)+((r - i) * datatype_size + datatype_stride));
						}
					}
					RDfile << endl;
					RD_element_count++;
				}
			}
			

			int time_mux_count;
			for (int in_row = 1; in_row <= e; in_row++) // in_row is used for counting the number of rows for the first matrix operand. The value of each column is stored in RS.
			{
				cout << "A number of row matrix= " << in_row << endl;

				bool VMM_done = 0;
				
				for (time_mux_count = 0; time_mux_count < time_mux; time_mux_count++) // this loop considers time multiplexing
				{
					if (VMM_done)
						break;

					for (int column_stride = datatype_size - 1; column_stride > -1; column_stride--)
					{
						RDsh_flag = 1;

						for (int Max_row_cnt = i; Max_row_cnt < i + p; Max_row_cnt = Max_row_cnt + Max_row_select)		// this for loop is for considering the maximum number of rows that can be selected for VMM. This restriction comes from ADC precision.
						{

							nanofile << "FS" << "\t" << "VMM" << endl; nano_line_counter++;

							if (RDsh_flag)
							{
								nanofile << "RDsh" << endl; nano_line_counter++;
								RDsh_flag = 0;
							}

							if (RDS_flag || (p > Max_row_select))
							{
								RDS_flag = 0;

								bool chunk_0_flags[no_of_rs_chunks] = { };
								bool chunk_1_flags[no_of_rs_chunks] = { };
								bool chunk_copy_flags[no_of_rs_chunks] = { };
								bool chunk_set = 0, rs_set_or_clear = 0;
								int rs_ones = 0;

								// Check the contents of each chunk, count ones and set some flags
								for (int rs_cnt = 1; rs_cnt <= no_of_rs_chunks; rs_cnt++)
								{
									for (int rs_index = 1; rs_index <= rs_bandwidth; rs_index++)
									{
										int r = rs_index + rs_bandwidth * (rs_cnt - 1);
										if (r >= Max_row_cnt && r < Max_row_cnt + Max_row_select && r < i + p)
										{
											rs_ones++;

											chunk_1_flags[rs_cnt - 1] = 1;				
											
										}
										else
										{
											chunk_0_flags[rs_cnt - 1] = 1;
										}
									}
								}

								// set chunk set to the most prominent value out of 0 or 1
								if (rs_ones < crossbar_row / 2)
									chunk_set = 0;
								else
									chunk_set = 1;

								// Find out which chunks should be updated based on the flags set in previous part and chunk_set
								for (int rs_cnt = 0; rs_cnt < no_of_rs_chunks; rs_cnt++)
								{
									if (chunk_0_flags[rs_cnt] && chunk_1_flags[rs_cnt])
										chunk_copy_flags[rs_cnt] = 1;
									else if (chunk_0_flags[rs_cnt] && chunk_set == 1)
										chunk_copy_flags[rs_cnt] = 1;
									else if (chunk_1_flags[rs_cnt] && chunk_set == 0)
										chunk_copy_flags[rs_cnt] = 1;
									else
									{
										chunk_copy_flags[rs_cnt] = 0;
										rs_set_or_clear = 1;
									}
								}

								// if not all chunks should be updated, execute rs_clear or rs_set
								if (rs_set_or_clear && chunk_set == 0)
								{
									nanofile << "RDSc" << endl; nano_line_counter++;
								}
								else if (rs_set_or_clear && chunk_set == 1)
								{
									nanofile << "RDSs" << endl; nano_line_counter++;
								}

								for (int rs_cnt = 1; rs_cnt <= no_of_rs_chunks; rs_cnt++)
								{

									if (chunk_copy_flags[rs_cnt - 1])
									{
										nanofile << "RDSb" << "\t";

										for (int k = (int)ceil(log2((float)crossbar_row / (float)rs_bandwidth)) - 1; k >= 0; k--)
											((rs_cnt - 1) >> k) & 1 ? nanofile << 1 : nanofile << 0;

										nanofile << "\t";

										for (int rs_index = 1; rs_index <= rs_bandwidth; rs_index++)
										{
											int r = rs_index + rs_bandwidth * (rs_cnt - 1);
											if (r >= Max_row_cnt && r < Max_row_cnt + Max_row_select && r < i + p)
											{
												nanofile << 1;
												//nanofile << *(intMem2 + Add_M + (in_row - 1) * (mem2_column_size)+((r - i) * datatype_size + column_stride));
											}
											else
											{
												nanofile << 0;
											}
										}
										nanofile << endl; nano_line_counter++;
										//RDfile << endl; 
									}
								}
							}

							if (WDS_for_all_operations == 'y')
							{
								// WDS start ------------------------------------------------------------------------------

								WDS_temp.clear();

								bool WDS_chunk_0_flags[no_of_wds_chunks] = { };
								bool WDS_chunk_1_flags[no_of_wds_chunks] = { };
								bool WDS_chunk_copy_flags[no_of_wds_chunks] = { };
								int WDS_set_or_clear_counter = 0;
								bool WDS_set_or_clear = false; // true = set, false = clear
								int WDS_chunks_to_write_counter = 0;

								for (int t = 0; t < no_of_wds_chunks; t++)
								{
									for (int k = 1; k <= wds_bandwidth; k++)
									{
										if (t * wds_bandwidth + k >= j && t * wds_bandwidth + k < j + q)
										{
											WDS_chunk_1_flags[t] = 1;

										}
										else
										{
											WDS_chunk_0_flags[t] = 1;
										}
									}

									if (WDS_chunk_1_flags[t] && WDS_chunk_0_flags[t])
										WDS_chunks_to_write_counter++;
									else if (WDS_chunk_1_flags[t] && !WDS_chunk_0_flags[t])
										WDS_set_or_clear_counter++;
									else if (WDS_chunk_0_flags[t] && !WDS_chunk_1_flags[t])
										WDS_set_or_clear_counter--;
								}

								// >0 means more blocks have all 1's so set. simillarly <0 means clear. ==0 means all blocks should be written so no set or clear
								if (WDS_chunks_to_write_counter < no_of_wds_chunks && WDS_set_or_clear_counter > 0)
								{
									nanofile << "WDSs" << endl; nano_line_counter++;
									WDS_set_or_clear = true;
								}
								else if (WDS_chunks_to_write_counter < no_of_wds_chunks && WDS_set_or_clear_counter <= 0)
								{
									nanofile << "WDSc" << endl; nano_line_counter++;
									WDS_set_or_clear = false;
								}

								for (int WDS_chunk = 0; WDS_chunk < crossbar_column / wd_bandwidth; WDS_chunk++)
								{
									WDS_temp.clear();
									if (WDS_chunks_to_write_counter == no_of_wds_chunks ||
										(WDS_set_or_clear && WDS_chunk_0_flags[WDS_chunk]) ||
										(!WDS_set_or_clear && WDS_chunk_1_flags[WDS_chunk])) // this chunk should be written
									{
										for (int t = 1; t <= wds_bandwidth; t++)
										{
											if (t + WDS_chunk * wds_bandwidth >= j && t + WDS_chunk * wds_bandwidth < j + q)
											{
												WDS_temp += '1';
											}
											else
											{
												WDS_temp += '0';
											}
										}

										nanofile << "WDSb" << "\t";

										for (int k = (int)ceil(log2((float)crossbar_column / (float)wds_bandwidth)) - 1; k >= 0; k--)
											((crossbar_column / wd_bandwidth) - (WDS_chunk + 1) >> k) & 1 ? nanofile << 1 : nanofile << 0;

										nanofile << "\t";

										nanofile << WDS_temp << endl; nano_line_counter++;

									}
								}

								// WDS end --------------------------------------------------------------------------------
							}

							/*
							if (FS_ref != "VMM")
							{
								nanofile << "FS" << "\t" << "VMM" << endl; nano_line_counter++;
								FS_ref = "VMM";
							}*/

							nanofile << "DoA" << endl; nano_line_counter++;
							nanofile << "DoS" << endl; nano_line_counter++;
							if (Max_row_cnt + Max_row_select > i + p - 1)
							{
								nanofile << "LS" << endl; nano_line_counter++; // Last Section of RS nano_line_counter++;
							}


							// This next section is used to write the read-out stage to the readStageFile. Afterwards it is compared with the jump file.
							// if it matches we use jump, if it doesnt match we overwrite the jumpfile and append a jr
							bool total_activation = 0;
							int activation = 0;
							bool first_activation = 0, first_activation_temp = 0;
							string CS_activation_bits = "";
							//string time_mux_altered = "";
							readstageoutfile.open("readStageFile.txt");
							for (int CS = 0; CS < crossbar_column / num_of_ADC; CS++)
							{

								//-------------------- before issuing next CS, it has to be checked if we are done with columns or not ----------  
								total_activation = 0;

								if (CS % datatype_size == 0)
									first_activation = first_activation_temp;

								CS_activation_bits.clear();
								//time_mux_altered.clear();
								for (int ADC_cnt = 0; ADC_cnt < num_of_ADC; ADC_cnt++)
								{
									if ((crossbar_column / num_of_ADC - CS) + ADC_cnt * crossbar_column / num_of_ADC >= j && (crossbar_column / num_of_ADC - CS) + ADC_cnt * crossbar_column / num_of_ADC < j + q)
									{
										CS_activation_bits += '1';
										total_activation = 1;
										first_activation_temp = 1;
									}
									else
									{
										CS_activation_bits += '0';
									}
								}

								if (total_activation == 0)
									VMM_done = 1;

								// ... and if we have to stop because of time multiplexing

								if (CS / datatype_size != time_mux_count && first_activation == 1 || CS / datatype_size < time_mux_count)
									total_activation = 0;


								//-----------------------------------------------------------------------------------------------

								if (total_activation)
								{
									//nanofile << "CS" << '\t';
									if (combine_CS_DoR)
										readstageoutfile << "CSR" << '\t';
									else
										readstageoutfile << "CS" << '\t';

									for (int k = (int)ceil(log2((float)crossbar_column / (float)num_of_ADC)) - 1; k >= 0; k--)
									{
										//(CS >> k) & 1 ? nanofile << 1 : nanofile << 0;
										(CS >> k) & 1 ? readstageoutfile << 1 : readstageoutfile << 0;
									}

									readstageoutfile << '\t';

									/*for (int activation_length_cnt = 0; activation_length_cnt < CS_activation_bits.length(); activation_length_cnt++)
									{
										if (activation_length_cnt / datatype_size == time_mux_count)
										{
											time_mux_altered += CS_activation_bits[activation_length_cnt];
										}
										else
										{
											time_mux_altered += '0';
										}

									}*/

									if (combine_CS_DoR)
										readstageoutfile << CS_activation_bits << endl;
									else
										readstageoutfile << CS_activation_bits << endl << "DoR" << endl;

								}
							}

							readstageoutfile.close();
							readstageinfile.open("readStageFile.txt");
							jumpinfile.open("jumpFile.txt");
							readstage_jump = 1;
							int test_counter = 0;

							while (true) // check if readfile and jumpfile are identical
							{
								getline(readstageinfile, readstageline);
								getline(jumpinfile, jumpfileline);

								if (readstageinfile.eof() || jumpinfile.eof())
									break;

								test_counter++;

								if (readstageline != jumpfileline)
								{
									readstage_jump = 0;
									break;
								}
							}

							if (!readstageinfile.eof() || !jumpinfile.eof()) // dont jump if one file is longer than the other
								readstage_jump = 0;

							jumpinfile.close();

							if (!readstage_jump)
							{
								//readstageinfile.open("readStageFile.txt");
								readstageinfile.clear();
								readstageinfile.seekg(0, ios::beg);
								remove("jumpFile.txt");
								jumpoutfile.open("jumpFile.txt");

								jal_jump_to = nano_line_counter + 1; // point to line containing first CS (+1 because it is the next line to write here)

								while (getline(readstageinfile, readstageline))
								{
									nanofile << readstageline << endl; nano_line_counter++;
									jumpoutfile << readstageline << endl;
								}
								nanofile << "jr" << '\t' << jal_jump_to << '\t' << nano_line_counter + 1 - jal_jump_to << endl; nano_line_counter++; // jr instruction to return to value stored in register by jal
								jumpoutfile.close();
							}
							else
							{
								nanofile << "jal" << '\t' << jal_jump_to << endl; nano_line_counter++;
							}

							readstageinfile.close();
							remove("readStageFile.txt");

							//---------------------------------------------------------
							if (Max_row_cnt + Max_row_select > i + p - 1)
							{
								nanofile << "IADD" << endl; nano_line_counter++; // activate Intermediate ADDer
								if (column_stride == 0)
								{
									nanofile << "CP" << endl; nano_line_counter++; output_read_counter++; // Last RS was executed
									if (crossbar_column / num_of_ADC < datatype_size)
									{
										for (int datatype_group_counter = datatype_size / (crossbar_column / num_of_ADC); datatype_group_counter >= 1; datatype_group_counter--)
										{
											//-- before issuing next AS we have to check if we are done or not
											int check_AS = 0;
											for (int numbers_on_crossbar = 1; numbers_on_crossbar <= crossbar_column / datatype_size; numbers_on_crossbar++)
											{
												for (int temp_counter = 1; temp_counter <= datatype_size / (crossbar_column / num_of_ADC); temp_counter++)
												{
													if (temp_counter == datatype_group_counter)
														if ((((numbers_on_crossbar - 1) * datatype_size + (datatype_group_counter - 1) * (crossbar_column / num_of_ADC) > j) && ((numbers_on_crossbar - 1) * datatype_size + (datatype_group_counter - 1) * (crossbar_column / num_of_ADC) < j + q)) || (((numbers_on_crossbar - 1) * datatype_size + (datatype_group_counter) * (crossbar_column / num_of_ADC) > j) && ((numbers_on_crossbar - 1) * datatype_size + (datatype_group_counter - 1) * (crossbar_column / num_of_ADC) < j + q)))
														{
															check_AS = 1;
															break;
														}
												}
											}
											//----------------------------------------------------------------

											if (check_AS == 1)
											{
												nanofile << "AS" << "\t"; // Adder Select
												for (int numbers_on_crossbar = 1; numbers_on_crossbar <= crossbar_column / datatype_size; numbers_on_crossbar++)
												{
													for (int temp_counter = 1; temp_counter <= datatype_size / (crossbar_column / num_of_ADC); temp_counter++)
													{
														if (temp_counter == datatype_group_counter)
															if ((((numbers_on_crossbar - 1) * datatype_size + (datatype_group_counter - 1) * (crossbar_column / num_of_ADC) + 1 > j) && ((numbers_on_crossbar - 1) * datatype_size + (datatype_group_counter - 1) * (crossbar_column / num_of_ADC) + 1 < j + q)) || (((numbers_on_crossbar - 1) * datatype_size + (datatype_group_counter) * (crossbar_column / num_of_ADC) > j) && ((numbers_on_crossbar - 1) * datatype_size + (datatype_group_counter) * (crossbar_column / num_of_ADC) < j + q)))
															{
																//cout << numbers_on_crossbar << "\t" << datatype_group_counter << endl;
																//cout << (numbers_on_crossbar - 1)* datatype_size + (datatype_group_counter - 1) * (crossbar_column / num_of_ADC) + 1 << endl;
																//cout << (numbers_on_crossbar - 1)* datatype_size + (datatype_group_counter) * (crossbar_column / num_of_ADC) << endl;
																//cout << j + q << endl;
																nanofile << "1";
															}
															else
																nanofile << "0";
														else
															nanofile << "0";
													}
												}
												nanofile << endl; nano_line_counter++;

											}
										}
										nanofile << "CB" << endl; nano_line_counter++; output_read_counter++;
									}

								}

							}
							//nanofile << "END" << endl; nano_line_counter++;
						}

					}
				}	
			}
			bufferfile_tmp << time_mux_count * datatype_size << endl;
			break;
		}

		//********************************************************
		//********************************************************

		//"logical_and" -- "Add_D" -- "Add_S" -- "256 row bits" -- "p = start column" -- "q = no_of_columns"
		case logical_and:
		{
			iss >> Add_D_string >> Add_S_string >> logic_row_string >> p >> q; // we do not use Add_D and Add_S at least in this version
			p += 1;

			nanofile << "FS" << "\t" << "AND" << endl; nano_line_counter++;
			output_read_counter++;

			// -- RS section --------------------------------------------------------------------------------------------------
			int rows_to_write = 0, rsbi_to_write = 0, block_temp = -1, block_current = 0;
			bool chunk_0_flags[no_of_rs_chunks] = { };
			bool chunk_1_flags[no_of_rs_chunks] = { };

			for (int i = 0; i < crossbar_row; i++) // determine how many rows/blocks should be written
			{
				block_current = i / rs_bandwidth;

				if (logic_row_string[i] == '1')
				{
					rows_to_write++;
					chunk_1_flags[block_current] = 1;
					if (block_temp != block_current)
					{
						rsbi_to_write++;
						block_temp = block_current;
					}
				}
				else
					chunk_0_flags[block_current] = 1;
			}

			int rsri_to_write = (int)ceil(((float)rows_to_write / ceil((float)rs_bandwidth / log2((float)crossbar_row)))); // number of rsri instructions

			// Now if it can be done using a single rsri we do that, otherwise use block-wise
			if (allow_rowwise && rsri_to_write == 1) // row-wise
			{
				int remaining_rows = rows_to_write, rows_this_instruction, string_index = 0;
				
				for (int i = 0; i < rsri_to_write; i++)
				{
					nanofile << "RSri" << "\t";

					if (remaining_rows >= (int)ceil((float)rs_bandwidth / log2((float)crossbar_row)))
					{
						remaining_rows -= (int)ceil((float)rs_bandwidth / log2((float)crossbar_row));
						rows_this_instruction = (int)ceil((float)rs_bandwidth / log2((float)crossbar_row));
					}
					else
					{
						rows_this_instruction = remaining_rows;
					}

					for (int k = (int)ceil(log2((float)rs_bandwidth / log2((float)crossbar_row))) - 1; k >= 0; k--)
						((rows_this_instruction - 1) >> k) & 1 ? nanofile << 1 : nanofile << 0;
					nanofile << '\t';

					for (int j = 0; j < rows_this_instruction; j++)
					{
						while (true)
						{
							if (logic_row_string[string_index] == '1')
								break;

							string_index++;
						}
						
						for (int k = (int)ceil(log2(crossbar_row)) - 1; k >= 0; k--)
							((string_index) >> k) & 1 ? nanofile << 1 : nanofile << 0;

						string_index++;
					}

					for (int k = 0; k < rs_bandwidth - rows_this_instruction * (int)ceil(log2(crossbar_row)); k++)
						nanofile << 0;

					nanofile << endl; nano_line_counter++;

				}
			}
			else // block-wise
			{
				int all_1_blocks = 0, all_0_blocks = 0, blocks_to_write = 0;
				bool chunk_set = 0;
				
				for (int i = 0; i < no_of_rs_chunks; i++)
				{
					if (chunk_0_flags[i] == 1 && chunk_1_flags[i] == 0)
						all_0_blocks++;
					else if (chunk_0_flags[i] == 0 && chunk_1_flags[i] == 1)
						all_1_blocks++;
				}

				if (all_1_blocks > all_0_blocks)
					chunk_set = 1;

				for (int i = 0; i < no_of_rs_chunks; i++)
				{
					if (chunk_set == 1 && chunk_0_flags[i] == 1)
					{
						blocks_to_write++;
					}
					else if (chunk_set == 0 && chunk_1_flags[i] == 1)
					{
						blocks_to_write++;
					}

				}

				if (blocks_to_write < no_of_rs_chunks && chunk_set)
				{
					nanofile << "RDSs" << endl; nano_line_counter++;
				}
				else if (blocks_to_write < no_of_rs_chunks)
				{
					nanofile << "RDSc" << endl; nano_line_counter++;
				}

				for (int i = 0; i < no_of_rs_chunks; i++)
				{
					if ((all_1_blocks > all_0_blocks && chunk_0_flags[i] == 1) || (all_1_blocks <= all_0_blocks&& chunk_1_flags[i] == 1))
					{
						nanofile << "RDSb" << '\t';

						for (int k = (int)ceil(log2((float)crossbar_row / (float)rs_bandwidth)) - 1; k >= 0; k--)
							((i) >> k) & 1 ? nanofile << 1 : nanofile << 0;

						nanofile << "\t";

						for (int j = 0; j < rs_bandwidth; j++)
						{
							nanofile << logic_row_string[j + rs_bandwidth * i];
						}

						nanofile << endl; nano_line_counter++;
					}
				}
			}
				
			// ----------------------------------------------------------------------------------------------------------------
			if (WDS_for_all_operations == 'y')
			{
				// WDS start ------------------------------------------------------------------------------

				WDS_temp.clear();

				bool WDS_chunk_0_flags[no_of_wds_chunks] = { };
				bool WDS_chunk_1_flags[no_of_wds_chunks] = { };
				bool WDS_chunk_copy_flags[no_of_wds_chunks] = { };
				int WDS_set_or_clear_counter = 0;
				bool WDS_set_or_clear = false; // true = set, false = clear
				int WDS_chunks_to_write_counter = 0;

				for (int t = 0; t < no_of_wds_chunks; t++)
				{
					for (int k = 1; k <= wds_bandwidth; k++)
					{
						if (t * wds_bandwidth + k >= j && t * wds_bandwidth + k < j + q)
						{
							WDS_chunk_1_flags[t] = 1;

						}
						else
						{
							WDS_chunk_0_flags[t] = 1;
						}
					}

					if (WDS_chunk_1_flags[t] && WDS_chunk_0_flags[t])
						WDS_chunks_to_write_counter++;
					else if (WDS_chunk_1_flags[t] && !WDS_chunk_0_flags[t])
						WDS_set_or_clear_counter++;
					else if (WDS_chunk_0_flags[t] && !WDS_chunk_1_flags[t])
						WDS_set_or_clear_counter--;
				}

				// >0 means more blocks have all 1's so set. simillarly <0 means clear. ==0 means all blocks should be written so no set or clear
				if (WDS_chunks_to_write_counter < no_of_wds_chunks && WDS_set_or_clear_counter > 0)
				{
					nanofile << "WDSs" << endl; nano_line_counter++;
					WDS_set_or_clear = true;
				}
				else if (WDS_chunks_to_write_counter < no_of_wds_chunks && WDS_set_or_clear_counter <= 0)
				{
					nanofile << "WDSc" << endl; nano_line_counter++;
					WDS_set_or_clear = false;
				}

				for (int WDS_chunk = 0; WDS_chunk < crossbar_column / wd_bandwidth; WDS_chunk++)
				{
					WDS_temp.clear();
					if (WDS_chunks_to_write_counter == no_of_wds_chunks ||
						(WDS_set_or_clear && WDS_chunk_0_flags[WDS_chunk]) ||
						(!WDS_set_or_clear && WDS_chunk_1_flags[WDS_chunk])) // this chunk should be written
					{
						for (int t = 1; t <= wds_bandwidth; t++)
						{
							if (t + WDS_chunk * wds_bandwidth >= j && t + WDS_chunk * wds_bandwidth < j + q)
							{
								WDS_temp += '1';
							}
							else
							{
								WDS_temp += '0';
							}
						}

						nanofile << "WDSb" << "\t";

						for (int k = (int)ceil(log2((float)crossbar_column / (float)wds_bandwidth)) - 1; k >= 0; k--)
							((crossbar_column / wd_bandwidth) - (WDS_chunk + 1) >> k) & 1 ? nanofile << 1 : nanofile << 0;

						nanofile << "\t";

						nanofile << WDS_temp << endl; nano_line_counter++;

					}
				}

				// WDS end --------------------------------------------------------------------------------
			}

			/*if (FS_ref != "AND")
			{
				nanofile << "FS" << "\t" << "AND" << endl; nano_line_counter++;
				FS_ref = "AND";
			}*/

			nanofile << "DoA" << endl; nano_line_counter++;
			nanofile << "DoS" << endl; nano_line_counter++;

			// This next section is used to write the read-out stage to the readStageFile. Afterwards it is compared with the jump file.
			// if it matches we use jump, if it doesnt match we overwrite the jumpfile and append a jr
			bool total_activation = 0;
			int activation = 0;
			string CS_activation_bits = "";
			readstageoutfile.open("readStageFile.txt");
			for (int CS = 0; CS < crossbar_column / num_of_ADC; CS++)
			{

				//-------------------- before issuing next CS, it has to be checked if we are done with columns or not ----------  
				total_activation = 0;
				CS_activation_bits.clear();
				for (int ADC_cnt = 0; ADC_cnt < num_of_ADC; ADC_cnt++)
				{
					if ((crossbar_column / num_of_ADC - CS) + ADC_cnt * crossbar_column / num_of_ADC >= p && (crossbar_column / num_of_ADC - CS) + ADC_cnt * crossbar_column / num_of_ADC < p + q)
					{
						CS_activation_bits += '1';
						total_activation = 1;
					}
					else
					{
						CS_activation_bits += '0';
					}
				}

				//-----------------------------------------------------------------------------------------------

				if (total_activation)
				{
					//nanofile << "CS" << '\t';
					if (combine_CS_DoR)
						readstageoutfile << "CSR" << '\t';
					else
						readstageoutfile << "CS" << '\t';

					for (int k = (int)ceil(log2((float)crossbar_column / (float)num_of_ADC)) - 1; k >= 0; k--)
					{
						//(CS >> k) & 1 ? nanofile << 1 : nanofile << 0;
						(CS >> k) & 1 ? readstageoutfile << 1 : readstageoutfile << 0;
					}

					//nanofile << '\t';
					readstageoutfile << '\t';

					//nanofile << CS_activation_bits << endl << "DoR" << endl;
					if (combine_CS_DoR)
						readstageoutfile << CS_activation_bits << endl;
					else
						readstageoutfile << CS_activation_bits << endl << "DoR" << endl;

				}
			}

			readstageoutfile.close();
			readstageinfile.open("readStageFile.txt");
			jumpinfile.open("jumpFile.txt");
			readstage_jump = 1;
			int test_counter = 0;

			while (true) // check if readfile and jumpfile are identical
			{
				getline(readstageinfile, readstageline);
				getline(jumpinfile, jumpfileline);

				if (readstageinfile.eof() || jumpinfile.eof())
					break;

				test_counter++;

				if (readstageline != jumpfileline)
				{
					readstage_jump = 0;
					break;
				}
			}

			if (!readstageinfile.eof() || !jumpinfile.eof()) // dont jump if one file is longer than the other
				readstage_jump = 0;

			jumpinfile.close();

			if (!readstage_jump)
			{
				//readstageinfile.open("readStageFile.txt");
				readstageinfile.clear();
				readstageinfile.seekg(0, ios::beg);
				remove("jumpFile.txt");
				jumpoutfile.open("jumpFile.txt");

				jal_jump_to = nano_line_counter + 1; // point to line containing first CS (+1 because it is the next line to write here)

				while (getline(readstageinfile, readstageline))
				{
					nanofile << readstageline << endl; nano_line_counter++;
					jumpoutfile << readstageline << endl;
				}
				nanofile << "jr" << '\t' << jal_jump_to << '\t' << nano_line_counter + 1 - jal_jump_to << endl; nano_line_counter++; // jr instruction to return to value stored in register by jal
				jumpoutfile.close();
			}
			else
			{
				nanofile << "jal" << '\t' << jal_jump_to << endl; nano_line_counter++;
			}

			readstageinfile.close();
			remove("readStageFile.txt");

			//nanofile << "END" << endl; nano_line_counter++;

			break;
		}

		//********************************************************
		//********************************************************

		//"logical_or" -- "Add_D" -- "Add_S" -- "i" -- "j" -- "p" --  "q"
		case logical_or:
		{
			iss >> Add_D_string >> Add_S_string >> logic_row_string >> p >> q; // we do not use Add_D and Add_S at least in this version
			p += 1;

			nanofile << "FS" << "\t" << "OR" << endl; nano_line_counter++;
			output_read_counter++;

			// -- RS section --------------------------------------------------------------------------------------------------
			int rows_to_write = 0, rsbi_to_write = 0, block_temp = -1, block_current = 0;
			bool chunk_0_flags[no_of_rs_chunks] = { };
			bool chunk_1_flags[no_of_rs_chunks] = { };

			for (int i = 0; i < crossbar_row; i++) // determine how many rows/blocks should be written
			{
				block_current = i / rs_bandwidth;

				if (logic_row_string[i] == '1')
				{
					rows_to_write++;
					chunk_1_flags[block_current] = 1;
					if (block_temp != block_current)
					{
						rsbi_to_write++;
						block_temp = block_current;
					}
				}
				else
					chunk_0_flags[block_current] = 1;
			}

			int rsri_to_write = (int)ceil(((float)rows_to_write / ceil((float)rs_bandwidth / log2((float)crossbar_row)))); // number of rsri instructions

			// Now if it can be done using a single rsri we do that, otherwise use block-wise
			if (allow_rowwise && rsri_to_write == 1) // row-wise
			{
				int remaining_rows = rows_to_write, rows_this_instruction, string_index = 0;

				for (int i = 0; i < rsri_to_write; i++)
				{
					nanofile << "RSri" << "\t";

					if (remaining_rows >= (int)ceil((float)rs_bandwidth / log2((float)crossbar_row)))
					{
						remaining_rows -= (int)ceil((float)rs_bandwidth / log2((float)crossbar_row));
						rows_this_instruction = (int)ceil((float)rs_bandwidth / log2((float)crossbar_row));
					}
					else
					{
						rows_this_instruction = remaining_rows;
					}

					for (int k = (int)ceil(log2((float)rs_bandwidth / log2((float)crossbar_row))) - 1; k >= 0; k--)
						((rows_this_instruction - 1) >> k) & 1 ? nanofile << 1 : nanofile << 0;
					nanofile << '\t';

					for (int j = 0; j < rows_this_instruction; j++)
					{
						while (true)
						{
							if (logic_row_string[string_index] == '1')
								break;

							string_index++;
						}

						for (int k = (int)ceil(log2(crossbar_row)) - 1; k >= 0; k--)
							((string_index) >> k) & 1 ? nanofile << 1 : nanofile << 0;

						string_index++;
					}

					for (int k = 0; k < rs_bandwidth - rows_this_instruction * (int)ceil(log2(crossbar_row)); k++)
						nanofile << 0;

					nanofile << endl; nano_line_counter++;

				}
			}
			else // block-wise
			{
				int all_1_blocks = 0, all_0_blocks = 0, blocks_to_write = 0;
				bool chunk_set = 0;

				for (int i = 0; i < no_of_rs_chunks; i++)
				{
					if (chunk_0_flags[i] == 1 && chunk_1_flags[i] == 0)
						all_0_blocks++;
					else if (chunk_0_flags[i] == 0 && chunk_1_flags[i] == 1)
						all_1_blocks++;
				}

				if (all_1_blocks > all_0_blocks)
					chunk_set = 1;

				for (int i = 0; i < no_of_rs_chunks; i++)
				{
					if (chunk_set == 1 && chunk_0_flags[i] == 1)
					{
						blocks_to_write++;
					}
					else if (chunk_set == 0 && chunk_1_flags[i] == 1)
					{
						blocks_to_write++;
					}

				}

				if (blocks_to_write < no_of_rs_chunks && chunk_set)
				{
					nanofile << "RDSs" << endl; nano_line_counter++;
				}
				else if (blocks_to_write < no_of_rs_chunks)
				{
					nanofile << "RDSc" << endl; nano_line_counter++;
				}

				for (int i = 0; i < no_of_rs_chunks; i++)
				{
					if ((all_1_blocks > all_0_blocks&& chunk_0_flags[i] == 1) || (all_1_blocks <= all_0_blocks && chunk_1_flags[i] == 1))
					{
						nanofile << "RDSb" << '\t';

						for (int k = (int)ceil(log2((float)crossbar_row / (float)rs_bandwidth)) - 1; k >= 0; k--)
							((i) >> k) & 1 ? nanofile << 1 : nanofile << 0;

						nanofile << "\t";

						for (int j = 0; j < rs_bandwidth; j++)
						{
							nanofile << logic_row_string[j + rs_bandwidth * i];
						}

						nanofile << endl; nano_line_counter++;
					}
				}
			}

			// ----------------------------------------------------------------------------------------------------------------

			if (WDS_for_all_operations == 'y')
			{
				// WDS start ------------------------------------------------------------------------------

				WDS_temp.clear();

				bool WDS_chunk_0_flags[no_of_wds_chunks] = { };
				bool WDS_chunk_1_flags[no_of_wds_chunks] = { };
				bool WDS_chunk_copy_flags[no_of_wds_chunks] = { };
				int WDS_set_or_clear_counter = 0;
				bool WDS_set_or_clear = false; // true = set, false = clear
				int WDS_chunks_to_write_counter = 0;

				for (int t = 0; t < no_of_wds_chunks; t++)
				{
					for (int k = 1; k <= wds_bandwidth; k++)
					{
						if (t * wds_bandwidth + k >= j && t * wds_bandwidth + k < j + q)
						{
							WDS_chunk_1_flags[t] = 1;

						}
						else
						{
							WDS_chunk_0_flags[t] = 1;
						}
					}

					if (WDS_chunk_1_flags[t] && WDS_chunk_0_flags[t])
						WDS_chunks_to_write_counter++;
					else if (WDS_chunk_1_flags[t] && !WDS_chunk_0_flags[t])
						WDS_set_or_clear_counter++;
					else if (WDS_chunk_0_flags[t] && !WDS_chunk_1_flags[t])
						WDS_set_or_clear_counter--;
				}

				// >0 means more blocks have all 1's so set. simillarly <0 means clear. ==0 means all blocks should be written so no set or clear
				if (WDS_chunks_to_write_counter < no_of_wds_chunks && WDS_set_or_clear_counter > 0)
				{
					nanofile << "WDSs" << endl; nano_line_counter++;
					WDS_set_or_clear = true;
				}
				else if (WDS_chunks_to_write_counter < no_of_wds_chunks && WDS_set_or_clear_counter <= 0)
				{
					nanofile << "WDSc" << endl; nano_line_counter++;
					WDS_set_or_clear = false;
				}

				for (int WDS_chunk = 0; WDS_chunk < crossbar_column / wd_bandwidth; WDS_chunk++)
				{
					WDS_temp.clear();
					if (WDS_chunks_to_write_counter == no_of_wds_chunks ||
						(WDS_set_or_clear && WDS_chunk_0_flags[WDS_chunk]) ||
						(!WDS_set_or_clear && WDS_chunk_1_flags[WDS_chunk])) // this chunk should be written
					{
						for (int t = 1; t <= wds_bandwidth; t++)
						{
							if (t + WDS_chunk * wds_bandwidth >= j && t + WDS_chunk * wds_bandwidth < j + q)
							{
								WDS_temp += '1';
							}
							else
							{
								WDS_temp += '0';
							}
						}

						nanofile << "WDSb" << "\t";

						for (int k = (int)ceil(log2((float)crossbar_column / (float)wds_bandwidth)) - 1; k >= 0; k--)
							((crossbar_column / wd_bandwidth) - (WDS_chunk + 1) >> k) & 1 ? nanofile << 1 : nanofile << 0;

						nanofile << "\t";

						nanofile << WDS_temp << endl; nano_line_counter++;

					}
				}

				// WDS end --------------------------------------------------------------------------------
			}

			/*if (FS_ref != "OR")
			{
				nanofile << "FS" << "\t" << "OR" << endl; nano_line_counter++;
				FS_ref = "OR";
			}*/

			nanofile << "DoA" << endl; nano_line_counter++;
			nanofile << "DoS" << endl; nano_line_counter++;


			// This next section is used to write the read-out stage to the readStageFile. Afterwards it is compared with the jump file.
						// if it matches we use jump, if it doesnt match we overwrite the jumpfile and append a jr
			bool total_activation = 0;
			int activation = 0;
			string CS_activation_bits = "";
			readstageoutfile.open("readStageFile.txt");
			for (int CS = 0; CS < crossbar_column / num_of_ADC; CS++)
			{

				//-------------------- before issuing next CS, it has to be checked if we are done with columns or not ----------  
				total_activation = 0;
				CS_activation_bits.clear();
				for (int ADC_cnt = 0; ADC_cnt < num_of_ADC; ADC_cnt++)
				{
					if ((crossbar_column / num_of_ADC - CS) + ADC_cnt * crossbar_column / num_of_ADC >= p && (crossbar_column / num_of_ADC - CS) + ADC_cnt * crossbar_column / num_of_ADC < p + q)
					{
						CS_activation_bits += '1';
						total_activation = 1;
					}
					else
					{
						CS_activation_bits += '0';
					}
				}

				//-----------------------------------------------------------------------------------------------

				if (total_activation)
				{
					//nanofile << "CS" << '\t';
					if (combine_CS_DoR)
						readstageoutfile << "CSR" << '\t';
					else
						readstageoutfile << "CS" << '\t';

					for (int k = (int)ceil(log2((float)crossbar_column / (float)num_of_ADC)) - 1; k >= 0; k--)
					{
						//(CS >> k) & 1 ? nanofile << 1 : nanofile << 0;
						(CS >> k) & 1 ? readstageoutfile << 1 : readstageoutfile << 0;
					}

					//nanofile << '\t';
					readstageoutfile << '\t';

					//nanofile << CS_activation_bits << endl << "DoR" << endl;
					if (combine_CS_DoR)
						readstageoutfile << CS_activation_bits << endl;
					else
						readstageoutfile << CS_activation_bits << endl << "DoR" << endl;

				}
			}

			readstageoutfile.close();
			readstageinfile.open("readStageFile.txt");
			jumpinfile.open("jumpFile.txt");
			readstage_jump = 1;
			int test_counter = 0;

			while (true) // check if readfile and jumpfile are identical
			{
				getline(readstageinfile, readstageline);
				getline(jumpinfile, jumpfileline);

				if (readstageinfile.eof() || jumpinfile.eof())
					break;

				test_counter++;

				if (readstageline != jumpfileline)
				{
					readstage_jump = 0;
					break;
				}
			}

			if (!readstageinfile.eof() || !jumpinfile.eof()) // dont jump if one file is longer than the other
				readstage_jump = 0;

			jumpinfile.close();

			if (!readstage_jump)
			{
				//readstageinfile.open("readStageFile.txt");
				readstageinfile.clear();
				readstageinfile.seekg(0, ios::beg);
				remove("jumpFile.txt");
				jumpoutfile.open("jumpFile.txt");

				jal_jump_to = nano_line_counter + 1; // point to line containing first CS (+1 because it is the next line to write here)

				while (getline(readstageinfile, readstageline))
				{
					nanofile << readstageline << endl; nano_line_counter++;
					jumpoutfile << readstageline << endl;
				}
				nanofile << "jr" << '\t' << jal_jump_to << '\t' << nano_line_counter + 1 - jal_jump_to << endl; nano_line_counter++; // jr instruction to return to value stored in register by jal
				jumpoutfile.close();
			}
			else
			{
				nanofile << "jal" << '\t' << jal_jump_to << endl; nano_line_counter++;
			}

			readstageinfile.close();
			remove("readStageFile.txt");

			//nanofile << "END" << endl; nano_line_counter++;
			break;
		}

		//********************************************************
		//********************************************************

		//"logical_xor" -- "Add_D" -- "Add_S" -- "i" -- "j" -- "p" --  "q"
		case logical_xor:
		{
			iss >> Add_D_string >> Add_S_string >> logic_row_string >> p >> q; // we do not use Add_D and Add_S at least in this version
			p += 1;

			nanofile << "FS" << "\t" << "XOR" << endl; nano_line_counter++;
			output_read_counter++;

			// -- RS section --------------------------------------------------------------------------------------------------
			int rows_to_write = 0, rsbi_to_write = 0, block_temp = -1, block_current = 0;
			bool chunk_0_flags[no_of_rs_chunks] = { };
			bool chunk_1_flags[no_of_rs_chunks] = { };

			for (int i = 0; i < crossbar_row; i++) // determine how many rows/blocks should be written
			{
				block_current = i / rs_bandwidth;

				if (logic_row_string[i] == '1')
				{
					rows_to_write++;
					chunk_1_flags[block_current] = 1;
					if (block_temp != block_current)
					{
						rsbi_to_write++;
						block_temp = block_current;
					}
				}
				else
					chunk_0_flags[block_current] = 1;
			}

			int rsri_to_write = (int)ceil(((float)rows_to_write / ceil((float)rs_bandwidth / log2((float)crossbar_row)))); // number of rsri instructions

			// Now if it can be done using a single rsri we do that, otherwise use block-wise
			if (allow_rowwise && rsri_to_write == 1) // row-wise
			{
				int remaining_rows = rows_to_write, rows_this_instruction, string_index = 0;

				for (int i = 0; i < rsri_to_write; i++)
				{
					nanofile << "RSri" << "\t";

					if (remaining_rows >= (int)ceil((float)rs_bandwidth / log2((float)crossbar_row)))
					{
						remaining_rows -= (int)ceil((float)rs_bandwidth / log2((float)crossbar_row));
						rows_this_instruction = (int)ceil((float)rs_bandwidth / log2((float)crossbar_row));
					}
					else
					{
						rows_this_instruction = remaining_rows;
					}

					for (int k = (int)ceil(log2((float)rs_bandwidth / log2((float)crossbar_row))) - 1; k >= 0; k--)
						((rows_this_instruction - 1) >> k) & 1 ? nanofile << 1 : nanofile << 0;
					nanofile << '\t';

					for (int j = 0; j < rows_this_instruction; j++)
					{
						while (true)
						{
							if (logic_row_string[string_index] == '1')
								break;

							string_index++;
						}

						for (int k = (int)ceil(log2(crossbar_row)) - 1; k >= 0; k--)
							((string_index) >> k) & 1 ? nanofile << 1 : nanofile << 0;

						string_index++;
					}

					for (int k = 0; k < rs_bandwidth - rows_this_instruction * (int)ceil(log2(crossbar_row)); k++)
						nanofile << 0;

					nanofile << endl; nano_line_counter++;

				}
			}
			else // block-wise
			{
				int all_1_blocks = 0, all_0_blocks = 0, blocks_to_write = 0;
				bool chunk_set = 0;

				for (int i = 0; i < no_of_rs_chunks; i++)
				{
					if (chunk_0_flags[i] == 1 && chunk_1_flags[i] == 0)
						all_0_blocks++;
					else if (chunk_0_flags[i] == 0 && chunk_1_flags[i] == 1)
						all_1_blocks++;
				}

				if (all_1_blocks > all_0_blocks)
					chunk_set = 1;

				for (int i = 0; i < no_of_rs_chunks; i++)
				{
					if (chunk_set == 1 && chunk_0_flags[i] == 1)
					{
						blocks_to_write++;
					}
					else if (chunk_set == 0 && chunk_1_flags[i] == 1)
					{
						blocks_to_write++;
					}

				}

				if (blocks_to_write < no_of_rs_chunks && chunk_set)
				{
					nanofile << "RDSs" << endl; nano_line_counter++;
				}
				else if (blocks_to_write < no_of_rs_chunks)
				{
					nanofile << "RDSc" << endl; nano_line_counter++;
				}

				for (int i = 0; i < no_of_rs_chunks; i++)
				{
					if ((all_1_blocks > all_0_blocks&& chunk_0_flags[i] == 1) || (all_1_blocks <= all_0_blocks && chunk_1_flags[i] == 1))
					{
						nanofile << "RDSb" << '\t';

						for (int k = (int)ceil(log2((float)crossbar_row / (float)rs_bandwidth)) - 1; k >= 0; k--)
							((i) >> k) & 1 ? nanofile << 1 : nanofile << 0;

						nanofile << "\t";

						for (int j = 0; j < rs_bandwidth; j++)
						{
							nanofile << logic_row_string[j + rs_bandwidth * i];
						}

						nanofile << endl; nano_line_counter++;
					}
				}
			}

			// ----------------------------------------------------------------------------------------------------------------

			if (WDS_for_all_operations == 'y')
			{
				// WDS start ------------------------------------------------------------------------------

				WDS_temp.clear();

				bool WDS_chunk_0_flags[no_of_wds_chunks] = { };
				bool WDS_chunk_1_flags[no_of_wds_chunks] = { };
				bool WDS_chunk_copy_flags[no_of_wds_chunks] = { };
				int WDS_set_or_clear_counter = 0;
				bool WDS_set_or_clear = false; // true = set, false = clear
				int WDS_chunks_to_write_counter = 0;

				for (int t = 0; t < no_of_wds_chunks; t++)
				{
					for (int k = 1; k <= wds_bandwidth; k++)
					{
						if (t * wds_bandwidth + k >= j && t * wds_bandwidth + k < j + q)
						{
							WDS_chunk_1_flags[t] = 1;

						}
						else
						{
							WDS_chunk_0_flags[t] = 1;
						}
					}

					if (WDS_chunk_1_flags[t] && WDS_chunk_0_flags[t])
						WDS_chunks_to_write_counter++;
					else if (WDS_chunk_1_flags[t] && !WDS_chunk_0_flags[t])
						WDS_set_or_clear_counter++;
					else if (WDS_chunk_0_flags[t] && !WDS_chunk_1_flags[t])
						WDS_set_or_clear_counter--;
				}

				// >0 means more blocks have all 1's so set. simillarly <0 means clear. ==0 means all blocks should be written so no set or clear
				if (WDS_chunks_to_write_counter < no_of_wds_chunks && WDS_set_or_clear_counter > 0)
				{
					nanofile << "WDSs" << endl; nano_line_counter++;
					WDS_set_or_clear = true;
				}
				else if (WDS_chunks_to_write_counter < no_of_wds_chunks && WDS_set_or_clear_counter <= 0)
				{
					nanofile << "WDSc" << endl; nano_line_counter++;
					WDS_set_or_clear = false;
				}

				for (int WDS_chunk = 0; WDS_chunk < crossbar_column / wd_bandwidth; WDS_chunk++)
				{
					WDS_temp.clear();
					if (WDS_chunks_to_write_counter == no_of_wds_chunks ||
						(WDS_set_or_clear && WDS_chunk_0_flags[WDS_chunk]) ||
						(!WDS_set_or_clear && WDS_chunk_1_flags[WDS_chunk])) // this chunk should be written
					{
						for (int t = 1; t <= wds_bandwidth; t++)
						{
							if (t + WDS_chunk * wds_bandwidth >= j && t + WDS_chunk * wds_bandwidth < j + q)
							{
								WDS_temp += '1';
							}
							else
							{
								WDS_temp += '0';
							}
						}

						nanofile << "WDSb" << "\t";

						for (int k = (int)ceil(log2((float)crossbar_column / (float)wds_bandwidth)) - 1; k >= 0; k--)
							((crossbar_column / wd_bandwidth) - (WDS_chunk + 1) >> k) & 1 ? nanofile << 1 : nanofile << 0;

						nanofile << "\t";

						nanofile << WDS_temp << endl; nano_line_counter++;

					}
				}

				// WDS end --------------------------------------------------------------------------------
			}

			/*if (FS_ref != "XOR")
			{
				nanofile << "FS" << "\t" << "XOR" << endl; nano_line_counter++;
				FS_ref = "XOR";
			}*/

			nanofile << "DoA" << endl; nano_line_counter++;
			nanofile << "DoS" << endl; nano_line_counter++;


			// This next section is used to write the read-out stage to the readStageFile. Afterwards it is compared with the jump file.
						// if it matches we use jump, if it doesnt match we overwrite the jumpfile and append a jr
			bool total_activation = 0;
			int activation = 0;
			string CS_activation_bits = "";
			readstageoutfile.open("readStageFile.txt");
			for (int CS = 0; CS < crossbar_column / num_of_ADC; CS++)
			{

				//-------------------- before issuing next CS, it has to be checked if we are done with columns or not ----------  
				total_activation = 0;
				CS_activation_bits.clear();
				for (int ADC_cnt = 0; ADC_cnt < num_of_ADC; ADC_cnt++)
				{
					if ((crossbar_column / num_of_ADC - CS) + ADC_cnt * crossbar_column / num_of_ADC >= p && (crossbar_column / num_of_ADC - CS) + ADC_cnt * crossbar_column / num_of_ADC < p + q)
					{
						CS_activation_bits += '1';
						total_activation = 1;
					}
					else
					{
						CS_activation_bits += '0';
					}
				}

				//-----------------------------------------------------------------------------------------------

				if (total_activation)
				{
					//nanofile << "CS" << '\t';
					if (combine_CS_DoR)
						readstageoutfile << "CSR" << '\t';
					else
						readstageoutfile << "CS" << '\t';

					for (int k = (int)ceil(log2((float)crossbar_column / (float)num_of_ADC)) - 1; k >= 0; k--)
					{
						//(CS >> k) & 1 ? nanofile << 1 : nanofile << 0;
						(CS >> k) & 1 ? readstageoutfile << 1 : readstageoutfile << 0;
					}

					//nanofile << '\t';
					readstageoutfile << '\t';

					//nanofile << CS_activation_bits << endl << "DoR" << endl;
					if (combine_CS_DoR)
						readstageoutfile << CS_activation_bits << endl;
					else
						readstageoutfile << CS_activation_bits << endl << "DoR" << endl;

				}
			}

			readstageoutfile.close();
			readstageinfile.open("readStageFile.txt");
			jumpinfile.open("jumpFile.txt");
			readstage_jump = 1;
			int test_counter = 0;

			while (true) // check if readfile and jumpfile are identical
			{
				getline(readstageinfile, readstageline);
				getline(jumpinfile, jumpfileline);

				if (readstageinfile.eof() || jumpinfile.eof())
					break;

				test_counter++;

				if (readstageline != jumpfileline)
				{
					readstage_jump = 0;
					break;
				}
			}

			if (!readstageinfile.eof() || !jumpinfile.eof()) // dont jump if one file is longer than the other
				readstage_jump = 0;

			jumpinfile.close();

			if (!readstage_jump)
			{
				//readstageinfile.open("readStageFile.txt");
				readstageinfile.clear();
				readstageinfile.seekg(0, ios::beg);
				remove("jumpFile.txt");
				jumpoutfile.open("jumpFile.txt");

				jal_jump_to = nano_line_counter + 1; // point to line containing first CS (+1 because it is the next line to write here)

				while (getline(readstageinfile, readstageline))
				{
					nanofile << readstageline << endl; nano_line_counter++;
					jumpoutfile << readstageline << endl;
				}
				nanofile << "jr" << '\t' << jal_jump_to << '\t' << nano_line_counter + 1 - jal_jump_to << endl; nano_line_counter++; // jr instruction to return to value stored in register by jal
				jumpoutfile.close();
			}
			else
			{
				nanofile << "jal" << '\t' << jal_jump_to << endl; nano_line_counter++;
			}

			readstageinfile.close();
			remove("readStageFile.txt");

			//nanofile << "END" << endl; nano_line_counter++;
			break;
		}
		}
	}
	
	bufferfile_tmp.close();
	bufferfile_tmp_i.open("bufferfile_tmp.txt");

	bufferfile << "WD_elements\t" << WD_element_count << endl;
	bufferfile << "RD_elements\t" << RD_element_count << endl;
	bufferfile << "matrix_rows\t" << matrix_rows << endl;
	int bufferfile_time_mux_cnt = 0;
	while (getline(bufferfile_tmp_i, line))
	{
		bufferfile << "RD_valid_bits_" << bufferfile_time_mux_cnt << '\t' << line << endl;
		bufferfile_time_mux_cnt++;
	}
	bufferfile_tmp_i.close();
	remove("bufferfile_tmp.txt");

	ofstream vivado_config;
	vivado_config.open("HDL/vivado_config.txt");
	vivado_config << "number of output reads: " << output_read_counter << endl;

	cout << "End of file" << endl;
	cout << "Total nano_instruction lines: " << nano_line_counter << endl;


	// This rearranges the instruction into different files containing the instructions that correspond to the different stages

	if (pipeline_rearrange == 'y')
	{
		cout << "Start splitting instructions" << endl;
		ofstream nanofile_stage_1;
		nanofile_stage_1.open("nanoInst_stage_1.txt");

		ofstream nanofile_stage_2;
		nanofile_stage_2.open("nanoInst_stage_2.txt");

		ifstream nanofile("nanoInst.txt");

		string instruction_line, instruction_line_temp;
		int stage_1_counter = 0, stage_2_counter = 0;

		int CS_delta;
		int jal_address;
		vector< vector<int> > jump_vector;
		vector<int> jump_vector_row;

		while (getline(nanofile, instruction_line))
		{
			instruction_line_temp = instruction_line;
			istringstream iss(instruction_line_temp);
			iss >> string_opcode;

			switch (nano_opcode[string_opcode])
			{
			case ACFG:
			case FS:
			case RDSb:
			case RDSs:
			case RDSc:
			case RDsh:
			case WDSb:
			case WDSs:
			case WDSc:
			case WDb:
			case DoA:
			case DoS:
				nanofile_stage_1 << instruction_line << endl;
				stage_1_counter++;
				break;
			case jr:

				iss >> jal_address >> CS_delta;
				jump_vector_row.push_back(jal_address);
				jump_vector_row.push_back(stage_2_counter - CS_delta);
				jump_vector.push_back(jump_vector_row);
				jump_vector_row.clear();

				nanofile_stage_2 << "jr" << endl;
				stage_2_counter++;
				break;
			case jal:

				iss >> jal_address;

				for (int i = 0; i < jump_vector.size(); i++)
				{
					if (jump_vector[i][0] == jal_address)
						nanofile_stage_2 << "jal" << '\t' << jump_vector[i][1] << endl;
				}
				stage_2_counter++;
				break;
			default:
				nanofile_stage_2 << instruction_line << endl;
				stage_2_counter++;
				break;
			}
		}
		nanofile_stage_1 << "NOP" << endl;
		nanofile_stage_2 << "NOP" << endl;
		cout << "Finished splitting instructions" << endl;
	}

	if (toHDL == 'y')
	{
		inst2hdl();
		data2hdl();
	}

	return 0;
}

void dispMem(int* memory, ofstream& dispMem)
{
	for (int i = 0; i < mem1_row_size; i++) {
		for (int k = 0; k < mem1_column_size; k++) {
			dispMem << *(memory + k + i * mem1_column_size);
		}
		dispMem << endl;
	}
}

void intMem_init(int* memory) {
	srand(time(NULL));
	for (int i = 0; i < mem1_row_size; i++) {
		for (int k = 0; k < mem1_column_size; k++) {
			*(memory + k + i * mem1_column_size) = rand() % memristor_level;
		}
	}
}

void Initialize()
{
	opcode["store"] = store;
	opcode["read"] = read;
	opcode["MMM"] = MMM;
	opcode["logical_and"] = logical_and;
	opcode["logical_or"] = logical_or;
	opcode["logical_xor"] = logical_xor;

	// stage 1
	nano_opcode["ACFG"] = ACFG;
	nano_opcode["FS"]   = FS;
	nano_opcode["RDSb"] = RDSb;
	nano_opcode["RDSs"] = RDSs;
	nano_opcode["RDSc"] = RDSc;
	nano_opcode["RDsh"] = RDsh;
	nano_opcode["WDSb"] = WDSb;
	nano_opcode["WDSs"] = WDSs;
	nano_opcode["WDSc"] = WDSc;
	nano_opcode["WDb"]  = WDb;
	nano_opcode["DoA"]  = DoA;
	nano_opcode["DoS"]  = DoS;

	// stage 2
	nano_opcode["CS"]   = CS;
	nano_opcode["DoR"]  = DoR;
	nano_opcode["CSR"]  = CSR;
	nano_opcode["jal"]  = jal;
	nano_opcode["jr"]   = jr;
	nano_opcode["BNE"]  = BNE;
	nano_opcode["AS"]   = AS;
	nano_opcode["CP"]   = CP;
	nano_opcode["CB"]   = CB;
	nano_opcode["LS"]   = LS;
	nano_opcode["IADD"] = IADD;
}


