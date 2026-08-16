`timescale 1ns / 1ps

module top_stopwatch (
    input clk,
    input reset,
    input btn_L,  // runstop(s) / 자리변경(w) 
    input btn_R,  // clear(s) / 자리변경(w)
    input btn_UP,  // mode(s) / up(w)
    input btn_DOWN,  // option(s) / down(w)
    input  [1:0] sw,        // sw[0]: 0-초:밀리초/1-시:분 sw[1]: 0-stopwatch/1-watch
    output [3:0] fnd_com,
    output [7:0] fnd_data,
    output [1:0] led  // indicator
);
    // 아직 아무 기능이 없으니 일단 켜두기
    assign led = 2'b11;

    // btn debounder OUTPUT SIGNAL
    wire w_btn_L, w_btn_R, w_btn_UP, w_btn_DOWN;

    // control unit -> datapath
    wire w_runstop, w_clear, w_mode;


    wire [1:0] w_state;
    wire [1:0] w_fnd_state;

    // 결정된 시간 데이터
    wire [6:0] w_msec;
    wire [5:0] w_sec, w_min;
    wire [4:0] w_hour;

    // stopwatch의 시간 데이터
    wire [6:0] w_msec_stopwatch;
    wire [5:0] w_sec_stopwatch, w_min_stopwatch;
    wire [4:0] w_hour_stopwatch;

    // watch의 시간 데이터
    wire [6:0] w_msec_watch;
    wire [5:0] w_sec_watch, w_min_watch;
    wire [4:0] w_hour_watch;

    assign w_msec = (sw[1]) ? w_msec_watch : w_msec_stopwatch;
    assign w_sec = (sw[1]) ? w_sec_watch : w_sec_stopwatch;
    assign w_min = (sw[1]) ? w_min_watch : w_min_stopwatch;
    assign w_hour = (sw[1]) ? w_hour_watch : w_hour_stopwatch;

    assign w_fnd_state = (sw[1]) ? w_state : 2'b00;

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

    // stopwatch control unit
    control_unit U_CNTL_UNIT (
        .clk      (clk),
        .reset    (reset),
        .i_runstop(w_btn_L & !sw[1]),
        .i_clear  (w_btn_R & !sw[1]),
        .i_mode   (w_btn_UP & !sw[1]),
        .o_runstop(w_runstop),
        .o_clear  (w_clear),
        .o_mode   (w_mode)
    );

    // stopwatch datapath
    stopwatch_datapath U_DATAPATH (
        .clk    (clk),
        .reset  (reset),
        .runstop(w_runstop),
        .clear  (w_clear),
        .mode   (w_mode),
        .m_sec  (w_msec_stopwatch),
        .sec    (w_sec_stopwatch),
        .min    (w_min_stopwatch),
        .hour   (w_hour_stopwatch)
    );

    // watch control unit
    watch_control_unit U_CNTL_UNIT_WATCH (
        .clk  (clk),
        .reset(reset),
        .btn_L(w_btn_L & sw[1]),
        .btn_R(w_btn_R & sw[1]),
        .state(w_state)
    );

    // watch datapath
    watch_datapath U_DATAPATH_WATCH (
        .clk  (clk),
        .reset(reset),
        .up   (w_btn_UP & sw[1]),
        .down (w_btn_DOWN & sw[1]),
        .state(w_state),
        .msec(w_msec_watch),
        .sec  (w_sec_watch),
        .min  (w_min_watch),
        .hour (w_hour_watch)
    );

    fnd_controller U_FND_CNTL (
        .clk(clk),
        .reset(reset),
        .msec(w_msec),
        .sec(w_sec),
        .min(w_min),
        .hour(w_hour),
        .state(w_fnd_state),
        .sw(sw),
        .display_mode(sw[0]),  // sw[0] -> 0=초/1=시간 선택
        .fnd_com(fnd_com),
        .fnd_data(fnd_data)
    );

endmodule

module stopwatch_datapath #(
    parameter MSEC_WIDTH = 7,
    SEC_WIDTH = 6,
    MIN_WIDTH = 6,
    HOUR_WIDTH = 5
) (
    input                   clk,
    input                   reset,
    input                   runstop,
    input                   clear,
    input                   mode,
    output [MSEC_WIDTH-1:0] m_sec,
    output [ SEC_WIDTH-1:0] sec,
    output [ MIN_WIDTH-1:0] min,
    output [HOUR_WIDTH-1:0] hour
);

    wire w_tick_msec, w_tick_sec, w_tick_min, w_tick_hour;

    tick_gen_100hz GEN_100HZ (
        .clk(clk),
        .reset(reset),
        .o_tick(w_tick_msec)
    );

    time_counter #(
        .COUNT_NUM(100)
    ) U_COUNTER_MSEC (
        .clk(clk),
        .reset(reset),
        .i_tick(w_tick_msec),
        .mode(mode),
        .run_stop(runstop),
        .clear(clear),
        .time_cnt(m_sec),
        .o_tick(w_tick_sec)
    );

    time_counter #(
        .COUNT_NUM(60)
    ) U_COUNTER_SEC (
        .clk(clk),
        .reset(reset),
        .i_tick(w_tick_sec),
        .mode(mode),
        .run_stop(runstop),
        .clear(clear),
        .time_cnt(sec),
        .o_tick(w_tick_min)
    );

    time_counter #(
        .COUNT_NUM(60)
    ) U_COUNTER_MIN (
        .clk(clk),
        .reset(reset),
        .i_tick(w_tick_min),
        .mode(mode),
        .run_stop(runstop),
        .clear(clear),
        .time_cnt(min),
        .o_tick(w_tick_hour)
    );

    time_counter #(
        .COUNT_NUM(24)
    ) U_COUNTER_HOUR (
        .clk(clk),
        .reset(reset),
        .i_tick(w_tick_hour),
        .mode(mode),
        .run_stop(runstop),
        .clear(clear),
        .time_cnt(hour),
        .o_tick()
    );

endmodule

module time_counter #(
    parameter COUNT_NUM = 100
) (
    input clk,
    input reset,
    input i_tick,
    input mode,
    input run_stop,
    input clear,
    input load,
    input [$clog2(COUNT_NUM)-1:0] value,
    output reg [$clog2(COUNT_NUM)-1:0] time_cnt,
    output reg o_tick
);

    // always @(posedge clk, posedge reset) begin
    //     if (reset) begin
    //         time_cnt <= 0;
    //         o_tick   <= 1'b0;
    //     end else begin
    //         if (i_tick) begin
    //             time_cnt <= time_cnt + 1;
    //             if (time_cnt == (COUNT_NUM - 1)) begin
    //                 time_cnt <= 0;
    //                 o_tick   <= 1'b1;
    //             end
    //         end else begin
    //             o_tick <= 1'b0;
    //         end
    //     end
    // end

    always @(posedge clk, posedge reset) begin
        if (reset | clear) begin
            time_cnt <= 0;
            o_tick   <= 1'b0;
        end else begin
            if (i_tick & run_stop) begin
                if (!mode) begin
                    time_cnt <= time_cnt + 1;
                    if (time_cnt == COUNT_NUM - 1) begin
                        time_cnt <= 0;
                        o_tick   <= 1'b1;
                    end
                end else begin
                    time_cnt <= time_cnt - 1;
                    if (time_cnt == 0) begin
                        time_cnt <= COUNT_NUM - 1;
                        o_tick   <= 1'b1;
                    end
                end
            end else begin
                o_tick <= 1'b0;
            end
            if(load) time_cnt <= value;
        end
    end

endmodule


module tick_gen_100hz (
    input clk,
    input reset,
    output reg o_tick
);

    parameter F_COUNT = 1_000_000;
    //parameter F_COUNT = 1000;
    reg [$clog2(F_COUNT)-1:0] counter_reg;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            counter_reg <= 0;
            o_tick <= 1'b0;
        end else begin
            if (counter_reg == F_COUNT - 1) begin
                counter_reg <= 0;
                o_tick <= 1'b1;
            end else begin
                counter_reg <= counter_reg + 1;
                o_tick <= 1'b0;
            end
        end
    end

endmodule

