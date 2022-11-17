#include "CIM_Row_Data.h"

CIM_Row_Data::CIM_Row_Data(sc_module_name nm) : sc_module(nm)
{
	p_outside_2_RD.bind(*this);

	SC_THREAD(clock_pos);
	sensitive << clock.pos();
	SC_THREAD(clock_neg);
	sensitive << clock.neg();

	SC_THREAD(RDsh);
	dont_initialize();
	SC_THREAD(RDSri);
	dont_initialize();
	SC_THREAD(RDSb);
	dont_initialize();
	SC_THREAD(RDSc);
	dont_initialize();
	SC_THREAD(RDSs);
	dont_initialize();
}

CIM_Row_Data::~CIM_Row_Data()
{}

void CIM_Row_Data::clock_pos()
{
	wait();
}

void CIM_Row_Data::clock_neg()
{
	wait();
}


void CIM_Row_Data::RDsh()
{
	clock_pos();
	for (int i = 0; i < Number_of_Rows; i++)
	{
		p_RD_out->data[i] = RD_buffer[i][0];
	}
	for (int i = 0; i < Number_of_Rows; i++)
	{
		for (int j = 0; j < RD_buffer_width; j++)
		{
			RD_buffer[i][j] = RD_buffer[i][j+1];
		}
	}
	
}

void CIM_Row_Data::RDSri()
{
	int row_index = 0;
	clock_pos();
	for (int i = 0; i < p_RDS_in->index; i++) // Put the data chunk in RS register
	{
		for (int j = 0; j < (int)log2(Number_of_Rows); j++)
		{
			row_index += (int)pow(2, log2(Number_of_Rows) - j - 1) * (p_RDS_in->data[j + i * (int)log2(Number_of_Rows)] - '0');
		}
		RDS_register[row_index] = 1;
		p_RDS_out->data[row_index] = RDS_register[row_index];
		row_index = 0;
	}
}

void CIM_Row_Data::RDSb()
{
	clock_pos();
	for (int i = 0; i < RDS_bandwidth; i++)
	{
		RDS_register[RDS_bandwidth * p_RDS_in->index + i] = (p_RDS_in->data[i] - '0');
		p_RDS_out->data[RDS_bandwidth * p_RDS_in->index + i] = RDS_register[RDS_bandwidth * p_RDS_in->index + i];
	}
}

void CIM_Row_Data::RDSc()
{
	clock_pos();
	for (int i = 0; i < Number_of_Rows; i++)
	{
		RDS_register[i] = 0;
		p_RDS_out->data[i] = RDS_register[i];
	}
	
}

void CIM_Row_Data::RDSs()
{
	clock_pos();
	for (int i = 0; i < Number_of_Rows; i++)
	{
		RDS_register[i] = 1;
		p_RDS_out->data[i] = RDS_register[i];
	}
}

// TLM interface with outside controller 
bool CIM_Row_Data::nb_put(const interfaces::outside_2_RD_if& t)
{
	// do not add delay here! it was already added in CIM_Outside_Controller  
	for(int i=0;i<RD_buffer_width;i++)
		RD_buffer[t.index][i]= t.data[i];
	return 1;
}

bool CIM_Row_Data::nb_can_put(tlm_tag<interfaces::outside_2_RD_if>* t) const
{return 0;}

const sc_core::sc_event& CIM_Row_Data::ok_to_put(tlm_tag<interfaces::outside_2_RD_if>* t) const
{
	return dummy;
}