#include "CIM_ADDER.h"

CIM_ADDER::CIM_ADDER(sc_module_name nm, CIM_Write_Data* CIM_WD_obj) : sc_module(nm), CIM_WD_object(CIM_WD_obj)
	, clock("clock")
	, In_data("In_data")
	, p_column_select("p_column_select")
	, p_WD("p_WD")
	, p_WDS("p_WDS")
	, p_LS("p_LS")
	, p_IADD("p_IADD")
	, p_CP("p_CP")
	, p_AS("p_AS")
	, p_AS_activation("p_AS_activation")
	, p_CB("p_CB")
	, p_adder_activation("p_adder_activation")
	, p_logical_operation("p_logical_operation")
	, p_write_verify("p_write_verify")
	, p_verify_result("p_verify_result")
	, out("out")
{
	//---------------------------------------------------------------------------
	//----------------------------Initialization of temp registers---------------
	for (int i = 0; i < Number_of_Cols; i++)
		primary_registers[i] = 0;
	for (int i = 0; i < int(Number_of_temp_primary_registers); i++)
		temp_primary_registers[i] = 0;
	for (int i = 0; i < int(Number_of_temp_secondary_registers); i++)
		temp_secondary_registers[i] = 0;
	for (int i = 0; i < int(Number_of_Cols / datatype_size); i++)
		final_temp[i] = 0;
	//---------------------------------------------------------------------------
	outputfile.open("outputfile_after_addition.txt");
	logical_operation_file.open("logical_operation_file.txt");
	//---------------------------------------------------------------------------
	LS = 0;
	shift = 0;
	energy_consumption = 0;
	//---------------------------------------------------------------------------
	SC_THREAD(clock_pos);
		sensitive << clock.pos();
	SC_THREAD(clock_neg);
		sensitive << clock.neg();
		
	SC_THREAD(registered_ADC_out)
		sensitive << event_done_ADC << clock.pos();
		dont_initialize();
	SC_THREAD(LS_function);
		sensitive << p_LS.pos();
		dont_initialize();
	
	
	//-------------------scheme 1 where we have low precision ADC----------------
	SC_THREAD(primary_addition);
		sensitive << event_primary_addition << clock.pos();
	dont_initialize();		
	SC_THREAD(secondary_addition_scheme1) 
		sensitive << primary_addition_done << clock.pos();
	dont_initialize();

	//-------------------scheme 2 where we have high precision ADC---------------
	SC_THREAD(secondary_addition_scheme2)
		sensitive << event_secondary_addition << clock.pos();
	dont_initialize();
	//-----------------------------------------------------------------

	SC_THREAD(third_addition)
		sensitive << p_IADD.pos() << clock.pos();
	dont_initialize();
	SC_THREAD(coppy_per_ADC)
		sensitive << p_CP.pos() << clock.pos();
	dont_initialize();
	SC_THREAD(Adder_select)
		sensitive << p_AS_activation.pos() << clock.pos();
	dont_initialize();
	SC_THREAD(coppy_between_ADC);
		sensitive << p_CB.pos() << clock.pos();
	dont_initialize();
	SC_THREAD(logical_operation_out);
		sensitive << clock.pos() << event_done_ADC;
	dont_initialize();
	SC_THREAD(write_verify);
		sensitive << clock.pos() << event_done_ADC;
	dont_initialize();
	SC_METHOD(fun_done_ADC);
		sensitive << p_done_ADC.pos();
	SC_METHOD(p_verify_result_update);
	sensitive << s_verify_result << p_BNE_flag.pos();
}

CIM_ADDER::~CIM_ADDER()
{}

void CIM_ADDER::clock_pos()
{
	wait();
}

void CIM_ADDER::clock_neg()
{
	wait();
}

void CIM_ADDER::LS_function()
{
	while (true)
	{		
		LS = 1;
		wait();
	}
}


void CIM_ADDER::registered_ADC_out()
{
	while (true)
	{
		wait(event_done_ADC);
		clock_pos();
		if (p_adder_activation == 1)
		{
			for (int i = 0; i < Number_of_Cols; i++)
				cs_register.data[i] = p_column_select->data[i];

			for (int i = 0; i < Number_of_ADCs; i++)
			{
				ADDER_inputs.data[i] = In_data->data[i];
				cout << "ADDER_inputs.data[i] = " << ADDER_inputs.data[i] << " at " << sc_time_stamp() << endl;
			}
			
			if (ADC_resolution >= (Number_of_Rows) * (memristor_level - 1))
				event_secondary_addition.notify();
			else
				event_primary_addition.notify();
		}
	}
}


void CIM_ADDER::primary_addition()
{
	while (true)
	{			
		wait(event_primary_addition);
		clock_pos();
		for (int i = 0; i < Number_of_Cols; i++)
		{
			if (cs_register.data[i] == '1')
			{
				primary_registers[i] += ADDER_inputs.data[int(i / (Number_of_Cols / Number_of_ADCs))]; // first column of crossbar (MSB) will be in the first register
				cout << "primary_registers[i] " << primary_registers[i] << endl;
				energy_consumption = energy_consumption + primary_adder_energy;
			}
		}		
				
		if (LS == 1)
		{
			primary_addition_done.notify();
		}
		
	}
}

void CIM_ADDER::secondary_addition_scheme1()
{
	while (true)
	{				
		wait(primary_addition_done);
		for (int j = 0; j < Number_of_Cols; j++)
		{
			if (cs_register.data[j] == '1') // primary_registers[0], associated to the first column of the crossbar, contains the MSB of the data
			{
				if (datatype_size >= Number_of_Cols / Number_of_temp_primary_registers)
					temp_primary_registers[int(j / (Number_of_Cols / Number_of_temp_primary_registers))] = pow(2, (j % (Number_of_Cols / int(Number_of_temp_primary_registers)))) * primary_registers[j] + temp_primary_registers[int(j / (Number_of_Cols / Number_of_temp_primary_registers))];				
				else 
					temp_primary_registers[int(j / (Number_of_Cols / Number_of_temp_primary_registers))] = pow(2, (j % datatype_size)) * primary_registers[j] + temp_primary_registers[int(j / (Number_of_Cols / Number_of_temp_primary_registers))];

				energy_consumption = energy_consumption + secondary_adder_energy;
				cout << "temp_primary_registers " << temp_primary_registers[int(j / (Number_of_Cols / Number_of_temp_primary_registers))] << endl;
			}
		}					
	}
}

void CIM_ADDER::secondary_addition_scheme2()
{
	while (true)
	{		
		wait(event_secondary_addition);
		clock_pos();
		cout << "temp_primary_registers = ";
		for (int j = 0; j < Number_of_Cols; j++)
		{
			if (cs_register.data[j] == '1')
			{
				if(datatype_size >= Number_of_Cols / Number_of_temp_primary_registers)
					temp_primary_registers[int(j / (Number_of_Cols / Number_of_temp_primary_registers))] = pow(2,(j % (Number_of_Cols / int(Number_of_temp_primary_registers))))*ADDER_inputs.data[int(j / (Number_of_Cols / Number_of_temp_primary_registers))]+ temp_primary_registers[int(j / (Number_of_Cols / Number_of_temp_primary_registers))];
				else 
					temp_primary_registers[int(j / (Number_of_Cols / Number_of_temp_primary_registers))] = pow(2, (j % datatype_size)) * ADDER_inputs.data[int(j / (Number_of_Cols / Number_of_temp_primary_registers))] + temp_primary_registers[int(j / (Number_of_Cols / Number_of_temp_primary_registers))];

				energy_consumption = energy_consumption + secondary_adder_energy;
				cout << temp_primary_registers[int(j / (Number_of_Cols / Number_of_temp_primary_registers))] << " ";
			}
		}
		cout << " at " << sc_time_stamp() << endl;
	}
}

/*	final addition per column. Three works need to be performed: 1) copy the remaining value of 
	temp_primary register to secondary register 2) reset the temp_primary register 
	3) add the current value of secondary register with
	temp_secondary register and store the result again in temp_secondary register.
	The execution of IADD will be started when IADD decoded which is one clock cycle after the last
	Done received from ADC. While IADD is working, if the LS instruction decoded, we will stop
	its execution in the controller until IADD finishes its work. 
*/ 
void CIM_ADDER::third_addition()  
{
	while (true)
	{	
		clock_pos();
		if (p_IADD == 1)
		{
			for (int i = 0; i < Number_of_Cols; i++)
				primary_registers[i] = 0;
			LS = 0;
			cout << "we are in IADD now at:\t" << sc_time_stamp() << endl;
			//------------------------------------
			for (int i = 0; i < latency_of_third_addition; i++)
				clock_pos();
			cout << "IADD done in the adder unit at:\t" << sc_time_stamp() << endl;
			//------------------------------------
			//cout << "temp_primary_registers[i]" << "\t";
			for (int i = 0; i < Number_of_temp_primary_registers; i++)
			{
				secondary_registers[i] = temp_primary_registers[i];
				temp_primary_registers[i] = 0;
				//cout << secondary_registers[i] << "\t";
			}
			//cout << endl;

			cout << "temp_secondary_registers[i]" << "\t";
			for (int j = 0; j < Number_of_temp_primary_registers; j++)
			{
				temp_secondary_registers[j] += secondary_registers[j] * pow(2, shift); // we assume the number of secondary registers is equal to the number of temp secondary registers
				energy_consumption = energy_consumption + third_adder_energy;
				cout << temp_secondary_registers[j] << " ";
			}
			cout << endl;
			shift++;
		}
		//-----------------------------------------------------------------------------
	}
}
/*	The value per ADC is ready we need to do 2 tasks:
	1) copy the remaining value of temp_secondary register to final_register_per_ADC
	2) reset the temp_secondary register
*/
void CIM_ADDER::coppy_per_ADC()
{
	while (true)
	{
		clock_pos();
		if (p_CP == 1)
		{
			clock_pos();
			//cout << "final_registers_per_ADC" << endl;
			for (int j = Number_of_temp_secondary_registers-1; j >= 0; j--)
			{
				final_registers_per_ADC[j] = temp_secondary_registers[j];
				//cout << final_registers_per_ADC[j] << "\t";
				temp_secondary_registers[j] = 0;
				//----------------------------------------------------
				cout << "final_registers_per_ADC = " << final_registers_per_ADC[j] << endl;
				if (Number_of_ADCs <= (Number_of_Cols / datatype_size))
					outputfile << final_registers_per_ADC[j] << "\t";
				//----------------------------------------------------
			}
			cout << endl;
			//----------------------------------------------------
			if (Number_of_ADCs <= (Number_of_Cols / datatype_size))
				outputfile << endl;
			//----------------------------------------------------
			shift = 0;
			//----------------------------------------------------
		}
	}
}

/*
	AS provides data for select of MUX and at the same time the adder will be activated. 
	After the latency_of_final_addition, final_temp register will be activated and store the result.  
*/
void CIM_ADDER::Adder_select()
{
	while (true)
	{
		clock_pos();
		if (p_AS_activation == 1)
		{
			for (int i = 0; i < latency_of_final_addition-1; i++) // last clk was added at the end 
				clock_pos();

			//------------------------------------		
			for (int i = 0; i < Number_of_ADCs; i++)
			{
				if (p_AS->data[i] == '1')
				{
					final_temp[int(i / (datatype_size / (Number_of_Cols / Number_of_ADCs)))] += final_registers_per_ADC[i] * pow(2, ((Number_of_Cols / Number_of_ADCs) * ((datatype_size / (Number_of_Cols / Number_of_ADCs)) - 1 - (i % (datatype_size / (Number_of_Cols / Number_of_ADCs))))));
					energy_consumption = energy_consumption + forth_adder_energy;
				}

			}

			//cout << "final_temp[i]" << "\t";
			for (int i = 0; i < int(Number_of_final_registers); i++)
			{
				//cout << final_temp[i] << "\t";
			}
			//cout << endl;

		}
	}
}

void CIM_ADDER::coppy_between_ADC()
{
	while (true)
	{
		clock_pos();
		if (p_CB == 1)
		{
			for (int j = Number_of_Cols / datatype_size-1; j >=0 ; j--)
			{
				out->data[j] = final_temp[j];
				outputfile << out->data[j] << "\t";
				final_temp[j] = 0;
			}
			outputfile << endl;
		}
	}
}

void CIM_ADDER::logical_operation_out()
{
	while (true)
	{
		clock_pos();
		if (p_logical_operation == 1)
		{
			for (int i = 0; i < Number_of_Cols; i++)
				cs_register.data[i] = p_column_select->data[i];
			wait(event_done_ADC);
			clock_pos();
			for (int i = 0; i < Number_of_Cols; i++)
				if (cs_register.data[i] == '1')
				{
					logical_operation_file << In_data->data[int(i / (Number_of_Cols / Number_of_ADCs))] << "\t";
				}
			logical_operation_file << endl;

		}
	}
}

// write verify scheme can be modeled more accurately 
void CIM_ADDER::write_verify()
{
	int write_verify_temp[Number_of_Cols] = {0};
	bool verify_result_bool = 0;
	
	while (true)
	{
		wait(event_done_ADC);		
		clock_pos();
		if (p_write_verify == 1)
		{
			//for (int i = 0; i < Number_of_Cols; i++)
				//cs_register.data[i] = p_column_select->data[i];
					
			for (int i = 0; i < Number_of_Cols; i++) // write read value to the verify reg
			{
				if (p_column_select->data[i] == '1')
				{
					//cout << "compare data is: " << In_data->data[int(i / (Number_of_Cols / Number_of_ADCs))] << " " << p_WD->data[i] << endl;
					if (In_data->data[int(i / (Number_of_Cols / Number_of_ADCs))] == (int)(p_WD->data[i]))
					{
						CIM_WD_object->WDS_register[i] = 0;
						CIM_WD_object->p_WDS_out->data[i] = 0; // in future to follow standard HDL rules, we can remove this line by making the port sensitive to the WDS register 
						
					}
					else
					{
						cout << "BBBBBBBBBBBBBBBBB" << endl;
						s_verify_result = true;
						cout << "p_BNE_flag = " << p_BNE_flag << endl;
					}
				}
			}
		}
	}
}


void CIM_ADDER::fun_done_ADC()
{	
	event_done_ADC.notify();	
}

void CIM_ADDER::p_verify_result_update()
{
	p_verify_result = s_verify_result;
	if (p_BNE_flag)
	{
		p_verify_result = 0;
		s_verify_result = 0;
	}
}