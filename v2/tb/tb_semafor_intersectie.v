// ============================================================
// Testbench: tb_semafor_intersectie
// Varianta: 11
// Secventa: S -> E -> V -> N
// Timpi: N=28s, S=26s, E=15s, V=29s, C5=10s, C6=9s
//
// Teste implementate:
//   T1: Functionare normala FARA buton pietoni
//   T2: Functionare normala CU buton pietoni (fiecare directie)
//   T3: Reset in timpul functionarii
//   T4: Verificare temporizare prin forme de unda (log)
// ============================================================
`timescale 1ns/1ps

module tb_semafor_intersectie;

// --------------------------------------------------------
// Parametri simulare
// --------------------------------------------------------
localparam CLK_PERIOD  = 100;        // 100 ns => 10 MHz
// Pentru simulare rapida folosim un factor de scalare
// 1 "secunda de simulare" = 1000 cicli de ceas (in loc de 10_000_000)
// ATENTIE: trebuie sa modificam si DUT-ul sau sa folosim un parametru separat
// In acest TB folosim CLK_FREQ_SIM = 1000 pentru viteza de simulare
localparam CLK_FREQ_SIM = 1_000;     // 1000 cicli = 1 secunda simulata

// --------------------------------------------------------
// Semnale DUT
// --------------------------------------------------------
reg  clk_i;
reg  reset_n_i;
reg  service_i;
reg  pietoni_btn_i;

wire rosu_auto_N_o,   galben_auto_N_o,   verde_auto_N_o;
wire rosu_pietoni_N_o, verde_pietoni_N_o;
wire rosu_auto_S_o,   galben_auto_S_o,   verde_auto_S_o;
wire rosu_pietoni_S_o, verde_pietoni_S_o;
wire rosu_auto_E_o,   galben_auto_E_o,   verde_auto_E_o;
wire rosu_pietoni_E_o, verde_pietoni_E_o;
wire rosu_auto_V_o,   galben_auto_V_o,   verde_auto_V_o;
wire rosu_pietoni_V_o, verde_pietoni_V_o;

// --------------------------------------------------------
// Instantiere DUT (cu CLK_FREQ_SIM pentru simulare rapida)
// --------------------------------------------------------
// Instantiem modulele direct cu parametrul modificat
// Rewire-uim semnalele de start/done manual

// Semnale interne pentru testbench
reg  start_N_tb, start_S_tb, start_E_tb, start_V_tb;
wire done_N_tb,  done_S_tb,  done_E_tb,  done_V_tb;

// --- Nord ---
semafor_directie #(
    .CLK_FREQ (CLK_FREQ_SIM),
    .C_VERDE  (28)
) dut_nord (
    .clk_i               (clk_i),
    .reset_n_i           (reset_n_i),
    .service_i           (service_i),
    .start_i             (start_N_tb),
    .pietoni_btn_i       (pietoni_btn_i),
    .rosu_auto_o         (rosu_auto_N_o),
    .galben_auto_o       (galben_auto_N_o),
    .verde_auto_o        (verde_auto_N_o),
    .rosu_pietoni_o      (rosu_pietoni_N_o),
    .verde_pietoni_o     (verde_pietoni_N_o),
    .secventa_incheiata_o(done_N_tb)
);

// --- Sud ---
semafor_directie #(
    .CLK_FREQ (CLK_FREQ_SIM),
    .C_VERDE  (26)
) dut_sud (
    .clk_i               (clk_i),
    .reset_n_i           (reset_n_i),
    .service_i           (service_i),
    .start_i             (start_S_tb),
    .pietoni_btn_i       (pietoni_btn_i),
    .rosu_auto_o         (rosu_auto_S_o),
    .galben_auto_o       (galben_auto_S_o),
    .verde_auto_o        (verde_auto_S_o),
    .rosu_pietoni_o      (rosu_pietoni_S_o),
    .verde_pietoni_o     (verde_pietoni_S_o),
    .secventa_incheiata_o(done_S_tb)
);

// --- Est ---
semafor_directie #(
    .CLK_FREQ (CLK_FREQ_SIM),
    .C_VERDE  (15)
) dut_est (
    .clk_i               (clk_i),
    .reset_n_i           (reset_n_i),
    .service_i           (service_i),
    .start_i             (start_E_tb),
    .pietoni_btn_i       (pietoni_btn_i),
    .rosu_auto_o         (rosu_auto_E_o),
    .galben_auto_o       (galben_auto_E_o),
    .verde_auto_o        (verde_auto_E_o),
    .rosu_pietoni_o      (rosu_pietoni_E_o),
    .verde_pietoni_o     (verde_pietoni_E_o),
    .secventa_incheiata_o(done_E_tb)
);

// --- Vest ---
semafor_directie #(
    .CLK_FREQ (CLK_FREQ_SIM),
    .C_VERDE  (29)
) dut_vest (
    .clk_i               (clk_i),
    .reset_n_i           (reset_n_i),
    .service_i           (service_i),
    .start_i             (start_V_tb),
    .pietoni_btn_i       (pietoni_btn_i),
    .rosu_auto_o         (rosu_auto_V_o),
    .galben_auto_o       (galben_auto_V_o),
    .verde_auto_o        (verde_auto_V_o),
    .rosu_pietoni_o      (rosu_pietoni_V_o),
    .verde_pietoni_o     (verde_pietoni_V_o),
    .secventa_incheiata_o(done_V_tb)
);

// --------------------------------------------------------
// Generare ceas
// --------------------------------------------------------
initial clk_i = 0;
always #(CLK_PERIOD/2) clk_i = ~clk_i;

// --------------------------------------------------------
// Functii ajutatoare
// --------------------------------------------------------
task apply_reset;
    begin
        reset_n_i     = 0;
        service_i     = 0;
        pietoni_btn_i = 0;
        start_N_tb    = 0;
        start_S_tb    = 0;
        start_E_tb    = 0;
        start_V_tb    = 0;
        repeat(5) @(posedge clk_i);
        reset_n_i = 1;
        @(posedge clk_i);
    end
endtask

// Asteapta finalizarea unui ciclu pe o directie si porneste urmatoarea
// Secventa varianta 11: S -> E -> V -> N
task run_sequence_no_btn;
    integer cycle;
    begin
        $display("\n[T1] ============= TEST 1: Functionare normala FARA pietoni =============");
        $display("[T1] Secventa: S -> E -> V -> N");

        // Ciclu 1: Sud
        $display("[T1] t=%0t | START Sud", $time);
        @(posedge clk_i); start_S_tb = 1;
        @(posedge clk_i); start_S_tb = 0;
        @(posedge done_S_tb);
        $display("[T1] t=%0t | DONE  Sud", $time);
        @(posedge clk_i);

        // Ciclu 2: Est
        $display("[T1] t=%0t | START Est", $time);
        @(posedge clk_i); start_E_tb = 1;
        @(posedge clk_i); start_E_tb = 0;
        @(posedge done_E_tb);
        $display("[T1] t=%0t | DONE  Est", $time);
        @(posedge clk_i);

        // Ciclu 3: Vest
        $display("[T1] t=%0t | START Vest", $time);
        @(posedge clk_i); start_V_tb = 1;
        @(posedge clk_i); start_V_tb = 0;
        @(posedge done_V_tb);
        $display("[T1] t=%0t | DONE  Vest", $time);
        @(posedge clk_i);

        // Ciclu 4: Nord
        $display("[T1] t=%0t | START Nord", $time);
        @(posedge clk_i); start_N_tb = 1;
        @(posedge clk_i); start_N_tb = 0;
        @(posedge done_N_tb);
        $display("[T1] t=%0t | DONE  Nord", $time);
        @(posedge clk_i);

        $display("[T1] Ciclu complet S->E->V->N finalizat cu succes!");
    end
endtask

task run_sequence_with_btn;
    begin
        $display("\n[T2] ============= TEST 2: Functionare normala CU pietoni =============");
        $display("[T2] Butonul pietoni va fi apasat in timpul fiecarei directii");

        // Sud cu pietoni
        $display("[T2] t=%0t | START Sud (cu pietoni)", $time);
        @(posedge clk_i); start_S_tb = 1;
        @(posedge clk_i); start_S_tb = 0;
        // Apasam butonul dupa 5 secunde simulate
        repeat(5 * CLK_FREQ_SIM) @(posedge clk_i);
        pietoni_btn_i = 1;
        repeat(3) @(posedge clk_i);
        pietoni_btn_i = 0;
        @(posedge done_S_tb);
        $display("[T2] t=%0t | DONE  Sud (cu pietoni)", $time);
        @(posedge clk_i);

        // Est cu pietoni
        $display("[T2] t=%0t | START Est (cu pietoni)", $time);
        @(posedge clk_i); start_E_tb = 1;
        @(posedge clk_i); start_E_tb = 0;
        repeat(3 * CLK_FREQ_SIM) @(posedge clk_i);
        pietoni_btn_i = 1;
        repeat(3) @(posedge clk_i);
        pietoni_btn_i = 0;
        @(posedge done_E_tb);
        $display("[T2] t=%0t | DONE  Est (cu pietoni)", $time);
        @(posedge clk_i);

        // Vest cu pietoni
        $display("[T2] t=%0t | START Vest (cu pietoni)", $time);
        @(posedge clk_i); start_V_tb = 1;
        @(posedge clk_i); start_V_tb = 0;
        repeat(10 * CLK_FREQ_SIM) @(posedge clk_i);
        pietoni_btn_i = 1;
        repeat(3) @(posedge clk_i);
        pietoni_btn_i = 0;
        @(posedge done_V_tb);
        $display("[T2] t=%0t | DONE  Vest (cu pietoni)", $time);
        @(posedge clk_i);

        // Nord cu pietoni
        $display("[T2] t=%0t | START Nord (cu pietoni)", $time);
        @(posedge clk_i); start_N_tb = 1;
        @(posedge clk_i); start_N_tb = 0;
        repeat(8 * CLK_FREQ_SIM) @(posedge clk_i);
        pietoni_btn_i = 1;
        repeat(3) @(posedge clk_i);
        pietoni_btn_i = 0;
        @(posedge done_N_tb);
        $display("[T2] t=%0t | DONE  Nord (cu pietoni)", $time);
        @(posedge clk_i);

        $display("[T2] Test 2 finalizat cu succes!");
    end
endtask

task test_reset;
    begin
        $display("\n[T3] ============= TEST 3: Reset in timpul functionarii =============");
        $display("[T3] t=%0t | START Sud", $time);
        @(posedge clk_i); start_S_tb = 1;
        @(posedge clk_i); start_S_tb = 0;

        // Asteptam 10 secunde simulate apoi aplicam reset
        repeat(10 * CLK_FREQ_SIM) @(posedge clk_i);
        $display("[T3] t=%0t | Aplicam RESET in timpul starii Verde Sud", $time);
        reset_n_i = 0;
        repeat(3) @(posedge clk_i);
        $display("[T3] t=%0t | Eliberam RESET", $time);
        reset_n_i = 1;
        repeat(5) @(posedge clk_i);

        // Verificam ca toate iesirile sunt in stare sigura (rosu)
        if (rosu_auto_S_o === 1'b1 && verde_auto_S_o === 1'b0 && galben_auto_S_o === 1'b0)
            $display("[T3] PASS: Dupa reset, Sud este pe ROSU (stare sigura)");
        else
            $display("[T3] FAIL: Dupa reset, starea Sud nu este corecta! R=%b G=%b V=%b",
                     rosu_auto_S_o, galben_auto_S_o, verde_auto_S_o);

        $display("[T3] Test 3 finalizat!");
    end
endtask

task test_service;
    begin
        $display("\n[T4] ============= TEST 4: Stare de avarie (service) =============");
        @(posedge clk_i); start_S_tb = 1;
        @(posedge clk_i); start_S_tb = 0;
        repeat(5 * CLK_FREQ_SIM) @(posedge clk_i);

        $display("[T4] t=%0t | Activam SERVICE in timpul functionarii", $time);
        service_i = 1;
        repeat(20) @(posedge clk_i);

        // Verificam semnalul galben intermitent (blink_sig activ)
        $display("[T4] t=%0t | Verificam semnale avarie: galben_S=%b, verde_p_S=%b",
                 $time, galben_auto_S_o, verde_pietoni_S_o);
        $display("[T4] t=%0t | Verificam semnale avarie: galben_N=%b, galben_E=%b, galben_V=%b",
                 $time, galben_auto_N_o, galben_auto_E_o, galben_auto_V_o);

        repeat(2 * CLK_FREQ_SIM) @(posedge clk_i);
        $display("[T4] t=%0t | Dezactivam SERVICE", $time);
        service_i = 0;
        repeat(5) @(posedge clk_i);
        $display("[T4] Test service finalizat!");
    end
endtask

// --------------------------------------------------------
// Secventa principala de testare
// --------------------------------------------------------
integer i;
initial begin
    // Setam fisier VCD pentru forme de unda
    $dumpfile("tb_semafor_intersectie.vcd");
    $dumpvars(0, tb_semafor_intersectie);

    $display("=======================================================");
    $display("  TESTBENCH: Semafor Intersectie - Varianta 11");
    $display("  Parametri: N=28s, S=26s, E=15s, V=29s, C5=10s, C6=9s");
    $display("  Secventa: S -> E -> V -> N");
    $display("  CLK_FREQ_SIM = %0d cicli/secunda", CLK_FREQ_SIM);
    $display("=======================================================\n");

    // Initializare
    apply_reset;

    // -------------------------------------------------------
    // TEST 1: Functionare normala fara buton pietoni
    // -------------------------------------------------------
    run_sequence_no_btn;

    // Pauza intre teste
    apply_reset;
    repeat(10) @(posedge clk_i);

    // -------------------------------------------------------
    // TEST 2: Functionare normala cu buton pietoni
    // -------------------------------------------------------
    run_sequence_with_btn;

    // Pauza intre teste
    apply_reset;
    repeat(10) @(posedge clk_i);

    // -------------------------------------------------------
    // TEST 3: Reset in timpul functionarii
    // -------------------------------------------------------
    test_reset;

    // Pauza intre teste
    apply_reset;
    repeat(10) @(posedge clk_i);

    // -------------------------------------------------------
    // TEST 4: Stare de avarie (service)
    // -------------------------------------------------------
    test_service;

    // -------------------------------------------------------
    // Sumar final
    // -------------------------------------------------------
    repeat(20) @(posedge clk_i);
    $display("\n=======================================================");
    $display("  TOATE TESTELE FINALIZATE");
    $display("  Verificati formele de unda in tb_semafor_intersectie.vcd");
    $display("=======================================================\n");
    $finish;
end

// --------------------------------------------------------
// Monitor automat - afiseaza schimbarile de stare
// --------------------------------------------------------
always @(posedge verde_auto_S_o)
    $display("[MON] t=%0t | SUD:  Verde AUTO activ", $time);
always @(negedge verde_auto_S_o)
    if (galben_auto_S_o)
        $display("[MON] t=%0t | SUD:  Galben AUTO activ", $time);

always @(posedge verde_auto_E_o)
    $display("[MON] t=%0t | EST:  Verde AUTO activ", $time);
always @(negedge verde_auto_E_o)
    if (galben_auto_E_o)
        $display("[MON] t=%0t | EST:  Galben AUTO activ", $time);

always @(posedge verde_auto_V_o)
    $display("[MON] t=%0t | VEST: Verde AUTO activ", $time);
always @(negedge verde_auto_V_o)
    if (galben_auto_V_o)
        $display("[MON] t=%0t | VEST: Galben AUTO activ", $time);

always @(posedge verde_auto_N_o)
    $display("[MON] t=%0t | NORD: Verde AUTO activ", $time);
always @(negedge verde_auto_N_o)
    if (galben_auto_N_o)
        $display("[MON] t=%0t | NORD: Galben AUTO activ", $time);

always @(posedge verde_pietoni_S_o)
    $display("[MON] t=%0t | SUD:  Verde PIETONI activ", $time);
always @(posedge verde_pietoni_E_o)
    $display("[MON] t=%0t | EST:  Verde PIETONI activ", $time);
always @(posedge verde_pietoni_V_o)
    $display("[MON] t=%0t | VEST: Verde PIETONI activ", $time);
always @(posedge verde_pietoni_N_o)
    $display("[MON] t=%0t | NORD: Verde PIETONI activ", $time);

// Verificare temporizare Test 1 (T4 din cerinta - observare temporizare)
reg [31:0] t_start_verde_S, t_stop_verde_S;
reg [31:0] t_start_verde_E, t_stop_verde_E;

always @(posedge verde_auto_S_o) t_start_verde_S = $time / CLK_PERIOD;
always @(negedge verde_auto_S_o) begin
    t_stop_verde_S = $time / CLK_PERIOD;
    $display("[TIMING] SUD Verde: %0d cicli (asteptat: %0d)",
             t_stop_verde_S - t_start_verde_S,
             26 * CLK_FREQ_SIM);
end

always @(posedge verde_auto_E_o) t_start_verde_E = $time / CLK_PERIOD;
always @(negedge verde_auto_E_o) begin
    t_stop_verde_E = $time / CLK_PERIOD;
    $display("[TIMING] EST Verde: %0d cicli (asteptat: %0d)",
             t_stop_verde_E - t_start_verde_E,
             15 * CLK_FREQ_SIM);
end

// Timeout de siguranta
initial begin
    // Timeout: 1000 secunde simulate * CLK_FREQ_SIM * CLK_PERIOD
    #(1_000 * CLK_FREQ_SIM * CLK_PERIOD * 10);
    $display("[TIMEOUT] Simularea a depasit limita de timp!");
    $finish;
end

endmodule
