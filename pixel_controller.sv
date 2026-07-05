module control_unit(
    input logic clk, n_rst, 
    input logic r_ready, g_ready, b_ready, 
    input logic confirm, 
    input logic [2:0] mode_in,
    input logic [4:0] threshold_in,
    output logic [2:0] mode_locked,
    output logic [4:0] threshold_locked,
    output logic output_ready
);
    typedef enum logic [1:0] {
        INPUT_MODE,
        INPUT_THRESHOLD,
        STREAM
    } state_t;

    state_t state, next_state;

    // INTERNAL SIGNAL DECLARATIONS

    // done signal to detect when we finish streaming
    logic done;

    // mode and threshold
    logic [2:0] mode_next;
    logic [4:0] threshold_next;

    // counter
    logic [12:0] counter, counter_next;

    // counter register block
    always_ff @(posedge clk, negedge n_rst) begin
        if(!n_rst) begin
            counter <= '0;
        end
        else begin
            counter <= counter_next;
        end
    end

    // counter combinational block
    always_comb begin
        counter_next = counter;
        done = '0;

        // 4799 since the count starts at 0
        // 80x60 brings us 4800 pixels
        if(counter == 13'd4799) begin
            counter_next = '0;
            done = '1;
        end
        else if(output_ready) begin
            counter_next = counter + 13'd1;
        end
        
    end

    // mode and threshold register block
    always_ff @(posedge clk, negedge n_rst) begin
        if(!n_rst) begin
            mode_locked <= '0;
            threshold_locked <= '0;
        end
        else begin
            mode_locked <= mode_next;
            threshold_locked <= threshold_next;
        end
    end

    // mode and threshold combinational block
    always_comb begin
        // lock the registers if we are not in an input state
        mode_next = mode_locked;
        threshold_next = threshold_locked;

        // accept mode or threshold inputs only if we are in the input mode or threshold states
        if(state == INPUT_MODE) begin
            mode_next = mode_in;
        end
        else if(state == INPUT_THRESHOLD) begin
            threshold_next = threshold_in;
        end
    end

    // state register block
    always_ff @(posedge clk, negedge n_rst) begin
        if(!n_rst) begin
            state <= INPUT_MODE;
        end
        else begin
            state <= next_state;
        end
    end

    

    // next state logic block
    always_comb begin
        case(state) 
            INPUT_MODE: next_state = confirm ? INPUT_THRESHOLD : INPUT_MODE;
            INPUT_THRESHOLD: next_state = confirm ? STREAM : INPUT_THRESHOLD;
            STREAM: next_state = done ? INPUT_MODE : STREAM;
            default: next_state = INPUT_MODE;
        endcase
    end

    // output logic block
    always_comb begin
        output_ready = '0;
        case(state) 
            // in stream state, assert output_ready if the rgb uart bytes have all been shifted in
            STREAM: output_ready = r_ready & g_ready & b_ready;
            default: output_ready = '0;
        endcase
    end
endmodule