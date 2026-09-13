module uart_rx (
    input  clk,
    input  rst,
    input  rx,              // Serial input line
    output reg [7:0] rx_data,  // Received 8-bit data
    output reg rx_done      // HIGH when a byte is received
);

parameter BAUD_LIMIT  = 10416;
parameter HALF_BAUD   = 5208; // Used to sample at center of bit

reg [13:0] baud_count = 0;
reg [3:0]  bit_index  = 0;
reg [7:0]  shift_reg  = 0;
reg        receiving  = 0;
reg        baud_tick  = 0;

// --- Baud Generator (same as TX) ---
always @(posedge clk) begin
    if (rst || !receiving) begin
        baud_count <= 0;
        baud_tick  <= 0;
    end else if (baud_count == BAUD_LIMIT - 1) begin
        baud_count <= 0;
        baud_tick  <= 1;
    end else begin
        baud_count <= baud_count + 1;
        baud_tick  <= 0;
    end
end

// --- Receiver FSM ---
// Waits for START bit (line goes LOW)
// Waits half a bit period ? samples at center of each bit
always @(posedge clk) begin
    if (rst) begin
        rx_data   <= 0;
        rx_done   <= 0;
        receiving <= 0;
        bit_index <= 0;
        shift_reg <= 0;
    end else begin
        rx_done <= 0;

        // Detect START bit: rx goes LOW when idle (HIGH)
        if (!receiving && !rx) begin
            receiving  <= 1;
            bit_index  <= 0;
            baud_count <= 0;
        end

        if (receiving && baud_tick) begin
            if (bit_index < 8) begin
                // Shift in the received bit (MSB last, builds correctly)
                shift_reg <= {rx, shift_reg[7:1]};
                bit_index <= bit_index + 1;
            end else begin
                // bit_index == 8 is the STOP bit
                rx_data   <= shift_reg;
                rx_done   <= 1;
                receiving <= 0;
            end
        end
    end
end

endmodule
