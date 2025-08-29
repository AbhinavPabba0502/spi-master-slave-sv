\# SPI Master–Slave (SystemVerilog, Mode 0)



A synthesizable SPI Master and SPI Slave in SystemVerilog, configured for Mode 0 (CPOL=0, CPHA=0), with a self-checking testbench.  

This project demonstrates protocol design, RTL coding, and verification skills for ASIC/FPGA workflows.



---



✨ Features

8-bit transfer, MSB-first

SPI Master

&nbsp; - Configurable SCLK divider (`CLK\_DIV`)

&nbsp; - `busy`/`done` status flags

&nbsp; - Preloads MOSI before the first rising edge (correct Mode-0 timing)

SPI Slave

&nbsp; - Preloads MISO on `SS\_n` assert

&nbsp; - `rx\_valid` pulses when a full byte is received

\- Mode 0 timing: drive on falling edge, sample on rising edge

\- Self-checking testbench prints `SIMULATION PASSED` on success



---



 📂 Files

spi\_master.sv # Master RTL

spi\_slave.sv # Slave RTL

spi\_tb.sv # Self-checking testbench

run.do # ModelSim/Questa script

README.md

LICENSE

.gitignore


---



▶️ Run (ModelSim/Questa)

From the ModelSim console:

```tcl

do run.do

Expected output:


XFER  M->S: 0x3c,  S->M: 0xa5  |  master\_got=0xa5, slave\_got=0x3c

XFER  M->S: 0x55,  S->M: 0xbb  |  master\_got=0xbb, slave\_got=0x55

XFER  M->S: 0xf0,  S->M: 0x0f  |  master\_got=0x0f, slave\_got=0xf0

SIMULATION PASSED

🔧 Interfaces

Master (spi\_master.sv)



Inputs: clk, rst\_n, start, tx\_data\[7:0], miso



Outputs: rx\_data\[7:0], busy, done, sclk, mosi, ss\_n



Parameter: CLK\_DIV → SCLK period = 2\*CLK\_DIV cycles of clk



Slave (spi\_slave.sv)



Inputs: rst\_n, sclk, ss\_n, mosi, tx\_data\[7:0]



Outputs: miso, rx\_data\[7:0], rx\_valid



🔮 Extensions

Add CPOL/CPHA parameters for Modes 0–3



Parameterize frame size (e.g., 16-bit)



Multi-byte bursts with FIFO and continuous SS\_n



Multiple slave selects



📜 License

Released under the MIT License.



---

