`timescale 1ns / 1ps

module time_ascii_sender (
    input clk,
    input reset,
    input get_trigger,
    input fifo_full,
    input sw_detail,
    input [6:0] msec,
    input [5:0] sec,
    input [5:0] min,
    input [4:0] hour,
    output reg [7:0] tx_data,
    output reg tx_push,
    output reg busy
);
    wire [6:0] msec_v = msec;
    wire [5:0] sec_v = sec;
    wire [5:0] min_v = min;
    wire [4:0] hour_v = hour;

    localparam IDLE=0, D0=1, D1=2, COLON=3, D2=4, D3=5, CR=6, LF=7;
    reg [3:0] state;

    reg [3:0] digit0, digit1, digit2, digit3;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            state <= IDLE;
            tx_data <= 0;
            tx_push <= 1'b0;
            busy <= 1'b0;
            digit0 <= 0; digit1 <= 0; digit2 <= 0; digit3 <= 0;
        end else begin
            tx_push <= 1'b0;

            case (state)
                IDLE: begin
                    busy <= 1'b0;
                    if (get_trigger) begin
                        if (!sw_detail) begin
                            digit3 <= (sec_v / 10) % 10;
                            digit2 <= sec_v % 10;
                            digit1 <= (msec_v / 10) % 10;
                            digit0 <= msec_v % 10;
                        end else begin
                            digit3 <= (hour_v / 10) % 10;
                            digit2 <= hour_v % 10;
                            digit1 <= (min_v / 10) % 10;
                            digit0 <= min_v % 10;
                        end
                        busy <= 1'b1;
                        state <= D0;
                    end
                end

                D0: begin
                    if (!fifo_full) begin
                        tx_data <= digit3 + 8'h30;
                        tx_push <= 1'b1;
                        state <= D1;
                    end
                end
                D1: begin
                    if (!fifo_full) begin
                        tx_data <= digit2 + 8'h30;
                        tx_push <= 1'b1;
                        state <= COLON;
                    end
                end
                COLON: begin
                    if (!fifo_full) begin
                        tx_data <= ":";
                        tx_push <= 1'b1;
                        state <= D2;
                    end
                end
                D2: begin
                    if (!fifo_full) begin
                        tx_data <= digit1 + 8'h30;
                        tx_push <= 1'b1;
                        state <= D3;
                    end
                end
                D3: begin
                    if (!fifo_full) begin
                        tx_data <= digit0 + 8'h30;
                        tx_push <= 1'b1;
                        state <= CR;
                    end
                end
                CR: begin
                    if (!fifo_full) begin
                        tx_data <= 8'h0D;
                        tx_push <= 1'b1;
                        state <= LF;
                    end
                end
                LF: begin
                    if (!fifo_full) begin
                        tx_data <= 8'h0A;
                        tx_push <= 1'b1;
                        state <= IDLE;
                    end
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule



// `timescale 1ns / 1ps

// module time_ascii_sender (
//     input clk,
//     input reset,
//     input get_trigger,
//     input fifo_full,
//     input sw_detail,
//     input [6:0] msec,
//     input [5:0] sec,
//     input [5:0] min,
//     input [4:0] hour,
//     output reg [7:0] tx_data,
//     output reg tx_push,
//     output reg busy
// );
//     wire [6:0] msec_v = msec;
//     wire [5:0] sec_v = sec;
//     wire [5:0] min_v = min;
//     wire [4:0] hour_v = hour;

//     localparam IDLE=0, D0=1, D1=2, D2=3, D3=4, CR=5, LF=6;
//     reg [3:0] state;

//     reg [3:0] digit0, digit1, digit2, digit3;

//     always @(posedge clk, posedge reset) begin
//         if (reset) begin
//             state <= IDLE;
//             tx_data <= 0;
//             tx_push <= 1'b0;
//             busy <= 1'b0;
//             digit0 <= 0; digit1 <= 0; digit2 <= 0; digit3 <= 0;
//         end else begin
//             tx_push <= 1'b0;

//             case (state)
//                 IDLE: begin
//                     busy <= 1'b0;
//                     if (get_trigger) begin
//                         if (!sw_detail) begin
//                             digit3 <= (msec_v / 10) % 10;
//                             digit2 <= msec_v % 10;
//                             digit1 <= (sec_v / 10) % 10;
//                             digit0 <= sec_v % 10;
//                         end else begin
//                             digit3 <= (min_v / 10) % 10;
//                             digit2 <= min_v % 10;
//                             digit1 <= (hour_v / 10) % 10;
//                             digit0 <= hour_v % 10;
//                         end
//                         busy <= 1'b1;
//                         state <= D0;
//                     end
//                 end

//                 D0: begin
//                     if (!fifo_full) begin
//                         tx_data <= digit3 + 8'h30;
//                         tx_push <= 1'b1;
//                         state <= D1;
//                     end
//                 end
//                 D1: begin
//                     if (!fifo_full) begin
//                         tx_data <= digit2 + 8'h30;
//                         tx_push <= 1'b1;
//                         state <= D2;
//                     end
//                 end
//                 D2: begin
//                     if (!fifo_full) begin
//                         tx_data <= digit1 + 8'h30;
//                         tx_push <= 1'b1;
//                         state <= D3;
//                     end
//                 end
//                 D3: begin
//                     if (!fifo_full) begin
//                         tx_data <= digit0 + 8'h30;
//                         tx_push <= 1'b1;
//                         state <= CR;
//                     end
//                 end
//                 CR: begin
//                     if (!fifo_full) begin
//                         tx_data <= 8'h0D;
//                         tx_push <= 1'b1;
//                         state <= LF;
//                     end
//                 end
//                 LF: begin
//                     if (!fifo_full) begin
//                         tx_data <= 8'h0A;
//                         tx_push <= 1'b1;
//                         state <= IDLE;
//                     end
//                 end
//                 default: state <= IDLE;
//             endcase
//         end
//     end
// endmodule