// ============================================================
// Modul: semafor_intersectie
// Varianta: 11
// Parametri varianta 11:
//   C1 (Nord  Verde) = 28s
//   C2 (Sud   Verde) = 26s
//   C3 (Est   Verde) = 15s
//   C4 (Vest  Verde) = 29s
//   C5 (Pietoni Verde) = 10s
//   C6 (Pietoni intermitent verde) = 9s
//   Secventa: S -> E -> V -> N
//
// Descriere: Modul top-level care instantiaza 4 module
//            semafor_directie si orchestreaza secventa
// ============================================================
module semafor_intersectie #(parameter CLK_FREQ = 10_000_000) (
    input  wire clk_i,
    input  wire reset_n_i,
    input  wire service_i,
    input  wire pietoni_btn_i,  

    // Iesiri Nord
    output wire rosu_auto_N_o,
    output wire galben_auto_N_o,
    output wire verde_auto_N_o,
    output wire rosu_pietoni_N_o,
    output wire verde_pietoni_N_o,

    // Iesiri Sud
    output wire rosu_auto_S_o,
    output wire galben_auto_S_o,
    output wire verde_auto_S_o,
    output wire rosu_pietoni_S_o,
    output wire verde_pietoni_S_o,

    // Iesiri Est
    output wire rosu_auto_E_o,
    output wire galben_auto_E_o,
    output wire verde_auto_E_o,
    output wire rosu_pietoni_E_o,
    output wire verde_pietoni_E_o,

    // Iesiri Vest
    output wire rosu_auto_V_o,
    output wire galben_auto_V_o,
    output wire verde_auto_V_o,
    output wire rosu_pietoni_V_o,
    output wire verde_pietoni_V_o
);

// Debouncer pentru butonul pietoni 20ms
wire pietoni_btn_debounced;
debouncer #(
    .CLK_FREQ    (CLK_FREQ),
    .DEBOUNCE_MS (20)
) inst_debouncer (
    .clk_i          (clk_i),
    .reset_n_i      (reset_n_i),
    .btn_i          (pietoni_btn_i),
    .btn_debounced_o(pietoni_btn_debounced)
);

// Parametri varianta 11
localparam C1_N = 28; // Nord  verde [s]
localparam C2_S = 26; // Sud   verde [s]
localparam C3_E = 15; // Est   verde [s]
localparam C4_V = 29; // Vest  verde [s]

// Semnale de start si incheiat pentru fiecare directie
reg  start_N, start_S, start_E, start_V;
wire done_N,  done_S,  done_E,  done_V;

// Secventa: S -> E -> V -> N  (varianta 11)
// Codificam secventa ca o masina de stari simpla
localparam [2:0]
    SEQ_IDLE = 3'd0,
    SEQ_S    = 3'd1,
    SEQ_E    = 3'd2,
    SEQ_V    = 3'd3,
    SEQ_N    = 3'd4;

reg [2:0] seq_state;

always @(posedge clk_i or negedge reset_n_i) begin
    if (!reset_n_i) begin
        seq_state <= SEQ_IDLE;
        start_N   <= 0;
        start_S   <= 0;
        start_E   <= 0;
        start_V   <= 0;
    end else if (service_i) begin
        seq_state <= SEQ_IDLE;
        start_N   <= 0;
        start_S   <= 0;
        start_E   <= 0;
        start_V   <= 0;
    end else begin
        // Default: stergem pulsurile de start (1 singur ciclu de ceas)
        start_N <= 0;
        start_S <= 0;
        start_E <= 0;
        start_V <= 0;

        case (seq_state)
            SEQ_IDLE: begin
                // Pornim cu Sud
                start_S   <= 1;
                seq_state <= SEQ_S;
            end

            SEQ_S: begin
                if (done_S) begin
                    start_E   <= 1;
                    seq_state <= SEQ_E;
                end
            end

            SEQ_E: begin
                if (done_E) begin
                    start_V   <= 1;
                    seq_state <= SEQ_V;
                end
            end

            SEQ_V: begin
                if (done_V) begin
                    start_N   <= 1;
                    seq_state <= SEQ_N;
                end
            end

            SEQ_N: begin
                if (done_N) begin
                    // Reluam ciclul: urmatorul este S
                    start_S   <= 1;
                    seq_state <= SEQ_S;
                end
            end

            default: seq_state <= SEQ_IDLE;
        endcase
    end
end

// Instantiere module semafor_directie
// Nord
semafor_directie #(
    .CLK_FREQ (CLK_FREQ),
    .C_VERDE  (C1_N)
) inst_nord (
    .clk_i               (clk_i),
    .reset_n_i           (reset_n_i),
    .service_i           (service_i),
    .start_i             (start_N),
    .pietoni_btn_i       (pietoni_btn_debounced),
    .rosu_auto_o         (rosu_auto_N_o),
    .galben_auto_o       (galben_auto_N_o),
    .verde_auto_o        (verde_auto_N_o),
    .rosu_pietoni_o      (rosu_pietoni_N_o),
    .verde_pietoni_o     (verde_pietoni_N_o),
    .secventa_incheiata_o(done_N)
);

// Sud
semafor_directie #(
    .CLK_FREQ (CLK_FREQ),
    .C_VERDE  (C2_S)
) inst_sud (
    .clk_i               (clk_i),
    .reset_n_i           (reset_n_i),
    .service_i           (service_i),
    .start_i             (start_S),
    .pietoni_btn_i       (pietoni_btn_debounced),
    .rosu_auto_o         (rosu_auto_S_o),
    .galben_auto_o       (galben_auto_S_o),
    .verde_auto_o        (verde_auto_S_o),
    .rosu_pietoni_o      (rosu_pietoni_S_o),
    .verde_pietoni_o     (verde_pietoni_S_o),
    .secventa_incheiata_o(done_S)
);

// Est
semafor_directie #(
    .CLK_FREQ (CLK_FREQ),
    .C_VERDE  (C3_E)
) inst_est (
    .clk_i               (clk_i),
    .reset_n_i           (reset_n_i),
    .service_i           (service_i),
    .start_i             (start_E),
    .pietoni_btn_i       (pietoni_btn_debounced),
    .rosu_auto_o         (rosu_auto_E_o),
    .galben_auto_o       (galben_auto_E_o),
    .verde_auto_o        (verde_auto_E_o),
    .rosu_pietoni_o      (rosu_pietoni_E_o),
    .verde_pietoni_o     (verde_pietoni_E_o),
    .secventa_incheiata_o(done_E)
);

// Vest
semafor_directie #(
    .CLK_FREQ (CLK_FREQ),
    .C_VERDE  (C4_V)
) inst_vest (
    .clk_i               (clk_i),
    .reset_n_i           (reset_n_i),
    .service_i           (service_i),
    .start_i             (start_V),
    .pietoni_btn_i       (pietoni_btn_debounced),
    .rosu_auto_o         (rosu_auto_V_o),
    .galben_auto_o       (galben_auto_V_o),
    .verde_auto_o        (verde_auto_V_o),
    .rosu_pietoni_o      (rosu_pietoni_V_o),
    .verde_pietoni_o     (verde_pietoni_V_o),
    .secventa_incheiata_o(done_V)
);

endmodule
