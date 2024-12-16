//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    17:49:31 11/20/2024 
// Design Name: 
// Module Name:    uart_state_ctrl 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module uart_state_ctrl
#(
    parameter SPI_ADDR_WIDTH = 6,
    parameter SPI_DATA_WIDTH = 20,
    parameter UART_DATA_WIDTH = 8
)
(
    input i_clk_sys,
    input i_rst_n,
    //UART rx params
    input [UART_DATA_WIDTH-1:0] i_uart_data,
    input i_rx_done,

    //UART tx params
    input                               i_uart_idle,
    output reg [UART_DATA_WIDTH-1:0]    o_data_tx,
    output reg                          o_data_valid,
    //SPI params
    input      i_spi_data_valid,
    output reg o_spi_start,
    output reg o_spi_rw,//0->write, 1->read
    output reg [SPI_ADDR_WIDTH-1:0] o_spi_write_address,
    output reg [SPI_DATA_WIDTH-1:0] o_spi_write_data,
    input  [SPI_DATA_WIDTH-1:0] i_spi_read_data,

    //debug
    output reg[6:0] o_ld_debug
    );
    parameter IDLE = 3'b000, REC_ADDR_HEAD = 3'b001, READ_ADDR=3'b010, 
                REC_DATA_HEAD = 3'b011, READ_DATA = 3'b100, WRITE_DATA=3'b101, 
                UART_TX=3'b110, DONE = 3'b111;
    
    parameter WRITE_STR = "Write\n";
    parameter READ_STR = "Read\n";
    reg[8*6-1:0] user_string;

    reg [2:0] state, next_state;
    reg [4:0] bit_cnt;
    reg [19:0] shift_reg;

    wire [3:0] uart_data_hex;

    assign uart_data_hex = (i_uart_data>=48 && i_uart_data<=57)?i_uart_data[3:0]:
                            ((i_uart_data>=65 && i_uart_data<=70)||(i_uart_data>=97&&i_uart_data<=102))?{1'b1,{i_uart_data[2:0]}+1'b1}:
                             4'd0;
    //Finite State Machine
    //1st
    always @(posedge i_clk_sys or negedge i_rst_n) begin
        if (!i_rst_n) state <= IDLE;
        else state <= next_state;
    end
    //2nd
    always @(*) begin
        case (state)
        IDLE:           next_state = (i_uart_data=="{")?REC_ADDR_HEAD:IDLE;
        REC_ADDR_HEAD:  next_state = (bit_cnt==2)?READ_ADDR:REC_ADDR_HEAD;//A->Read, a->Write
        READ_ADDR:
        begin
            if(bit_cnt==4)
                next_state = (o_spi_rw)?READ_DATA:REC_DATA_HEAD;
            else 
                next_state = READ_ADDR;
        end
        REC_DATA_HEAD:  next_state = (bit_cnt==6)?WRITE_DATA:REC_DATA_HEAD;
        WRITE_DATA:     next_state = (bit_cnt==11)?UART_TX:WRITE_DATA;
        READ_DATA:      next_state = (i_spi_data_valid 
                                        && ~o_spi_start
                                        && bit_cnt==5)?UART_TX:READ_DATA;
        UART_TX:        next_state = (bit_cnt==0)?DONE:UART_TX;
        DONE:           next_state = IDLE;  
        endcase
    end

    //3rd
    always @(posedge i_clk_sys or negedge i_rst_n) begin
        if(~i_rst_n) begin
            bit_cnt                 <= 5'd0;
            o_spi_start             <= 1'b0;
            o_spi_rw                <= 1'b0;
            o_spi_write_address     <= 6'd0;
            o_spi_write_data        <= 20'd0;
            o_data_tx               <= 8'd0;
            o_data_valid            <= 1'b0;
            user_string             <= 40'd0;
            o_ld_debug              <= 7'b111_1111;
        end else begin
            case(state)
            IDLE: begin
                bit_cnt     <= 5'd0;
                o_ld_debug  <= 7'b111_0000;
            end
            REC_ADDR_HEAD: begin
                o_ld_debug <= 7'b000_0001;
                if(i_rx_done) begin
                    case(bit_cnt)
                    5'd0:begin
                        if(i_uart_data=="A") begin
                            o_spi_rw <= 1'b1;
                            bit_cnt <= bit_cnt+1'b1;
                            user_string <= READ_STR;
                        end
                        else if(i_uart_data=="a") begin
                            o_spi_rw <= 1'b0;
                            bit_cnt <= bit_cnt+1'b1;
                            user_string <= WRITE_STR;
                        end
                        else bit_cnt <= 5'd0;
                    end
                    5'd1:
                        if(i_uart_data==":") begin
                            bit_cnt <= bit_cnt+1'b1;
                        end
                        else bit_cnt <= 5'd0;
                    default: bit_cnt <= 5'd0;
                    endcase
                end
            end
            READ_ADDR: begin
                o_ld_debug <= 7'b000_0011;
                if(i_rx_done) begin
                    bit_cnt <= bit_cnt + 1'b1;
                    if(bit_cnt == 5'd2) begin   //i_uart_data - 8'b00110000
                        o_spi_write_address[5:4] <= uart_data_hex[1:0];
                    end
                    else if(bit_cnt == 5'd3) begin
                        o_spi_write_address[3:0] <= uart_data_hex[3:0];
                    end
                end
            end
            REC_DATA_HEAD: begin
                o_ld_debug <= 7'b000_0111;
                if(i_rx_done) begin
                    if(i_uart_data=="D" && bit_cnt == 5'd4)
                        bit_cnt <= bit_cnt+1'b1;
                    else if(i_uart_data==":" && bit_cnt == 5'd5)
                        bit_cnt <= bit_cnt+1'b1;
                end
            end
            WRITE_DATA: begin
                o_ld_debug <= 7'b000_1111;
                if(i_rx_done) begin
                    bit_cnt <= bit_cnt + 1'b1;
                    o_spi_write_data <= {o_spi_write_data[15:0], uart_data_hex};
                end
                if(bit_cnt == 5'd11) 
                    o_spi_start <= 1'b1;
            end
            READ_DATA: begin//begin to read and wait the result
                o_ld_debug <= 7'b001_1111;
                if(i_spi_data_valid && bit_cnt==4) begin
                    o_spi_start <= 1'b1;
                    bit_cnt <= bit_cnt+1'b1;
                end
                else o_spi_start <= 1'b0;
            end
            UART_TX: begin
                o_spi_start <= 1'b0;
                o_ld_debug  <= 7'b011_1111;
                if(i_uart_idle && o_data_valid == 1'b0) begin
                    o_spi_start <= 1'b0;
                    if(o_spi_rw==0) //write mode, bit_cnt starts from 11
                    begin
                        o_data_valid    <= 1'b1;
                        o_data_tx       <= (user_string)>>(8*(16-bit_cnt));
                        bit_cnt         <= (bit_cnt==16)?0:bit_cnt+1'b1;
                    end
                    else begin  //read mode, bit_cnt starts from 6, rec len=4
                        o_data_valid    <= 1'b1;
                        if(bit_cnt<=10) begin
                            o_data_tx       <= (user_string)>>(8*(10-bit_cnt));
                            shift_reg       <= i_spi_read_data;
                        end
                        else begin
                            if(shift_reg[19:16]<=4'd9)
                                o_data_tx   <= shift_reg[19:16] + "0";
                            else 
                                o_data_tx   <= shift_reg[19:16] + "A" - 8'd10;
                            shift_reg       <= shift_reg << 3'd4;
                        end
                        bit_cnt         <= (bit_cnt==15)?0:bit_cnt+1'b1;
                    end
                end
                else o_data_valid <= 1'b0;
            end
            DONE: begin
                o_ld_debug <= 7'b111_1111;
                bit_cnt <= 5'd0;
            end
            endcase
        end
    end
endmodule
