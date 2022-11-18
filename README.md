# Memristor CIM tile architecture TU Delft
This version was designed for "V1 CIM-tile architecture" with 2 pipelined stages. The folder contains codes for the simulator, compiler, and VHDL implementation. For information about "V1 CIM-tile architecture", please contact m.z.zahedi@tudelft.nl 

## Setup guide
This guide assumes that you are using Linux Ubuntu/Pop!_OS

### Installing SystemC
Install [SystemC 2.3.3](https://www.accellera.org/downloads/standards/systemc).

```
sudo apt-get install build-essential
tar -xvf systemc-2.3.3.tar.gz
cd systemc-2.3.3
mkdir objdir
sudo mkdir /usr/local/systemc-2.3.3
sudo ../configure --prefix=/usr/local/systemc-2.3.3/
sudo make
sudo make install
export SYSTEMC_HOME=/usr/local/systemc-2.3.3/
```

More detailed instructions [here](https://howto.tech.blog/2016/11/27/installing-systemc-2-3-1/).

```
g++ -I. -I$SYSTEMC_HOME/include -L. -L$SYSTEMC_HOME/lib-linux64 -Wl,-rpath=$SYSTEMC_HOME/lib-linux64 -o hello hello.cpp -lsystemc -lm
```

To compile for SystemC.

## How to use

### Micro -> Nano compiler
"Add_S" --row start "i" --column start "j" --rows to write "p" --columns to write "q"
store | &B[0][0] | i: 1 | j: 0 | p: 1 | q: 256 | 256

"read" -- "Add_D" -- "Add_S" --row starting point "i" --column starting point "j" --number of rows to read "p" --number of columns to read "q"

"Add_M" --row_start "i" --column start "j" --rows to write "e" --columns to write "q" p
MMM | &B[0][0] | i: 0 | j: 0 | e: 1 | q: 256 | p: 256 | 256 | 256

logical_and1

"logical_or" -- "Add_D" -- "Add_S" -- "i" -- "j" -- "p" --  "q"
logical_or1 test test 0 0 256 256

logical_xor

2d unsigned short int matrix -> file
file -> 1d int array (0 or 1)

TODO