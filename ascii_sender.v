`timescale 1ns / 1ps



module ascii_sender (
    input clk,
    input reset,
    input i_run_stop,
    input i_clear,
    input i_mode,
    input i_left,
    input i_right,
    input i_up,
    input i_down,
    input run_state,
    output reg [7:0] tx_data,
    output reg tx_push


);
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            tx_data <= 8'b0;
            tx_push <= 1'b0;
        end else begin
            tx_push <= 1'b0;

            if (i_run_stop) begin
                tx_data <= run_state ? "s" : "r";
                tx_push <= 1'b1;
            end else if (i_clear) begin
                tx_data <= "c";
                tx_push <= 1'b1;
            end else if (i_mode) begin
                tx_data <= "m";
                tx_push <= 1'b1;
            end else if (i_left) begin
                tx_data <= "a";
                tx_push <= 1'b1;

            end else if (i_right) begin
                tx_data <= "n";
                tx_push <= 1'b1;
            end else if (i_up) begin
                tx_data <= "u";
                tx_push <= 1'b1;
            end else if (i_down) begin
                tx_data <= "d";
                tx_push <= 1'b1;
            end


        end
    end
endmodule
