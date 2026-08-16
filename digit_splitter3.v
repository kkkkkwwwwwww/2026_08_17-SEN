`timescale 1ns / 1ps

module digit_splitter3 (
    input  [8:0] ds_in,
    output [3:0] d1,
    output [3:0] d10,
    output [3:0] d100
);
    assign d1   = ds_in % 10;
    assign d10  = (ds_in / 10) % 10;
    assign d100 = (ds_in / 100) % 10;
endmodule