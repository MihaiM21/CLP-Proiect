// ============================================================
// Modul: debouncer
// Descriere: Filtreaza zgomotul mecanic (bouncing) al butonului.
//            Include 2 FF de sincronizare (protectie metastabilitate)
//            si un contor care cere stabilitate DEBOUNCE_CYCLES tacturi
//            inainte de a propaga schimbarea semnalului de intrare.
// ============================================================
`timescale 1ns/1ps

module debouncer #(
    parameter CLK_FREQ    = 10_000_000,
    parameter DEBOUNCE_MS = 20
)(
    input  wire clk_i,
    input  wire reset_n_i,
    input  wire btn_i,
    output reg  btn_debounced_o
);

localparam integer DEBOUNCE_CYCLES = CLK_FREQ * DEBOUNCE_MS / 1000;

reg [31:0] cnt;
reg        btn_sync0, btn_sync1;

// 2-FF synchronizer
always @(posedge clk_i or negedge reset_n_i) begin
    if (!reset_n_i) begin
        btn_sync0 <= 1'b0;
        btn_sync1 <= 1'b0;
    end else begin
        btn_sync0 <= btn_i;
        btn_sync1 <= btn_sync0;
    end
end

// Debounce: output se actualizeaza doar dupa DEBOUNCE_CYCLES tacturi stabile
always @(posedge clk_i or negedge reset_n_i) begin
    if (!reset_n_i) begin
        cnt             <= 0;
        btn_debounced_o <= 1'b0;
    end else begin
        if (btn_sync1 != btn_debounced_o) begin
            if (cnt >= DEBOUNCE_CYCLES - 1) begin
                btn_debounced_o <= btn_sync1;
                cnt             <= 0;
            end else
                cnt <= cnt + 1;
        end else
            cnt <= 0;
    end
end

endmodule
