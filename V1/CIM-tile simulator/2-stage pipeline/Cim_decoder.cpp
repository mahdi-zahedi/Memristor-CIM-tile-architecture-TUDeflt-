#include "CIM_decoder.h"
#include <math.h>

CIM_decoder::CIM_decoder(sc_module_name nm, CIM_Write_Data* CIM_WD_obj, CIM_Row_Data* CIM_RD_obj, DIM_Crossbar* DIM_Crossbar_obj)  : sc_module(nm)
			, p_DoA("p_DoA")
			, p_DoS("p_DoS")
			, p_DoR("p_DoR")
			, p_FS("p_FS")
			, p_CS("p_CS")

			, p_done_crossbar("p_done_crossbar") // comes from crossbar
			, p_done_SH("p_done_SH") // comes from S&H
			, p_done_ADC("p_done_ADC") // comes from ADC
			, p_verify_result("p_verify_result")

			, p_LS("p_LS")
			, p_IADD("p_IADD")
			, p_AS("p_AS")
			, p_CP("p_CP")
			, p_CB("p_CB")
			, p_AS_activation("p_AS_activation")
			
			, sc_done_crossbar("sc_done_crossbar")
			, sc_done_SH("sc_done_SH")
			, sc_done_ADC("sc_done_ADC")
			, first_iteration("first_iteration")
			, flag_IADD("flag_IADD")
			, p_adder_activation("p_adder_activation")
			, busy_flag_S2("busy_flag_S2")

			, CIM_WD_object(CIM_WD_obj)
			, CIM_RD_object(CIM_RD_obj) 
			, DIM_Crossbar_object(DIM_Crossbar_obj)
			
			, p_inCtrl_2_outside_RD("p_inCtrl_2_outside_RD")
			, p_inCtrl_2_outside_WD("p_inCtrl_2_outside_WD")
			, p_RDS_in("p_RDS_in")
			, p_WDS_data_in("p_WDS_data_in")
			, p_WD_index_int("p_WD_index_int")

			, RDS_flipper(0)
			, RD_buffer_flipper(0)
			, WD_flipper(0)
			, WDS_flipper(0)
			, CSR_flipper(0)
			, FS_flipper(0)
			, RD_buffer_counter(0)
			
{	
		
	first_iteration.write(true);
	sc_done_crossbar = 1; sc_done_SH = 0; sc_done_ADC = 1; flag_IADD = 0; sc_done_CSR = 1;
	first_CS = false; read_finished_flag = 1; inst_bypass_flag = 0;
	PC1 = 0; PC2 = 0; Number_Of_wrong_write = 0;
	branch_register_s1 = std::numeric_limits<int>::max();
	jump_register_s2 = std::numeric_limits<int>::max();
	branch_register_s2 = std::numeric_limits<int>::max();

	CS_index = new char[log2(Number_of_Cols / Number_of_ADCs) + 1];
	CS_select_data = new char[Number_of_ADCs + 1];

	SC_THREAD(clock_pos);
	sensitive << clock.pos();
	dont_initialize();
	SC_THREAD(clock_neg);
	sensitive << clock.neg();
	dont_initialize();
//------------------------------------------------
	SC_THREAD(fun_done_crossbar);
	sensitive << p_done_crossbar.pos();
	//dont_initialize();
	SC_THREAD(fun_done_SH);
	sensitive << p_done_SH.pos();
	//dont_initialize();
	SC_THREAD(fun_done_ADC);
	sensitive << p_done_ADC.pos();
	//dont_initialize();

	SC_THREAD(signals_update);
	sensitive <<  s_write_verify << s_DoR << s_adder_activation << s_logical_operation;
	//dont_initialize();

//--------------------------------------------------------
//--------------------------------------------------------
	SC_METHOD(func_wait_for_outside_RD)
	sensitive << e_wait_for_outside_RD;
	SC_METHOD(func_wait_for_outside_WD)
	sensitive << e_wait_for_outside_WD;
//--------------------------------------------------------

	SC_THREAD(stage1_decode);
	sensitive << e_done_outside_RD << event_done_crossbar << event_busy_flag_2 << event_BNE << event_clock_pos;
	dont_initialize();

	SC_THREAD(stage2_decode);
	sensitive << event_done_SH << event_done_ADC << event_clock_pos;
	dont_initialize();

	SC_THREAD(stage1_exe);
	sensitive << event_stage1_exe << event_clock_pos;
	dont_initialize();

	SC_THREAD(stage2_exe);
	sensitive << event_stage2_exe << event_clock_pos;
	dont_initialize();
	//------------------------------------------------
	infile1.open(nanoInst_stage_1, fstream::in);
	infile2.open(nanoInst_stage_2, fstream::in);
	//------------------------------------------------
	
}

CIM_decoder::~CIM_decoder()
{
	delete[] CS_index;
	delete[] CS_select_data;
}

// just need to do double check and add the skipping mechanism for WVF
void CIM_decoder::stage1_decode()
{				
	enum s1_opcode {
		FS,
		RDSb,
		RDSri,
		RDSc,
		RDSs,
		RDsh,
		WDb,
		WDSb,
		WDSc,
		WDSs,
		DoA,
		DoS,
		NOP
	};
	map<string, s1_opcode>			s1_opcode1;
	s1_opcode1["FS"]	=			FS;
	s1_opcode1["RDSb"]	=			RDSb;
	s1_opcode1["RDSri"] =			RDSri;
	s1_opcode1["RDSc"]	=			RDSc;
	s1_opcode1["RDSs"]	=			RDSs;
	s1_opcode1["RDsh"]	=			RDsh;
	s1_opcode1["WDb"]	=			WDb;
	s1_opcode1["WDSb"]	=			WDSb;
	s1_opcode1["WDSc"]	=			WDSc;
	s1_opcode1["WDSs"]	=			WDSs;
	s1_opcode1["DoA"]	=			DoA;
	s1_opcode1["DoS"]	=			DoS;
	s1_opcode1["NOP"]	=			NOP;

	bool	waited					= 0;
	int		WDS_chunk_cnt			= 0;
	bool	RDsh_first_iteration	= 1;
	string line;
	//wait(clock_period, SC_NS);
	wait(SC_ZERO_TIME);

	while (getline(infile1, line) && !infile1.eof())
	{
		//cout << "new instruction ... " << sc_time_stamp() << endl;
		PC1++;
		cout << "PC1 = " << PC1 << endl;
		istringstream iss1(line);
		iss1 >> s1_string_opcode1;
		//cout << "the decoded instruction is " << s1_string_opcode1 << " at " << sc_time_stamp() << endl;
		//clock_neg();
		//cout << "the decoded instruction is " << s1_string_opcode1 << " at " << sc_time_stamp() << endl;
		//wait(SC_ZERO_TIME);
		
		
		for (int i = 1; i <= fetch_and_decoding_delay_cycle; i++) // It's the number of cycles that decoding takes
			wait(event_clock_pos);
		
		p_DoS = false;
		p_DoA = false;

		wait(SC_ZERO_TIME);
		s1_string_opcode2 = s1_string_opcode1;
		
		switch (s1_opcode1[s1_string_opcode1])
		{
			case RDSb:
			{
				cout << "RDSb is decoded at " << sc_time_stamp() << endl;
				if (inst_bypass_flag)
					break;
				char* RDSb_index= new char [(int)log2(Number_of_Rows/RDS_bandwidth)+1]; 				
				char* RDSb_chunk_size = new char[RDS_bandwidth + 1];
				
				iss1 >> RDSb_index;
				iss1 >> RDSb_chunk_size;
				int RDSb_index_int=0;
				
				
				for (int i = 1; i <= (int)log2(Number_of_Rows / RDS_bandwidth); i++)
				{
					RDSb_index_int += pow(2, (int)log2(Number_of_Rows / RDS_bandwidth)-i)*(RDSb_index[i-1] - '0');
				}
			
				for (int i = 0; i < RDS_bandwidth; i++)
					p_RDS_in->data[i] = *(RDSb_chunk_size + i);
				
				p_RDS_in->data[RDS_bandwidth] = NULL;
				p_RDS_in->index = RDSb_index_int;

				
				event_stage1_exe.notify();
				//CIM_RD_object->RDSb();				

				delete[] RDSb_index;
				delete[] RDSb_chunk_size;

				break;
			}
			case RDSc:
			{				
				cout << "RDSc is decoded at " << sc_time_stamp() << endl;
				if (inst_bypass_flag)
					break;				
				//wait(SC_ZERO_TIME);
				event_stage1_exe.notify();
				
				break;
			}
			case RDSs:
			{				
				if (inst_bypass_flag)
					break;
				cout << "RDSs is decoded at " << sc_time_stamp() << endl;
				event_stage1_exe.notify();
				//CIM_RD_object->RDSs();

				break;
			}
			case RDSri:
			{				
				if (inst_bypass_flag)
					break;
				char* RDSri_index = new char[ceil(log2((RDS_bandwidth/log2(Number_of_Rows))))+1];
				char* RDSri_data_size = new char[RDS_bandwidth + 1];

				iss1 >> RDSri_index;
				iss1 >> RDSri_data_size;

				int RDSri_index_int = 1;
				for (int i = 0; i < strlen(RDSri_index); i++) // determine how many chunks are passed in the instruction 
				{
					RDSri_index_int += (int)pow(2, ceil(log2((RDS_bandwidth / log2(Number_of_Rows)))) - (i + 1)) * (RDSri_index[i] - '0');
				}

				for (int i = 0; i++; i < RDS_bandwidth)
					p_RDS_in->data[i] = *(RDSri_data_size + i);
				p_RDS_in->data[RDS_bandwidth] = NULL;
				p_RDS_in->index = RDSri_index_int;
				
				cout << "RDSri is decoded at " << sc_time_stamp() << endl;
				event_stage1_exe.notify();
				//CIM_RD_object->RDSri();				

				delete[] RDSri_index;
				delete[] RDSri_data_size;
									
				break; 
			}
			case RDsh:
			{				
				interfaces::inCtrl_2_outside_RD_if dummy;
				if (RDsh_first_iteration)
				{
					p_inCtrl_2_outside_RD->nb_put(dummy);
					e_wait_for_outside_RD.notify();
					wait(e_done_outside_RD);
					RD_buffer_counter = 0;
					RDsh_first_iteration = 0;
				}
				else if (RD_buffer_counter == RD_buffer_width) // if the outside controller is still busy with filling the buffer (means we cannot put new request)
				{
					if(!p_inCtrl_2_outside_RD->nb_can_put())
						wait(e_done_outside_RD);
				
					RD_buffer_counter = 0;
				}
				
				cout << "RDsh is decoded ... " << sc_time_stamp() << endl;
				event_stage1_exe.notify();
				//CIM_RD_object->RDsh();
				
				
				break;
			}
			case WDb:
			{	
				//--------------------------------------------------------------------------------------
				//--------------------------------------------------------------------------------------
				cout << "WDb is decoded at " << sc_time_stamp() << endl;
				wait(SC_ZERO_TIME); // to give time for updating the WD_buffer_counter 
				if (inst_bypass_flag)
					break;
				char* WD_index = new char[log2(Number_of_Cols / WD_buffer_bandwidth) + 1];
				interfaces::inCtrl_2_outside_WD_if dummy;
				iss1 >> WD_index;								
						
				int WD_index_int = 0;
				for (int i = 0; i < strlen(WD_index); i++) // determine where to place the data chunk
				{
					WD_index_int += (int)pow(2, strlen(WD_index) - (i + 1)) * (WD_index[i] - '0');
				}
				p_WD_index_int = WD_index_int; // send index to CIM_Write_Data class
				
				if (CIM_WD_object->WD_buffer_counter == 0) // in future, we can make it more complex by filling the buffer while the counter does not even come to the end!
				{
					//wait(SC_ZERO_TIME);
					p_inCtrl_2_outside_WD->nb_put(dummy); // in this implementation, when we get to this line, for sure the last request to fill the buffer already done!
					e_wait_for_outside_WD.notify();
					wait(e_done_outside_WD); 
					wait(SC_ZERO_TIME);
				}
				if (CIM_WD_object->WD_buffer_counter == 1) // in future, we can make it more complex by filling the buffer while the counter does not even come to the end!			
					p_inCtrl_2_outside_WD->nb_put(dummy);
				

				event_stage1_exe.notify();
				//CIM_WD_object->WDb();
			
				delete[] WD_index;
				break;
			}
			case WDSb:
			{
				//--------------------------------------------------------------------------------------
				//--------------------------------------------------------------------------------------
				if (inst_bypass_flag)
					break;
				char* WDS_index = new char[log2(Number_of_Cols/WDS_bandwidth)+1];
				char* WDS_data = new char[RDS_bandwidth + 1];

				iss1 >> WDS_index;
				iss1 >> WDS_data;

				int WDS_index_int = 0;
				for (int i = 0; i < strlen(WDS_index); i++) // determine how many chunks are passed in the instruction 
				{
					WDS_index_int += (int)pow(2, strlen(WDS_index) - (i + 1)) * (WDS_index[i] - '0');
				}
				
				p_WDS_data_in->index = WDS_index_int;
				for(int i=0;i< WDS_bandwidth;i++)
					p_WDS_data_in->data[i] = WDS_data[i]; 
		
				cout << "WDSb is decoded at " << sc_time_stamp() << endl;
				event_stage1_exe.notify();
				//CIM_WD_object->WDSb();

				delete[] WDS_index;
				delete[] WDS_data;
				break;
			}
			case WDSc:
			{
				if (inst_bypass_flag)
					break;
				cout << "WDSc is decoded at " << sc_time_stamp() << endl;
				event_stage1_exe.notify();
				//CIM_WD_object->WDSc();	

				break;
			}
			case WDSs:
			{
				if (inst_bypass_flag)
					break;
				cout << "WDSs is decoded at " << sc_time_stamp() << endl;
				event_stage1_exe.notify();
				//CIM_WD_object->WDSs();

				break;
			}
			case FS:
			{							
				if (sc_done_crossbar == 0)
					wait(event_done_crossbar);
				iss1 >> p_FS->data;
				event_stage1_exe.notify();			
				cout << "FS is decoded at " << sc_time_stamp() << endl;
				break;
			}
			case DoA:
			{
				cout << "DoA is decoded at " << sc_time_stamp() << endl;
				p_DoA=true;	
				sc_done_crossbar = 0;
				//--------------------------------------------------------------------------------------													
				break;
			}
			case DoS:
			{		
				cout << "DoS is decoded at " << sc_time_stamp() << endl;
				// no execute stage for DoS - All is combinational logic 			
				if (sc_done_crossbar==0)
					wait(event_done_crossbar);				

				if (busy_flag_S2 == 1)
					wait(event_busy_flag_2);					
				
				sc_done_SH = 0;
				p_DoS = true;
				first_CS = true;
				wait(SC_ZERO_TIME);
				busy_flag_S2 = 1; // make this stage busy
				read_finished_flag = 0;
						
				//event_busy_flag_2.notify();
				strcpy(FS_buffer.data, p_FS->data);

				if (strcmp(p_FS->data, "VRF") == 0)
				{
					wait(event_BNE);
					cout << "BNE event received " << sc_time_stamp() << endl;
					if (p_verify_result == 1) // branch taken
					{						
						wait(event_clock_pos); // clock was added to fill the PC register with new address
						//sc_done_SH = 0; // to stop executing CS 
						PC1 = branch_register_s1 - 1;
						inst_bypass_flag = 1;

						infile1.seekg(0, ios::beg);
						for (int i = 1; i < branch_register_s1; i++) // skip branch_register - 1 lines so next getline gets proper line
							getline(infile1, line);

					}
					else
					{
						//clock_pos();
						inst_bypass_flag = 0;
					}
				}
				cout << "DoS is done at " << sc_time_stamp() << endl;
				
				break;
			}
			case NOP:
			{
				cout << "*************End of stage 1 instruction file ***************" << endl;
				break;
			}
			default:
			{
				cout << "s1_string_opcode1" << s1_string_opcode1 << endl;
				cout << "Error! Wrong opcode" << endl;
				break;
			}
		}
	}

}

void CIM_decoder::stage2_decode()
{	
	enum s2_opcode {
		CSR,
		jal,
		jr,
		BNE,
		LS,
		IADD,
		CP,
		AS,
		CB,
		NOP
	};
	map<string, s2_opcode>		s2_opcode1;
	s2_opcode1["CSR"]		=	CSR;
	s2_opcode1["jal"]		=	jal;
	s2_opcode1["jr"]		=	jr;
	s2_opcode1["BNE"]		=	BNE;
	s2_opcode1["LS"]		=	LS;
	s2_opcode1["IADD"]		=	IADD;
	s2_opcode1["CP"]		=	CP;
	s2_opcode1["AS"]		=	AS;
	s2_opcode1["CB"]		=	CB;
	s2_opcode1["NOP"]		=	NOP;
	bool waited				=	0;
	int WDS_chunk_cnt		=	0;
	
	string line;
	wait(SC_ZERO_TIME);

	while (getline(infile2, line) && !infile2.eof())
	{
		PC2++;
		cout << "PC2 = " << PC2 << endl;
		istringstream iss(line);
		iss >> s2_string_opcode1;
		wait(SC_ZERO_TIME);

		for (int i = 1; i <= fetch_and_decoding_delay_cycle; i++) // It's the number of cycles that decoding takes
			wait(event_clock_pos);
		
		p_CP = 0;
		p_IADD = 0;
		p_CB = 0;
		s2_string_opcode2 = s2_string_opcode1;

		//if (!busy_flag_S2)
		//	wait(event_busy_flag_2);

		switch (s2_opcode1[s2_string_opcode1])
		{
		case CSR:
		{							
			cout << "CSR is decoded at " << sc_time_stamp() << endl;	
			//-------------------------------------------------------------------
			if (read_finished_flag == 1)
			{
				busy_flag_S2 = 0;
				event_busy_flag_2.notify();
				wait(event_done_SH);
			}
			//-------------------------------------------------------------------
			if (sc_done_ADC == 0)
				wait(event_done_ADC);
			sc_done_ADC = 0;
			p_BNE_flag = 0;
			//sc_done_CSR = 0;
			event_stage2_exe.notify();
			iss >> CS_index;
			iss >> CS_select_data;
			
			break;
		}
		case jal:
		{
			int temp;
			iss >> temp;
			wait(event_clock_pos); // This clock was added to fill the PC with new address
			cout << "Jal already done at " << sc_time_stamp() << endl;
			infile2.seekg(0, ios::beg);
			for (int i = 0; i < temp; i++) // skip jump_register - 1 lines so next getline gets proper line
				getline(infile2, line);
							
			jump_register_s2 = PC2;
			PC2 = temp;
			break;
		}
		case jr:
		{
			if (sc_done_ADC == 0)
				wait(event_done_ADC);
			//p_BNE_flag = 0;
			cout << "Jr decoded at " << sc_time_stamp() << endl;
			wait(event_clock_pos); // This clock was added to fill the PC with new address

			s_DoR = false;
			s_adder_activation = 0;
			s_logical_operation = 0;
			s_write_verify = 0;
			read_finished_flag = 1;
			if (jump_register_s2 == std::numeric_limits<int>::max())
				break;
			cout << "Jr already done at " << sc_time_stamp() << endl;

			infile2.seekg(0, ios::beg);
			for (int i = 0; i < jump_register_s2; i++) // skip jump_register lines so next getline gets line after jal
				getline(infile2, line);

			PC2 = jump_register_s2;
			//jump_register_s2 = std::numeric_limits<int>::max();

			break;
		}
		case BNE:
		{			
			// if the branch taken, means we have to add one clock cycle since we flush the decode stage			
			cout << "BNE is decoded at " << sc_time_stamp() << endl;
			
			if (sc_done_ADC == 0)
				wait(event_done_ADC);
			event_BNE.notify();
			cout << "BNE is ready to check for jump at " << sc_time_stamp() << endl;
			if (p_verify_result)
			{				
				// Now branch back to FS VRF...
				wait(event_clock_pos);
				cout << "BNE already jumped at " << sc_time_stamp() << endl;
				infile2.seekg(0, ios::beg);
				for (int i = 0; i < branch_register_s2 - 1; i++) // skip jump_register lines so next getline gets line after jal
					getline(infile2, line);

				PC2 = branch_register_s2 - 1;
				cout << "PC after BNE = " << PC2 << endl;
				Number_Of_wrong_write++;
			}
			else
			{
				cout << "cnt 2: correct write: continue as usual" << endl;
			}
			p_BNE_flag = 1;
			busy_flag_S2 = 0;
			break;
		}
		case LS:
		{
	
			for (int i = 0; i < latency_of_third_addition-4; i++) // -4: 1clk->LS 2clk->Jal 1clk->CSR decode
				wait(event_clock_pos);
			p_LS = 1;			
			
			cout << "LS instruction decoded and finished at:\t" << sc_time_stamp() << endl;
			break;
		}

		case IADD:
		{				
			cout << "IADD instruction decoded at:\t" << sc_time_stamp() << endl;
			p_LS = 0;
			//p_CP = 0;	
					
			if (ADC_resolution >= (Number_of_Rows) * (memristor_level - 1))
			{
				//wait(event_clock_pos);
				//wait(event_clock_pos);
			}
			else
			{
				//wait(event_clock_pos);
				wait(event_clock_pos); // two 8-bit adder next to each other 
				//wait(event_clock_pos);
			}
			p_IADD = 1;
			
			cout << "IADD instruction finished at:\t" << sc_time_stamp() << endl;
			break;
		}

		case CP:  
		{
			for (int i = 0; i < latency_of_third_addition-1; i++) //IADD latency
				wait(event_clock_pos); // get IADD data ready

			p_CP = 1;
			p_AS_activation = 0;
			cout << "CP instruction finished at:\t" << sc_time_stamp() << endl;
			break;
		}

		case AS:
		{		
			iss >> p_AS->data;		// -----> pass the the data for LS
			event_stage2_exe.notify();
			for (int i = 0; i < latency_of_final_addition; i++)
				wait(event_clock_pos); //stall the execution till one cycle before AS gets done 

			cout << "AS in controller decode stage is done at " << sc_time_stamp() << endl;
			p_AS_activation = 0;
			p_CB = 0;
			
			break;
		}

		case CB:
		{
			p_CB = 1;
			cout << "CB instruction finished at:\t" << sc_time_stamp() << endl;
			break;
		}
		
		case NOP:
		{
			cout << "*************End of stage 2 instruction file ***************" << endl;
			cout << "Number of wrong write = " << Number_Of_wrong_write << endl;
			break;
		}
		default:
		{
			cout << "Error! Wrong opcode" << endl;
			break;
		}
		}
	}
}

void CIM_decoder::stage1_exe()
{
	enum s1_opcode {
		FS,
		RDSb,
		RDSri,
		RDSc,
		RDSs,
		RDsh,
		WDb,
		WDSb,
		WDSc,
		WDSs,
		DoA,
		DoS
	};
	map<string, s1_opcode>			s1_opcode1;
	s1_opcode1["FS"]		=		FS;
	s1_opcode1["RDSb"]		=		RDSb;
	s1_opcode1["RDSri"]		=		RDSri;
	s1_opcode1["RDSc"]		=		RDSc;
	s1_opcode1["RDSs"]		=		RDSs;
	s1_opcode1["RDsh"]		=		RDsh;
	s1_opcode1["WDb"]		=		WDb;
	s1_opcode1["WDSb"]		=		WDSb;
	s1_opcode1["WDSc"]		=		WDSc;
	s1_opcode1["WDSs"]		=		WDSs;
	s1_opcode1["DoA"]		=		DoA;
	s1_opcode1["DoS"]		=		DoS;

	while (true)
	{
		wait(event_stage1_exe);
		switch (s1_opcode1[s1_string_opcode2])
		{
		case RDSb:
		{
			CIM_RD_object->RDSb();
			cout << "RDSb is done at " << sc_time_stamp() << endl;
			if (RDS_flipper == 0)
				RDS_flipper = 1;
			else
				RDS_flipper = 0;

			break;
		}
		case RDSc:
		{
			CIM_RD_object->RDSc();
			cout << "RDSc is done at " << sc_time_stamp() << endl;
			if (RDS_flipper == 0)
				RDS_flipper = 1;
			else
				RDS_flipper = 0;

			break;
		}
		case RDSs:
		{
			CIM_RD_object->RDSs();
			cout << "RDSs is done at " << sc_time_stamp() << endl;
			if (RDS_flipper == 0)
				RDS_flipper = 1;
			else
				RDS_flipper = 0;

			break;
		}
		case RDSri:
		{
			CIM_RD_object->RDSri();
			cout << "RDSri is done at " << sc_time_stamp() << endl;
			if (RDS_flipper == 0)
				RDS_flipper = 1;
			else
				RDS_flipper = 0;

			break;
		}
		case RDsh:
		{
			interfaces::inCtrl_2_outside_RD_if dummy;
			if (RD_buffer_counter == RD_buffer_width-1) // check before the RD buffer gets empty					
				p_inCtrl_2_outside_RD->nb_put(dummy);// dummy is used to pass dummy data to nb_put()

			CIM_RD_object->RDsh();
			RD_buffer_counter++;
			cout << "RDsh is done at ... " << sc_time_stamp() << endl;
			if (RD_buffer_counter == RD_buffer_width) // check the RD buffer is empty or not 					
				RD_buffer_counter = 0;

			if (RD_buffer_flipper == 0)
				RD_buffer_flipper = 1;
			else
				RD_buffer_flipper = 0;

			break;
		}
		case WDb:
		{
			CIM_WD_object->WDb();
			cout << "WDb is done at ... " << sc_time_stamp() << endl;
			if (WD_flipper == 0)
				WD_flipper = 1;
			else
				WD_flipper = 0;
			break;
		}
		case WDSb:
		{
			CIM_WD_object->WDSb();
			cout << "WDSb is done at ... " << sc_time_stamp() << endl;
			if (WDS_flipper == 0)
				WDS_flipper = 1;
			else
				WDS_flipper = 0;
			break;
		}
		case WDSc:
		{
			CIM_WD_object->WDSc();
			cout << "WDSc is done at ... " << sc_time_stamp() << endl;
			if (WDS_flipper == 0)
				WDS_flipper = 1;
			else
				WDS_flipper = 0;
			break;
		}
		case WDSs:
		{
			CIM_WD_object->WDSs();
			cout << "WDSs is done at ... " << sc_time_stamp() << endl;
			if (WDS_flipper == 0)
				WDS_flipper = 1;
			else
				WDS_flipper = 0;
			break;
		}
		case FS:
		{
			wait(event_clock_pos);
			if (strcmp(p_FS->data, "WR") == 0) // I think the crossbar delay depends on number of rows and columns which are going to be activated
			{
				branch_register_s1 = PC1-1;
				DIM_Crossbar_object->crossbar_counter = DIM_Crossbar_counter_write;
				FS_flipper = 1;
			}
			else if (strcmp(p_FS->data, "RD") == 0 || strcmp(p_FS->data, "VRF") == 0)
			{
				DIM_Crossbar_object->crossbar_counter = DIM_Crossbar_counter_read;
				FS_flipper = 2;
			}
			else if (strcmp(p_FS->data, "VMM") == 0)
			{
				DIM_Crossbar_object->crossbar_counter = DIM_Crossbar_counter_read;
				FS_flipper = 3;
			}
			else if (strcmp(p_FS->data, "AND") == 0 || strcmp(p_FS->data, "OR") == 0 || strcmp(p_FS->data, "XOR") == 0)
			{
				DIM_Crossbar_object->crossbar_counter = DIM_Crossbar_counter_read;
				FS_flipper = 4;
			}
			//-----------------------------------------------------------------------------------------------				
			cout << "FS is done at " << sc_time_stamp() << endl;
			break;
		}
		default:
		{
			cout << "Error! Wrong opcode";
			break;
		}
		}
	}
}

void CIM_decoder::stage2_exe()
{
	enum s2_opcode {
		CSR,
		jal,
		jr,
		BNE,
		LS,
		IADD,
		CP,
		AS,
		CB
	};
	map<string, s2_opcode>			s2_opcode1;
	s2_opcode1["CSR"]		=		CSR;
	s2_opcode1["jal"]		=		jal;
	s2_opcode1["jr"]		=		jr;
	s2_opcode1["BNE"]		=		BNE;
	s2_opcode1["LS"]		=		LS;
	s2_opcode1["IADD"]		=		IADD;
	s2_opcode1["CP"]		=		CP;
	s2_opcode1["AS"]		=		AS;
	s2_opcode1["CB"]		=		CB;

	while (true)
	{
		wait(event_stage2_exe);
		//clock is embedded in each instruction

		switch (s2_opcode1[s2_string_opcode2])
		{
		case CSR:
		{	
			wait(event_clock_pos); // to fill in the CS register and issue DoR

			//-------------flag initialization ----------------------------------
			if (strcmp(FS_buffer.data, "VMM") == 0)
				s_adder_activation = 1;
			else if (strcmp(FS_buffer.data, "VRF") == 0)
				s_write_verify = 1;
			else
				s_logical_operation = 1;
			//-------------------------------------------------------------------

			int CS_index_int = 0;
			for (int i = 0; i < log2(Number_of_Cols / Number_of_ADCs); i++) // determine where to place the data chunk
			{
				CS_index_int += (int)pow(2, log2(Number_of_Cols / Number_of_ADCs) - (i + 1)) * (CS_index[i] - '0');
			}

			
			for (int i = 0; i < (Number_of_Cols / Number_of_ADCs); i++)
			{
				if (i == CS_index_int)
				{
					for (int j = 0; j < Number_of_ADCs; j++)
					{
						p_CS->data[j * Number_of_Cols / Number_of_ADCs + i] = CS_select_data[Number_of_ADCs-1-j];
					}
				}
				else
				{
					for (int j = 0; j < Number_of_ADCs; j++)
					{
						p_CS->data[j * Number_of_Cols / Number_of_ADCs + i] = '0';
					}
				}
			}
			//-------------------------------------------------------------------
			s_DoR = true;

			if (first_CS == true)
			{
				first_CS = false;
				branch_register_s2 = PC2-1; 
			}

			if (CSR_flipper == 0)
				CSR_flipper = 1;
			else
				CSR_flipper = 0;

			cout << "CSR is done at " << sc_time_stamp() << endl;
			break;
		}
		case AS:
		{
			
			wait(event_clock_pos);
			p_AS_activation = 1;
			for (int i = 0; i < latency_of_final_addition; i++)
				wait(event_clock_pos); //stall the execution till one cycle before AS gets done 

			cout << "AS in controller exe_stage is done at " << sc_time_stamp() << endl;
			if (AS_flipper == 0)
				AS_flipper = 1;
			else
				AS_flipper = 0;
			break;
		}
		default:
		{
			cout << "Error! Wrong opcode";
			break;
		}
		}
	}

}

//-----------------------------------------------
//-----------------------------------------------
void CIM_decoder::clock_pos()
{
	while (true)
	{
		wait();
		event_clock_pos.notify();
	}
}
void CIM_decoder::clock_neg()
{
	while (true)
	{
		wait();
		event_clock_neg.notify();
	}
}
//------------------------------------------------
//------------------------------------------------

void CIM_decoder::fun_done_crossbar()
{
	while (true)
	{
		wait();
		sc_done_crossbar=1;
		event_done_crossbar.notify();
	}	
}
void CIM_decoder::fun_done_SH()
{
	while (true)
	{
		wait();
		sc_done_SH=1;
		event_done_SH.notify();		
	}
}
void CIM_decoder::fun_done_ADC()
{
	while (true)
	{
		wait();
		sc_done_ADC=1;
		event_done_ADC.notify();
	}
}

//----------------------------------------------
//----------------------------------------------
void CIM_decoder::func_wait_for_outside_RD()
{	

	if (p_inCtrl_2_outside_RD->nb_can_put())
		e_done_outside_RD.notify();
	else
		next_trigger(p_inCtrl_2_outside_RD->ok_to_put());
}
void CIM_decoder::func_wait_for_outside_WD()
{	
	if (p_inCtrl_2_outside_WD->nb_can_put())
	{
		e_done_outside_WD.notify();
		cout << "nb_can_put granted at " << sc_time_stamp() << endl;
	}
	else
	{
		cout << "next_trigger for outside WD at " << sc_time_stamp() << endl;
		next_trigger(p_inCtrl_2_outside_WD->ok_to_put());
		
	}
}

void CIM_decoder::signals_update()
{
	while (true)
	{
		wait();
		p_DoR = s_DoR;
		p_adder_activation = s_adder_activation;
		p_write_verify = s_write_verify;
		p_logical_operation = s_logical_operation;
		//wait(SC_ZERO_TIME);
		//cout << "p_write_verify " << p_write_verify << " " << p_write_verify << endl;		
	}
}


