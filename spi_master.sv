`timescale 1ns/1ps
// SPI Master — Mode 0 (CPOL=0, CPHA=0), 8-bit frames, MSB first
module spi_master #(
    parameter int CLK_DIV = 4  // sysclk/CLK_DIV = SCLK*2 (full period = 2*CLK_DIV)
) (
    input  logic        clk,        // system clock
    input  logic        rst_n,      // active-low reset
    input  logic        start,      // pulse 1 clk to start a transfer
    input  logic [7:0]  tx_data,    // byte to transmit
    output logic [7:0]  rx_data,    // byte received
    output logic        busy,       // high while transfer in progress
    output logic        done,       // 1-cycle pulse when byte completes

    // SPI lines
    output logic        sclk,       // SPI clock (CPOL=0)
    output logic        mosi,       // master out, slave in
    input  logic        miso,       // master in, slave out
    output logic        ss_n        // active-low chip select
);

    // clock divider for SCLK
    logic [$clog2(CLK_DIV)-1:0] div_cnt;
    logic sclk_en;  // toggles SCLK when active

    // shift registers and bit counter
    logic [7:0] sh_tx, sh_rx;
    logic [2:0] bit_cnt;

    typedef enum logic [1:0] {IDLE, ASSERT_SS, XFER, COMPLETE} state_t;
    state_t state, nstate;

    // SCLK generation: CPOL=0. Only toggles during XFER.
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            div_cnt <= '0;
            sclk    <= 1'b0;
        end else if (sclk_en) begin
            if (div_cnt == CLK_DIV-1) begin
                div_cnt <= '0;
                sclk    <= ~sclk;
            end else begin
                div_cnt <= div_cnt + 1'b1;
            end
        end else begin
            div_cnt <= '0;
            sclk    <= 1'b0; // CPOL=0 when idle
        end
    end

    // FSM
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) state <= IDLE;
        else        state <= nstate;
    end

    always_comb begin
        nstate  = state;
        case (state)
            IDLE:       nstate = start ? ASSERT_SS : IDLE;
            ASSERT_SS:  nstate = XFER;
            XFER:       nstate = (bit_cnt == 3'd0 && sclk_en == 1'b1 && sclk == 1'b0 && div_cnt == CLK_DIV-1) ? COMPLETE : XFER;
            COMPLETE:   nstate = IDLE;
            default:    nstate = IDLE;
        endcase
    end

    // outputs & datapath
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ss_n    <= 1'b1;
            busy    <= 1'b0;
            done    <= 1'b0;
            sh_tx   <= 8'h00;
            sh_rx   <= 8'h00;
            bit_cnt <= 3'd7;
            mosi    <= 1'b0;
            sclk_en <= 1'b0;
            rx_data <= 8'h00;
        end else begin
            done <= 1'b0;

            unique case (state)
                IDLE: begin
                    ss_n    <= 1'b1;
                    busy    <= 1'b0;
                    sclk_en <= 1'b0;
                    mosi    <= 1'b0;
                    if (start) begin
                        sh_tx   <= tx_data;
                        sh_rx   <= '0;
                        bit_cnt <= 3'd7;
                    end
                end

                 ASSERT_SS: begin
                    ss_n    <= 1'b0;   // assert chip-select
                    busy    <= 1'b1;
                    sclk_en <= 1'b1;   // start SCLK toggling
                    mosi    <= sh_tx[7]; // PRELOAD first bit before first rising edge
                end

                XFER: begin
                    // MODE 0: drive MOSI on SCLK falling edge, sample MISO on rising edge.
                    // We detect SCLK edges using the divider's half-period completion.
                    if (div_cnt == CLK_DIV-1) begin
                        if (sclk == 1'b1) begin
                            // about to fall to 0 → falling edge next cycle: update MOSI with current MSB
                            mosi <= sh_tx[7];
                        end else begin
                            // about to rise to 1 → rising edge next cycle: sample MISO, then shift
                            sh_rx <= {sh_rx[6:0], miso};
                            sh_tx <= {sh_tx[6:0], 1'b0};
                            if (bit_cnt != 3'd0) bit_cnt <= bit_cnt - 1'b1;
                        end
                    end
                end

                COMPLETE: begin
                    ss_n    <= 1'b1;
                    sclk_en <= 1'b0;
                    busy    <= 1'b0;
                    done    <= 1'b1;
                    rx_data <= sh_rx;
                end
            endcase
        end
    end

endmodule
