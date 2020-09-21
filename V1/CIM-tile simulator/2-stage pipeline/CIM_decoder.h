#pragma once
/***************************************************************************
 * class: CIM_decoder 
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
#include "CIM_Write_Data.h"
#include "CIM_Row_Data.h"
#include "DIM_Crossbar.h"
#include "CIM_ADC.h"

using namespace std;
using tlm::tlm_nonblocking_put_if;
using tlm::tlm_tag;



class CIM_decoder
	: public sc_module	
{
	private:
		
		int					RD_buffer_counter; // used for datatype
		int					PC1, PC2;
		int					branch_register_s1;
		int					jump_register_s2, branch_register_s2;
		int					Number_Of_wrong_write;
	
		bool				sc_done_crossbar, sc_done_SH, sc_done_ADC, sc_done_CSR;
		
		bool				inst_bypass_flag, read_finished_flag;
		bool				first_CS;

		char*				CS_index;
		char*				CS_select_data;
					
		sc_event			event_done_crossbar,event_done_SH,event_done_ADC;
		FS_if				FS_buffer;

		sc_event			event_IADD;		
		sc_event			e_wait_for_outside_RD;
		sc_event			e_done_outside_RD;

		sc_event			e_wait_for_outside_WD;
		sc_event			e_done_outside_WD;

		sc_event			event_busy_flag_2, event_BNE;
		sc_event			event_stage1_exe, event_stage2_exe;

		sc_event			event_clock_pos, event_clock_neg;
		//-----------------------signals----------------------------------------------
	
		sc_signal < bool, SC_MANY_WRITERS>		busy_flag_S2, first_iteration;
		sc_signal < bool, SC_MANY_WRITERS>		flag_IADD;
		
		sc_signal	<bool, SC_MANY_WRITERS>		s_DoR, s_adder_activation, s_write_verify, s_logical_operation;
		//------------------------------------------------------------	
		
		string									s1_string_opcode1, s1_string_opcode2, s2_string_opcode1, s2_string_opcode2;
		fstream									infile1;
		fstream									infile2;
		
	public:
		
		//------------------- friend classes ----------------------------------------
		CIM_Write_Data*							CIM_WD_object; int temp2;
		CIM_Row_Data*							CIM_RD_object;
		DIM_Crossbar*							DIM_Crossbar_object;
		CIM_ADC*								CIM_ADC_object;

		//-------------------------input--------------------------------------------
		//*****inputs which come from the top module to set the counter and mode****
		sc_in_clk								clock;				
		//---------------------------------------------------------------------------
		sc_in<bool>  							p_done_crossbar; // comes from crossbar
		sc_in<bool>  							p_done_SH; // comes from S&H
		sc_in<bool>  							p_done_ADC; // comes from ADC
		sc_in<bool>								p_verify_result; // from ADDER
		
		//***************************************************************************
		//*******************interface to outside controller ************************
		sc_port< port_inCtrl_2_outside_RD_if >		p_inCtrl_2_outside_RD;
		sc_port< port_inCtrl_2_outside_WD_if >		p_inCtrl_2_outside_WD;
		//---------------------------------------------------------------------------

		sc_port< RDS_data_in_if, SC_MANY_WRITERS >	p_RDS_in; // data to RS		
		sc_port< WDS_data_in_if, SC_MANY_WRITERS >	p_WDS_data_in; // data to WD
		sc_out<int>									p_WD_index_int;
		
		//---------------------------------------------------------------------------
		sc_port< FS_if, SC_MANY_WRITERS >			p_FS; // data to CS
		sc_port< CS_if, SC_MANY_WRITERS >			p_CS; // data to CS
		sc_port< AS_if, SC_MANY_WRITERS >			p_AS; // data to Adder select	
		//---------------------------------------------------------------------------
		sc_out<bool>								p_adder_activation; // logical AND between DoA and FS 
		sc_out<bool>								p_DoA;
		sc_out<bool>								p_DoS;
		//---------------------------------------------------------------------------
		sc_out<bool>								p_DoR;
		sc_out<bool>								p_BNE_flag;
		//---------------------------------------------------------------------------
		sc_out<bool>								p_LS;
		sc_out<bool>								p_IADD;
		sc_out<bool>								p_CP;
		sc_out<bool>								p_AS_activation;
		sc_out<bool>								p_logical_operation;
		sc_out<bool>								p_write_verify;
		sc_out<bool>								p_CB;
		
		//**************************************************************************
		//**************************************************************************
		int				RDS_flipper;
		int				RD_buffer_flipper;
		int				WD_flipper;
		int				WDS_flipper;
		int				CSR_flipper;
		int				FS_flipper;
		int				AS_flipper;
		//---------------------------------------------------------------------------

		CIM_decoder(sc_module_name nm, CIM_Write_Data* CIM_WD_obj, CIM_Row_Data* CIM_RD_obj, DIM_Crossbar* DIM_Crossbar_obj, CIM_ADC* CIM_ADC_obj);
		~CIM_decoder();
		SC_HAS_PROCESS(CIM_decoder);

		void clock_pos();
		void clock_neg();
		void fun_done_crossbar();
		void fun_done_SH();
		void fun_done_ADC();
		void signals_update();

		void stage1_decode();
		void stage1_exe();
		void stage2_decode();
		void stage2_exe();

		void func_wait_for_outside_RD();
		void func_wait_for_outside_WD();
};

