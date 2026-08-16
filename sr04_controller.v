`timescale 1ns / 1ps `timescale 1ns / 1ps

module Top_SR04 (
    input        clk,
    input        reset,
    input        btn_start,
    output       trigger,
    input        echo,
    output [3:0] fnd_com,
    output [7:0] fnd_data,
    output led_done
);
    wire        w_start;
    wire [15:0] w_distance;
    wire        w_done;




    Btn_debouncer U_BD (
        .clk  (clk),
        .rst  (reset),
        .i_btn(btn_start),
        .o_btn(w_start)
    );

    sr04_controller U_SR04 (
        .clk     (clk),
        .reset   (reset),
        .start   (w_start),
        .echo    (echo),
        .trigger (trigger),
        .done    (w_done),
        .distance(w_distance)
    );

    fnd_distance_controller U_FND (
        .clk     (clk),
        .rst     (reset),
        .distance(w_distance),
        .fnd_com (fnd_com),
        .fnd_data(fnd_data)
    );

    reg led_done_reg;
    always @(posedge clk, posedge reset) begin
        if(reset) led_done_reg <= 0;
        else if(w_done) led_done_reg <=1;
        else if(w_start) led_done_reg <=0;
    end
    assign led_done = led_done_reg;

endmodule




`timescale 1ns / 1ps

module tick_us_sr04(
    input clk,
    input reset,
    input run_stop,
    input clear,
    output reg o_tick_us
);
    parameter COUNT_MAX = 100;
    reg [$clog2(COUNT_MAX)-1:0] count;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            count     <= 0;
            o_tick_us <= 0;
        end else if (clear) begin
            count     <= 0;
            o_tick_us <= 0;
        end else if (run_stop) begin
            if (count == COUNT_MAX - 1) begin
                count     <= 0;
                o_tick_us <= 1;
            end else begin
                count     <= count + 1;
                o_tick_us <= 0;
            end
        end else begin
            o_tick_us <= 0;
        end
    end
endmodule


module sr04_controller (
    input clk,
    input reset,
    input start,
    input echo,
    output trigger,
    output done,
    output [15:0] distance
);
    localparam [2:0] idle = 0, start_s = 1, wait_in = 2, count = 3, calc = 4;

    reg [2:0] c_state, n_state;
    reg [7:0] tick_cnt_reg, tick_cnt_next;
    reg [5:0] echo_cnt_reg, echo_cnt_next;
    reg [8:0] dist_cnt_reg, dist_cnt_next;
    reg trig_reg, trig_next;
    reg done_reg, done_next;
    reg [8:0] distance_reg, distance_next;
    reg run_stop_reg, run_stop_next;
    reg clear_reg, clear_next;

    wire w_tick_us;

    reg [1:0] echo_sync;
    always @(posedge clk, posedge reset) begin
        if(reset) begin
            echo_sync <= 2'b00;
    end else begin
        echo_sync <= {echo_sync[0], echo};
    end
    end
    wire echo_stable = echo_sync[1];

    tick_us_sr04 U_TICK_US (
        .clk(clk),
        .reset(reset),
        .run_stop(run_stop_reg),
        .clear(clear_reg),
        .o_tick_us(w_tick_us)
    );

    assign trigger  = trig_reg;
    assign done     = done_reg;
    assign distance = distance_reg;

    // state register
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            c_state      <= idle;
            tick_cnt_reg <= 0;
            echo_cnt_reg <= 0;
            dist_cnt_reg <= 0;
            trig_reg     <= 0;
            done_reg     <= 0;
            distance_reg <= 0;
            run_stop_reg <= 0;
            clear_reg    <= 0;
        end else begin
            c_state      <= n_state;
            tick_cnt_reg <= tick_cnt_next;
            echo_cnt_reg <= echo_cnt_next;
            dist_cnt_reg <= dist_cnt_next;
            trig_reg     <= trig_next;
            done_reg     <= done_next;
            distance_reg <= distance_next;
            run_stop_reg <= run_stop_next;
            clear_reg    <= clear_next;
        end
    end

    // next state, output logic
    always @(*) begin
        n_state       = c_state;
        tick_cnt_next = tick_cnt_reg;
        echo_cnt_next = echo_cnt_reg;
        dist_cnt_next = dist_cnt_reg;
        trig_next     = trig_reg;
        done_next     = 1'b0;
        distance_next = distance_reg;
        run_stop_next = 1'b1;
        clear_next    = 1'b0;

        case (c_state)
            idle: begin
                trig_next     = 1'b0;
                run_stop_next = 1'b0;
                if (start) n_state = start_s;
            end

            start_s: begin
                tick_cnt_next = 0;
                echo_cnt_next = 0; 
                clear_next    = 1'b1;
                n_state       = wait_in;
            end

            wait_in: begin

                trig_next = 1'b1;
                if (w_tick_us) begin
                    if (tick_cnt_reg == 4'd10) begin
                        tick_cnt_next = 0;
                        distance_next = 0;
                        dist_cnt_next = 0;
                        echo_cnt_next = 0;
                        n_state = count;
                    end else begin
                        tick_cnt_next = tick_cnt_reg + 1;
                    end
                end
            end

            count: begin
                trig_next = 1'b0;
                if (echo_stable) begin
                    if (w_tick_us) begin
                        if(echo_cnt_reg ==6'd57) begin
                            echo_cnt_next = 0;
                            dist_cnt_next = dist_cnt_reg + 1;
                    end else begin
                        echo_cnt_next = echo_cnt_reg + 1;
                    end
                    end
            end else begin
                if (dist_cnt_reg != 0 || echo_cnt_reg != 0) begin
                n_state = calc;
            end
            end
            end
            
            calc: begin
                if(dist_cnt_reg > 9'd400) begin
                    distance_next = 9'd0;
            end else begin
                distance_next = dist_cnt_reg;
            end
            done_next =1'b1;
            n_state = idle;
            end
            default: n_state = idle;
        endcase
    end
endmodule
