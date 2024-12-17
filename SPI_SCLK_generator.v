module SPI_SCLK_generator
#(
    parameter CPOL          = 1'b0,
    parameter SPI_SCLK_DIV  = 4
)
(
    input i_clk_sys,
    input i_rst_n,
    input en_SCLK,
    output reg o_SCLK
);

//SCLK counter
reg[7:0] sclk_cnt;
always @(posedge i_clk_sys or negedge i_rst_n) begin
    if(~i_rst_n) begin
        sclk_cnt <= 'd0;
    end
    else begin
        sclk_cnt <= (sclk_cnt < SPI_SCLK_DIV-1'b1) ? sclk_cnt + 1'b1 : 'd0;
    end
end

//SCLK output logic
always @(posedge i_clk_sys or negedge i_rst_n) begin
    if(~i_rst_n) begin
        o_SCLK <= CPOL;
    end
    else if(~en_SCLK) begin
        o_SCLK <= CPOL;
    end
    else begin
        o_SCLK <= (sclk_cnt < (SPI_SCLK_DIV>>1)) ? CPOL : ~CPOL;
    end
end


endmodule
