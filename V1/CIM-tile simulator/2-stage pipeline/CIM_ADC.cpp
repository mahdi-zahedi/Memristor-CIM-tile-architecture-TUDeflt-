#include "CIM_ADC.h"

CIM_ADC::CIM_ADC(sc_module_name nm) : sc_module(nm)
, p_done_ADC(0),energy_consumption(0)
{
	SC_THREAD(clock_pos);
	sensitive << clock.pos();
	SC_THREAD(clock_neg);
	sensitive << clock.neg();

	SC_THREAD(execution);
	sensitive << e_activation << clock.pos();
	dont_initialize();
}

CIM_ADC::~CIM_ADC()
{}

void CIM_ADC::clock_pos()
{
	wait();
}

void CIM_ADC::clock_neg()
{
	wait();
}

void CIM_ADC::execution()
{

	while (true)
	{
		wait(e_activation);
		temp2++;
		p_done_ADC.write(0);
		
		int j = 0; 
		for (int i = 0; i < Number_of_ADCs; i++)
		{
			int temp = 0; 
			for (int j = 0; j < Number_of_Cols / Number_of_ADCs; j++)
			{
				if (p_column_select->data[i * (Number_of_Cols / Number_of_ADCs) + j] == '1')
				{
					output->data[i] = p_In_data->data[i * (Number_of_Cols / Number_of_ADCs) + j];
					temp = 1;
					energy_consumption = energy_consumption + ADC_energy;
					break;
				}
			}

			if (temp == 0)
			{
				output->data[i] = 0;
			}
		}

		if (mode_def == 1) //using counter inside controller
			for (int i = 1; i <= ADC_counter_def; i++)
				wait(clock_period, SC_NS);
		else
			wait(ADC_delay_def, SC_NS);

		p_done_ADC.write(1);
	}
}

void CIM_ADC::activation()
{
	e_activation.notify();
}

