/***************************************************************************
 *
 * @project: Translation of instruction txt files to hdl arrays
 * @version: -
 * @author: Remon van Duijnen (R.F.J.vanDuijnen@student.tudelft.nl)
 *
 ***************************************************************************/

 /****************************description*********************************************

 This script can be used to translate the Instfile text version of the instructions to HDL
 Some operand sizes are unkown due to e.g. indices of blocks being dependent on crossbar and bandwidth sizes
 Serarate bytes are taken for these operands. The small operands are assumed to fit in a byte.
 If the final configuration is known, the instruction memory may be used more efficiently.

 opcode = 1 byte
 small operand (indices, FS, ACFG etc.) = 1 byte
 large operands (RDS, WDS etc.) = multiple bytes depending on required size.

 *************************************************************************************/

#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <map>
#include <cstdlib>
#include <ctime>
#include <math.h>
#include <vector>
#include "inst2hdl.h"

using namespace std;

//---- SET THESE VALUES BEFORE RUNNING SCRIPT ----
int mem_address_bits = 10;

//------------------------------------------------

enum s_nano_opcode {
	NOP = 1,
	// -- stage 1 ---
	ACFG,
	FS,
	RDSb,
	RDSs,
	RDSc,
	RDsh,
	WDSb,
	WDSs,
	WDSc,
	WDb,
	DoA,
	DoS,
	// --------------
	// -- stage 2 ---
	CS,
	DoR,
	CSR,
	jal,
	jr,
	BNE,
	AS,
	CP,
	CB,
	LS,
	IADD
	// --------------
};

enum s_operation {
	WR = 1,
	VRF,
	RD,
	VMM,
	AND,
	OR,
	XOR
};

static map<std::string, s_nano_opcode> nano_opcode;
static map<std::string, s_operation> operation;

void Initialize_inst2hdl(void);
void write_to_HDL_file(ofstream& stage_1_inst_HDL, string data, bool append_or_prepend);

// opcode definitions
string
NOP_op = "0000",
ACFG_op = "0100",
FS_op = "0101",
RDSb_op = "0001",
RDSs_op = "1100",
RDSc_op = "1101",
RDsh_op = "1110",
WDSb_op = "0011",
WDSs_op = "1010",
WDSc_op = "1011",
WDb_op = "0110",
DoA_op = "1000",
DoS_op = "1001",

CS_op = "0001",
CSR_op = "0001",
DoR_op = "1010",
jal_op = "0100",
jr_op = "1000",
AS_op = "0110",
LS_op = "1100",
CP_op = "1110",
CB_op = "1111",
IADD_op = "1101",
BNE_op = "1001";

// FS operation encoding
string
WR_bits = "000",
VRF_bits = "101",
RD_bits = "100",
VMM_bits = "111",
AND_bits = "010",
OR_bits = "011",
XOR_bits = "110";

int byte_counter;

void inst2hdl()
{
	Initialize_inst2hdl();
	ifstream stage_1_infile("nanoInst_stage_1.txt");
	ifstream stage_2_infile("nanoInst_stage_2.txt");
	string line, opcode, operand_1, operand_2, inverted_operand;
	int operand_1_int;
	ofstream stage_1_inst_HDL;
	ofstream stage_2_inst_HDL;
	stage_1_inst_HDL.open("HDL/stage_1_inst_HDL.txt");
	stage_2_inst_HDL.open("HDL/stage_2_inst_HDL.txt");



	// ----- stage 1 -------------------- 
	byte_counter = 0;

	while (getline(stage_1_infile, line))
	{
		istringstream iss(line);
		iss >> opcode;

		switch (nano_opcode[opcode])
		{
		case NOP:
			write_to_HDL_file(stage_1_inst_HDL, NOP_op, false);
			break;

		case ACFG:
			write_to_HDL_file(stage_1_inst_HDL, ACFG_op, false);
			iss >> operand_1; // Adder config bits
			write_to_HDL_file(stage_1_inst_HDL, operand_1, true);
			break;

		case FS:
			write_to_HDL_file(stage_1_inst_HDL, FS_op, false);
			iss >> operand_1; // FS bits

			switch (operation[operand_1])
			{
			case WR:
				write_to_HDL_file(stage_1_inst_HDL, WR_bits, true);
				break;
			case VRF:
				write_to_HDL_file(stage_1_inst_HDL, VRF_bits, true);
				break;
			case RD:
				write_to_HDL_file(stage_1_inst_HDL, RD_bits, true);
				break;
			case VMM:
				write_to_HDL_file(stage_1_inst_HDL, VMM_bits, true);
				break;
			case AND:
				write_to_HDL_file(stage_1_inst_HDL, AND_bits, true);
				break;
			case OR:
				write_to_HDL_file(stage_1_inst_HDL, OR_bits, true);
				break;
			case XOR:
				write_to_HDL_file(stage_1_inst_HDL, XOR_bits, true);
				break;
			}
			break;

		case RDSb:
			write_to_HDL_file(stage_1_inst_HDL, RDSb_op, false);
			iss >> operand_1; // index
			write_to_HDL_file(stage_1_inst_HDL, operand_1, true);
			iss >> operand_2; // mask bits
			for (int i = operand_2.size() - 1; i >= 0; i--) // invert because of VHDL language MSB position
			{
				inverted_operand += operand_2[i];
			}
			write_to_HDL_file(stage_1_inst_HDL, inverted_operand, true);
			inverted_operand.clear();
			break;

		case RDSs:
			write_to_HDL_file(stage_1_inst_HDL, RDSs_op, false);
			break;

		case RDSc:
			write_to_HDL_file(stage_1_inst_HDL, RDSc_op, false);
			break;

		case RDsh:
			write_to_HDL_file(stage_1_inst_HDL, RDsh_op, false);
			break;

		case WDSb:
			write_to_HDL_file(stage_1_inst_HDL, WDSb_op, false);
			iss >> operand_1; // index
			write_to_HDL_file(stage_1_inst_HDL, operand_1, true);
			iss >> operand_2; // mask bits
			for (int i = operand_2.size() - 1; i >= 0; i--) // invert because of VHDL language MSB position
			{
				inverted_operand += operand_2[i];
			}
			write_to_HDL_file(stage_1_inst_HDL, inverted_operand, true);
			inverted_operand.clear();
			break;

		case WDSs:
			write_to_HDL_file(stage_1_inst_HDL, WDSs_op, false);
			break;

		case WDSc:
			write_to_HDL_file(stage_1_inst_HDL, WDSc_op, false);
			break;

		case WDb:
			write_to_HDL_file(stage_1_inst_HDL, WDb_op, false);
			iss >> operand_1; // index
			write_to_HDL_file(stage_1_inst_HDL, operand_1, true);
			break;

		case DoA:
			write_to_HDL_file(stage_1_inst_HDL, DoA_op, false);
			break;

		case DoS:
			write_to_HDL_file(stage_1_inst_HDL, DoS_op, false);
			break;
		default:
			cout << opcode << " is an invalid opcode" << endl;
		}

	}

	stage_1_inst_HDL << '\t' << "others => \"00000000\"" << endl;

	cout << "Stage 1 instruction memory requirement is " << byte_counter << " bytes" << endl;


	// ----- stage 2 --------------------
	byte_counter = 0;
	int byte_address;
	bool zero_address;
	vector <int> line_to_byte_address;

	while (getline(stage_2_infile, line))
	{
		line_to_byte_address.push_back(byte_counter);
		istringstream iss(line);
		string address_binary_reversed, address_binary;
		iss >> opcode;

		switch (nano_opcode[opcode])
		{
		case NOP:
			write_to_HDL_file(stage_2_inst_HDL, NOP_op, false);
			break;

		case CS: // CS and CSR have same functionality/opcode. The implicit DoR for CSR is interpreted by the tile controller hardware.
		case CSR:
			write_to_HDL_file(stage_2_inst_HDL, CS_op, false);
			iss >> operand_1; // analog MUX select
			iss >> operand_2; // ADC acitvation bits
			write_to_HDL_file(stage_2_inst_HDL, operand_2, false);
			write_to_HDL_file(stage_2_inst_HDL, operand_1, true); // write index after data (nicer for hardware)
			break;

		case DoR:
			write_to_HDL_file(stage_2_inst_HDL, DoR_op, false);
			break;

		case jal:
			write_to_HDL_file(stage_2_inst_HDL, jal_op, false);
			iss >> operand_1_int; // address to jump to in decimal
			byte_address = line_to_byte_address[operand_1_int];
			zero_address = 1;

			while (byte_address || zero_address)
			{
				(byte_address) & 1 ? address_binary_reversed += '1' : address_binary_reversed += '0';
				byte_address >>= 1;
				zero_address = 0;
			}

			for (int i = 0; i < mem_address_bits - address_binary_reversed.size(); i++) // prepend zeros to ensure correct address size
			{
				address_binary += '0';
			}

			for (int j = address_binary_reversed.size() - 1; j >= 0; j--)
			{
				address_binary += address_binary_reversed[j];
			}

			write_to_HDL_file(stage_2_inst_HDL, address_binary, true);

			break;

		case jr:
			write_to_HDL_file(stage_2_inst_HDL, jr_op, false);
			break;

		case BNE:
			write_to_HDL_file(stage_2_inst_HDL, BNE_op, false);
			break;

		case AS:
			write_to_HDL_file(stage_2_inst_HDL, AS_op, false);
			break;

		case CP:
			write_to_HDL_file(stage_2_inst_HDL, CP_op, false);
			break;

		case CB:
			write_to_HDL_file(stage_2_inst_HDL, CB_op, false);
			break;

		case LS:
			write_to_HDL_file(stage_2_inst_HDL, LS_op, false);
			break;

		case IADD:
			write_to_HDL_file(stage_2_inst_HDL, IADD_op, false);
			break;

		default:
			cout << opcode << " is an invalid opcode" << endl;

		}
	}

	stage_2_inst_HDL << '\t' << "others => \"00000000\"" << endl;

	cout << "Stage 2 instruction memory requirement is " << byte_counter << " bytes" << endl;



	return;
}

void write_to_HDL_file(ofstream& file, string data, bool append_or_prepend)
{
	string zero_pad, padded_data;
	string data_byte;

	int num_bytes = ceil((float)data.size() / (float)8);

	if (data.size() % 8 != 0)
	{
		for (int i = 8 - (data.size() % 8); i > 0; i--)
		{
			zero_pad += '0';
		}
	}

	if (append_or_prepend)
		padded_data = zero_pad + data;
	else
		padded_data = data + zero_pad;

	for (int i = 0; i < num_bytes; i++)
	{
		data_byte.clear();
		for (int j = 0; j < 8; j++)
		{
			data_byte += padded_data[i * 8 + j];
		}

		file << '\t' << byte_counter << " => \"" << data_byte << "\"," << endl;

		byte_counter++;
	}

	return;
}

void Initialize_inst2hdl()
{
	// FS operation codes
	operation["WR"] = WR;
	operation["VRF"] = VRF;
	operation["RD"] = RD;
	operation["VMM"] = VMM;
	operation["AND"] = AND;
	operation["OR"] = OR;
	operation["XOR"] = XOR;

	// stage 1
	nano_opcode["NOP"] = NOP;
	nano_opcode["ACFG"] = ACFG;
	nano_opcode["FS"] = FS;
	nano_opcode["RDSb"] = RDSb;
	nano_opcode["RDSs"] = RDSs;
	nano_opcode["RDSc"] = RDSc;
	nano_opcode["RDsh"] = RDsh;
	nano_opcode["WDSb"] = WDSb;
	nano_opcode["WDSs"] = WDSs;
	nano_opcode["WDSc"] = WDSc;
	nano_opcode["WDb"] = WDb;
	nano_opcode["DoA"] = DoA;
	nano_opcode["DoS"] = DoS;

	// stage 2
	nano_opcode["CS"] = CS;
	nano_opcode["DoR"] = DoR;
	nano_opcode["CSR"] = CSR;
	nano_opcode["jal"] = jal;
	nano_opcode["jr"] = jr;
	nano_opcode["BNE"] = BNE;
	nano_opcode["AS"] = AS;
	nano_opcode["CP"] = CP;
	nano_opcode["CB"] = CB;
	nano_opcode["LS"] = LS;
	nano_opcode["IADD"] = IADD;
}