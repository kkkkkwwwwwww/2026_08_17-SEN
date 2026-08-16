`timescale 1ns / 1ps

module sr04_controller (
    input clk,
    input reset,
    input start,
    input echo,
    output reg trigger,
    output [8:0] distance
);
    wire w_tick_us;
    //fsm control_unit
    //5개니까 3비트로
    localparam [2:0] IDLE = 0, START = 1, WAIT = 2, COUNT = 3, DISTANCE = 4;
    reg [2:0] c_state, n_state;
    reg run_stop, clear;
    reg [$clog2(58*400)-1:0] counter_reg, counter_next;
    // reg done_reg, done_next;
    reg [8:0] distance_reg, distance_next;

    // assign done = done_reg;
    assign distance = distance_reg;

    // ila_1 U_ILA (
    //     .clk(clk),
    //     .probe0(start),  //start
    //     .probe1(trigger),  //trigger
    //     .probe2(echo),  //echo
    //     .probe3(c_state)  //c_state
    // );

    tick_us U_TICK_US (
        .clk(clk),
        .reset(reset),
        .run_stop(run_stop),
        .clear(clear),
        .o_tick_us(w_tick_us)
    );

    // assign distance = 9'd123;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            c_state <= IDLE;
            counter_reg <= 0;
            // done_reg <= 1'b0;
            distance_reg <= 9'd0;
        end else begin
            c_state <= n_state;
            counter_reg <= counter_next;
            // done_reg <= done_next;
            distance_reg <= distance_next;
        end
    end

    //next , output
    always @(*) begin
        n_state = c_state;
        counter_next = counter_reg;
        // done_next = done_reg;
        distance_next = distance_reg;
        run_stop = 1'b0;
        clear = 1'b0;
        trigger = 1'b0;
        case (c_state)
            IDLE: begin
                run_stop = 1'b0;
                clear = 1'b1;
                if (start) begin
                    n_state = START;
                    counter_next = 0;
                end
            end
            //start에선 trigger생성. tick_cnt동작시키게 
            //tick_us : run_stop=1 , clear = 0, trigger = 1
            START: begin
                run_stop = 1'b1;
                clear = 1'b0;
                trigger = 1'b1;
                if (w_tick_us) begin
                    //start에서 wait로 가려면 tick이 10번 필요 -> tick_cnt 필요
                    counter_next = counter_reg + 1;
                end
                //시작하자마자 틱이 생성되는게 아니기 때문에 10이 아닌 11
                //다음으로 바뀌려면 tick_cnt = 11
                if (counter_reg == 11) begin
                    counter_next = 0;
                    n_state = WAIT;
                end
            end
            WAIT: begin
                run_stop = 1'b1;
                clear = 1'b0;
                trigger = 1'b0;
                if (w_tick_us) begin
                    if (echo) begin
                        counter_next = counter_reg + 1;
                        n_state = COUNT;
                    end
                end
                //test
                // n_state = IDLE;
                // run_stop = 1'b0;
                // clear = 1'b0;
                // trigger = 1'b0;
            end
            COUNT: begin
                run_stop = 1'b1;
                clear = 1'b0;
                trigger = 1'b0;
                if (w_tick_us) begin
                    if (echo) begin
                        counter_next = counter_reg + 1; //echo=1인 동안 계속 카운트
                    end else begin
                        n_state = DISTANCE; /// echo=0으로 떨어지면 종료
                    end
                end
            end
            DISTANCE: begin
                // distance_next = counter_reg / 58;
                // 나눗셈연산 slack time negative 해결방안
                distance_next = (counter_reg * 1130) >> 16;
                // done_next = 1'b1;
                n_state = IDLE;
            end
        endcase
    end


endmodule

module tick_us (
    input  clk,
    input  reset,
    input  run_stop,
    input  clear,
    output o_tick_us
);
    //100mhz
    parameter F_COUNT = 100;

    reg [$clog2(F_COUNT)-1:0] counter_reg;
    reg tick_us_reg;

    assign o_tick_us = tick_us_reg;


    always @(posedge clk, posedge reset) begin
        if (reset | clear) begin
            counter_reg <= 0;
            tick_us_reg <= 0;
        end else begin
            if (run_stop) begin
                counter_reg <= counter_reg + 1;
                if (counter_reg == (F_COUNT - 1)) begin
                    counter_reg <= 0;
                    tick_us_reg <= 1'b1;
                end else begin
                    tick_us_reg <= 1'b0;
                end
            end
        end
    end

endmodule
