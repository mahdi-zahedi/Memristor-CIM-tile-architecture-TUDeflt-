#pragma once
#include <math.h>
#include <cmath>

#define nanoInst_stage_1 "D:/Phd/simulators/sim_compiler_arch2/v1/compiler/compiler/nanoInst_stage_1.txt"
#define nanoInst_stage_2 "D:/Phd/simulators/sim_compiler_arch2/v1/compiler/compiler/nanoInst_stage_2.txt"
#define RD_file_path "D:/Phd/simulators/sim_compiler_arch2/v1/compiler/compiler/RDfile.txt"
#define WD_file_path "D:/Phd/simulators/sim_compiler_arch2/v1/compiler/compiler/WDfile.txt"

//******************* playing with these number needs changing nan-instructions (compiler) as well **************
#define Number_of_Rows 256
//#define Number_of_Rows_bits 8 // number of bits necessary to represent induvidual rows
#define Number_of_Cols 256

#define RDS_bandwidth 32 // assumed to be a power of 2 in this version. 
#define WDS_bandwidth 32
#define WD_buffer_bandwidth 32

//#define RS_chunk_bits 3 // number of bits necessary to represent chunk indices
//#define WD_chunk_bits 3 
//#define WDS_chunk_bits 3 
//#define RSri_bits 2 // bits used to determine how many rows will be selected by RSri

#define Number_of_ADCs 8  // just as a redundant information. If CS has more 1 than number of ADCs, it generates an error regarding wrong nano-instruction
#define ADC_resolution 256 // levels
//#define ADC_index_bits log2(Number_of_Cols/Number_of_ADCs)
#define memristor_level 2
#define maximum_datatype_size 32
#define RD_buffer_width maximum_datatype_size
#define datatype_size 32
//***************************************************************************************************************

#define mode_def  0    // 1 means using counter inside controller	

// ************* All the values in nano second ****************************************

#define simulation_time 10000000
#define clock_period  2//nano second

#define write_fault_probability 0 // 1 = 0.01%, so 100 = 1%
const float cell_resistance[memristor_level] = { 0.005,1 }; // cell_resistance = {LRS,HRS} - unit should be "M"
const float read_voltage[1] = { 0.2 };
const float write_voltage[1] = { 2 };
const float write_current[1] = { 100 }; // unit is uA


#define fetch_and_decoding_delay_cycle  1
//#define RDS_filling_cycle 1
//#define WD_filling_cycle 1
//#define WDS_filling_cycle 1
//#define FS_filling_cycle 1
//#define CS_filling_cycle 1
//#define buffer_filling_cycle 1

#define dim_crossbar_write_delay  100
#define dim_crossbar_read_delay   10

#define DIM_Crossbar_counter_write   	(dim_crossbar_write_delay/clock_period) + (dim_crossbar_write_delay%clock_period)  
#define DIM_Crossbar_counter_read	 	(dim_crossbar_read_delay/clock_period) + dim_crossbar_read_delay%clock_period


#define SH_delay_def  0.9 
#define ADC_delay_def  1  // ADC delay + 8-bit Adder (in future we can seperate them)

#define SH_counter_def  (SH_delay_def)/clock_period+1				
#define ADC_counter_def	 (ADC_delay_def)/clock_period+1			

#define latency_of_third_addition 5
#define latency_of_final_addition 5

#define write_DIM_power 1000/256 // unit is "uW"
#define read_DIM_power  1000/256 // unit is "uW"

//#define write_energy 40 // 40pj per cell
//#define read_energy  0.4 // 0.4pj per cell

#define ADC_energy   2 // pj per ADC
#define SH_energy 0.001 // 1fj per sampling
#define primary_adder_energy 0.01 // pj
#define secondary_adder_energy 0.01 // pj
#define third_adder_energy 0.25  // pj
#define forth_adder_energy 4 // pj-addition between ADCs