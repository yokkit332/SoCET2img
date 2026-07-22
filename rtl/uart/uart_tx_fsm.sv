// uart_tx_fsm.sv
// UART transmitter finite-state machine.
// Controls start bit, 8 data bits, and stop bit transmission for one byte.

module uart_tx_fsm (
    input  logic       clk,       // System clock
    input  logic       n_rst,     // Active-low asynchronous reset
    input  logic       tx_valid,  // Pulse from pixel_serializer when tx_data is ready
    input  logic       baud_tick, // Bit-period timing pulse from baud_generator
    output logic       load,      // Load tx_data into shift register
    output logic       shift_en,  // Enable shift register on each data bit
    output logic       tx_ready,  // High when FSM can accept a new byte
    output logic [1:0] tx_state   // Current state of the FSM
);

    // Transmitter FSM states
    typedef enum logic [1:0] {
        IDLE,   // Waiting for tx_valid; line idle (high)
        START,  // Drive start bit (low)
        DATA,   // Shift out 8 data bits
        STOP    // Drive stop bit (high), then return to IDLE
    } tx_state_t;

    tx_state_t state;      // Current FSM state (registered)
    tx_state_t next_state; // Next FSM state (combinational)

    // Bit counter: tracks progress through start/data/stop phases
    logic [3:0] bit_count;
    assign tx_state = state;

    // -------------------------------------------------------------------------
    // State register
    // -------------------------------------------------------------------------
    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst) begin
            // TODO: Reset state to IDLE
            state <= IDLE;
        end else begin
            // TODO: Update state <= next_state on each clock edge
            state <= next_state;
        end
    end

    // -------------------------------------------------------------------------
    // Bit counter register
    // -------------------------------------------------------------------------
    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst) begin
            // TODO: Reset bit_count
            bit_count <= 0;
        end else begin
            // TODO: Increment or reset bit_count based on state and baud_tick
            if (state == DATA && baud_tick == 1'b1) begin
                bit_count <= bit_count + 1;
            end else if (state == START && next_state == DATA) begin
                bit_count <= 0;
            end else begin
                bit_count <= bit_count;
            end

        end
    end

    // -------------------------------------------------------------------------
    // Next-state and output logic
    // -------------------------------------------------------------------------
    always_comb begin
        // Default outputs
        next_state = state;
        load       = 1'b0;
        shift_en   = 1'b0;
        tx_ready   = 1'b0;

        // TODO: Implement state transitions (IDLE -> START -> DATA -> STOP -> IDLE)
        case (state)
            IDLE: begin 
                tx_ready = 1'b1;
                if (tx_valid)
                    next_state = START;
                end
            START: begin
                if (baud_tick) begin
                    next_state = DATA;
                    load = 1'b1;
                end
            end
            DATA: begin
                
                if (baud_tick) begin
                    shift_en = 1'b1;
                    if (bit_count == 7)
                        next_state = STOP;
                    else
                        next_state = DATA;
                end
            end
            STOP: begin
                if (baud_tick)
                    next_state = IDLE;
            end
        endcase


        // TODO: Assert load when entering DATA state (after start bit)
        // TODO: Assert shift_en during DATA state on baud_tick
        // TODO: Assert tx_ready when in IDLE and ready for a new byte
    end

endmodule
