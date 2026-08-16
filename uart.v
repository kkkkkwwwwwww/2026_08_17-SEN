`timescale 1ns / 1ps

//TOP module
module uart_controller (
    input clk,
    input reset,
    input tx_start,
    input [7:0] tx_data,
    input rx,
    output rx_done,
    output [7:0] rx_data,
    output tx_busy,
    output tx_done,
    output tx
);
    wire w_baud_tick_x16;

    //인스턴스
    uart_tx U_UART_TX (
        .clk(clk),
        .reset(reset),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .i_baud_tick(w_baud_tick_x16),
        .tx_busy(tx_busy),
        .tx_done(tx_done),
        .tx(tx)
    );

    baud_tick_x16 U_BAUD_TICK_x16 (
        .clk(clk),
        .reset(reset),
        .o_baud_tick(w_baud_tick_x16)
    );

    uart_rx U_UART_RX (
        .clk(clk),
        .reset(reset),
        .i_baud_tick(w_baud_tick_x16),
        .rx(rx),
        .rx_data(rx_data),
        .rx_done(rx_done)
    );

endmodule

module uart_rx (
    input clk,
    input reset,
    input i_baud_tick,
    input rx,
    output [7:0] rx_data,
    output rx_done
);

    //state
    localparam [1:0] IDLE = 0, START = 1, DATA = 2, STOP = 3;

    reg [1:0] c_state, n_state;
    reg [3:0] tick_count_reg, tick_count_next;
    reg [2:0] bit_count_reg, bit_count_next;
    reg [7:0] data_reg, data_next;
    //for CL output
    //reg rx_done_reg;
    //for SL output
    reg rx_done_reg, rx_done_next;

    assign rx_done = rx_done_reg;
    assign rx_data = data_reg;

    //state SL
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            c_state <= IDLE;
            tick_count_reg <= 0;
            bit_count_reg <= 0;
            data_reg <= 0;
            rx_done_reg <= 0;
        end else begin
            c_state <= n_state;
            tick_count_reg <= tick_count_next;
            bit_count_reg <= bit_count_next;
            data_reg <= data_next;
            rx_done_reg <= rx_done_next;
        end
    end

    //next CL
    always @(*) begin
        n_state = c_state;
        tick_count_next = tick_count_reg;
        bit_count_next = bit_count_reg;
        data_next = data_reg;
        //for CL output
        //rx_done_reg = 0;
        //for SL output
        rx_done_next = rx_done_reg;
        case (c_state)
            IDLE: begin
                rx_done_next = 0;
                bit_count_next  = 0;
                if (i_baud_tick) begin
                    if (!rx) begin
                        if (tick_count_reg == 7) begin
                            n_state = START;
                            tick_count_next = 0;
                        end else begin
                            tick_count_next = tick_count_reg + 1;
                        end
                    end  //rx가 0이 아니면
                    else begin
                        // data_next = 0;
                        tick_count_next = 0;
                    end
                end
            end
            START: begin
                if (i_baud_tick) begin
                    if (tick_count_reg == 15) begin
                        tick_count_next = 0;
                        n_state = DATA;
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end
            DATA: begin
                if (i_baud_tick) begin
                    if (tick_count_reg == 0) begin
                        //0이 넘어와서 들어온거니까 bit_count_reg
                        //data_next = data_reg[bit_count_reg]; // PIPO, bit indexing
                        //SIPO
                        data_next = {rx, data_reg[7:1]};
                    end
                    if (tick_count_reg == 15) begin
                        tick_count_next = 0;
                        if (bit_count_reg == 7) begin
                            n_state = STOP;
                        end else begin
                            bit_count_next = bit_count_reg + 1;
                        end
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end
            STOP: begin
                if (i_baud_tick) begin
                    // if (tick_count_reg == 7) begin
                        //for CL output
                        rx_done_next = 1;
                        n_state = IDLE;
                    // end else begin
                    //     tick_count_next = tick_count_reg + 1;
                    // end
                end
            end
        endcase
    end


endmodule


module uart_tx (
    input clk,
    input reset,
    input tx_start,
    input [7:0] tx_data,
    input i_baud_tick,
    output tx,
    output tx_busy,
    output tx_done
);
    localparam [1:0] IDLE = 3'd0, START = 3'd1;
    localparam [1:0] DATA = 3'd2, STOP = 3'd3;
    // localparam [2:0] WAIT = 3'd1;  //state추가


    reg [1:0] c_state, n_state;
    //3bit counter register로 bit0~7까지 묶기
    reg [2:0] bit_count_reg, bit_count_next;
    reg [3:0] tick_count_reg, tick_count_next;
    reg tx_reg, tx_next;
    //순차로직이니까 현재와 next 까지 선언
    reg [7:0] data_reg, data_next;
    reg tx_busy_reg, tx_busy_next;
    reg tx_done_reg, tx_done_next;

    assign tx = tx_reg;
    assign tx_busy = tx_busy_reg;
    assign tx_done = tx_done_reg;
    //state register
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            c_state <= IDLE;
            tick_count_reg <= 4'b0000;
            bit_count_reg <= 3'd0;
            tx_reg <= 1'b1;  //초기값은 IDLE 상태 유지해야되니까
            data_reg <= 8'h00;
            tx_busy_reg <= 1'b0;
            tx_done_reg <= 1'b0;
        end else begin
            c_state <= n_state;
            tick_count_reg <= tick_count_next;
            bit_count_reg <= bit_count_next;
            tx_reg <= tx_next;
            data_reg <= data_next;
            tx_busy_reg <= tx_busy_next;
            tx_done_reg <= tx_done_next;
        end
    end

    //next ,output CL
    always @(*) begin
        n_state = c_state;
        tick_count_next = tick_count_reg;
        bit_count_next = bit_count_reg;
        tx_next = tx_reg;
        data_next = data_reg;
        tx_busy_next = tx_busy_reg;
        tx_done_next = tx_done_reg;
        case (c_state)
            IDLE: begin
                tick_count_next = 0;
                //output
                tx_next = 1'b1;
                tx_busy_next = 1'b0;
                tx_done_next = 1'b0;
                //condition of next transition : moore output
                if (tx_start) begin
                    data_next = tx_data;  //tx_data 추가
                    tx_busy_next = 1'b1;
                    n_state = START;
                end
            end
            // WAIT: begin
            //     if (i_baud_tick) n_state = START;
            // end
            START: begin
                tx_next = 1'b0;
                bit_count_next = 3'd0;
                if (i_baud_tick) begin
                    if (tick_count_reg == 15) begin
                        tick_count_next = 0;
                        n_state = DATA;
                    end else tick_count_next = tick_count_reg + 1;
                end
            end
            DATA: begin
                //현재값을 내보내야 하니까 reg
                //좌변이 next가 아니면 race condition 발생. 순차에서도 reg고 조합에서도 reg가 나오면 안됨
                //lsb first
                tx_next = data_reg[0];
                if (i_baud_tick) begin
                    if (tick_count_reg == 15) begin
                        //0부터 data_reg의 7:1까지 채움, bit_cnt증가하는 부분에 넣어줌
                        //data_next = data_reg >> 1;
                        data_next = {1'b0, data_reg[7:1]};
                        tick_count_next = 0;
                        if (bit_count_reg == 7) n_state = STOP;
                        else begin
                            n_state = DATA;
                            bit_count_next = bit_count_reg + 1;
                        end
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end
            STOP: begin
                tx_next = 1'b1;
                if (i_baud_tick) begin
                    if (tick_count_reg == 15) begin
                        tx_busy_next = 1'b0;
                        tx_done_next = 1'b1;  //tx_done tick
                        n_state = IDLE;
                    end else tick_count_next = tick_count_reg + 1;
                end
            end
        endcase
    end
endmodule

// module baud_tick (
//     input  clk,
//     input  reset,
//     output o_baud_tick
// );
//     //9600bps baud tick gen
//     //tick count = input freq / baud_tick_freq
//     parameter F_COUNT = 100_000_000 / 9600;

//     //count_next  : 순차로직과 조합로직 분리하려고
//     //always 구문 작성시
//     reg [$clog2(F_COUNT)-1:0] count_reg, count_next;

//     //assign문 작성시
//     // reg  [$clog2(F_COUNT)-1:0] count_reg;
//     // wire [$clog2(F_COUNT)-1:0] count_next;

//     //count_reg SL
//     always @(posedge clk, posedge reset) begin
//         if (reset) begin
//             count_reg <= 0;
//         end else begin
//             count_reg <= count_next;
//         end
//     end

//     //count_next CL
//     //assign문으로 하려면 위에 reg를 wire로 바꿔야함
//     // assign count_next  = (count_reg == F_COUNT - 1) ? 0 : count_reg + 1;

//     always @(*) begin
//         //full case라서 생략 가능
//         //count_next = count_reg;
//         if (count_reg == F_COUNT - 1) count_next = 0;
//         else count_next = count_reg + 1;
//     end

//     //output CL
//     assign o_baud_tick = (count_reg == (F_COUNT - 1)) ? 1 : 0;

// endmodule

module baud_tick_x16 (
    input  clk,
    input  reset,
    output o_baud_tick
);
    //9600bps baud tick gen
    //tick count = input freq / baud_tick_freq
    parameter F_COUNT = 100_000_000 / (9600 * 16);

    //count_next  : 순차로직과 조합로직 분리하려고
    //always 구문 작성시
    reg [$clog2(F_COUNT)-1:0] count_reg, count_next;

    //assign문 작성시
    // reg  [$clog2(F_COUNT)-1:0] count_reg;
    // wire [$clog2(F_COUNT)-1:0] count_next;

    //count_reg SL
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            count_reg <= 0;
        end else begin
            count_reg <= count_next;
        end
    end

    //count_next CL
    //assign문으로 하려면 위에 reg를 wire로 바꿔야함
    // assign count_next  = (count_reg == F_COUNT - 1) ? 0 : count_reg + 1;

    always @(*) begin
        //full case라서 생략 가능
        //count_next = count_reg;
        if (count_reg == F_COUNT - 1) count_next = 0;
        else count_next = count_reg + 1;
    end

    //output CL
    assign o_baud_tick = (count_reg == (F_COUNT - 1)) ? 1 : 0;

endmodule


// module baud_tick_2 (
//     input  clk,
//     input  reset,
//     output o_baud_tick
// );
//     //9600bps baud tick gen
//     //tick count = input freq / baud_tick_freq
//     parameter F_COUNT = 100_000_000 / 9600;
//     reg [$clog2(F_COUNT)-1:0] count_reg;

//     //output CL
//     assign o_baud_tick = (count_reg == (F_COUNT - 1)) ? 1'b1 : 1'b0;

//     always @(posedge clk, posedge reset) begin
//         if (reset) begin
//             count_reg <= 0;
//         end else begin
//             count_reg <= count_reg + 1;
//             if (count_reg == (F_COUNT - 1)) begin
//                 count_reg <= 0;
//             end
//         end
//     end

// endmodule
