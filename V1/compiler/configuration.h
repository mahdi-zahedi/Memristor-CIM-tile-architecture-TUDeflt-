#pragma once
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



const int mem1_row_size = 2000; const int mem1_column_size = 2000;
const int mem2_row_size = 2000; const int mem2_column_size = 2000;
const int memristor_level = 2; const int num_of_crossbar = 1; const int crossbar_row = 256; const int crossbar_column = 256;
const int num_of_ADC = 32; const char WDS_for_all_operations = 'n'; int Max_row_select = 256; const int datatype_size = 8; const int max_datatype_size = 8;
const int rs_bandwidth = 32, wd_bandwidth = 32, wds_bandwidth = 32; const int no_of_rs_chunks = crossbar_row / rs_bandwidth; const int no_of_wds_chunks = crossbar_column / wds_bandwidth;
const int num_pipeline_counters = 2; const char pipeline_rearrange = 'y'; const char write_verify = 'n';
const bool allow_rowwise = 0; // 0 = dis-allow (row-wise is not supported in hardware)
const bool combine_CS_DoR = 1; // 1 for CSR, 0 for separate CS and DoR
const int time_mux_const = (crossbar_column / num_of_ADC) / datatype_size;
const char toHDL = 'n';


//********** micro-instruction file ********************
ifstream infile("D:/Phd/simulators/sim_compiler_arch2/benchmarks/medium/xor_sample.txt");


void Initialize(void);
void intMem_init(int*);
void dispMem(int*, ofstream&);

