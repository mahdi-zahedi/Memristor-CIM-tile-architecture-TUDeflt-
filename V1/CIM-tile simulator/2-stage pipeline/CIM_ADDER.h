#pragma once
/***************************************************************************
 * class: CIM_ADDER (Addition unit)
 *
 * description: Object of this class, is responsible to get the data from ADC and perform proper process
				on it to provide final result in a datatype structure which asked by user.  
 * version number: 3 (04-10-2019)
 *
 * authors: Mahdi Zahedi (m.z.zahedi@tudelft.nl)
 ***************************************************************************/

#include <iostream>
#include <systemc.h>
#include <fstream>
#include <sstream>
#include <string>
#include <map>
#include <cstdlib>
#include <ctime>
#include <cmath>
#include "CIM_interface.h"
#include "CIM_Write_Data.h"

#define Number_of_temp_primary_registers Number_of_ADCs
#define Number_of_temp_secondary_registers Number_of_temp_primary_registers
#define Number_of_final_registers Number_of_Cols / datatype_size
using namespace std;

class CIM_ADDER :public sc_module
{
private:

	bool					LS;
	int						shift;
	bool					sc_done_ADC;

	CS_if					cs_register;
	ADC_ADDER_if			ADDER_inputs;

	long long				primary_registers[Number_of_Cols], temp_primary_registers[Number_of_temp_primary_registers];
	long long				secondary_registers[Number_of_temp_primary_registers],temp_secondary_registers[Number_of_temp_secondary_registers]; // final regsiter per datatype
	long long				final_registers_per_ADC[Number_of_temp_secondary_registers];
	long long				final_temp[int(Number_of_final_registers)];
	
	sc_event				event_primary_addition;
	sc_event				event_secondary_addition;
	sc_event				primary_addition_done;
	sc_event				event_done_ADC;
	sc_event				event_write_to_WDS;

	sc_signal<bool, SC_MANY_WRITERS>				s_verify_result;
	sc_signal<bool, SC_MANY_WRITERS>				new_WDS_value[Number_of_Cols];
public:					
	ofstream				outputfile;
	ofstream				logical_operation_file;
	//---------------inputs----------------------------------
	sc_in_clk				clock;

	sc_port<ADC_ADDER_if>	In_data;
	sc_port<CS_if>			p_column_select;
	sc_port< WD_out_if>		p_WD; // data to WD
	sc_port< WDS_out_if>	p_WDS; // data to WDS
	sc_port<AS_if>			p_AS;
	sc_in<bool>				p_LS,p_IADD,p_CP,p_CB, p_AS_activation;
	sc_in<bool>  			p_adder_activation;
	sc_in<bool>				p_logical_operation;
	sc_in<bool>				p_write_verify;
	sc_in<bool>  			p_done_ADC; // comes from ADC
	sc_in<bool>				p_BNE_flag;

	int energy_consumption;
	//--------------outputs----------------------------------
	
	sc_port<ADDER_out_if>	out;
	sc_out<bool>			p_verify_result;
	//------------------- friend classes ----------------------------------------
	CIM_Write_Data* CIM_WD_object;
	//---------------------------------------------------------------------------

	CIM_ADDER(sc_module_name nm, CIM_Write_Data* CIM_WD_obj);
	~CIM_ADDER();

	SC_HAS_PROCESS(CIM_ADDER);
	void clock_pos();
	void clock_neg();

	void registered_ADC_out();
	void LS_function();

	void primary_addition();
	void secondary_addition_scheme1();
	void secondary_addition_scheme2();

	void third_addition(); //final addition per ADC
	void coppy_per_ADC();
	void Adder_select();
	void coppy_between_ADC();
	void logical_operation_out();
	void write_verify();
	void fun_done_ADC();
	void p_verify_result_update();
};