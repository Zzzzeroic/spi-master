//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:20:24 11/20/2024 
// Design Name: 
// Module Name:    spi 
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
module SPI_Controller
#(
    parameter CPOL              = 1'b0,
    parameter CPHA              = 1'b0,
    parameter SPI_CLK_DIV       = 4,
    parameter SPI_ADDR_WIDTH    = 6,
    parameter SPI_DATA_WIDTH    = 20,
    parameter SPI_WAIT_WIDTH    = 2
)
(
    input i_clk_sys,
    input i_rst_n,
    input i_start,
    input i_rw,                       //0->Write, 1->Read

    input[SPI_ADDR_WIDTH-1:0] i_address,
    input[SPI_DATA_WIDTH-1:0] i_write_data,         //data from PoolCache, transfer to jt201D
    output reg[SPI_DATA_WIDTH-1:0] o_read_data,     //data from jt201D, display for user
    output reg o_data_valid,          //able to receive data from cache pool
    //SPI
    input i_MISO,
    output reg o_SCLK,
    output reg o_MOSI,
    output reg o_SEN
    //testSignal
    //output reg o_busy
    //output reg o_send_done
    );

    parameter IDLE = 3'b000, START = 3'b001, SEND_ADDR = 3'b010, SEND_DATA = 3'b011, 
                WAIT_READ = 3'b100, READ_DATA = 3'b101;

    reg [2:0] spi_state;
    reg [4:0] bit_cnt;           // 位计数器，用于控制位发送与接收
    reg [3:0] wait_cnt;
    reg [SPI_DATA_WIDTH-1:0] shift_reg;        // 数据移位寄存器
    reg [SPI_ADDR_WIDTH-1:0] addr_reg;          // 地址寄存器

    reg en_SCLK;
    wire SCLK_posedge, SCLK_negedge;
    wire get_number_edge, switch_number_edge;

    assign get_number_edge      = (CPHA==1'b0)?SCLK_posedge:SCLK_negedge;
    assign switch_number_edge   = (CPHA==1'b0)?SCLK_negedge:SCLK_posedge;

    always @(posedge i_clk_sys or negedge i_rst_n) begin
        if(!i_rst_n) 
            spi_state       <= IDLE;
            o_SEN           <= 1'b1;
        else begin
            if(spi_state==IDLE && i_start == 1'b1) 
                spi_state <= START;
            else if(spi_state==WAIT_READ) 
            begin
                if(wait_cnt==SPI_CLK_DIV*SPI_WAIT_WIDTH-1) 
                begin
                    spi_state   <= READ_DATA;
                    o_SEN       <= 1'b0;
                end
            end
            else if(switch_number_edge) 
            begin
                case (spi_state) 
                START: begin
                    spi_state <= SEND_ADDR;
                end
                SEND_ADDR:
                begin
                    if(bit_cnt == SPI_ADDR_WIDTH) 
                    begin
                        if(i_rw==1'b1) begin//read
                            spi_state   <= WAIT_READ;
                            o_SEN       <= 1'b1;
                        end
                        else spi_state  <= SEND_DATA;
                    end
                end
                SEND_DATA:  begin
                    spi_state = (bit_cnt == SPI_ADDR_WIDTH+SPI_DATA_WIDTH)? IDLE:SEND_DATA;
                end
                READ_DATA:  begin
                    spi_state = (bit_cnt == SPI_ADDR_WIDTH+SPI_DATA_WIDTH)? IDLE:READ_DATA;
                end
                default:    begin
                    spi_state = IDLE;
                end
                endcase
            end
        end
    end

    always @(posedge i_clk_sys or negedge i_rst_n) begin
        if(~i_rst_n) begin
            o_data_valid    <= 1'b0;
            o_MOSI          <= 1'b0;
            en_SCLK         <= 1'b0;
            bit_cnt         <= 'd0;
            shift_reg       <= 'd0;
            addr_reg        <= 'd0;
            o_read_data     <= 'd0;
            wait_cnt        <= 'd0;
        end else begin
            case (spi_state)
            IDLE:
            begin
                //o_busy        <= 1'b0;
                o_data_valid    <= (i_start==1'b1)?1'b0:1'b1;
                bit_cnt         <= 'd0;
                en_SCLK         <= 1'b0;
            end
            START:
            begin
                //o_busy        <= 1'b1;
                addr_reg        <= i_address;
                shift_reg       <= i_write_data;
                o_data_valid    <= 1'b0;
                bit_cnt         <= 'd0;
                o_MOSI          <= i_rw;
                en_SCLK         <= 1'b1;
            end
            SEND_ADDR:
            begin
                if(switch_number_edge) begin // negedge
                    o_MOSI      <= addr_reg[SPI_ADDR_WIDTH-1];
                    addr_reg    <= addr_reg << 1;
                    bit_cnt     <= bit_cnt + 1'b1;
                end
            end
            SEND_DATA:
            begin
                if(switch_number_edge) begin
                    o_MOSI      <= shift_reg[SPI_DATA_WIDTH-1];
                    shift_reg   <= shift_reg << 1'b1;
                    bit_cnt     <= bit_cnt+1'b1;
                end
            end
            WAIT_READ:  
            begin
                wait_cnt    <= wait_cnt+1'b1;
            end
            READ_DATA:
            begin
                if(get_number_edge)begin
                    shift_reg <= {shift_reg[18:0], i_MISO};
                    bit_cnt <= bit_cnt+1'b1;
                end
            end
            endcase
        end
    end

    SPI_SCLK_generator
    #(
        .CPOL(CPOL),
        .SPI_SCLK_DIV(SPI_SCLK_DIV)
    )u_sclk
    (
        .i_clk_sys(i_clk_sys),
        .i_rst_n(i_rst_n),
        .en_SCLK(en_SCLK),
        .o_SCLK(o_SCLK)
    );

    edge_detector #(.POSITIVE_EDGE(1'b1))u_posedge(.i_chip_clk(i_clk_sys), .i_rst_n(i_rst_n), .i_det(o_SCLK), .o_edge(SCLK_posedge));
    edge_detector #(.POSITIVE_EDGE(1'b0))u_negedge(.i_chip_clk(i_clk_sys), .i_rst_n(i_rst_n), .i_det(o_SCLK), .o_edge(SCLK_negedge));

endmodule

