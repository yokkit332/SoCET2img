// uart_rx_fsm.sv
// UART receiver finite-state machine.
// Detects the start bit, controls byte shifting, and asserts rx_valid after
// one complete 8-bit data byte (plus start/stop framing) is received.

module uart_rx_fsm (
    input  logic       clk,       // System clock
    input  logic       n_rst,     // Active-low asynchronous reset
    input  logic       serial_rx, // Incoming serial line (monitored for start bit)
    input  logic       baud_tick, // Bit-period timing pulse from baud_generator
    output logic       shift_en,  // Enable shift register on each data bit
    output logic       rx_valid   // One-cycle pulse when a byte is fully received
);

    // Receiver FSM states
    typedef enum logic [1:0] {
        IDLE,   // Waiting for start bit (serial_rx == 0)
        START,  // Confirm start bit at baud_tick midpoint
        DATA,   // Shift in 8 data bits
        STOP    // Verify stop bit, then assert rx_valid
    } rx_state_t;

    rx_state_t state;      // Current FSM state (registered)
    rx_state_t next_state; // Next FSM state (combinational)

    // Bit counter: tracks progress through start/data/stop phases
    logic [3:0] bit_count;

    // -------------------------------------------------------------------------
    // State register
    // -------------------------------------------------------------------------
    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst) begin
            // TODO: Reset state to IDLE
        end else begin
            // TODO: Update state <= next_state on each clock edge
        end
    end

    // -------------------------------------------------------------------------
    // Bit counter register
    // -------------------------------------------------------------------------
    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst) begin
            // TODO: Reset bit_count
        end else begin
            // TODO: Increment or reset bit_count based on state and baud_tick
        end
    end

    // -------------------------------------------------------------------------
    // Next-state and output logic
    // -------------------------------------------------------------------------
    always_comb begin
        // Default outputs
        next_state = state;
        shift_en   = 1'b0;
        rx_valid   = 1'b0;

        // TODO: Implement state transitions (IDLE -> START -> DATA -> STOP -> IDLE)
        // TODO: Assert shift_en during DATA state on baud_tick
        // TODO: Assert rx_valid for one cycle when a byte is complete
    end

endmodule
