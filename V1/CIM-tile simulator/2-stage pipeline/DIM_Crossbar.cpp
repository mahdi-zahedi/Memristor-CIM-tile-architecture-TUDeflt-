#include "DIM_Crossbar.h"

DIM_Crossbar::DIM_Crossbar(sc_module_name nm) : sc_module(nm)
, p_done_crossbar(0), energy_consumption(0)
{
	memfile.open("DispCrossbar_init.txt");
	intMem = new int[Number_of_Rows * Number_of_Cols];
	intMem_init(intMem); // initialize the crossbar just for the first time.
	dispMem(memfile);
	SC_THREAD(execution);
		sensitive << p_DoA.pos();
	dont_initialize();
}

DIM_Crossbar::~DIM_Crossbar()
{}

void DIM_Crossbar::intMem_init(int* memory) 
{
	srand(time(NULL));
	for (int i = 0; i < Number_of_Rows; i++) {
		for (int k = 0; k < Number_of_Cols; k++) {
			*(memory + k + i * Number_of_Cols) = rand() % memristor_level;
		}
	}
}

void DIM_Crossbar::dispMem(ofstream& dispMem)
{
	for (int i = 0; i < Number_of_Rows; i++) {
		for (int k = 0; k < Number_of_Cols; k++) {
			dispMem << *(intMem + k + i * Number_of_Cols);
		}
		dispMem << endl;
	}
}

void DIM_Crossbar::execution()
{	
	srand(time(NULL));
	while (true)
	{		
		p_done_crossbar.write(0);
		bool Row_selected = 0;
		int row, column = 0;
		
		//------------------perform write operation on crossbar--------------------------------------------------
		//cout << "p_WDS= ";
		//for (int i = 0; i < Number_of_Cols; i++)
			//cout << p_WDS->data[i];
		//cout << endl;

		//cout << "p_WD= ";
		//for (int i = 0; i < Number_of_Cols; i++)
			//cout << p_WD->data[i];
		//cout << endl;


		if (strcmp(p_FS->data, "WR") == 0)
		{
			for (row = 0; row < Number_of_Rows; row++) // Note: It is not possible to write to more than one rows at the same time
			{
				if (p_RS->data[row] == 1)
				{
					Row_selected = 1;
					break;
				}
			}
			if (Row_selected == 0)
				cout << "Error: In WR nano-instruction, no row was selected" << endl;


			for (column = 0; column < Number_of_Cols; column++)
			{				
				if (p_WDS->data[column] == 1)
				{
					if ((rand() % 10000) >= write_fault_probability)
					{
						*(intMem + row * Number_of_Rows + Number_of_Cols - 1 - column) = p_WD->data[column];
					}
					else
					{
						*(intMem + row * Number_of_Rows + Number_of_Cols - 1 - column) = !((bool)p_WD->data[column]);
					}

					//energy_consumption = energy_consumption + write_energy;
					energy_consumption = energy_consumption + dim_crossbar_write_delay * (write_voltage[0] * write_current[0] + write_DIM_power);
				}
			}			
			if (mode_def == 1) //using counter inside controller
				for (int i = 1; i <= crossbar_counter; i++) // It's the number of cycles that represents crossbar delay (minus one due to the above reason)
					wait(clock_period, SC_NS);
			else
				wait(dim_crossbar_write_delay, SC_NS);

			p_done_crossbar.write(1);
			
		}
		//------------------perform read operation on crossbar, also for verify------------------------------------
		else if (strcmp(p_FS->data, "RD") == 0 || strcmp(p_FS->data, "VRF") == 0)
		{
			for (row = 0; row < Number_of_Rows; row++) // Note: We have to select just one row
			{
				if (p_RS->data[row] == 1)
				{
					Row_selected = 1;
					break;
				}
			}
			if (Row_selected == 0)
				cout << "Error: In RD nano-instruction, no row was selected" << endl;

			for (column = 0; column < Number_of_Cols; column++)
			{
				ToSH->data[Number_of_Cols-1-column] = (*(intMem + row * Number_of_Cols + column));
				energy_consumption = energy_consumption + dim_crossbar_read_delay * (pow(read_voltage[0], 2) / cell_resistance[*(intMem + row * Number_of_Cols + column)]);
			}
			energy_consumption = energy_consumption + dim_crossbar_read_delay * read_DIM_power; // just one DIM is active for read operation

			if (mode_def == 1) //using counter inside controller
				for (int i = 1; i <= crossbar_counter; i++) // It's the number of cycles that represents crossbar delay (minus one due to the above reason)
					wait(clock_period, SC_NS);
			else
				wait(dim_crossbar_read_delay, SC_NS);
			p_done_crossbar.write(1);
			
		}
		//------------------perform VMM operation on crossbar-----------------------------------------------------
		else if (strcmp(p_FS->data, "VMM") == 0)
		{
			for (column = 0; column < Number_of_Cols; column++) // Initilize data to zero
				ToSH->data[column]=0;

			for (row = 0; row < Number_of_Rows; row++) // Note: We can select more than one row
				if (p_RS->data[row] != 0 && p_RD->data[row] != 0)
				{
					
					for (column = 0; column < Number_of_Cols; column++)
					{
						ToSH->data[Number_of_Cols-1-column]=((*(intMem + row * Number_of_Cols + column)) * p_RD->data[row] + ToSH->data[Number_of_Cols - 1 - column]);
						energy_consumption = energy_consumption + dim_crossbar_read_delay * (pow(read_voltage[0], 2) / cell_resistance[*(intMem + row * Number_of_Cols + column)]);
					}
					energy_consumption = energy_consumption + dim_crossbar_read_delay * read_DIM_power;
				}
			
			if (mode_def == 1) //using counter inside controller
				for (int i = 1; i <= crossbar_counter; i++) // It's the number of cycles that represents crossbar delay (minus one due to the above reason)
					wait(clock_period, SC_NS);
			else
				wait(dim_crossbar_read_delay, SC_NS);
			p_done_crossbar.write(1);
			
		}
		//------------------perform AND operation on crossbar-----------------------------------------------------		
		else if (strcmp(p_FS->data, "AND") == 0)
		{
			for (int row1 = 0; row1 < Number_of_Rows; row1++) // Note: We can just select two rows (RS has to has binary value)
			{
				if (p_RS->data[row1] == 1)
				{
					for (int row2 = row1+1; row2 < Number_of_Rows; row2++)
					{
						if (p_RS->data[row2] == 1)
						{
							for (column = 0; column < Number_of_Cols; column++)
							{
								ToSH->data[Number_of_Cols-1-column] = (*(intMem + row1 * Number_of_Cols + column)) * (*(intMem + row2 * Number_of_Cols + column));
								energy_consumption = energy_consumption + dim_crossbar_read_delay * (pow(read_voltage[0], 2) / cell_resistance[*(intMem + row1 * Number_of_Cols + column)] + read_DIM_power);
								energy_consumption = energy_consumption + dim_crossbar_read_delay * (pow(read_voltage[0], 2) / cell_resistance[*(intMem + row2 * Number_of_Cols + column)] + read_DIM_power);
							}
							break;
						}
					}
					break;
				}
			}		

			if (mode_def == 1) //using counter inside controller
				for (int i = 1; i <= crossbar_counter; i++) // It's the number of cycles that represents crossbar delay (minus one due to the above reason)
					wait(clock_period, SC_NS);
			else
				wait(dim_crossbar_read_delay, SC_NS);
			p_done_crossbar.write(1);		
		}
		//------------------perform OR operation on crossbar-----------------------------------------------------
		else if (strcmp(p_FS->data, "OR") == 0)
		{
			for (int row1 = 0; row1 < Number_of_Rows; row1++) // Note: We can just select two rows (RS has to has binary value)
			{
				if (p_RS->data[row1] == 1)
				{
					for (int row2 = row1+1; row2 < Number_of_Rows; row2++)
					{
						if (p_RS->data[row2] == 1)
						{
							for (column = 0; column < Number_of_Cols; column++)
							{
								ToSH->data[Number_of_Cols-1-column] = ((*(intMem + row1 * Number_of_Cols + column)) | (*(intMem + row2 * Number_of_Cols + column)));
								energy_consumption = energy_consumption + dim_crossbar_read_delay * (pow(read_voltage[0], 2) / cell_resistance[*(intMem + row1 * Number_of_Cols + column)] + read_DIM_power);
								energy_consumption = energy_consumption + dim_crossbar_read_delay * (pow(read_voltage[0], 2) / cell_resistance[*(intMem + row2 * Number_of_Cols + column)] + read_DIM_power);
							}
							break;
						}
					}
					break;
				}
			}
			if (mode_def == 1) //using counter inside controller
				for (int i = 1; i <= crossbar_counter; i++) // It's the number of cycles that represents crossbar delay (minus one due to the above reason)
					wait(clock_period, SC_NS);
			else
				wait(dim_crossbar_read_delay, SC_NS);
			p_done_crossbar.write(1);
		}
		//------------------perform XOR operation on crossbar-----------------------------------------------------
		else if (strcmp(p_FS->data, "XOR") == 0)
		{
			for (int row1 = 0; row1 < Number_of_Rows; row1++) // Note: We can just select two rows (RS has to has binary value)
			{
				if (p_RS->data[row1] == 1)
				{
					for (int row2 = row1+1; row2 < Number_of_Rows; row2++)
					{
						if (p_RS->data[row2] == 1)
						{
							for (column = 0; column < Number_of_Cols; column++)
							{
								ToSH->data[Number_of_Cols-1-column] = ((*(intMem + row1 * Number_of_Cols + column)) ^ (*(intMem + row2 * Number_of_Cols + column)));
								energy_consumption = energy_consumption + dim_crossbar_read_delay * (pow(read_voltage[0], 2) / cell_resistance[*(intMem + row1 * Number_of_Cols + column)] + read_DIM_power);
								energy_consumption = energy_consumption + dim_crossbar_read_delay * (pow(read_voltage[0], 2) / cell_resistance[*(intMem + row2 * Number_of_Cols + column)] + read_DIM_power);
							}
							break;
						}
					}
					break;
				}
			}
			if (mode_def == 1) //using counter inside controller
				for (int i = 1; i <= crossbar_counter; i++) // It's the number of cycles that represents crossbar delay (minus one due to the above reason)
					wait(clock_period, SC_NS);
			else
				wait(dim_crossbar_read_delay, SC_NS);
			p_done_crossbar.write(1);
		}

		wait();
	}
}