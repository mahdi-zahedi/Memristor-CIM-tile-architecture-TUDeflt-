#pragma once
/***************************************************************************
 * class: CIM_ADC (Analog to Digital Converter)
 *
 * description: The number of ADCs determine the number of outputs. CS signal determines which columns can be connected to ADCs
 * version number: 1 (09-08-2020)
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
#include "CIM_interface.h"

using namespace std;

class CIM_ADC :public sc_module
{
private:
	CS_if					R_column_select; // column select register 
	sc_event				e_activation;
public:

	long double				energy_consumption; int temp2;
	//---------------inputs----------------------------------
	sc_in_clk				clock;
	sc_port<SH_ADC_if>		p_In_data;
	sc_port< CS_if>			p_column_select;	
	sc_in<bool>				p_DoR;

	//--------------outputs----------------------------------
	sc_port<ADC_ADDER_if>	output;
	sc_out<bool>			p_done_ADC;
	//------------------------------------------------------------

	CIM_ADC(sc_module_name nm);
	~CIM_ADC();

	SC_HAS_PROCESS(CIM_ADC);
	void clock_pos();
	void clock_neg();
	void execution();
	void activation();
};