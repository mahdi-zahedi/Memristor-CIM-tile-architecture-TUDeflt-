/***************************************************************************
 * class: CIM tile simulator testbench
 *
 * description: 

 * version number: 1 (17-08-2019)
 *
 * authors: Mahdi Zahedi (m.z.zahedi@tudelft.nl)
 ***************************************************************************/

#include <systemc.h>
#include <iostream>
#include "Cim_Tile.h"

using namespace std;

int sc_main(int argc, char* argv[])
{
	ofstream				memfile;
	memfile.open("DispCrossbar_final.txt");
	int Total_Energy=0;
	Cim_Tile CIM_Tile_ins("Cim_Tile");
	sc_clock my_clk("clock", clock_period, SC_NS, 0.5, 0, SC_NS, true);
	CIM_Tile_ins.clock(my_clk);	

	//----------------------------------------------------------------------
	//----------------------------------------------------------------------
	sc_trace_file* Tf = sc_create_vcd_trace_file("traces");
	sc_trace(Tf, my_clk, "clk");

	//sc_trace(Tf, CIM_Tile_ins.decoder_ins.clock, "decoder clock");
	sc_trace(Tf, CIM_Tile_ins.decoder_ins.RD_buffer_flipper, "RD_buffer_flipper");
	sc_trace(Tf, CIM_Tile_ins.decoder_ins.RDS_flipper, "RDS_flipper");
	sc_trace(Tf, CIM_Tile_ins.decoder_ins.WD_flipper, "WD_flipper");
	sc_trace(Tf, CIM_Tile_ins.decoder_ins.WDS_flipper, "WDS_flipper");
	sc_trace(Tf, CIM_Tile_ins.decoder_ins.FS_flipper, "FS_flipper");
	
	sc_trace(Tf, CIM_Tile_ins.p_DoA, "DoA data");
	sc_trace(Tf, CIM_Tile_ins.p_done_crossbar, "Done_Crossbar data");

	sc_trace(Tf, CIM_Tile_ins.p_DoS, "DoS data");
	sc_trace(Tf, CIM_Tile_ins.p_done_SH, "p_done_SH data");

	sc_trace(Tf, CIM_Tile_ins.decoder_ins.CSR_flipper, "CSR_flipper");
	sc_trace(Tf, CIM_Tile_ins.p_DoR, "DoR data");
	sc_trace(Tf, CIM_Tile_ins.p_done_ADC, "p_done_ADC data");

	sc_trace(Tf, CIM_Tile_ins.p_LS, "p_LS");
	sc_trace(Tf, CIM_Tile_ins.p_IADD, "p_IADD");
	sc_trace(Tf, CIM_Tile_ins.p_CP, "p_CP");
	sc_trace(Tf, CIM_Tile_ins.decoder_ins.AS_flipper, "AS_flipper");
	sc_trace(Tf, CIM_Tile_ins.p_CB, "p_CB");
	//----------------------------------------------------------------------
	//----------------------------------------------------------------------
	
	sc_start(simulation_time, SC_NS);
	CIM_Tile_ins.DIM_Crossbar_ins.dispMem(memfile);
	Total_Energy = CIM_Tile_ins.DIM_Crossbar_ins.energy_consumption + CIM_Tile_ins.ADC_ins.energy_consumption + CIM_Tile_ins.SH_ins.energy_consumption + CIM_Tile_ins.ADDER_ins.energy_consumption;
	cout << "******************************************************************" << endl;
	cout << "CIM_Tile_ins.DIM_Crossbar_ins.energy_consumption " << CIM_Tile_ins.DIM_Crossbar_ins.energy_consumption/1000000 << " uj" << endl;
	cout << "CIM_Tile_ins.ADC_ins.energy_consumption " << CIM_Tile_ins.ADC_ins.energy_consumption << " pj" << endl;
	cout << "CIM_Tile_ins.ADC_ins.temp " << CIM_Tile_ins.ADC_ins.temp2 << endl;
	cout << CIM_Tile_ins.decoder_ins.temp2 << endl;
	cout << "CIM_Tile_ins.SH_ins.energy_consumption " << CIM_Tile_ins.SH_ins.energy_consumption/1000 << " nj" << endl;

	cout << "Total energy= " << Total_Energy << " pj";
	sc_close_vcd_trace_file(Tf);

	return 1;
}



