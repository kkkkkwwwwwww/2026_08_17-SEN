`timescale 1ns / 1ps

module tb_ascii_decoder;

    reg clk;
    reg reset;
    reg [7:0] rx_data;
    reg rx_done;
    reg run_state;
    wire o_run_stop;
    wire o_clear;
    wire o_mode;
    wire o_left;
    wire o_right;
    wire o_up;
    wire o_down;
    wire o_get;

    ascii_decoder U_DUT (
        .clk(clk),
        .reset(reset),
        .rx_data(rx_data),
        .rx_done(rx_done),
        .run_state(run_state),
        .o_run_stop(o_run_stop),
        .o_clear(o_clear),
        .o_mode(o_mode),
        .o_left(o_left),
        .o_right(o_right),
        .o_up(o_up),
        .o_down(o_down),
        .o_get(o_get)
    );

    always #5 clk = ~clk;

    task send_char(input [7:0] c);
        begin
            rx_data = c;
            rx_done = 1;
            #10;
            rx_done = 0;
            #20;
        end
    endtask

    initial begin
        clk = 0;
        reset = 1;
        rx_data = 0;
        rx_done = 0;
        run_state = 0;

        #20;
        reset = 0;
        #10;

        send_char("r");           

        send_char("s");         

        run_state = 1;
        send_char("s");          

        send_char("c");
        send_char("m");
        send_char("a");
        send_char("n");
        send_char("u");
        send_char("d");


        send_char("g");
        send_char("e");
        send_char("t");           


        send_char("g");
        send_char("x");
        send_char("t");         

        #50;
        $finish;
    end

endmodule