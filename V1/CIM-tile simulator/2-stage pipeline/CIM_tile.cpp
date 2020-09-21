#include "CIM_tile.h"

Cim_Tile::Cim_Tile(sc_module_name nm)
	: sc_module(nm)
	, decoder_ins("decoder", &Write_Data_ins, &Row_Data_ins, &DIM_Crossbar_ins, &ADC_ins)
	, Outside_Controller_RD_ins("Outside_Controller_RD")
	, Outside_Controller_WD_ins("Outside_Controller_WD", &Write_Data_ins)
	, Write_Data_ins("Write_Data")
	, Row_Data_ins("Row_Data")
	, DIM_Crossbar_ins("DIM_Crossbar")
	, SH_ins("S&H")
	, ADC_ins("ADC")
	, ADDER_ins("ADDER", &Write_Data_ins)
	
	, clock("clock")	
	, p_done_crossbar("p_done_crossbar")
	, p_done_SH("p_done_SH")
	, p_done_ADC("p_done_ADC")
	, p_verify_result("p_verify_result")
	, p_DoA("p_DoA")
	, p_DoS("p_DoS")
	, p_DoR("p_DoR")	
	, p_LS("p_LS")
	, p_IADD("p_IADD")
	, p_AS_activation("p_AS_activation")
	, p_CP("p_CP")
	, p_CB("p_CB")
	, p_adder_activation("p_adder_activation")
	, p_logical_operation("p_logical_operation")
	, p_write_verify("p_write_verify")
	, p_WD_index_int("p_WD_index_int")
	
{
	//************************input to decoder*************************
	decoder_ins.clock(clock);
	decoder_ins.p_done_crossbar(p_done_crossbar);
	decoder_ins.p_done_SH(p_done_SH);
	decoder_ins.p_done_ADC(p_done_ADC);
	decoder_ins.p_verify_result(p_verify_result);

	//*************************output of decoder***********************
	decoder_ins.p_inCtrl_2_outside_RD.bind(Outside_Controller_RD_ins.p_inCtrl_2_outside_RD);
	decoder_ins.p_inCtrl_2_outside_WD.bind(Outside_Controller_WD_ins.p_inCtrl_2_outside_WD);

	decoder_ins.p_RDS_in(p_RDS_in);
	decoder_ins.p_WDS_data_in(p_WDS_in);
	decoder_ins.p_WD_index_int(p_WD_index_int);

	decoder_ins.p_CS(p_CS);
	decoder_ins.p_FS.bind(DIM_Crossbar_ins.p_FS);
	decoder_ins.p_AS(p_AS);
	
	decoder_ins.p_adder_activation(p_adder_activation);
	decoder_ins.p_DoA(p_DoA);
	decoder_ins.p_DoS(p_DoS);
	decoder_ins.p_DoR(p_DoR);
	decoder_ins.p_LS(p_LS);
	decoder_ins.p_IADD(p_IADD);
	decoder_ins.p_CP(p_CP);	
	decoder_ins.p_AS_activation(p_AS_activation);
	decoder_ins.p_logical_operation(p_logical_operation);
	decoder_ins.p_write_verify(p_write_verify);	
	decoder_ins.p_CB(p_CB);
	decoder_ins.p_BNE_flag(p_BNE_flag);

	//*************input/output to outside controller RD************************
	Outside_Controller_RD_ins.clock(clock);
	Outside_Controller_RD_ins.p_outside_2_RD.bind(Row_Data_ins.p_outside_2_RD);
	//p_inCtrl_2_outside_RD;
	
	//*************input/output to outside controller WD************************
	Outside_Controller_WD_ins.clock(clock);
	Outside_Controller_WD_ins.p_outside_2_WD.bind(Write_Data_ins.p_outside_2_WD);
	//p_inCtrl_2_outside_WD;

	//*************input/output to Row Data*************************************
	Row_Data_ins.clock(clock);
	//p_outside_2_RD;
	Row_Data_ins.p_RDS_in(p_RDS_in);
	Row_Data_ins.p_RD_out(p_RD);
	Row_Data_ins.p_RDS_out(p_RS);
	//*************input/output to Write Data***********************************
	Write_Data_ins.clock(clock);
	//p_outside_2_WD;
	Write_Data_ins.p_WDS_in(p_WDS_in);
	Write_Data_ins.p_WD_index_int(p_WD_index_int);
	Write_Data_ins.p_WD_out(p_WD);
	Write_Data_ins.p_WDS_out(p_WDS);
	//*******************************************************************
	DIM_Crossbar_ins.p_DoA(p_DoA);
	DIM_Crossbar_ins.p_RD(p_RD);
	DIM_Crossbar_ins.p_RS(p_RS);
	DIM_Crossbar_ins.p_WD(p_WD);
	DIM_Crossbar_ins.p_WDS(p_WDS);
	DIM_Crossbar_ins.p_FS(p_FS);		
	DIM_Crossbar_ins.ToSH(p_crossbar_data);
	DIM_Crossbar_ins.p_done_crossbar(p_done_crossbar);
	//*******************************************************************
	SH_ins.In_data(p_crossbar_data);
	SH_ins.p_DoS(p_DoS);
	SH_ins.ToADC(p_SH_To_ADC);
	SH_ins.p_done_SH(p_done_SH);
	//*******************************************************************
	ADC_ins.clock(clock);
	ADC_ins.p_In_data(p_SH_To_ADC);
	ADC_ins.p_column_select(p_CS);
	ADC_ins.p_DoR(p_DoR);
	ADC_ins.p_done_ADC(p_done_ADC);
	ADC_ins.output(p_ADC_ADDER);
	//*******************************************************************
	ADDER_ins.clock(clock);
	ADDER_ins.In_data(p_ADC_ADDER);
	ADDER_ins.p_column_select(p_CS);
	ADDER_ins.p_WD(p_WD);
	ADDER_ins.p_WDS(p_WDS);
	ADDER_ins.p_LS(p_LS);
	ADDER_ins.p_IADD(p_IADD);
	ADDER_ins.p_AS(p_AS);
	ADDER_ins.p_CP(p_CP);
	ADDER_ins.p_AS_activation(p_AS_activation);
	ADDER_ins.p_CB(p_CB);
	ADDER_ins.p_adder_activation(p_adder_activation);
	ADDER_ins.p_logical_operation(p_logical_operation);
	ADDER_ins.p_write_verify(p_write_verify);
	ADDER_ins.p_verify_result(p_verify_result);
	ADDER_ins.p_done_ADC(p_done_ADC);
	ADDER_ins.p_BNE_flag(p_BNE_flag);
	ADDER_ins.out(ADDER_out);	
	//*******************************************************************	
	SC_THREAD(start);
	sensitive << clock.pos();
}

Cim_Tile::~Cim_Tile()
{}

void Cim_Tile::start()
{
	cout << "Mode is\t" << mode_def << "-- 1 means using counter inside the controller" << endl;
	cout << endl;
}