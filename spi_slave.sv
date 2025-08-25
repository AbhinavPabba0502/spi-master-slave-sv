`timescale 1ns/1ps
// SPI Slave — Mode 0 (CPOL=0, CPHA=0), 8-bit frames, MSB first
module spi_slave (
    input  logic       rst_n,     // async active-low reset
    input  logic       sclk,      // clock from master (CPOL=0)
    input  logic       ss_n,      // chip-select from master (active low)
    input  logic       mosi,      // master out
    output logic       miso,      // slave out

    input  logic [7:0] tx_data,   // byte to send back (loaded when ss_n asserted)
    output logic [7:0] rx_data,   // last received byte
    output logic       rx_valid   // pulses when a full byte received
);

    logic [7:0] sh_tx, sh_rx;
    logic [2:0] bit_cnt;

    
    // Load TX shift when SS goes low (select), clear counters
    always_ff @(negedge ss_n or negedge rst_n) begin
        if (!rst_n) begin
            sh_tx   <= 8'h00;
            bit_cnt <= 3'd7;
            miso    <= 1'b0;
        end else begin
            sh_tx   <= tx_data;
            bit_cnt <= 3'd7;
            miso    <= tx_data[7]; // PRELOAD first bit so master samples correctly on first rising edge
        end
    end


    // MODE 0: update MISO on falling edge; sample MOSI on rising edge
    always_ff @(negedge sclk or negedge rst_n) begin
        if (!rst_n)          miso <= 1'b0;
        else if (!ss_n)      miso <= sh_tx[7];
        else                 miso <= 1'b0;
    end

    always_ff @(posedge sclk or negedge rst_n) begin
        if (!rst_n) begin
            sh_rx   <= 8'h00;
            sh_tx   <= 8'h00;
            rx_data <= 8'h00;
            rx_valid<= 1'b0;
        end else if (!ss_n) begin
            rx_valid <= 1'b0;
            sh_rx <= {sh_rx[6:0], mosi};
            sh_tx <= {sh_tx[6:0], 1'b0};
            if (bit_cnt != 3'd0) begin
                bit_cnt <= bit_cnt - 1'b1;
            end else begin
                rx_data <= {sh_rx[6:0], mosi};
                rx_valid<= 1'b1; // full byte received
            end
        end else begin
            rx_valid <= 1'b0;
        end
    end

endmodule
