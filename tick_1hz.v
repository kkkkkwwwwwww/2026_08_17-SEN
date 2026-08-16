`timescale 1ns / 1ps

module tick_1hz (
    input clk,
    input reset,
    output reg o_tick_1hz
);
    parameter COUNT_MAX = 100_000_000;
    reg [$clog2(COUNT_MAX)-1:0] count;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            count     <= 0;
            o_tick_1hz <= 0;
        end else if (count == COUNT_MAX - 1) begin
                count     <= 0;
                o_tick_1hz <= 1;
            end else begin
                count     <= count + 1;
                o_tick_1hz <= 0;
            end
    end
endmodule