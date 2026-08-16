`timescale 1ns / 1ps

module Top_stopwatch_watch #(
    parameter MSEC_WIDTH = 7,
    SEC_WIDTH = 6,
    MIN_WIDTH = 6,
    HOUR_WIDTH = 5
) (
    input        clk,
    input        rst,
    input  [3:0] sw,
    input        btnL,
    input        btnR,
    input        btnU,
    input        btnD,
    input        echo,
    input        rx,
    output       tx,
    output [3:0] fnd_com,
    output [7:0] fnd_data,
    output [7:0] led_watch,
    output [1:0] led_sw,
    output       trigger,
    inout        dht11_io

);

    wire w_tick_1hz;
    wire w_sr04_start, w_dht_start;
    wire w_sr04_done, w_dht_done, w_dht_valid;
    wire [15:0] w_distance;
    wire [15:0] w_h, w_t;

    wire sy_btnL, sy_btnR, sy_btnU, sy_btnD;
    wire w_btnL, w_btnR, w_btnU, w_btnD;
    wire sw_btnL, sw_btnR, sw_btnU, sw_btnD;
    wire [MSEC_WIDTH - 1:0] sw_msec;
    wire [SEC_WIDTH - 1:0] sw_sec;
    wire [MIN_WIDTH - 1:0] sw_min;
    wire [HOUR_WIDTH - 1:0] sw_hour;
    wire [MSEC_WIDTH - 1:0] w_msec;
    wire [SEC_WIDTH - 1:0] w_sec;
    wire [MIN_WIDTH - 1:0] w_min;
    wire [HOUR_WIDTH - 1:0] w_hour;
    wire [MSEC_WIDTH - 1:0] msec;
    wire [SEC_WIDTH - 1:0] sec;
    wire [MIN_WIDTH - 1:0] min;
    wire [HOUR_WIDTH - 1:0] hour;
    wire [2:0] position;
    wire w_uart_run_stop, w_uart_clear, w_uart_mode, w_uart_down, w_uart_up, w_uart_right, w_uart_left;
    wire w_run_state;

    wire m_btnL = sw_btnL | w_uart_run_stop;
    wire m_btnR = sw_btnR | w_uart_clear;
    wire m_btnU = sw_btnU | w_uart_mode;
    wire n_btnL = w_btnL | w_uart_left;
    wire n_btnR = w_btnR | w_uart_right;
    wire n_btnU = w_btnU | w_uart_up;
    wire n_btnD = w_btnD | w_uart_down;

    wire [7:0] w_rx_data;
    wire w_rx_done;
    wire [7:0] w_fifo_rx_rdata;
    wire w_fifo_rx_empty;

    wire [7:0] w_tx_data;
    wire w_tx_push;
    wire [7:0] w_fifo_tx_rdata;
    wire w_fifo_tx_empty;
    wire w_tx_busy;
    wire w_tx_done;

    wire w_uart_get;
    wire [7:0] w_time_tx_data;
    wire w_time_tx_push, w_time_busy;

    wire [7:0] final_tx_data = w_tx_push ? w_tx_data : w_time_tx_data;
    wire       final_tx_push = w_tx_push | w_time_tx_push;

    wire       w_fifo_tx_full;

    reg  [8:0] distance_reg;
    reg [7:0] hum_reg, temp_reg;
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            distance_reg <= 0;
            hum_reg <= 0;
            temp_reg <= 0;
        end else begin
            if (w_sr04_done) distance_reg <= w_distance[8:0];
            if (w_dht_done && w_dht_valid) begin
                hum_reg  <= w_h[15:8];
                temp_reg <= w_t[15:8];
            end
        end
    end

    tick_1hz U_TICK_1HZ (
        .clk(clk),
        .reset(rst),
        .o_tick_1hz(w_tick_1hz)
    );
    sensor_sequencer U_SEN_SEQ (
        .clk(clk),
        .reset(rst),
        .tick_1hz(w_tick_1hz),
        .sr04_done(w_sr04_done),
        .dht11_done(w_dht_done),
        .sr04_start(w_sr04_start),
        .dht11_start(w_dht_start)
    );
    sr04_controller U_SR04_CON (
        .clk(clk),
        .reset(rst),
        .start(w_sr04_start),
        .echo(echo),
        .trigger(trigger),
        .done(w_sr04_done),
        .distance(w_distance)
    );


    t_h_controller U_T_H_CON (
        .clk(clk),
        .reset(rst),
        .start(w_dht_start),
        .dht11_io(dht11_io),
        .done(w_dht_done),
        .valid(w_dht_valid),
        .h(w_h),
        .t(w_t)
    );

    uart_controller U_UART_CONTROLLER (
        .clk(clk),
        .reset(rst),
        .rx(rx),
        .tx(tx),
        .rx_data(w_rx_data),
        .rx_done(w_rx_done),
        .tx_data(w_fifo_tx_rdata),
        .tx_start(~w_fifo_tx_empty),
        .tx_busy(w_tx_busy),
        .tx_done(w_tx_done)
    );
    fifo #(
        .width(2)
    ) U_FIFO_RX (
        .clk  (clk),
        .reset(rst),
        .push (w_rx_done),
        .pop  (~w_fifo_rx_empty),
        .wdata(w_rx_data),
        .rdata(w_fifo_rx_rdata),
        .full (),
        .empty(w_fifo_rx_empty)
    );
    fifo #(
        .width(2)
    ) U_FIFO_TX (
        .clk  (clk),
        .reset(rst),
        .push (final_tx_push),
        .pop  (~w_tx_busy),
        .wdata(final_tx_data),
        .rdata(w_fifo_tx_rdata),
        .full (w_fifo_tx_full),
        .empty(w_fifo_tx_empty)
    );




    ascii_decoder U_ASCII_DECODER (
        .clk(clk),
        .reset(rst),
        .rx_data(w_fifo_rx_rdata),
        .rx_done(~w_fifo_rx_empty),
        .run_state(w_run_state),
        .o_run_stop(w_uart_run_stop),
        .o_clear(w_uart_clear),
        .o_mode(w_uart_mode),
        .o_right(w_uart_right),
        .o_left(w_uart_left),
        .o_up(w_uart_up),
        .o_down(w_uart_down),
        .o_get(w_uart_get)
    );


    ascii_sender U_ASCII_SENDER (
        .clk(clk),
        .reset(rst),
        .i_run_stop(m_btnL),
        .i_clear(m_btnR),
        .i_mode(m_btnU),
        .i_left(n_btnL),
        .i_right(n_btnR),
        .i_up(n_btnU),
        .i_down(n_btnD),
        .run_state(w_run_state),
        .tx_data(w_tx_data),
        .tx_push(w_tx_push)
    );

    time_ascii_sender U_TIME_SENDER (
        .clk(clk),
        .reset(rst),
        .get_trigger(w_uart_get),
        .fifo_full(w_fifo_tx_full),
        .sw_detail(sw[0]),
        .sw_mode(sw[3:2]),
        .msec(msec),
        .sec(sec),
        .min(min),
        .hour(hour),
        .distance(distance_reg),
        .temp(temp_reg),
        .hum(hum_reg),
        .tx_data(w_time_tx_data),
        .tx_push(w_time_tx_push),
        .busy(w_time_busy)
    );

    Btn_debouncer Btn_debouncer_btnL (
        .clk  (clk),
        .rst  (rst),
        .i_btn(btnL),
        .o_btn(sy_btnL)
    );
    Btn_debouncer Btn_debouncer_btnR (
        .clk  (clk),
        .rst  (rst),
        .i_btn(btnR),
        .o_btn(sy_btnR)
    );
    Btn_debouncer Btn_debouncer_btnU (
        .clk  (clk),
        .rst  (rst),
        .i_btn(btnU),
        .o_btn(sy_btnU)
    );
    Btn_debouncer Btn_debouncer_btnD (
        .clk  (clk),
        .rst  (rst),
        .i_btn(btnD),
        .o_btn(sy_btnD)
    );


    Btn_Demuxer Btn_Demuxer_0 (
        .sy_btnL(sy_btnL),
        .sy_btnR(sy_btnR),
        .sy_btnU(sy_btnU),
        .sy_btnD(sy_btnD),
        .sw(sw[1]),
        .w_btnL(w_btnL),
        .w_btnR(w_btnR),
        .w_btnU(w_btnU),
        .w_btnD(w_btnD),
        .sw_btnL(sw_btnL),
        .sw_btnR(sw_btnR),
        .sw_btnU(sw_btnU),
        .sw_btnD(sw_btnD)
    );
    Top_stopwatch Top_stopwatch_0 (
        .clk(clk),
        .rst(rst),
        .btnU(m_btnU),
        .btnL(m_btnL),
        .btnR(m_btnR),
        .msec(sw_msec),
        .sec(sw_sec),
        .min(sw_min),
        .hour(sw_hour),
        .o_run_stop_status(w_run_state)
    );
    Top_watch Top_watch_0 (
        .clk(clk),
        .rst(rst),
        .btnL(n_btnL),
        .btnR(n_btnR),
        .btnU(n_btnU),
        .btnD(n_btnD),
        .msec(w_msec),
        .sec(w_sec),
        .min(w_min),
        .hour(w_hour),
        .o_position(position)
    );

    assign msec = (sw[1]) ? w_msec : sw_msec;
    assign sec = (sw[1]) ? w_sec : sw_sec;
    assign min = (sw[1]) ? w_min : sw_min;
    assign hour = (sw[1]) ? w_hour : sw_hour;
    assign led_sw = sw;


    Fnd_controller Fnd_controller_0 (
        .clk(clk),
        .rst(rst),
        .sw_mode(sw[3:2]),
        .sw_detail(sw[0]),
        .msec(msec),
        .sec(sec),
        .min(min),
        .hour(hour),
        .distance(distance_reg),
        .temp(temp_reg),
        .hum(hum_reg),
        .fnd_com(fnd_com),
        .fnd_data(fnd_data)
    );
    WatchPostion_to_LED WatchPostion_to_LED_0 (
        .position(position),
        .sw(sw[1]),
        .led_watch(led_watch)
    );

endmodule

module WatchPostion_to_LED (
    input      [2:0] position,
    input            sw,
    output reg [7:0] led_watch
);
    always @(*) begin
        led_watch = 8'b0000_0000;
        if (sw) begin
            case (position)
                3'b000: led_watch = 8'b0000_0001;
                3'b001: led_watch = 8'b0000_0010;
                3'b010: led_watch = 8'b0000_0100;
                3'b011: led_watch = 8'b0000_1000;
                3'b100: led_watch = 8'b0001_0000;
                3'b101: led_watch = 8'b0010_0000;
                3'b110: led_watch = 8'b0100_0000;
                3'b111: led_watch = 8'b1000_0000;
            endcase
        end
    end
endmodule

module Btn_Demuxer (
    input  sy_btnL,
    input  sy_btnR,
    input  sy_btnU,
    input  sy_btnD,
    input  sw,
    output w_btnL,
    output w_btnR,
    output w_btnU,
    output w_btnD,
    output sw_btnL,
    output sw_btnR,
    output sw_btnU,
    output sw_btnD
);
    assign w_btnL  = sw ? sy_btnL : 0;
    assign sw_btnL = sw ? 0 : sy_btnL;
    assign w_btnR  = sw ? sy_btnR : 0;
    assign sw_btnR = sw ? 0 : sy_btnR;
    assign w_btnU  = sw ? sy_btnU : 0;
    assign sw_btnU = sw ? 0 : sy_btnU;
    assign w_btnD  = sw ? sy_btnD : 0;
    assign sw_btnD = sw ? 0 : sy_btnD;

endmodule
