#pragma once
/***************************************************************************
 * class: CIM_Write_Data
 *
 * description: 
 * version number: 1 (09-08-2020)
 *
 * authors: Mahdi Zahedi (m.z.zahedi@tudelft.nl)
 ***************************************************************************/
#include "CIM_interface.h"

using namespace std;
using namespace interfaces;
using tlm::tlm_nonblocking_put_if;
using tlm::tlm_tag;

class CIM_Write_Data
	: public sc_module, port_outside_2_WD_if
{
private:
	bool											WD_register[Number_of_Cols];
	bool											WDS_register[Number_of_Cols];
	bool											WD_buffer[Number_of_Cols / WD_buffer_bandwidth][WD_buffer_bandwidth];
	sc_event										dummy;
public:
	sc_signal<int, SC_MANY_WRITERS>					s_WDb, s_nb_put;
	sc_in_clk										clock;
	sc_signal < int, SC_MANY_WRITERS>				WD_buffer_counter; // point to where we need to write into WD buffer

	//************
	sc_export< port_outside_2_WD_if >				p_outside_2_WD; 
	//************
	sc_in<int>										p_WD_index_int;
	sc_port< WD_out_if >							p_WD_out; // data to WD

	sc_port< WDS_data_in_if >						p_WDS_in; // data to WDS
	sc_port< WDS_out_if >							p_WDS_out; // data to DIM

	CIM_Write_Data(sc_module_name nm);
	~CIM_Write_Data();
	SC_HAS_PROCESS(CIM_Write_Data);

	friend class CIM_decoder;
	friend class CIM_Outside_Controller_WD;
	friend class CIM_ADDER;

	void clock_pos();
	void clock_neg();

	bool nb_put(const interfaces::outside_2_WD_if& t);
	bool nb_can_put(tlm_tag<interfaces::outside_2_WD_if>* t = 0) const;
	const sc_core::sc_event& ok_to_put(tlm_tag<interfaces::outside_2_WD_if>* t = 0) const;
	void WDb();
	void WDSb();
	void WDSc();
	void WDSs();
	void WD_buffer_counter_update();

};
