#include "CIM_SH.h"

CIM_SH::CIM_SH(sc_module_name nm) : sc_module(nm)
, p_done_SH(0), energy_consumption(0)
{
	SC_THREAD(execution);
	sensitive << p_DoS.pos();
	dont_initialize();
}

CIM_SH::~CIM_SH()
{}


void CIM_SH::execution()
{
	while (true)
	{
		p_done_SH.write(0);
		cout << "SH = ";
		for (int i = 0; i < Number_of_Cols; i++)
		{
			ToADC->data[i] = In_data->data[i];
			cout << In_data->data[i] << " ";
			energy_consumption = energy_consumption + SH_energy;
		}
		cout << endl;
		
		if (mode_def == 1) //using counter inside controller
			for (int i = 1; i <= SH_counter_def; i++) // It's the number of cycles that S&H takes
				wait(clock_period, SC_NS);
		else
			wait(SH_delay_def, SC_NS);
		p_done_SH.write(1);
		
		wait(); // wait for next DoA signal
	}
}

