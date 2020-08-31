#pragma once
/***************************************************************************
 * class: DIM_Crossbar
 *
 * description:

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
#include <vector>

using namespace interfaces;

class DIM_Crossbar : public sc_module
{
	private:		
		int*			intMem;
		int				crossbar_counter;

	public:
		
		ofstream		memfile;
		
		//-----------------inputs--------------------------------------
		//------------------------------------------------------------
		sc_in < bool >				p_DoA;
		sc_port< RD_out_if >		p_RD; // data for RD
		sc_port< RDS_out_if >		p_RS; // data for RS
		sc_port< WD_out_if >		p_WD; // data for WD
		sc_port< WDS_out_if >		p_WDS; // data for WDS
		sc_port< FS_if >			p_FS; 

		int							energy_consumption;
		//-----------------outputs-------------------------------------
		//-------------------------------------------------------------

		sc_port<crossbar_SH_if>		ToSH;		
		sc_out<bool>				p_done_crossbar;

		//-------------------------------------------------------------
		friend class CIM_decoder;

		DIM_Crossbar(sc_module_name nm);
		~DIM_Crossbar();	

		SC_HAS_PROCESS(DIM_Crossbar);
		
		void execution();
		void intMem_init(int*);
		void dispMem(ofstream&);
};