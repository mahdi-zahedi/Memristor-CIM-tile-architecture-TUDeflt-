mkdir bin
g++ -I. -I$SYSTEMC_HOME/include -L. -L$SYSTEMC_HOME/lib-linux64 -Wl,-rpath=$SYSTEMC_HOME/lib-linux64 -o ./bin/cim_tile.exe ./cim-tile/*.cpp -lsystemc -lm