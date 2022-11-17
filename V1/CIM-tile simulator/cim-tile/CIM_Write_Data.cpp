#include "CIM_Write_Data.h"

CIM_Write_Data::CIM_Write_Data(sc_module_name nm) : sc_module(nm)
	, WD_buffer_counter("WD_buffer_counter")
{
	WD_buffer_counter = 1;
	s_WDb = 0; s_nb_put = 0;
	p_outside_2_WD.bind(*this);

	SC_THREAD(clock_pos);
	sensitive << clock.pos();
	SC_THREAD(clock_neg);
	sensitive << clock.neg();

	SC_THREAD(WDb);
	sensitive << clock.pos();
	dont_initialize();
	SC_THREAD(WDSb);
	sensitive << clock.pos();
	dont_initialize();
	SC_THREAD(WDSc);
	sensitive << clock.pos();
	dont_initialize();
	SC_THREAD(WDSs);
	sensitive << clock.pos();
	dont_initialize();
	SC_METHOD(WD_buffer_counter_update);
	sensitive << s_WDb << s_nb_put;
	dont_initialize();
}

CIM_Write_Data::~CIM_Write_Data()
{}

void CIM_Write_Data::clock_pos()
{
	wait();
}

void CIM_Write_Data::clock_neg()
{
	wait();
}


void CIM_Write_Data::WDb()
{
	//cout << "increasing WD_buffer_counter at " << sc_time_stamp() << endl;
	// put WD_buffer to WD register! decrease the counter
	clock_pos();  // we used neg_edge to prevent any conflict due to the multi drivers for WD buffer counter
	for (int i = 0; i < WD_buffer_bandwidth; i++)
	{
		WD_register[WD_buffer_bandwidth * (p_WD_index_int)+i] = WD_buffer[0][i];
		p_WD_out->data[WD_buffer_bandwidth * (p_WD_index_int)+i] = WD_register[WD_buffer_bandwidth * (p_WD_index_int)+i];

		//p_WD_out->data[Number_of_Cols - WD_buffer_bandwidth * (p_WD_index_int + 1) + i] = WD_register[Number_of_Cols - WD_buffer_bandwidth * (p_WD_index_int + 1) + i];
		for(int j=0; j<WD_buffer_counter;j++)
			WD_buffer[j][i] = WD_buffer[j+1][i];
	}
	s_WDb = 1;
	//WD_buffer_counter = WD_buffer_counter - 1;
}

void CIM_Write_Data::WDSb()
{
	//put WDS_data to WDS register!
	clock_pos();
	for (int i = 0; i < WDS_bandwidth; i++)
	{
		WDS_register[Number_of_Cols - WDS_bandwidth * (p_WDS_in->index + 1) + i] = (p_WDS_in->data[i]-'0');
		p_WDS_out->data[Number_of_Cols - WDS_bandwidth * (p_WDS_in->index + 1) + i] = WDS_register[Number_of_Cols - WDS_bandwidth * (p_WDS_in->index + 1) + i];
	}
}

void CIM_Write_Data::WDSc()
{
	clock_pos();
	for (int i = 0; i < Number_of_Cols; i++)
	{
		WDS_register[i] = 0;
		p_WDS_out->data[i] = WDS_register[i];
	}
}

void CIM_Write_Data::WDSs()
{
	clock_pos();
	for (int i = 0; i < Number_of_Cols; i++)
	{
		WDS_register[i] = 1;
		p_WDS_out->data[i] = WDS_register[i];
	}
}

bool CIM_Write_Data::nb_put(const interfaces::outside_2_WD_if& t)
{
	//timing clock_pos is added to the outside controller
	
	for (int i = 0; i < WD_buffer_bandwidth; i++)
	{
		//cout << "t outside controller WD = " << t.data[i] << endl;
		WD_buffer[WD_buffer_counter][i] = t.data[i];
	}
	s_nb_put = 1;
	//WD_buffer_counter = WD_buffer_counter + 1;
	return 1;
}
bool CIM_Write_Data::nb_can_put(tlm_tag<interfaces::outside_2_WD_if>* t) const
{return 0;}

const sc_core::sc_event& CIM_Write_Data::ok_to_put(tlm_tag<interfaces::outside_2_WD_if>* t) const
{
	return dummy;
}

void CIM_Write_Data::WD_buffer_counter_update()
{
	if (s_WDb == 1 && s_nb_put == 1)
	{
		WD_buffer_counter = WD_buffer_counter;
		s_WDb = 0; s_nb_put = 0;
	}
	else if (s_WDb == 0 && s_nb_put == 1)
	{
		//cout << "increasing WD_buffer_counter at " << sc_time_stamp() << endl;
		WD_buffer_counter = WD_buffer_counter + 1;
		s_nb_put = 0;
	}
	else if (s_WDb == 1 && s_nb_put == 0)
	{
		//cout << "decreasing WD_buffer_counter at " << sc_time_stamp() << endl;
		WD_buffer_counter = WD_buffer_counter - 1;
		s_WDb = 0;
	}
	//cout << "WD_buffer_counter_update = " << WD_buffer_counter << endl;
}
