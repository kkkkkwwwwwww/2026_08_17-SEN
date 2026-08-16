

`timescale 1ns / 1ps

module Top_stopwatch (
    input clk,
    input rst,
    input btnU,
    input btnL,
    input btnR,
    output [4:0] hour,
    output [5:0] min,
    output [6:0] msec,
    output [5:0] sec,
    output o_run_stop_status 
);
    wire w_run_stop, w_clear, w_mode;
  


    control_unit U_CONTROL_UNIT (
        .clk(clk),
        .reset(rst),
        .i_run_stop(btnL),
        .i_clear(btnR),
        .i_mode(btnU),
        .o_run_stop(w_run_stop),
        .o_clear(w_clear),
        .o_mode(w_mode)
    );
     assign o_run_stop_status = w_run_stop;

    stopwatch_datapath U_STOPWATCH_DATAPATH (

        .clk(clk),
        .reset(rst),
        .run_stop(w_run_stop),
        .clear(w_clear),
        .mode(w_mode),
        .msec(msec),
        .sec(sec),
        .min(min),
        .hour(hour)
    );



endmodule




module stopwatch_datapath #(
    parameter MSEC_WIDTH = 7,
    SEC_WIDTH = 6,
    MIN_WIDTH = 6,
    HOUR_WIDTH = 5
) (
    input clk,
    input reset,
    input run_stop,
    input clear,
    input mode,
    output [MSEC_WIDTH-1:0] msec,
    output [SEC_WIDTH-1:0] sec,
    output [MIN_WIDTH-1:0] min,
    output [HOUR_WIDTH-1:0] hour
);

    TIME_COUNT #(
        .BIT_WIDTH(MSEC_WIDTH),
        .TIMES(24)
    ) U_HOUR_COUNTER (
        .clk(clk),
        .reset(reset),
        .i_tick(w_tick_hour),
        .mode(mode),
        .run_stop(run_stop),
        .clear(clear),
        .time_counter(hour),
        .o_tick()
    );




    TIME_COUNT #(
        .BIT_WIDTH(MSEC_WIDTH),
        .TIMES(60)
    ) U_MIN_COUNTER (
        .clk(clk),
        .reset(reset),
        .i_tick(w_tick_min),
        .mode(mode),
        .run_stop(run_stop),
        .clear(clear),
        .time_counter(min),
        .o_tick(w_tick_hour)
    );


    TIME_COUNT #(
        .BIT_WIDTH(SEC_WIDTH),
        .TIMES(60)
    ) U_SEC_COUNTER (
        .clk(clk),
        .reset(reset),
        .i_tick(w_tick_sec),
        .mode(mode),
        .run_stop(run_stop),
        .clear(clear),
        .time_counter(sec),
        .o_tick(w_tick_min)
    );




    TIME_COUNT #(
        .BIT_WIDTH(MSEC_WIDTH),
        .TIMES(100)
    ) U_MSEC_COUNTER (
        .clk(clk),
        .reset(reset),
        .i_tick(w_tick_100hz),
        .mode(mode),
        .run_stop(run_stop),
        .clear(clear),
        .time_counter(msec),
        .o_tick(w_tick_sec)
    );
    tick_gen_100hz U_TICKGEN (
        .clk(clk),
        .reset(reset),
        .o_tick(w_tick_100hz)
    );



    // parameter  MSEC_WIDTH = 7, SEC_WIDTH = 6, MIN_WIDTH = 6, HOUR_WIDTH = 5;
endmodule


module tick_gen_100hz (
    input clk,
    input reset,
    output reg o_tick
);
    parameter count_max = 1_000_000;
    reg [$clog2(count_max) -1:0] counter_reg;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            counter_reg <= 0;
            o_tick <= 1'b0;
        end else begin
            counter_reg <= counter_reg + 1;
            if (counter_reg == (count_max - 1)) begin
                counter_reg <= 0;
                o_tick <= 1'b1;
            end else begin
                o_tick <= 1'b0;
            end
        end
    end


endmodule

// module time_counter #(
//     parameter BIT_WIDTH = 7,
//     TIMES = 100
// ) (
//     input clk,
//     input reset,
//     input i_tick,
//     input mode,
//     input run_stop,
//     input clear,
//     output [BIT_WIDTH-1:0] time_counter,
//     output reg o_tick
// );
//     reg [$clog2(TIMES)-1:0] counter_reg;
//     assign time_counter = counter_reg;

//     always @(posedge clk, posedge reset) begin
//         if (reset) begin
//             counter_reg <= 0;
//             o_tick <= 1'b0;
//         end else begin
//             if (i_tick & run_stop) begin
//                 if (!mode) begin
//                     counter_reg <= counter_reg + 1;
//                     if (counter_reg == (TIMES - 1)) begin
//                         counter_reg <= 0;
//                         o_tick <= 1'b1;
//                     end else begin 
//                         o_tick <=1'b0;
//                     end
//                 end else begin
//                     counter_reg <= counter_reg - 1;
//                     if (counter_reg == 0) begin
//                         counter_reg <= (TIMES - 1);
//                         o_tick <= 1'b1;
//                     end else begin
//                         o_tick <=1'b0;
//                     end
//                 end
//             end else begin
//                 o_tick <= 1'b0;

//             end
//         end
//     end

// endmodule

`timescale 1ns / 1ps

module control_unit (
    input  clk,
    input  reset,
    input  i_run_stop,
    input  i_clear,
    input  i_mode,
    output o_run_stop,
    output o_clear,
    output o_mode
);

    parameter stop = 0, run = 1, clear = 2, mode = 3;

    reg [1:0] c_state, n_state;
    reg run_stop_reg, run_stop_next, clear_reg, clear_next, mode_reg, mode_next;
    reg i_run_stop_prev, i_clear_prev, i_mode_prev;
    wire run_stop_edge, clear_edge, mode_edge;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            i_run_stop_prev <= 1'b0;
            i_clear_prev    <= 1'b0;
            i_mode_prev     <= 1'b0;
        end else begin
            i_run_stop_prev <= i_run_stop;
            i_clear_prev    <= i_clear;
            i_mode_prev     <= i_mode;
        end
    end

    assign run_stop_edge = i_run_stop & ~i_run_stop_prev; 
    assign clear_edge = i_clear & ~i_clear_prev;
    assign mode_edge = i_mode & ~i_mode_prev;

    // output
    assign o_run_stop = run_stop_reg;
    assign o_clear = clear_reg;
    assign o_mode = mode_reg;

    // state register
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            c_state <= stop;
            run_stop_reg <= 1'b0;
            clear_reg <= 1'b0;
            mode_reg <= 1'b0;
        end else begin
            c_state <= n_state;
            run_stop_reg <= run_stop_next;
            clear_reg <= clear_next;
            mode_reg <= mode_next;
        end
    end

    // next state combinational logic
    always @(*) begin
        n_state = c_state;
        run_stop_next = run_stop_reg;
        clear_next = clear_reg;
        mode_next = mode_reg;
        case (c_state)
            stop: begin
                clear_next = 1'b0;
                if (run_stop_edge) n_state = run;
                else if (clear_edge) n_state = clear;
                else if (mode_edge) n_state = mode;
                else n_state = c_state;
            end
            run: begin
                run_stop_next = 1'b1;
                if (run_stop_edge) begin
                    run_stop_next = 1'b0;
                    n_state = stop;
                end
            end
            clear: begin
                clear_next = 1'b1;   
                n_state = stop;
            end
            mode: begin
                mode_next = ~mode_reg;
                n_state   = stop;
            end
        endcase
    end

endmodule



// module STOPWATCH_DATAPATH #(
//     parameter MSEC_WIDTH = 7, SEC_WIDTH = 6, MIN_WIDTH = 6, HOUR_WIDTH = 5
    
// )(
//     input clear,
//     input clk,
//     input reset,
//     input mode,
//     input run_stop,
//     output [MSEC_WIDTH - 1:0] msec,
//     output [SEC_WIDTH - 1:0] sec,
//     output [MIN_WIDTH - 1:0] min,
//     output [HOUR_WIDTH - 1:0] hour

// );
//     wire w_msec, w_sec, w_min,w_hour;

//     TIME_COUNT #(
//     .BIT_WIDTH(HOUR_WIDTH),
//     .TIMES(24)
// )    U_TIMECOUNT_HOUR(
//     .clk(clk),
//     .reset(reset),
//     .clear(clear),
//     .run_stop(run_stop),
//     .mode(mode),
//     .i_tick(w_hour),
//     .o_tick(),
//     .time_counter(hour)
// );
    
    
//     TIME_COUNT #(
//     .BIT_WIDTH(MIN_WIDTH),
//     .TIMES(60)
// )    U_TIMECOUNT_MIN(
//     .clk(clk),
//     .reset(reset),
//     .clear(clear),
//     .run_stop(run_stop),
//     .mode(mode),
//     .i_tick(w_min),
//     .o_tick(w_hour),
//     .time_counter(min)
// );
    
    
    
//     TIME_COUNT #(
//     .BIT_WIDTH(SEC_WIDTH),
//     .TIMES(60)
// )    U_TIMECOUNT_SEC(
//     .clk(clk),
//     .reset(reset),
//     .clear(clear),
//     .run_stop(run_stop),
//     .mode(mode),
//     .i_tick(w_sec),
//     .o_tick(w_min),
//     .time_counter(sec)
// );
    
    
    
//     TIME_COUNT #(
//     .BIT_WIDTH(MSEC_WIDTH),
//     .TIMES(100)
// )    U_TIMECOUNT_MSEC(
//     .clk(clk),
//     .reset(reset),
//     .clear(clear),
//     .run_stop(run_stop),
//     .mode(mode),
//     .i_tick(w_tick),
//     .o_tick(w_sec),
//     .time_counter(msec)
// );
    
    
    
//     tick_gen U_TICKGEN(
//     .clk(clk),
//     .reset(reset),
//     .o_tick(w_tick)
// );

// endmodule 






// module tick_gen (
//     input clk,
//     input reset,
//     output reg o_tick
// );
//     parameter count_max = 1_000_000;
//     reg [$clog2(count_max)-1:0] counter_reg;

//     always @(posedge clk, posedge reset) begin
//         if (reset) begin
//             counter_reg <= 0;
//             o_tick <= 1'b0;
//         end else begin
//             counter_reg <= counter_reg + 1;
//             if (counter_reg == (count_max - 1)) begin
//                 counter_reg <= 0;
//                 o_tick <= 1'b1;
//             end else begin
//                 o_tick <= 1'b0;
//             end
//         end
//     end
// endmodule

module TIME_COUNT #(
    parameter BIT_WIDTH = 7,
    TIMES = 100
) (
    input clk,
    input reset,
    input clear,
    input run_stop,
    input mode,
    input i_tick,
    output reg o_tick,
    output [BIT_WIDTH - 1:0] time_counter
);
    reg [$clog2(TIMES)-1:0] counter_reg;
    assign time_counter = counter_reg;

    always @(posedge clk, posedge reset) begin
        if (reset || clear) begin
            counter_reg <= 0;
            o_tick <= 1'b0;
        end else begin
            if (i_tick & run_stop) begin
                if (!mode) begin
                    counter_reg <= counter_reg + 1;
                    if (counter_reg == TIMES - 1) begin
                        counter_reg <= 0;
                        o_tick <= 1'b1;
                    end else begin
                        o_tick <= 1'b0;
                    end
                end else begin
                    counter_reg <= counter_reg - 1;
                    if (counter_reg == 0) begin
                        counter_reg <= (TIMES - 1);
                        o_tick <= 1'b1;
                    end else begin
                        o_tick <= 1'b0;
                    end
                end
            end else begin
                o_tick <= 1'b0;
            end
        end
    end


endmodule

