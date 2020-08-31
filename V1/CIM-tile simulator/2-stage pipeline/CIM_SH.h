#pragma once
/***************************************************************************
 * class: CIM_SH (Sample and Hold)
 *
 * description: Object of this class, just capture the data from crossbar and send it to ADC
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

class CIM_SH :public sc_module
{
	private:

	public:

		//---------------inputs----------------------------------
		sc_port<crossbar_SH_if> In_data;
		sc_in<bool> p_DoS;

		int energy_consumption;
		//--------------outputs----------------------------------
		sc_port<SH_ADC_if> ToADC;
		sc_out<bool> p_done_SH;
		//------------------------------------------------------------

		CIM_SH(sc_module_name nm);
		~CIM_SH();

		SC_HAS_PROCESS(CIM_SH);

		void execution();
};