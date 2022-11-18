#pragma once
/***************************************************************************
 * Interface:
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
#include <cstdlib>
#include "tlm.h"
#include "configuration.h"
#include <thread>
//--------------------------------------inside/outside controller ------------------------
//----------------------------------------------------------------------------------------
namespace interfaces
{
	class inCtrl_2_outside_RD_if 
	{
	public:
		uint32_t data[Number_of_Rows]; // the data is not used so far! 
	};

	class inCtrl_2_outside_WD_if 
	{
	public:
		uint32_t data[Number_of_Rows]; // the data is not used so far!
	};
}
//--------------------------------------Row Data -----------------------------------------
//----------------------------------------------------------------------------------------
namespace interfaces
{
	class outside_2_RD_if
	{
	public:
		bool data[RD_buffer_width];
		int index;
	};

	class RDS_data_in_if :public sc_interface //block wise 
	{
	public:
		char data[RDS_bandwidth + 1];
		int  index;
	};

	class RD_out_if :public sc_interface
	{
	public:
		int data[Number_of_Rows];
	};
	class RDS_out_if :public sc_interface
	{
	public:
		int data[Number_of_Rows];
	};
}
//--------------------------------------Write Data ---------------------------------------
//----------------------------------------------------------------------------------------
namespace interfaces
{
	class outside_2_WD_if
	{
	public:
		int data[WD_buffer_bandwidth];
	};

	class WD_out_if :public sc_interface
	{
	public:
		int data[Number_of_Cols];
	};

	class WDS_data_in_if :public sc_interface
	{
	public:
		char data[WDS_bandwidth + 1];
		int	 index;
	};

	class WDS_out_if :public sc_interface
	{
	public:
		int data[Number_of_Cols];
	};
}
//----------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------



class CS_if :public sc_interface
{
public:
	char data[Number_of_Cols+1];
};

class FS_if :public sc_interface
{
public:
	char data[4];
};

class crossbar_SH_if : public sc_interface
{
public:
	int data[Number_of_Cols+1];
};

class SH_ADC_if : public sc_interface
{
public:
	int data[Number_of_Cols+1];
};

class ADC_ADDER_if : public sc_interface
{
public:
	int data[Number_of_ADCs+1];
};

class AS_if : public sc_interface
{
public:
	char data[Number_of_ADCs+1];
};

class ADDER_out_if : public sc_interface
{
public:
	long long data[Number_of_Cols / datatype_size+1];
};


typedef tlm::tlm_nonblocking_put_if<interfaces::outside_2_RD_if> 			port_outside_2_RD_if;
typedef tlm::tlm_nonblocking_put_if<interfaces::outside_2_WD_if> 			port_outside_2_WD_if;
typedef tlm::tlm_nonblocking_put_if<interfaces::inCtrl_2_outside_RD_if> 	port_inCtrl_2_outside_RD_if;
typedef tlm::tlm_nonblocking_put_if<interfaces::inCtrl_2_outside_WD_if> 	port_inCtrl_2_outside_WD_if;