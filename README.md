\# SPI Master–Slave (Mode 0) — SystemVerilog



Working SPI \*\*Master\*\* and \*\*Slave\*\* (CPOL=0, CPHA=0), 8-bit MSB-first, with a self-checking testbench.



\## Run (ModelSim/Questa)



do run.do





Expected:





XFER M->S: 0x3c ... master\_got=0xa5, slave\_got=0x3c

XFER M->S: 0x55 ... master\_got=0xbb, slave\_got=0x55

XFER M->S: 0xf0 ... master\_got=0x0f, slave\_got=0xf0

SIMULATION PASSED

