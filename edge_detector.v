module edge_detector
#(
    parameter POSITIVE_EDGE = 1'b1//default: positive edge
    )
    (
    input   i_chip_clk,
    input   i_rst_n,
    input   i_det,
    output  o_edge
);
    reg edge_last_time;

    always @(posedge i_chip_clk or negedge i_rst_n) begin
        if(~i_rst_n) begin
            edge_last_time <= 'd0;
        end
        else begin
            edge_last_time <= i_det;
        end
    end

    generate
        if(POSITIVE_EDGE == 1'b1)//detect posedge
            assign o_edge = ~edge_last_time&i_det;
        else 
            assign o_edge = edge_last_time&~i_det;
    endgenerate

endmodule
