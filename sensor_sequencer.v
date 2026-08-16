`timescale 1ns / 1ps


module sensor_sequencer (
    input clk,
    input reset,
    input tick_1hz,
    input sr04_done,
    input dht11_done,
    output reg sr04_start,
    output reg dht11_start
);

    localparam idle = 0, sr04_wait = 1, dht11_wait = 2;

    reg [1:0] state;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            state <= idle;
            sr04_start <= 1'b0;
            dht11_start <= 1'b0;
        end else begin
            sr04_start  <= 1'b0;
            dht11_start <= 1'b0;
            case (state)
                idle: begin
                    if (tick_1hz) begin
                        sr04_start <= 1'b1;
                        state <= sr04_wait;
                    end
                end
                sr04_wait: begin
                    if (sr04_done) begin
                        dht11_start <= 1'b1;
                        state <= dht11_wait;
                    end
                end
                dht11_wait: begin
                    if (dht11_done) begin
                        state <= idle;
                    end
                end
                default: state <= idle;
            endcase
        end
    end


endmodule
