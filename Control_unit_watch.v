`timescale 1ns / 1ps

module Control_unit_watch (
    input        clk,
    input        rst,
    input        i_btnL,
    input        i_btnR,
    input        i_btnU,
    input        i_btnD,
    output [2:0] position,
    output [1:0] up_down
);
    localparam S0 = 3'b000, S1 = 3'b001, S2 = 3'b010, S3 = 3'b011;
    localparam S4 = 3'b100, S5 = 3'b101, S6 = 3'b110, S7 = 3'b111;
    reg [2:0] c_state, n_state;
    //c_state FSM
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            c_state <= S0;
        end else begin
            c_state <= n_state;
        end
    end
    //n_state CL
    always @(*) begin
        n_state = c_state;
        if (rst) begin
            n_state = S0;
        end else begin
            n_state = c_state;
            case (c_state)
                S0: begin
                    if (i_btnL) n_state = S1;
                    else if (i_btnR) n_state = S7;
                    else n_state = c_state;
                end
                S1: begin
                    if (i_btnL) n_state = S2;
                    else if (i_btnR) n_state = S0;
                    else n_state = c_state;
                end
                S2: begin
                    if (i_btnL) n_state = S3;
                    else if (i_btnR) n_state = S1;
                    else n_state = c_state;
                end
                S3: begin
                    if (i_btnL) n_state = S4;
                    else if (i_btnR) n_state = S2;
                    else n_state = c_state;
                end
                S4: begin
                    if (i_btnL) n_state = S5;
                    else if (i_btnR) n_state = S3;
                    else n_state = c_state;
                end
                S5: begin
                    if (i_btnL) n_state = S6;
                    else if (i_btnR) n_state = S4;
                    else n_state = c_state;
                end
                S6: begin
                    if (i_btnL) n_state = S7;
                    else if (i_btnR) n_state = S5;
                    else n_state = c_state;
                end
                S7: begin
                    if (i_btnL) n_state = S0;
                    else if (i_btnR) n_state = S6;
                    else n_state = c_state;
                end
            endcase
        end
    end
    //output
    assign position = c_state;
    assign up_down = ({i_btnU, i_btnD} == 2'b10) ? 2'b10 :
                     ({i_btnU, i_btnD} == 2'b01) ? 2'b01 : 2'b00;

endmodule
