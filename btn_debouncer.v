`timescale 1ns / 1ps

module Btn_debouncer (
    input  clk,
    input  rst,
    input  i_btn,
    output o_btn
);
    parameter reg_Lenth = 8;
    reg o_10khz;
    reg [$clog2(5000)-1:0] counter_reg;
    reg [reg_Lenth-1:0] q_reg;
    wire debounce;
    reg edge_reg;

    always @(posedge clk or posedge rst) begin
        if(rst) begin
            counter_reg <= 0;
            o_10khz <= 0;
        end else begin
            counter_reg <= counter_reg + 1;
            if(counter_reg == 4999) begin
                counter_reg <= 0;
                o_10khz <= ~o_10khz;
            end
        end
    end

    always @(posedge o_10khz or posedge rst) begin
        if (rst) begin
            q_reg <= 0;
        end else begin
            q_reg <= {q_reg[reg_Lenth-2:0], i_btn};
        end
    end

    assign debounce = &q_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            edge_reg <= 0;
        end else begin
            edge_reg <= debounce;
        end
    end

    assign o_btn = (debounce) & (~edge_reg);

endmodule








