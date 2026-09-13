`timescale 1ns / 1ps  // 1ns time unit, 1ps precision

module uart_tb;

// --- Declare signals ---
reg clk = 0, rst = 0;
reg tx_start = 0;
reg [7:0] tx_data = 0;

wire tx_line;    // Wire connecting TX output to RX input
wire tx_done;
wire [7:0] rx_data;
wire rx_done;

// --- Clock: 100MHz ? toggle every 5ns ---
always #5 clk = ~clk;

// --- Connect TX to RX (loopback test) ---
uart_tx DUT_TX (
    .clk(clk), .rst(rst),
    .tx_start(tx_start), .tx_data(tx_data),
    .tx(tx_line), .tx_done(tx_done)
);

uart_rx DUT_RX (
    .clk(clk), .rst(rst),
    .rx(tx_line),         // TX output ? RX input
    .rx_data(rx_data), .rx_done(rx_done)
);

// --- Test Sequence ---
initial begin
    // 1. Reset everything
    rst = 1;
    #100;
    rst = 0;
    #100;

    // 2. Send first byte: 0x55 = 01010101
    tx_data  = 8'h55;
    tx_start = 1;
    #10;
    tx_start = 0;

    // 3. Wait for TX to finish
    @(posedge tx_done);
    #1000;

    // 4. Check what RX received
    if (rx_data == 8'h55)
        $display("PASS: Received 0x%h correctly", rx_data);
    else
        $display("FAIL: Expected 0x55, got 0x%h", rx_data);

    // 5. Send second byte: 0xAA = 10101010
    #5000;
    tx_data  = 8'hAA;
    tx_start = 1;
    #10;
    tx_start = 0;

    @(posedge tx_done);
    #1000;

    if (rx_data == 8'hAA)
        $display("PASS: Received 0x%h correctly", rx_data);
    else
        $display("FAIL: Expected 0xAA, got 0x%h", rx_data);

    #5000;
    $display("Simulation complete!");
    $finish;
end

// --- Live monitor: print every time RX receives a byte ---
always @(posedge rx_done)
    $display("RX got: 0x%h at time %0t ns", rx_data, $time);

endmodule
