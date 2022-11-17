#pragma once
/***************************************************************************
 * class: CIM_tile
 *
 * description: Top level modules
 * version number: 3 (4-10-2019)
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


using namespace std;
#include "CIM_interface.h"
#include "CIM_decoder.h"
#include "CIM_Outside_Controller.h"
#include "CIM_Write_Data.h"
#include "CIM_Row_Data.h"
#include "DIM_Crossbar.h"
#include "CIM_SH.h"
#include "CIM_ADC.h"
#include "CIM_ADDER.h"

class Cim_Tile
	: public sc_module
{
public:
	
	CIM_decoder						decoder_ins;
	CIM_Outside_Controller_RD		Outside_Controller_RD_ins;
	CIM_Outside_Controller_WD		Outside_Controller_WD_ins;
	CIM_Write_Data					Write_Data_ins;
	CIM_Row_Data					Row_Data_ins;
	DIM_Crossbar					DIM_Crossbar_ins;
	CIM_SH							SH_ins;
	CIM_ADC							ADC_ins;
	CIM_ADDER						ADDER_ins;
	
	
	Cim_Tile(sc_module_name nm);
	~Cim_Tile();

	SC_HAS_PROCESS(Cim_Tile);

	//--------------------------------------------------------------------------------
	//----------- Timing signals which are initilized in the constructor by user  ----
	sc_in_clk				clock;	
	sc_signal<int>			p_WD_index_int;

	AS_if					p_AS;
	WD_out_if				p_WD;
	WDS_out_if				p_WDS;
	CS_if					p_CS;
	ADC_ADDER_if			p_ADC_ADDER;
	SH_ADC_if				p_SH_To_ADC;
	crossbar_SH_if			p_crossbar_data;
	FS_if					p_FS;
	RD_out_if				p_RD;
	RDS_out_if				p_RS;
	RDS_data_in_if			p_RDS_in;
	WDS_data_in_if			p_WDS_in;

	sc_signal<bool>  		p_done_crossbar;
	sc_signal<bool>  		p_done_SH;
	sc_signal<bool>  		p_done_ADC;
	sc_signal<bool>			p_verify_result;	
	sc_signal<bool>			p_DoA;
	sc_signal<bool>			p_DoS;
	sc_signal<bool>			p_DoR;
	sc_signal<bool>			p_LS;
	sc_signal<bool>			p_IADD;
	sc_signal<bool>			p_CP;
	sc_signal<bool>			p_AS_activation;
	sc_signal<bool>			p_CB;
	sc_signal<bool>			p_adder_activation;
	sc_signal<bool>			p_logical_operation;
	sc_signal<bool>			p_write_verify;
	sc_signal<bool>			p_BNE_flag;
	ADDER_out_if			ADDER_out;
	//------------------------------------------------------------------------------
	
	void start();
};

