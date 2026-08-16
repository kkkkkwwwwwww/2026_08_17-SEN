`timescale 1ns / 1ps

module Fnd_controller #(
    parameter MSEC_WIDTH = 7,
    SEC_WIDTH = 6,
    MIN_WIDTH = 6,
    HOUR_WIDTH = 5
) (
    input                     clk,
    input                     rst,
    input  [             1:0] sw_mode,
    input                     sw_detail,
    input  [MSEC_WIDTH - 1:0] msec,
    input  [ SEC_WIDTH - 1:0] sec,
    input  [ MIN_WIDTH - 1:0] min,
    input  [HOUR_WIDTH - 1:0] hour,
    input  [             8:0] distance,
    input  [             7:0] temp,
    input  [             7:0] hum,
    output [             3:0] fnd_com,
    output [             7:0] fnd_data
);
    wire [3:0] d_out0, d_out1, d_out2, d_out3;
    wire [3:0] d_out4, d_out5, d_out6, d_out7;
    wire [2:0] sel;
    wire [3:0] MUX_out0, MUX_out1, time_BCD;
    wire d_clk, com_out;
    digit_splitter digit_splitter_msec (
        .ds_in(msec),
        .d1(d_out0),
        .d10(d_out1)
    );
    digit_splitter digit_splitter_sec (
        .ds_in({1'b0, sec}),
        .d1(d_out2),
        .d10(d_out3)
    );
    digit_splitter digit_splitter_min (
        .ds_in({1'b0, min}),
        .d1(d_out4),
        .d10(d_out5)
    );
    digit_splitter digit_splitter_hour (
        .ds_in({1'b00, hour}),
        .d1(d_out6),
        .d10(d_out7)
    );
    MUX8to1 MUX0 (
        .sel(sel),
        .com_out(com_out),
        .M_in0(d_out0),
        .M_in1(d_out1),
        .M_in2(d_out2),
        .M_in3(d_out3),
        .out(MUX_out0)
    );
    MUX8to1 MUX1 (
        .sel(sel),
        .com_out(com_out),
        .M_in0(d_out4),
        .M_in1(d_out5),
        .M_in2(d_out6),
        .M_in3(d_out7),
        .out(MUX_out1)
    );
    MUX2to1 MUX2 (
        .sel  (sw_detail),
        .M_in0(MUX_out0),
        .M_in1(MUX_out1),
        .out  (time_BCD)
    );
    clk_divider clk_divider_0 (
        .clk  (clk),
        .rst  (rst),
        .d_clk(d_clk)
    );
    Counter Counter_0 (
        .clk(d_clk),
        .rst(rst),
        .out_sel(sel)
    );
    Decoder2to4 Decoder2to4_0 (
        .sel(sel[1:0]),
        .out(fnd_com)
    );
    Comparator_50 Comparator_50_0 (
        .msec (msec),
        .DP_ON(com_out)
    );

    wire [3:0] dist_d1, dist_d10, dist_d100;
    wire [3:0] tem_d1, tem_d10;
    wire [3:0] hum_d1, hum_d10;


    digit_splitter3 digit_splitter3_dist (
        .ds_in(distance),
        .d1(dist_d1),
        .d10(dist_d10),
        .d100(dist_d100)
    );
    digit_splitter digit_splitter_temp (
        .ds_in({1'b0, temp[6:0]}),
        .d1(tem_d1),
        .d10(tem_d10)
    );
    digit_splitter digit_splitter_hum (
        .ds_in({1'b0, hum[6:0]}),
        .d1(hum_d1),
        .d10(hum_d10)
    );

    reg [3:0] sensor_BCD;
    always @(*) begin
        case (sw_mode)
            2'b01: begin
                case (sel[1:0])
                    2'b00: sensor_BCD = dist_d1;
                    2'b01: sensor_BCD = dist_d10;
                    2'b10: sensor_BCD = dist_d100;
                    2'b11: sensor_BCD = 4'b1111;
                endcase
            end
            2'b10: begin
                case (sel[1:0])
                    2'b00: sensor_BCD = hum_d1;
                    2'b01: sensor_BCD = hum_d10;
                    2'b10: sensor_BCD = tem_d1;
                    2'b11: sensor_BCD = tem_d10;
                endcase
            end
            default: sensor_BCD = 4'b1111;
        endcase
    end
    wire [3:0] final_BCD_in = (sw_mode == 2'b00) ? time_BCD : sensor_BCD;
    BCD BCD_0 (
        .BCD_in (final_BCD_in),
        .BCD_out(fnd_data)
    );

endmodule


module digit_splitter (
    input  [6:0] ds_in,
    output [3:0] d1,
    output [3:0] d10
);
    assign d1  = ds_in % 10;
    assign d10 = (ds_in / 10) % 10;
endmodule

module MUX8to1 (
    input  [2:0] sel,
    input        com_out,
    input  [3:0] M_in0,
    input  [3:0] M_in1,
    input  [3:0] M_in2,
    input  [3:0] M_in3,
    output [3:0] out
);
    reg [3:0] out_reg;
    always @(*) begin
        case (sel)
            3'b000: out_reg = M_in0;
            3'b001: out_reg = M_in1;
            3'b010: out_reg = M_in2;
            3'b011: out_reg = M_in3;
            3'b100: out_reg = 4'b1111;
            3'b101: out_reg = 4'b1111;
            3'b110: out_reg = {3'b111, com_out};
            3'b111: out_reg = 4'b1111;
        endcase
    end
    assign out = out_reg;
endmodule

module MUX2to1 (
    input        sel,
    input  [3:0] M_in0,
    input  [3:0] M_in1,
    output [3:0] out
);
    assign out = (sel) ? M_in1 : M_in0;
endmodule

module Counter (
    input clk,
    input rst,
    output [2:0] out_sel
);
    reg [2:0] count;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            count <= 0;
        end else begin
            count <= count + 1;
        end
    end
    assign out_sel = count;
endmodule

module clk_divider (
    input  clk,
    input  rst,
    output d_clk
);
    reg [$clog2(12500)-1:0] count;
    reg clk_reg;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            clk_reg <= 0;
            count   <= 0;
        end else begin
            if (count >= 12499) begin
                count   <= 0;
                clk_reg <= ~clk_reg;
            end else begin
                count <= count + 1;
            end
        end
    end
    assign d_clk = clk_reg;
endmodule

module Decoder2to4 (
    input  [1:0] sel,
    output [3:0] out
);
    assign out = (sel == 2'b00) ? 4'b1110 :
                (sel == 2'b01) ? 4'b1101 :
                (sel == 2'b10) ? 4'b1011 :
                (sel == 2'b11) ? 4'b0111 : 4'b1111;
endmodule

module BCD (
    input [3:0] BCD_in,
    output reg [7:0] BCD_out
);
    always @(BCD_in) begin
        case (BCD_in)
            4'b0000: BCD_out = 8'hC0;
            4'b0001: BCD_out = 8'hF9;
            4'b0010: BCD_out = 8'hA4;
            4'b0011: BCD_out = 8'hB0;
            4'b0100: BCD_out = 8'h99;
            4'b0101: BCD_out = 8'h92;
            4'b0110: BCD_out = 8'h82;
            4'b0111: BCD_out = 8'hF8;
            4'b1000: BCD_out = 8'h80;
            4'b1001: BCD_out = 8'h90;
            4'b1010: BCD_out = 8'h88;  //a
            4'b1011: BCD_out = 8'h83;  //b
            4'b1100: BCD_out = 8'hC6;  //c
            4'b1101: BCD_out = 8'hA1;  //d
            4'b1110: BCD_out = 8'h7F;  //dp on
            4'b1111: BCD_out = 8'hFF;  //off
        endcase
    end
endmodule

module Comparator_50 (
    input [6:0] msec,
    output DP_ON
);
    assign DP_ON = (msec >= 50) ? 1 : 0;
endmodule
