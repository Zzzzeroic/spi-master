module edge_detector
#(
    parameter POSITIVE_EDGE = 1'b1//default: positive edge
    )
    (
    input   i_chip_clk,
    input   i_rst_n,
    input   i_det,
    output reg o_edge
);
    reg[1:0] edge_shift_reg;

    always @(posedge i_chip_clk or negedge i_rst_n) begin
        if(~i_rst_n) begin
            edge_shift_reg <= 2'b00;
        end
        else begin
            edge_shift_reg <= {edge_shift_reg[0], i_det};
        end
    end

    generate
        if(POSITIVE_EDGE == 1'b1)//detect posedge
            o_edge <= (edge_shift_reg==2'b01)?1'b1:1'b0;
        else 
            o_edge <= (edge_shift_reg==2'b10)?1'b1:1'b0;
    endgenerate

endmodule
