# Memristor CIM tile architecture TU Delft

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

TODO