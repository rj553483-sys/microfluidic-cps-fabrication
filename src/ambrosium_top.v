// Project AMBROSIUM v10.0: Monolithic Cyber-Physical Microfluidic Core
// Module: ambrosium_top.v
// Target Device: AMD/Xilinx Artix-7 (XC7A100T-2CSG324C)
// Synthesizable Verilog HDL FSM Core & 10 MHz Circular FIFO Pipeline
// Author: Jacob (Jake) James Rasmussen (ORCID: 0009-0009-7084-6523)

`timescale 1ns / 1ps

module ambrosium_top (
    input  wire        clk,           // 10 MHz Parallel Clock
    input  wire        rst_n,         // Active-Low System Reset
    input  wire [13:0] adc_data,      // 14-bit Parallel ADC Stream
    input  wire        trigger_in,    // Microfluidic Trigger Pulse
    output reg  [1:0]  fsm_state,     // Moore FSM State Output
    output reg         actuate_sfat,  // 10,000-Channel SFAT MEMS Control Pulse
    output reg         rf_enable,     // WR-340 2.45 GHz Microwave Gelation Gate
    output reg         ed_gate_en,    // Active Electrodialysis Ion Gate Enable
    output reg         blockade_flag, // Microsecond Nanopore Blockade Signal
    output wire        fifo_full,     // 1024-Word FIFO Overflow Indicator
    output reg  [15:0] y_prev_out     // Baseline-Filtered ADC Value (Signed 16-bit)
);

    localparam ST_IDLE     = 2'b00;
    localparam ST_PARSE    = 2'b01;
    localparam ST_ACTUATE  = 2'b10;
    localparam ST_CORRECT  = 2'b11;

    // Biophysical Guard Threshold (y_prev < 16'sd2000)
    localparam signed [15:0] GUARD_THRESHOLD = 16'sd2000;

    reg signed [15:0] x_curr;
    reg signed [15:0] x_prev;
    reg signed [15:0] y_prev;

    // Circular FIFO Buffer (1024 words x 14-bit)
    reg [13:0] fifo_mem [0:1023];
    reg [9:0]  write_ptr;
    reg [9:0]  read_ptr;
    reg [10:0] fifo_count;

    assign fifo_full = (fifo_count == 11'd1024);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            x_curr     <= 16'sd0;
            x_prev     <= 16'sd0;
            y_prev     <= 16'sd0;
            write_ptr  <= 10'd0;
            read_ptr   <= 10'd0;
            fifo_count <= 11'd0;
        end else begin
            x_prev <= x_curr;
            x_curr <= {2'b00, adc_data};
            // Difference Equation: y[n] = alpha*y[n-1] + alpha*(x[n] - x[n-1])
            y_prev <= ((y_prev * 7) >>> 3) + (((x_curr - x_prev) * 7) >>> 3);

            fifo_mem[write_ptr] <= adc_data;
            write_ptr <= write_ptr + 1'b1;
            if (!fifo_full) begin
                fifo_count <= fifo_count + 1'b1;
            end else begin
                read_ptr <= read_ptr + 1'b1;
            end
        end
    end

    always @(posedge clk) begin
        y_prev_out <= y_prev;
    end

    reg [1:0] next_state;
    reg [15:0] cycle_counter;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fsm_state     <= ST_IDLE;
            cycle_counter <= 16'd0;
        end else begin
            fsm_state <= next_state;
            if (fsm_state == next_state) begin
                cycle_counter <= cycle_counter + 1'b1;
            end else begin
                cycle_counter <= 16'd0;
            end
        end
    end

    always @(*) begin
        next_state    = fsm_state;
        actuate_sfat  = 1'b0;
        rf_enable     = 1'b0;
        ed_gate_en    = 1'b0;
        blockade_flag = 1'b0;

        case (fsm_state)
            ST_IDLE: begin
                ed_gate_en = 1'b1; // Maintain active desalting
                if (trigger_in) begin
                    next_state = ST_PARSE;
                end
            end

            ST_PARSE: begin
                ed_gate_en = 1'b1;
                if (y_prev < GUARD_THRESHOLD) begin
                    blockade_flag = 1'b1;
                    next_state = ST_CORRECT;
                end else if (cycle_counter >= 16'd100000) begin
                    next_state = ST_ACTUATE;
                end
            end

            ST_ACTUATE: begin
                actuate_sfat = 1'b1; // Trigger SFAT MEMS array
                ed_gate_en   = 1'b1;
                if (cycle_counter >= 16'd8500) begin
                    rf_enable  = 1'b1; // Trigger WR-340 RF flash gelation (tau = 0.85 s)
                end
                if (cycle_counter >= 16'd10000) begin
                    next_state = ST_IDLE;
                end
            end

            ST_CORRECT: begin
                blockade_flag = 1'b1;
                ed_gate_en    = 1'b1;
                actuate_sfat  = 1'b1;
                if (cycle_counter >= 16'd1420) begin // WCET = 1.42 ms
                    next_state = ST_PARSE;
                end
            end

            default: next_state = ST_IDLE;
        endcase
    end

endmodule
