`timescale 1ns/1ps
module spi_tb;

    // ===== Declarations (ALL at the top) =====
    // System clock for master
    logic clk;
    logic rst_n;

    // Master control/data
    logic        start;
    logic [7:0]  m_tx;
    logic [7:0]  m_rx;
    logic        busy, done;

    // SPI wires
    wire sclk, mosi, miso, ss_n;

    // Slave side
    logic [7:0]  s_tx;
    logic [7:0]  s_rx;
    logic        s_rx_valid;

    // Vars used later
    logic [7:0]  mg, sg;

    // ===== Tasks (declare BEFORE any always/initial) =====
    // simple check task (avoid 'string' type for max compatibility)
    task automatic check(input bit cond, input [127:0] msg);
        if (!cond) begin
            $display("FATAL: %s", msg);
            $finish;
        end
    endtask

    // drive a single 8-bit transaction (master TX -> slave RX; slave TX -> master RX)
    task automatic xfer(
        input  [7:0] master_send,
        input  [7:0] slave_send,
        output [7:0] master_got,
        output [7:0] slave_got
    );
        begin
            // preload slave response
            s_tx = slave_send;
            // start master
            m_tx = master_send;
            start = 1'b1;
            @(posedge clk);
            start = 1'b0;

            // wait for completion
            wait (done);
            @(posedge clk); // settle

            master_got = m_rx;
            slave_got  = s_rx;

            $display("XFER  M->S: 0x%02h,  S->M: 0x%02h  |  master_got=0x%02h, slave_got=0x%02h",
                     master_send, slave_send, master_got, slave_got);
        end
    endtask

    // ===== DUTs =====
    spi_master #(.CLK_DIV(4)) u_master (
        .clk     (clk),
        .rst_n   (rst_n),
        .start   (start),
        .tx_data (m_tx),
        .rx_data (m_rx),
        .busy    (busy),
        .done    (done),
        .sclk    (sclk),
        .mosi    (mosi),
        .miso    (miso),
        .ss_n    (ss_n)
    );

    spi_slave u_slave (
        .rst_n   (rst_n),
        .sclk    (sclk),
        .ss_n    (ss_n),
        .mosi    (mosi),
        .miso    (miso),
        .tx_data (s_tx),
        .rx_data (s_rx),
        .rx_valid(s_rx_valid)
    );

    // ===== Clk gen (procedural) =====
    always #5 clk = ~clk;

    // ===== Main test (procedural) =====
    initial begin
        // init
        clk = 0; rst_n = 0; start = 0; m_tx = 8'h00; s_tx = 8'h00;
        repeat (3) @(posedge clk);
        rst_n = 1;

        // run a few transfers
        xfer(8'h3C, 8'hA5, mg, sg);
        check(mg==8'hA5 && sg==8'h3C, "Transfer 1 mismatch");

        xfer(8'h55, 8'hBB, mg, sg);
        check(mg==8'hBB && sg==8'h55, "Transfer 2 mismatch");

        xfer(8'hF0, 8'h0F, mg, sg);
        check(mg==8'h0F && sg==8'hF0, "Transfer 3 mismatch");

        $display("SIMULATION PASSED");
        $finish;
    end

endmodule
