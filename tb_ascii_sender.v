`timescale 1ns / 1ps

module tb_ascii_sender;

    reg clk;
    reg reset;
    reg i_run_stop;
    reg i_clear;
    reg i_mode;
    reg i_left;
    reg i_right;
    reg i_up;
    reg i_down;
    reg run_state;
    wire [7:0] tx_data;
    wire tx_push;

    ascii_sender U_DUT (
        .clk(clk),
        .reset(reset),
        .i_run_stop(i_run_stop),
        .i_clear(i_clear),
        .i_mode(i_mode),
        .i_left(i_left),
        .i_right(i_right),
        .i_up(i_up),
        .i_down(i_down),
        .run_state(run_state),
        .tx_data(tx_data),
        .tx_push(tx_push)
    );

    always #5 clk = ~clk;

    task pulse_event(
        input sel_run_stop,
        input sel_clear,
        input sel_mode,
        input sel_left,
        input sel_right,
        input sel_up,
        input sel_down
    );
        begin
            i_run_stop = sel_run_stop;
            i_clear    = sel_clear;
            i_mode     = sel_mode;
            i_left     = sel_left;
            i_right    = sel_right;
            i_up       = sel_up;
            i_down     = sel_down;
            #10;
            i_run_stop = 0;
            i_clear    = 0;
            i_mode     = 0;
            i_left     = 0;
            i_right    = 0;
            i_up       = 0;
            i_down     = 0;
            #20;
        end
    endtask

    initial begin
        clk = 0;
        reset = 1;
        i_run_stop = 0;
        i_clear = 0;
        i_mode = 0;
        i_left = 0;
        i_right = 0;
        i_up = 0;
        i_down = 0;
        run_state = 0;

        #20;
        reset = 0;
        #10;

        run_state = 0;
        pulse_event(1,0,0,0,0,0,0);   // "r" 

        run_state = 1;
        pulse_event(1,0,0,0,0,0,0);   // "s" 

        pulse_event(0,1,0,0,0,0,0);   // "c"
        pulse_event(0,0,1,0,0,0,0);   // "m"
        pulse_event(0,0,0,1,0,0,0);   // "a"
        pulse_event(0,0,0,0,1,0,0);   // "n"
        pulse_event(0,0,0,0,0,1,0);   // "u"
        pulse_event(0,0,0,0,0,0,1);   // "d"

        #50;
        $finish;
    end

endmodule