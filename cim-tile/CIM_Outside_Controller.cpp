#include "CIM_Outside_Controller.h"

CIM_Outside_Controller_RD::CIM_Outside_Controller_RD(sc_module_name nm) : sc_module(nm), free_flag(0)
{

	p_inCtrl_2_outside_RD.bind(*this);
	temp_RD_data = new interfaces::outside_2_RD_if;

	SC_THREAD(clock_pos);
	sensitive << clock.pos();
	SC_THREAD(clock_neg);
	sensitive << clock.neg();

	SC_THREAD(send_2_RD);
	sensitive << clock.pos();
	dont_initialize();

	RD_file.open(RD_file_path, fstream::in);
}

CIM_Outside_Controller_RD::~CIM_Outside_Controller_RD()
{}

//-------------------------------------------------------------------------------------------------------------

void CIM_Outside_Controller_RD::clock_pos()
{
	wait();
}

void CIM_Outside_Controller_RD::clock_neg()
{
	wait();
}

void CIM_Outside_Controller_RD::send_2_RD()
{
	while (true)
	{
		clock_pos();
		if (s_send_2_RD == 1)
		{
			free_flag = 0;
			char* RD_index_char = new char[(int)log2(Number_of_Rows) + 1];
			char* RD_data_char = new char[RD_buffer_width + 1];

			for (int j = 0; j < Number_of_Rows; j++)
			{
				getline(RD_file, line);
				if (RD_file.eof())
					break;
				istringstream iss(line);
				iss >> RD_index_char;
				iss >> RD_data_char;
				RD_data_int = 0;

				for (int i = 0; i < log2(Number_of_Rows); i++)
					RD_data_int += pow(2, (int)log2(Number_of_Rows) - i - 1) * (RD_index_char[i] - '0');
				temp_RD_data->index = RD_data_int;
				for (int i = 0; i < RD_buffer_width; i++)
				{
					temp_RD_data->data[RD_buffer_width - i - 1] = RD_data_char[i] - '0';
				}

				clock_pos();
				p_outside_2_RD->nb_put(*temp_RD_data);
				cout << "outside controller send data to RD buffer at " << sc_time_stamp() << endl;
			}
			cout << "***********outside controller for RD buffer is done at " << sc_time_stamp() << endl;
			e_ready.notify();
			free_flag = 1;
			s_send_2_RD = 0;
		}
	}
}

bool CIM_Outside_Controller_RD::nb_can_put(tlm_tag<interfaces::inCtrl_2_outside_RD_if>* t) const
{
	return free_flag;
}

const sc_core::sc_event& CIM_Outside_Controller_RD::ok_to_put(tlm_tag<interfaces::inCtrl_2_outside_RD_if>* t) const
{
	return e_ready; 
}

bool CIM_Outside_Controller_RD::nb_put(const interfaces::inCtrl_2_outside_RD_if& t)
{
	s_send_2_RD = 1;; // in future we can add more functionality here if the outside controller should do something else 
	return 1;
}

//**********************************************************************
//**********************************************************************
//**********************************************************************
//**********************************************************************

CIM_Outside_Controller_WD::CIM_Outside_Controller_WD(sc_module_name nm, CIM_Write_Data* CIM_WD_obj) : sc_module(nm)
	, free_flag(0)
	, s_send_2_WD(0)
	, CIM_WD_object(CIM_WD_obj)
{

	p_inCtrl_2_outside_WD.bind(*this);
	temp_WD_data = new interfaces::outside_2_WD_if;

	SC_THREAD(clock_pos);
	sensitive << clock.pos();
	SC_THREAD(clock_neg);
	sensitive << clock.neg();
	//dont_initialize();

	SC_THREAD(send_2_WD);
	sensitive << clock.pos();
	dont_initialize();

	WD_file.open(WD_file_path, fstream::in);
}

CIM_Outside_Controller_WD::~CIM_Outside_Controller_WD()
{}

//-------------------------------------------------------------------------------------------------------------
void CIM_Outside_Controller_WD::clock_pos()
{
	wait();
}

void CIM_Outside_Controller_WD::clock_neg()
{
	wait();
}

void CIM_Outside_Controller_WD::send_2_WD()
{
	char* WD_data_char = new char[WD_buffer_bandwidth + 1];
	while (true)
	{	
		clock_pos();
		if (s_send_2_WD == 1)
		{
			free_flag = 0;
			while (CIM_WD_object->WD_buffer_counter != Number_of_Cols / WD_buffer_bandwidth)
			{
				getline(WD_file, line);
				istringstream iss(line);
				iss >> WD_data_char;
				//cout << "outside controller WD file = " << WD_data_char << endl;
				for (int i = 0; i < WD_buffer_bandwidth; i++)
				{
					temp_WD_data->data[WD_buffer_bandwidth - i - 1] = WD_data_char[i] - '0';
				}

				p_outside_2_WD->nb_put(*temp_WD_data);
				e_ready.notify();
				free_flag = 1;
				cout << "Outside_Controller_WD increased the counter by one at " << sc_time_stamp() << endl;
				clock_pos();
				
			}
			
			cout << "Outside_Controller_WD is done at " << sc_time_stamp() << endl;
			s_send_2_WD = 0;
		}
	}
	
}

bool CIM_Outside_Controller_WD::nb_can_put(tlm_tag<interfaces::inCtrl_2_outside_WD_if>* t) const
{
	return free_flag;
}

const sc_core::sc_event& CIM_Outside_Controller_WD::ok_to_put(tlm_tag<interfaces::inCtrl_2_outside_WD_if>* t) const
{
	return e_ready;
}

bool CIM_Outside_Controller_WD::nb_put(const interfaces::inCtrl_2_outside_WD_if& t)
{
	s_send_2_WD = 1;
	// in future we can add more functionality here if the outside controller should do something else 
	return 1;
}