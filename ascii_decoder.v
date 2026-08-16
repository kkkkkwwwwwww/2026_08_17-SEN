module ascii_decoder (
    input clk,
    input reset,
    input [7:0] rx_data,
    input rx_done,
    input run_state,
    output reg o_run_stop,
    output reg o_clear,
    output reg o_mode,
    output reg o_left,
    output reg o_right,
    output reg o_up,
    output reg o_down,
    output reg o_get
);
    reg [7:0] char2, char1, char0;  

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            o_run_stop <= 1'b0;
            o_clear <= 1'b0;
            o_mode <= 1'b0;
            o_left <= 1'b0;
            o_right <= 1'b0;
            o_up <= 1'b0;
            o_down <= 1'b0;
            o_get <= 1'b0;
            char2 <= 8'd0;
            char1 <= 8'd0;
            char0 <= 8'd0;
        end else begin
            o_run_stop <= 1'b0;
            o_clear <= 1'b0;
            o_mode <= 1'b0;
            o_left <= 1'b0;
            o_right <= 1'b0;
            o_up <= 1'b0;
            o_down <= 1'b0;
            o_get <= 1'b0;

            if (rx_done) begin
                char2 <= char1;
                char1 <= char0;
                char0 <= rx_data;

                if (char1 == "g" && char0 == "e" && rx_data == "t") begin
                    o_get <= 1'b1;
                end

                case (rx_data)
                    "r": if (!run_state) o_run_stop <= 1'b1;
                    "s": if (run_state) o_run_stop <= 1'b1;
                    "c": o_clear <= 1'b1;
                    "m": o_mode <= 1'b1;
                    "a": o_left <= 1'b1;
                    "n": o_right <= 1'b1;
                    "u": o_up <= 1'b1;
                    "d": o_down <= 1'b1;
                    default: ;
                endcase
            end
        end
    end
endmodule