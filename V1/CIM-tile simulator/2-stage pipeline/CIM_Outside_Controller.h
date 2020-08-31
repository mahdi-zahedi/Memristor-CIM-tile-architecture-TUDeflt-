/***************************************************************************
 * class: CIM_Outside_Controller
 *
 * description:

 * version number: 1 (09-08-2020)
 *
 * authors: Mahdi Zahedi (m.z.zahedi@tudelft.nl)
 ***************************************************************************/
#pragma once
#include "CIM_interface.h"
#include "CIM_Write_Data.h"

using namespace std;
using tlm::tlm_nonblocking_put_if;
using tlm::tlm_tag;

class CIM_Outside_Controller_RD 
	: public sc_module, port_inCtrl_2_outside_RD_if
{
private:

	interfaces::outside_2_RD_if*				temp_RD_data;
	fstream										RD_file;
	string										line;
	int											RD_data_int;
	bool										free_flag;

	bool										s_send_2_RD;
	sc_event									e_ready;
public:
	sc_in_clk									clock;
	sc_port< port_outside_2_RD_if >				p_outside_2_RD;
	sc_export< port_inCtrl_2_outside_RD_if >	p_inCtrl_2_outside_RD;

	void clock_pos();
	void clock_neg();

	void send_2_RD();
	bool nb_put(const interfaces::inCtrl_2_outside_RD_if& t);
	bool nb_can_put(tlm_tag<interfaces::inCtrl_2_outside_RD_if>* t=0) const;
	const sc_core::sc_event& ok_to_put(tlm_tag<interfaces::inCtrl_2_outside_RD_if>* t=0) const;	

	CIM_Outside_Controller_RD(sc_module_name nm);
	~CIM_Outside_Controller_RD();
	SC_HAS_PROCESS(CIM_Outside_Controller_RD);

};

class CIM_Outside_Controller_WD
	: public sc_module, port_inCtrl_2_outside_WD_if
{
private:

	interfaces::outside_2_WD_if*				temp_WD_data;
	fstream										WD_file;
	string										line;
	int											WD_data_int;
	bool										free_flag;

	bool										s_send_2_WD;
	sc_event									e_ready;
public:
	sc_in_clk									clock;
	sc_port< port_outside_2_WD_if >				p_outside_2_WD;
	sc_export< port_inCtrl_2_outside_WD_if >	p_inCtrl_2_outside_WD;

	//------------------- friend classes ----------------------------------------
	CIM_Write_Data* CIM_WD_object;

	//---------------------------------------------------------------------------
	void clock_pos();
	void clock_neg();

	void send_2_WD();
	bool nb_put(const interfaces::inCtrl_2_outside_WD_if& t);
	bool nb_can_put(tlm_tag<interfaces::inCtrl_2_outside_WD_if>* t = 0) const;
	const sc_core::sc_event& ok_to_put(tlm_tag<interfaces::inCtrl_2_outside_WD_if>* t = 0) const;
	

	CIM_Outside_Controller_WD(sc_module_name nm, CIM_Write_Data* CIM_WD_obj);
	~CIM_Outside_Controller_WD();
	SC_HAS_PROCESS(CIM_Outside_Controller_WD);

};