`timescale 1ns / 1ps
module sensor_stopwatch_watch_uart_fifo (
    input clk,
    input reset,
    input btn_L,
    input btn_R,
    input btn_UP,
    input btn_DOWN,
    input [4:0] sw,
    input rx,
    input echo,
    output [3:0] fnd_com,
    output [7:0] fnd_data,
    output led,
    output tx,
    output trigger,
    inout dht11_io
);
    //mode 정의
    wire [1:0] mode = sw[4:3];

    //btn_debounce
    wire w_btn_L, w_btn_R, w_btn_UP, w_btn_DOWN;

    //ascii_decoder 입력
    wire w_ascii_in;
    wire w_ascii_in_valid;
    wire w_tx_full;

    //ascii_decoder 출력
    wire w_dec_run_stop, w_dec_clear, w_dec_mode;
    wire w_dec_left, w_dec_right, w_dec_up, w_dec_down, w_dec_get;

    //stopwatch control unit - datapath
    wire w_runstop, w_clear, w_sw_mode, w_save, w_load;
    wire w_is_data_saved;
    assign led = w_is_data_saved;

    wire [6:0] w_msec_stopwatch;
    wire [5:0] w_sec_stopwatch, w_min_stopwatch;
    wire [4:0] w_hour_stopwatch;

    wire [6:0] w_msec_watch;
    wire [5:0] w_sec_watch, w_min_watch;
    wire [4:0] w_hour_watch;

    //watch control unit - datapath
    wire [1:0] w_state;

    // mode → sender의 sw_mode로 변환   
    wire [1:0] w_sender_sw_mode = (mode == 2'b10) ? 2'b01 :   // SR04 → sender의 distance 분기
    (mode == 2'b11) ? 2'b10 :  // DHT  → sender의 temp/hum 분기
    2'b00;  // STOPWATCH/WATCH → sender의 default 분기

    wire [15:0] w_humidity, w_temperature;
    wire [8:0] w_distance;
    wire w_send_trigger;

    wire [6:0] w_msec;
    wire [5:0] w_sec, w_min;
    wire [4:0] w_hour;
    wire w_format12_watch;
    reg [4:0] w_hour_display_watch;
    assign w_format12_watch = sw[2];

    always @(*) begin
        w_hour_display_watch = w_hour_watch;
        if (w_format12_watch) begin
            if (w_hour_watch > 12) w_hour_display_watch = w_hour_watch - 12;
            else if (w_hour_watch == 0) w_hour_display_watch = 12;
        end
    end

    assign w_msec = (mode == 2'b01) ? w_msec_watch : w_msec_stopwatch;
    assign w_sec  = (mode == 2'b01) ? w_sec_watch : w_sec_stopwatch;
    assign w_min  = (mode == 2'b01) ? w_min_watch : w_min_stopwatch;
    assign w_hour = (mode == 2'b01) ? w_hour_display_watch : w_hour_stopwatch;

    wire [7:0] w_time_tx_data;
    wire w_time_tx_push, w_time_busy;

    wire w_run_state;   // decoder의 r/s 판정용, stopwatch의 현재 runstop 상태
    assign w_run_state = w_runstop;

    wire [7:0] w_btn_tx_data;
    wire w_btn_tx_push;

    wire [1:0] w_fnd_state;
    assign w_fnd_state = (mode == 2'b01) ? w_state : 2'b00;

    wire w_dht_start_pulse;

    wire w_sr04_start_pulse;
    //pc가 요청하는 트리거 
    wire [7:0] i_tx_data;
    wire       i_tx_valid;
   
    assign w_send_trigger = w_dec_get;
    //fifo tx mux 
    //ascii_sender의 버튼 이벤트, time_ascii_sender의 시간/센서 데이터 중 어느 쪽 출력을 FIFO_TX에 밀어넣을지 고르는 셀렉터
    assign i_tx_data = w_btn_tx_push ? w_btn_tx_data : w_time_tx_data;
    assign i_tx_valid = w_btn_tx_push | w_time_tx_push;

    tick_gen_100hz #(
        .F_COUNT(10_000_000)  // 100MHz 기준 100ms 주기
    ) U_TICK_GEN_SR04 (
        .clk(clk),
        .reset(reset),
        .o_tick(w_sr04_start_pulse)
    );

    sr04_controller U_SR04 (
        .clk(clk),
        .reset(reset),
        .start(w_sr04_start_pulse & (mode == 2'b10)),
        .echo(echo),
        .trigger(trigger),
        .distance(w_distance)
    );

    tick_gen_100hz #(
        .F_COUNT(100_000_000)  // 100MHz 기준 1초 주기
    ) U_TICK_GEN_DHT (
        .clk(clk),
        .reset(reset),
        .o_tick(w_dht_start_pulse)
    );

    dht11 U_DHT11 (
        .clk(clk),
        .reset(reset),
        .start(w_dht_start_pulse & (mode == 2'b11)),
        .humidity(w_humidity),
        .temperature(w_temperature),
        .done(),
        .valid(),
        .dht11_io(dht11_io)
    );

    fnd_controller U_FND_CNTL (
        .clk(clk),
        .reset(reset),
        .msec(w_msec),
        .sec(w_sec),
        .min(w_min),
        .hour(w_hour),
        .distance(w_distance),
        .humidity(w_humidity),
        .temperature(w_temperature),
        .mode(mode),
        .state(w_fnd_state),
        .sw(sw[1:0]),
        .display_mode(sw[0]),
        .fnd_com(fnd_com),
        .fnd_data(fnd_data)
    );

    ascii_sender U_ASCII_SENDER_BTN (
        .clk       (clk),
        .reset     (reset),
        .i_run_stop((w_btn_L | w_dec_run_stop) & (mode == 2'b00)),
        .i_clear   ((w_btn_R | w_dec_clear) & (mode == 2'b00)),
        .i_mode    ((w_btn_UP | w_dec_mode) & (mode == 2'b00)),
        .i_left    ((w_btn_L | w_dec_left) & (mode == 2'b01)),
        .i_right   ((w_btn_R | w_dec_right) & (mode == 2'b01)),
        .i_up      ((w_btn_UP | w_dec_up) & (mode == 2'b01)),
        .i_down    ((w_btn_DOWN | w_dec_down) & (mode == 2'b01)),
        .run_state (w_run_state),
        .tx_data   (w_btn_tx_data),
        .tx_push   (w_btn_tx_push)
    );

    ascii_decoder U_ASCII_DECODER (
        .clk(clk),
        .reset(reset),
        .rx_data(w_ascii_in),
        .rx_done(w_ascii_in_valid),
        .run_state(w_run_state),
        .o_run_stop(w_dec_run_stop),
        .o_clear(w_dec_clear),
        .o_mode(w_dec_mode),
        .o_left(w_dec_left),
        .o_right(w_dec_right),
        .o_up(w_dec_up),
        .o_down(w_dec_down),
        .o_get(w_dec_get)
    );

    time_ascii_sender U_TIME_ASCII_SENDER (
        .clk(clk),
        .reset(reset),
        .get_trigger(w_send_trigger),         // 주기적 트리거 (mode 상관없이 항상 동작)
        .fifo_full(w_tx_full),  // uart_fifo_loop_back의 o_tx_full
        .sw_detail(sw[0]),
        .sw_mode(w_sender_sw_mode),  // 위에서 변환한 신호
        .msec(w_msec),
        .sec(w_sec),
        .min(w_min),
        .hour(w_hour),   // FND용으로 이미 mode 프리먹스된 것 재사용
        .distance(w_distance),
        .temp(w_temperature[15:8]),  // 정수부만 (DHT 8비트)
        .hum(w_humidity[15:8]),
        .tx_data(w_time_tx_data),
        .tx_push(w_time_tx_push),
        .busy(w_time_busy)
    );

    // watch control unit
    watch_control_unit U_CNTL_UNIT_WATCH (
        .clk  (clk),
        .reset(reset),
        .btn_L((w_btn_L | w_dec_left) & (mode == 2'b01)),
        .btn_R((w_btn_R | w_dec_right) & (mode == 2'b01)),
        .state(w_state)
    );

    // watch datapath
    watch_datapath U_DATAPATH_WATCH (
        .clk  (clk),
        .reset(reset),
        .up   ((w_btn_UP | w_dec_up) & (mode == 2'b01)),
        .down ((w_btn_DOWN | w_dec_down) & (mode == 2'b01)),
        .state(w_state),
        .msec(w_msec_watch),
        .sec  (w_sec_watch),
        .min  (w_min_watch),
        .hour (w_hour_watch)
    );

    // stopwatch control unit
    control_unit U_CNTL_UNIT (
        .clk(clk),
        .reset(reset),
        .i_runstop((w_btn_L | w_dec_run_stop) & (mode == 2'b00)),
        .i_clear((w_btn_R | w_dec_clear) & (mode == 2'b00)),
        .i_mode((w_btn_UP | w_dec_mode) & (mode == 2'b00)),
        .i_save_load(w_btn_DOWN & (mode == 2'b00)),  // btn down
        .i_is_data_saved(w_is_data_saved), // datapath에 데이터 저장되어 있는지 t/f 
        .o_runstop(w_runstop),
        .o_clear(w_clear),
        .o_mode(w_sw_mode),
        .o_save(w_save),
        .o_load(w_load)
    );

    // stopwatch datapath
    stopwatch_datapath U_DATAPATH (
        .clk            (clk),
        .reset          (reset),
        .runstop        (w_runstop),
        .clear          (w_clear),
        .mode           (w_sw_mode),
        .save           (w_save),
        .load           (w_load),
        .o_is_data_saved(w_is_data_saved),
        .m_sec          (w_msec_stopwatch),
        .sec            (w_sec_stopwatch),
        .min            (w_min_stopwatch),
        .hour           (w_hour_stopwatch)
    );

    btn_debouncer U_DB_BTN_L (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_L),
        .o_btn(w_btn_L)
    );

    btn_debouncer U_DB_BTN_R (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_R),
        .o_btn(w_btn_R)
    );

    btn_debouncer U_DB_BTN_UP (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_UP),
        .o_btn(w_btn_UP)
    );

    btn_debouncer U_DB_BTN_DOWN (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_DOWN),
        .o_btn(w_btn_DOWN)
    );

    uart_fifo_loop_back U_UART_FIFO_LOOP_BACK (
        .clk(clk),
        .reset(reset),
        .rx(rx),
        .tx(tx),
        .o_tx_full(w_tx_full),
        .o_rx_data(w_ascii_in),
        .o_rx_valid(w_ascii_in_valid),
        .i_tx_data(i_tx_data),
        .i_tx_valid(i_tx_valid)
    );



endmodule
