vlib work
vlog spi_master.sv spi_slave.sv spi_tb.sv
vsim -c work.spi_tb -do "run -all; quit"
