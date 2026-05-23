// ============================================================
// Modul: div_frecventa
// Descriere: Divizor de frecventa parametrizabil.
//            Toggleaza iesirea la fiecare DIV_FACTOR tacturi de ceas.
//            Frecventa iesire = CLK_FREQ / (2 * DIV_FACTOR)
//            Exemplu: DIV_FACTOR = CLK_FREQ => iesire 0.5 Hz
// ============================================================
`timescale 1ns/1ps

module div_frecventa #(
    parameter DIV_FACTOR = 10_000_000
)(
    input  wire clk_i,
    input  wire reset_n_i,
    output reg  clk_div_o
);

reg [31:0] cnt;

always @(posedge clk_i or negedge reset_n_i) begin
    if (!reset_n_i) begin
        cnt       <= 0;
        clk_div_o <= 1'b0;
    end else begin
        if (cnt >= DIV_FACTOR - 1) begin
            cnt       <= 0;
            clk_div_o <= ~clk_div_o;
        end else
            cnt <= cnt + 1;
    end
end

endmodule
