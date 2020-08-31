/***************************************************************************
 *
 * @project: Translation of RD/WD data to HDL memory array
 * @version: -
 * @author: Remon van Duijnen (R.F.J.vanDuijnen@student.tudelft.nl)
 *
 ***************************************************************************/

 /****************************description*********************************************

 This script is used to translate the RD/WD data from the compiled tile-program
 It creates 4 files, two for RD (index and data) one for WD and one for delcarations
 The files contain VHDL style array which can be copied/pasted into VHDL code
 This can be used to quickly write data into VHDL for writing to BRAM
 There, the outside controller fetches the data and feeds it to the tile buffers

 *************************************************************************************/

#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include "data2hdl.h"

using namespace std;

void data2hdl()
{
	string line;
	ofstream declarations;
	declarations.open("HDL/declarations.txt");

	/**************** RD ***************/
	cout << "Processing RD data and index" << endl;
	ifstream RD_infile("RDfile.txt");
	ofstream RD_index_HDL;
	ofstream RD_data_HDL;
	RD_index_HDL.open("HDL/RD_index_HDL.txt");
	RD_data_HDL.open("HDL/RD_data_HDL.txt");
	int RD_line_counter = 0;
	int RD_index_size = 0, RD_data_size = 0;
	string RD_index, RD_data;
	bool first_line = 1;

	while (getline(RD_infile, line))
	{
		istringstream iss(line);
		iss >> RD_index >> RD_data;

		if (!first_line)
		{
			RD_index_HDL << "," << endl;
			RD_data_HDL << "," << endl;
		}
		else
		{
			first_line = 0;
			RD_index_size = RD_index.size();
			RD_data_size = RD_data.size();
		}

		RD_index_HDL << RD_line_counter << " => \"" << RD_index << "\"";
		RD_data_HDL << RD_line_counter << " => \"" << RD_data << "\"";

		RD_line_counter++;
	}

	cout << "Finished processing RD data and index" << endl;

	/**************** WD ***************/

	cout << "Processing WD data and index" << endl;

	ifstream WD_infile("WDfile.txt");
	ofstream WD_HDL;
	WD_HDL.open("HDL/WD_data_HDL.txt");
	int WD_line_counter = 0;
	int WD_data_size = 0;
	string WD_data;
	first_line = 1;

	while (getline(WD_infile, line))
	{
		if (!first_line)
			WD_HDL << "," << endl;
		else
		{
			first_line = 0;
			WD_data_size = line.size();
		}

		WD_HDL << WD_line_counter << " => \"" << line << "\"";

		WD_line_counter++;
	}
	cout << "Finished processing WD data" << endl;

	/**************** OUTSIDE ***************/

	ifstream outside_infile("bufferfile.txt");
	string txt, data;

	getline(outside_infile, line); istringstream iss_1(line);
	iss_1 >> txt >> data;
	declarations << "constant WD_elements   : integer := " << data << ";" << endl;
	getline(outside_infile, line); istringstream iss_2(line);
	iss_2 >> txt >> data;
	declarations << "constant RD_elements   : integer := " << data << ";" << endl;
	getline(outside_infile, line); istringstream iss_3(line);
	iss_3 >> txt >> data;
	declarations << "constant matrix_rows   : integer := " << data << ";" << endl;
	getline(outside_infile, line); istringstream iss_4(line);
	iss_4 >> txt >> data;
	declarations << "constant RD_valid_bits : integer := " << data << ";" << endl;



	return;
}