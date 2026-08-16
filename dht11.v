`timescale 1ns / 1ps

module dht11 (
    input clk,
    input reset,
    input start,
    output [15:0] humidity,
    output [15:0] temperature,
    output done,
    output valid,
    inout dht11_io
);

    localparam [2:0] IDLE = 0, START = 1, WAIT = 2, SYNC = 3, DATA_L = 4, DATA_H = 5, STOP = 6;
    reg [2:0] c_state, n_state;
    wire tick_us;
    reg [$clog2(19_000)-1:0] tick_count_reg, tick_count_next;

    reg io_control;
    reg dht11_io_reg, dht11_io_next;
    // 40까지라 6비트 사용
    reg [5:0] bit_count_reg, bit_count_next;
    //high구간 길이 용도
    reg [6:0] high_time_reg, high_time_next;
    //직전클럭값
    reg data_prev_reg;

    // ---- 비동기 입력 동기화 (2단 FF) ----
    reg dht_sync1, dht_sync2;
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            dht_sync1 <= 1'b1;
            dht_sync2 <= 1'b1;
        end else begin
            dht_sync1 <= dht11_io;
            dht_sync2 <= dht_sync1;
        end
    end

    assign dht11_io = (io_control) ? (dht11_io_reg) : 1'bz;
    //falling,rising edge 감지 (동기화된 신호 기준)
    wire falling_edge, rising_edge;
    assign falling_edge = data_prev_reg & ~dht_sync2;
    assign rising_edge  = ~data_prev_reg & dht_sync2;
    //판정된 40비트 시프트하는 용도
    reg [39:0] shift_reg, shift_next;

    //sync 부분 low,high
    reg sync_reg, sync_next;

    //습도부 정수와 소수
    assign humidity = {shift_reg[39:32], shift_reg[31:24]};

    //온도부 정수와 소수
    assign temperature = {shift_reg[23:16], shift_reg[15:8]};

    //40비트하면 완료
    assign done = (bit_count_reg == 40);

    //check sum
    wire [7:0] check_sum;
    assign check_sum = shift_reg[39:32] + shift_reg[31:24] + shift_reg[23:16] + shift_reg[15:8];
    assign valid = check_sum == shift_reg[7:0];

    tick_us U_TICK_US (
        .clk(clk),
        .reset(reset),
        .run_stop(1'b1),
        .clear(1'b0),
        .o_tick_us(tick_us)
    );

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            c_state <= IDLE;
            dht11_io_reg <= 1'b1;
            tick_count_reg <= 0;
            bit_count_reg <= 0;
            high_time_reg <= 0;
            data_prev_reg <= 1;
            shift_reg <= 0;
            sync_reg <= 0;
        end else begin
            c_state <= n_state;
            dht11_io_reg <= dht11_io_next;
            tick_count_reg <= tick_count_next;
            bit_count_reg <= bit_count_next;
            high_time_reg <= high_time_next;
            data_prev_reg <= dht_sync2;
            shift_reg <= shift_next;
            sync_reg <= sync_next;
        end
    end

    always @(*) begin
        n_state = c_state;
        dht11_io_next = dht11_io_reg;
        io_control = 1'b1;
        tick_count_next = tick_count_reg;
        bit_count_next = bit_count_reg;
        high_time_next = high_time_reg;
        shift_next = shift_reg;
        sync_next = sync_reg;
        case (c_state)
            IDLE: begin
                dht11_io_next = 1;
                io_control = 1'b1;
                tick_count_next = 0;
                if (start) begin
                    n_state = START;
                end
            end
            START: begin
                dht11_io_next = 0;
                io_control = 1'b1;
                //19msec low
                if (tick_us)
                    if (tick_count_reg == 19_000) begin
                        tick_count_next = 0;
                        n_state = WAIT;
                    end else tick_count_next = tick_count_reg + 1;
            end
            WAIT: begin
                dht11_io_next = 1;
                io_control = 1'b1;
                //30usec low
                if (tick_us)
                    if (tick_count_reg == 30) begin
                        n_state = SYNC;
                    end else tick_count_next = tick_count_reg + 1;
            end
            SYNC: begin
                dht11_io_next = 0;
                io_control = 0;
                //tick조건 없이 클럭만 체크
                if (sync_reg == 0) begin
                    if (rising_edge) begin
                        sync_next = 1;
                    end
                end else begin
                    if (falling_edge) begin
                        n_state   = DATA_L;
                        sync_next = 0;
                        bit_count_next = 0;
                    end
                end
            end
            DATA_L: begin
                dht11_io_next = 0;
                io_control = 0;
                if(rising_edge) begin
                    high_time_next = 0;
                    n_state = DATA_H;
                end
            end
            DATA_H : begin
                io_control = 0;
                if(falling_edge) begin
                    bit_count_next = bit_count_reg + 1;
                    shift_next = {
                                shift_reg[38:0],
                                (high_time_reg > 50) ? 1'b1 : 1'b0
                            };
                            if(bit_count_reg + 1 == 40) n_state = STOP;
                            else n_state = DATA_L;
                end else if (tick_us) begin
                    high_time_next = high_time_reg + 1;
                end
            end
            STOP: begin
                dht11_io_next = 0;
                io_control = 0;
                if (tick_us) begin
                    if (tick_count_reg > 50) begin
                        n_state = IDLE;
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end
        endcase

    end
endmodule