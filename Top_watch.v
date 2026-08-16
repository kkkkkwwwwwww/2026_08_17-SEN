`timescale 1ns / 1ps

module Top_watch #(
    parameter MSEC_WIDTH = 7,
    SEC_WIDTH = 6,
    MIN_WIDTH = 6,
    HOUR_WIDTH = 5
) (
    input clk,
    input rst,
    input btnL,
    input btnR,
    input btnU,
    input btnD,
    output [MSEC_WIDTH-1:0] msec,
    output [SEC_WIDTH-1:0] sec,
    output [MIN_WIDTH-1:0] min,
    output [HOUR_WIDTH-1:0] hour,
    output [2:0] o_position
);
    wire [2:0] position;
    wire [1:0] up_down;
    Control_unit_watch Control_unit_watch_0 (
        .clk(clk),
        .rst(rst),
        .i_btnL(btnL),
        .i_btnR(btnR),
        .i_btnU(btnU),
        .i_btnD(btnD),
        .position(position),
        .up_down(up_down)
    );
Watch_datapath Watch_datapath_0(
    .clk(clk),
    .rst(rst),
    .position(position),
    .up_down(up_down),
    .msec(msec),
    .sec(sec),
    .min(min),
    .hour(hour)
);
assign o_position = position;
endmodule
