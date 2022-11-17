#pragma once
/***************************************************************************
 * class: CIM_Row_Data
 *
 * description: Input data coming to the crossbars

 * version number: 1 (09-08-2020)
 *
 * authors: Mahdi Zahedi (m.z.zahedi@tudelft.nl)
 ***************************************************************************/

#include "CIM_interface.h"
using tlm::tlm_nonblocking_put_if;
using tlm::tlm_tag;

using namespace std;
using namespace interfaces;

class CIM_Row_Data
	: public sc_module, port_outside_2_RD_if
{
private:

	bool				RDS_register[Number_of_Rows];
	bool				RD_buffer[Number_of_Rows][RD_buffer_width + 1];
	sc_event			dummy;
public:
	sc_in_clk										clock;
	//************
	sc_export< port_outside_2_RD_if >				p_outside_2_RD;
	//************
	sc_port< RDS_data_in_if, SC_MANY_WRITERS>		p_RDS_in; // data to RDS	
	//************
	sc_port< RD_out_if, SC_MANY_WRITERS>			p_RD_out; // data to DIM
	sc_port< RDS_out_if, SC_MANY_WRITERS>			p_RDS_out; // data to DIM


	CIM_Row_Data(sc_module_name nm);
	~CIM_Row_Data();
	SC_HAS_PROCESS(CIM_Row_Data);

	friend class CIM_decoder;

	bool nb_put(const interfaces::outside_2_RD_if& t);
	bool nb_can_put(tlm_tag<interfaces::outside_2_RD_if>* t = 0) const;
	const sc_core::sc_event& ok_to_put(tlm_tag<interfaces::outside_2_RD_if>* t = 0) const;

	void clock_pos();
	void clock_neg();

	void RDsh();
	void RDSri();
	void RDSb();
	void RDSc();
	void RDSs();
};
