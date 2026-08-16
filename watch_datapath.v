`timescale 1ns / 1ps

module Watch_datapath #(
    parameter MSEC_WIDTH = 7,
    SEC_WIDTH = 6,
    MIN_WIDTH = 6,
    HOUR_WIDTH = 5
) (
    input                   clk,
    input                   rst,
    input  [           2:0] position,
    input  [           1:0] up_down,
    output [MSEC_WIDTH-1:0] msec,
    output [ SEC_WIDTH-1:0] sec,
    output [ MIN_WIDTH-1:0] min,
    output [HOUR_WIDTH-1:0] hour
);
    wire tick_100hz;
    wire tick_msec1;
    wire tick_sec0;
    wire tick_sec1;
    wire tick_min0;
    wire tick_min1;
    wire tick_hour0;
    wire [3:0] msec_1;
    wire [3:0] msec_10;
    wire [3:0] sec_1;
    wire [2:0] sec_10;
    wire [3:0] min_1;
    wire [2:0] min_10;
    wire [4:0] hour_1;
    wire [1:0] msec_add0;
    wire [1:0] msec_add1;
    wire [1:0] sec_add0;
    wire [1:0] sec_add1;
    wire [1:0] min_add0;
    wire [1:0] min_add1;
    wire [2:0] hour_add;
    assign msec_add0 = (position == 3'b000) ? up_down : 2'b00;
    assign msec_add1 = (position == 3'b001) ? up_down : 2'b00;
    assign sec_add0 = (position == 3'b010) ? up_down : 2'b00;
    assign sec_add1 = (position == 3'b011) ? up_down : 2'b00;
    assign min_add0 = (position == 3'b100) ? up_down : 2'b00;
    assign min_add1 = (position == 3'b101) ? up_down : 2'b00;
    assign hour_add = (position == 3'b110) ? {1'b0, up_down} : 
                    (position == 3'b111) ? {1'b1, up_down} : 3'b000;
    assign msec = msec_1 + 10 * msec_10;
    assign sec = sec_1 + 10 * sec_10;
    assign min = min_1 + 10 * min_10;
    assign hour = hour_1;
    Tick_gen_100Hz_watch Tick_gen_100Hz_watch_01 (
        .clk(clk),
        .rst(rst),
        .o_tick(tick_100hz)
    );
    Time_Counter_Watch #(
        .TIME_WIDTH(4),
        .TIME_COUNT(10)
    ) Time_Counter_msec0 (
        .clk(clk),
        .rst(rst),
        .addition(msec_add0),
        .i_tick(tick_100hz),
        .time_count(msec_1),
        .o_tick(tick_msec1)
    );
    Time_Counter_Watch #(
        .TIME_WIDTH(4),
        .TIME_COUNT(10)
    ) Time_Counter_msec1 (
        .clk(clk),
        .rst(rst),
        .addition(msec_add1),
        .i_tick(tick_msec1),
        .time_count(msec_10),
        .o_tick(tick_sec0)
    );
    Time_Counter_Watch #(
        .TIME_WIDTH(4),
        .TIME_COUNT(10)
    ) Time_Counter_sec0 (
        .clk(clk),
        .rst(rst),
        .addition(sec_add0),
        .i_tick(tick_sec0),
        .time_count(sec_1),
        .o_tick(tick_sec1)
    );
    Time_Counter_Watch #(
        .TIME_WIDTH(3),
        .TIME_COUNT(6)
    ) Time_Counter_sec1 (
        .clk(clk),
        .rst(rst),
        .addition(sec_add1),
        .i_tick(tick_sec1),
        .time_count(sec_10),
        .o_tick(tick_min0)
    );
    Time_Counter_Watch #(
        .TIME_WIDTH(4),
        .TIME_COUNT(10)
    ) Time_Counter_min0 (
        .clk(clk),
        .rst(rst),
        .addition(min_add0),
        .i_tick(tick_min0),
        .time_count(min_1),
        .o_tick(tick_min1)
    );
    Time_Counter_Watch #(
        .TIME_WIDTH(3),
        .TIME_COUNT(6)
    ) Time_Counter_min1 (
        .clk(clk),
        .rst(rst),
        .addition(min_add1),
        .i_tick(tick_min1),
        .time_count(min_10),
        .o_tick(tick_hour0)
    );
    Time_Counter_Watch_hour #(
        .TIME_WIDTH(5),
        .TIME_COUNT(24)
    ) Time_Counter_hour (
        .clk(clk),
        .rst(rst),
        .i_tick(tick_hour0),
        .addition(hour_add),
        .time_count(hour_1),
        .o_tick()
    );
endmodule

module Tick_gen_100Hz_watch (
    input      clk,
    input      rst,
    output reg o_tick
);
    parameter F_COUNT = 1_000_000;
    reg [$clog2(F_COUNT)-1:0] count;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            count  <= 0;
            o_tick <= 0;
        end else begin
            count  <= count + 1;
            o_tick <= 0;
            if (count == (F_COUNT - 1)) begin
                o_tick <= 1;
                count  <= 0;
            end else begin
                o_tick <= 0;
            end
        end
    end
endmodule

module Time_Counter_Watch #(
    parameter TIME_WIDTH = 7,
    TIME_COUNT = 100
) (
    input                       clk,
    input                       rst,
    input                       i_tick,
    input      [           1:0] addition,
    output reg [TIME_WIDTH-1:0] time_count,
    output reg                  o_tick
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            time_count <= 0;
            o_tick <= 0;
        end else begin
            time_count <= time_count;
            o_tick <= 0;
            if (addition == 2'b10) begin
                if (time_count == (TIME_COUNT - 1)) begin
                    time_count <= 0;
                end else begin
                    time_count <= time_count + 1;
                end
            end else if (addition == 2'b01) begin
                if (time_count == 0) begin
                    time_count <= (TIME_COUNT - 1);
                end else begin
                    time_count <= time_count - 1;
                end
            end else if (i_tick) begin
                time_count <= time_count + 1;
                if (time_count == (TIME_COUNT - 1)) begin
                    time_count <= 0;
                    o_tick <= 1;
                end else begin
                    o_tick <= 0;
                end
            end
        end
    end
endmodule

module Time_Counter_Watch_hour #(
    parameter TIME_WIDTH = 5,
    TIME_COUNT = 24
) (
    input                       clk,
    input                       rst,
    input                       i_tick,
    input      [           2:0] addition,
    output reg [TIME_WIDTH-1:0] time_count,
    output reg                  o_tick
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            time_count <= 0;
            o_tick <= 0;
        end else begin
            time_count <= time_count;
            o_tick <= 0;
            if (addition == 3'b010) begin
                if (time_count == (TIME_COUNT - 1)) begin
                    time_count <= 0;
                end else begin
                    time_count <= time_count + 1;
                end
            end else if (addition == 3'b001) begin
                if (time_count == 0) begin
                    time_count <= (TIME_COUNT - 1);
                end else begin
                    time_count <= time_count - 1;
                end
            end else if (addition == 3'b110) begin
                if (time_count >= (TIME_COUNT - 10)) begin
                    time_count <= time_count - 10 * (time_count / 10);
                end else begin
                    time_count <= time_count + 10;
                end
            end else if (addition == 3'b101) begin
                if (time_count < 4) begin
                    time_count <= time_count + 20;
                end else if (time_count < 10) begin
                    time_count <= time_count + 10;
                end else begin
                    time_count <= time_count - 10;
                end
            end else if (i_tick) begin
                time_count <= time_count + 1;
                if (time_count == (TIME_COUNT - 1)) begin
                    time_count <= 0;
                    o_tick <= 1;
                end else begin
                    o_tick <= 0;
                end
            end
        end
    end
endmodule
