module uart_tx (
    input  clk,          // System clock
    input  rst,          // Reset (active high)
    input  tx_start,     // Pulse this HIGH to send data
    input  [7:0] tx_data,// 8-bit data you want to send
    output reg tx,       // Serial output line
    output reg tx_done   // Goes HIGH when transmission complete
);

// For 9600 baud at 100MHz clock:
// Baud tick every 100MHz/9600 = 10416 cycles
parameter BAUD_LIMIT = 10416;

reg [13:0] baud_count = 0;  // Counts up to BAUD_LIMIT
reg [3:0]  bit_index  = 0;  // Which bit we're sending (0-9)
reg [9:0]  shift_reg  = 0;  // Holds: start + data + stop
reg        sending    = 0;  // Are we currently transmitting?
reg        baud_tick  = 0;  // 1-cycle pulse every baud period

// --- Baud Rate Generator ---
// Creates a tick every 10416 clock cycles (= 1 bit period at 9600 baud)
always @(posedge clk) begin
    if (rst) begin
        baud_count <= 0;
        baud_tick  <= 0;
    end else if (baud_count == BAUD_LIMIT - 1) begin
        baud_count <= 0;
        baud_tick  <= 1;  // Fire the tick
    end else begin
        baud_count <= baud_count + 1;
        baud_tick  <= 0;
    end
end

// --- Transmitter FSM ---
// When tx_start fires: load start(0) + data + stop(1) into shift register
// Each baud tick: shift out 1 bit onto tx line
always @(posedge clk) begin
    if (rst) begin
        tx       <= 1;  // UART idle line is HIGH
        tx_done  <= 0;
        sending  <= 0;
        bit_index<= 0;
        shift_reg<= 0;
    end else begin
        tx_done <= 0;  // Default: not done

        if (tx_start && !sending) begin
            // Load: {stop_bit, data[7:0], start_bit}
            shift_reg <= {1'b1, tx_data, 1'b0};
            sending   <= 1;
            bit_index <= 0;
        end

        if (sending && baud_tick) begin
            tx        <= shift_reg[0];  // Send LSB first
            shift_reg <= shift_reg >> 1;// Shift right
            bit_index <= bit_index + 1;

            if (bit_index == 9) begin   // 10 bits sent (1 start + 8 data + 1 stop)
                sending  <= 0;
                tx_done  <= 1;          // Signal completion
            end
        end
    end
end

endmodule
