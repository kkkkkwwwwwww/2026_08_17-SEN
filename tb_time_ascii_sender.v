`timescale 1ns / 1ps

module tb_time_ascii_sender;

    reg clk;
    reg reset;
    reg get_trigger;
    reg fifo_full;
    reg sw_detail;
    reg [1:0] sw_mode;
    reg [6:0] msec;
    reg [5:0] sec;
    reg [5:0] min;
    reg [4:0] hour;
    reg [8:0] distance;
    reg [7:0] temp;
    reg [7:0] hum;
    wire [7:0] tx_data;
    wire tx_push;
    wire busy;

    time_ascii_sender U_DUT (
        .clk(clk),
        .reset(reset),
        .get_trigger(get_trigger),
        .fifo_full(fifo_full),
        .sw_detail(sw_detail),
        .sw_mode(sw_mode),
        .msec(msec),
        .sec(sec),
        .min(min),
        .hour(hour),
        .distance(distance),
        .temp(temp),
        .hum(hum),
        .tx_data(tx_data),
        .tx_push(tx_push),
        .busy(busy)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;
        get_trigger = 0;
        fifo_full = 0;
        sw_detail = 0;
        sw_mode = 2'b00;
        msec = 45;
        sec = 23;
        min = 12;
        hour = 5;
        distance = 296;
        temp = 26;
        hum = 52;

        #20;
        reset = 0;
        #20;

        // 시간 모드 (sw_mode=00)
        get_trigger = 1;
        #10;
        get_trigger = 0;
        #200;

        // 거리 모드 (sw_mode=01)
        sw_mode = 2'b01;
        #20;
        get_trigger = 1;
        #10;
        get_trigger = 0;
        #200;

        // 온습도 모드 (sw_mode=10)
        sw_mode = 2'b10;
        #20;
        get_trigger = 1;
        #10;
        get_trigger = 0;
        #200;

        $finish;
    end

endmodule