// ============================================================
// Testbench: tb_semafor_intersectie_top
// Varianta: 11
// Secventa: S -> E -> V -> N
// Timpi: N=28s, S=26s, E=15s, V=29s, C5=10s, C6=9s
//
// NOTA: Acest testbench instantiaza modulul TOP-LEVEL semafor_intersectie.
//       Pentru a permite simulare rapida, semafor_intersectie trebuie
//       recompilat cu parametrul CLK_FREQ modificat la CLK_FREQ_SIM=1000.
//       Alternativ, se poate adauga CLK_FREQ ca parametru la modulul top.
//
// Teste implementate:
//   T1: Functionare normala FARA buton pietoni
//   T2: Functionare normala CU buton pietoni (fiecare directie)
//   T3: Reset in timpul functionarii
//   T4: Stare de avarie (service)
// ============================================================
`timescale 1ns/1ps

module tb_semafor_intersectie_top;

// Parametri simulare
localparam CLK_PERIOD   = 100;       // 100 ns => 10 MHz
localparam CLK_FREQ_SIM = 1_000;     // 1000 cicli = 1 secunda simulata

// Semnale DUT
reg  clk_i;
reg  reset_n_i;
reg  service_i;
reg  pietoni_btn_i;

wire rosu_auto_N_o,    galben_auto_N_o,    verde_auto_N_o;
wire rosu_pietoni_N_o, verde_pietoni_N_o;
wire rosu_auto_S_o,    galben_auto_S_o,    verde_auto_S_o;
wire rosu_pietoni_S_o, verde_pietoni_S_o;
wire rosu_auto_E_o,    galben_auto_E_o,    verde_auto_E_o;
wire rosu_pietoni_E_o, verde_pietoni_E_o;
wire rosu_auto_V_o,    galben_auto_V_o,    verde_auto_V_o;
wire rosu_pietoni_V_o, verde_pietoni_V_o;

// Instantiere DUT - modulul top-level semafor_intersectie
semafor_intersectie #(.CLK_FREQ(CLK_FREQ_SIM)) dut (
    .clk_i          (clk_i),
    .reset_n_i      (reset_n_i),
    .service_i      (service_i),
    .pietoni_btn_i  (pietoni_btn_i),

    .rosu_auto_N_o       (rosu_auto_N_o),
    .galben_auto_N_o     (galben_auto_N_o),
    .verde_auto_N_o      (verde_auto_N_o),
    .rosu_pietoni_N_o    (rosu_pietoni_N_o),
    .verde_pietoni_N_o   (verde_pietoni_N_o),

    .rosu_auto_S_o       (rosu_auto_S_o),
    .galben_auto_S_o     (galben_auto_S_o),
    .verde_auto_S_o      (verde_auto_S_o),
    .rosu_pietoni_S_o    (rosu_pietoni_S_o),
    .verde_pietoni_S_o   (verde_pietoni_S_o),

    .rosu_auto_E_o       (rosu_auto_E_o),
    .galben_auto_E_o     (galben_auto_E_o),
    .verde_auto_E_o      (verde_auto_E_o),
    .rosu_pietoni_E_o    (rosu_pietoni_E_o),
    .verde_pietoni_E_o   (verde_pietoni_E_o),

    .rosu_auto_V_o       (rosu_auto_V_o),
    .galben_auto_V_o     (galben_auto_V_o),
    .verde_auto_V_o      (verde_auto_V_o),
    .rosu_pietoni_V_o    (rosu_pietoni_V_o),
    .verde_pietoni_V_o   (verde_pietoni_V_o)
);


// Generare ceas
initial clk_i = 0;
always #(CLK_PERIOD/2) clk_i = ~clk_i;

// Task: Reset
task apply_reset;
    begin
        reset_n_i     = 0;
        service_i     = 0;
        pietoni_btn_i = 0;
        repeat(5) @(posedge clk_i);
        reset_n_i = 1;
        @(posedge clk_i);
        $display("[RESET] t=%0t | Reset aplicat si eliberat", $time);
    end
endtask

// Task: Asteapta un ciclu complet S->E->V->N fara pietoni
task run_sequence_no_btn;
    begin
        $display("\n[T1] ============= TEST 1: Functionare normala FARA pietoni =============");
        $display("[T1] Secventa automata: S -> E -> V -> N (controlata intern de DUT)");

        // Asteptam verde pe Sud
        @(posedge verde_auto_S_o);
        $display("[T1] t=%0t | Verde AUTO activ: SUD", $time);

        @(negedge verde_auto_S_o);
        $display("[T1] t=%0t | Verde AUTO terminat: SUD", $time);

        // Asteptam verde pe Est
        @(posedge verde_auto_E_o);
        $display("[T1] t=%0t | Verde AUTO activ: EST", $time);

        @(negedge verde_auto_E_o);
        $display("[T1] t=%0t | Verde AUTO terminat: EST", $time);

        // Asteptam verde pe Vest
        @(posedge verde_auto_V_o);
        $display("[T1] t=%0t | Verde AUTO activ: VEST", $time);

        @(negedge verde_auto_V_o);
        $display("[T1] t=%0t | Verde AUTO terminat: VEST", $time);

        // Asteptam verde pe Nord
        @(posedge verde_auto_N_o);
        $display("[T1] t=%0t | Verde AUTO activ: NORD", $time);

        @(negedge verde_auto_N_o);
        $display("[T1] t=%0t | Verde AUTO terminat: NORD", $time);

        $display("[T1] Ciclu complet S->E->V->N finalizat cu succes!");
    end
endtask

// Task: Un ciclu complet cu buton pietoni pe fiecare directie
task run_sequence_with_btn;
    begin
        $display("\n[T2] ============= TEST 2: Functionare normala CU pietoni =============");
        $display("[T2] Butonul pietoni va fi apasat in timpul fiecarei directii");

        // --- Sud cu pietoni ---
        @(posedge verde_auto_S_o);
        $display("[T2] t=%0t | Verde AUTO activ: SUD - apasam buton pietoni", $time);
        repeat(5 * CLK_FREQ_SIM) @(posedge clk_i);
        pietoni_btn_i = 1;
        repeat(50) @(posedge clk_i);
        pietoni_btn_i = 0;

        @(posedge verde_pietoni_S_o);
        $display("[T2] t=%0t | Verde PIETONI activ: SUD", $time);
        @(negedge verde_pietoni_S_o);
        $display("[T2] t=%0t | Verde PIETONI terminat: SUD", $time);

        // --- Est cu pietoni ---
        @(posedge verde_auto_E_o);
        $display("[T2] t=%0t | Verde AUTO activ: EST - apasam buton pietoni", $time);
        repeat(3 * CLK_FREQ_SIM) @(posedge clk_i);
        pietoni_btn_i = 1;
        repeat(50) @(posedge clk_i);
        pietoni_btn_i = 0;

        @(posedge verde_pietoni_E_o);
        $display("[T2] t=%0t | Verde PIETONI activ: EST", $time);
        @(negedge verde_pietoni_E_o);
        $display("[T2] t=%0t | Verde PIETONI terminat: EST", $time);

        // --- Vest cu pietoni ---
        @(posedge verde_auto_V_o);
        $display("[T2] t=%0t | Verde AUTO activ: VEST - apasam buton pietoni", $time);
        repeat(10 * CLK_FREQ_SIM) @(posedge clk_i);
        pietoni_btn_i = 1;
        repeat(50) @(posedge clk_i);
        pietoni_btn_i = 0;

        @(posedge verde_pietoni_V_o);
        $display("[T2] t=%0t | Verde PIETONI activ: VEST", $time);
        @(negedge verde_pietoni_V_o);
        $display("[T2] t=%0t | Verde PIETONI terminat: VEST", $time);

        // --- Nord cu pietoni ---
        @(posedge verde_auto_N_o);
        $display("[T2] t=%0t | Verde AUTO activ: NORD - apasam buton pietoni", $time);
        repeat(8 * CLK_FREQ_SIM) @(posedge clk_i);
        pietoni_btn_i = 1;
        repeat(50) @(posedge clk_i);
        pietoni_btn_i = 0;

        @(posedge verde_pietoni_N_o);
        $display("[T2] t=%0t | Verde PIETONI activ: NORD", $time);
        @(negedge verde_pietoni_N_o);
        $display("[T2] t=%0t | Verde PIETONI terminat: NORD", $time);

        $display("[T2] Test 2 finalizat cu succes!");
    end
endtask


// Task: Reset in timpul functionarii
task test_reset;
    begin
        $display("\n[T3] ============= TEST 3: Reset in timpul functionarii =============");

        // Asteptam pornirea Sud
        @(posedge verde_auto_S_o);
        $display("[T3] t=%0t | Verde AUTO activ: SUD - aplicam reset dupa 10s simulate", $time);

        repeat(10 * CLK_FREQ_SIM) @(posedge clk_i);
        $display("[T3] t=%0t | Aplicam RESET", $time);
        reset_n_i = 0;
        repeat(3) @(posedge clk_i);
        $display("[T3] t=%0t | Eliberam RESET", $time);
        reset_n_i = 1;
        repeat(5) @(posedge clk_i);

        // Verificam starea dupa reset: toate directiile trebuie sa fie pe ROSU
        if (rosu_auto_S_o && !verde_auto_S_o && !galben_auto_S_o)
            $display("[T3] PASS: Dupa reset, SUD este pe ROSU");
        else
            $display("[T3] FAIL: Dupa reset, starea SUD gresita! R=%b G=%b V=%b",
                     rosu_auto_S_o, galben_auto_S_o, verde_auto_S_o);

        if (rosu_auto_E_o && !verde_auto_E_o && !galben_auto_E_o)
            $display("[T3] PASS: Dupa reset, EST este pe ROSU");
        else
            $display("[T3] FAIL: Dupa reset, starea EST gresita! R=%b G=%b V=%b",
                     rosu_auto_E_o, galben_auto_E_o, verde_auto_E_o);

        if (rosu_auto_V_o && !verde_auto_V_o && !galben_auto_V_o)
            $display("[T3] PASS: Dupa reset, VEST este pe ROSU");
        else
            $display("[T3] FAIL: Dupa reset, starea VEST gresita! R=%b G=%b V=%b",
                     rosu_auto_V_o, galben_auto_V_o, verde_auto_V_o);

        if (rosu_auto_N_o && !verde_auto_N_o && !galben_auto_N_o)
            $display("[T3] PASS: Dupa reset, NORD este pe ROSU");
        else
            $display("[T3] FAIL: Dupa reset, starea NORD gresita! R=%b G=%b V=%b",
                     rosu_auto_N_o, galben_auto_N_o, verde_auto_N_o);

        $display("[T3] Test 3 finalizat!");
    end
endtask

// Task: Stare de avarie (service)
task test_service;
    begin
        $display("\n[T4] ============= TEST 4: Stare de avarie (service) =============");

        @(posedge verde_auto_S_o);
        $display("[T4] t=%0t | Verde SUD activ - activam service dupa 5s simulate", $time);
        repeat(5 * CLK_FREQ_SIM) @(posedge clk_i);

        $display("[T4] t=%0t | Activam SERVICE", $time);
        service_i = 1;
        repeat(20) @(posedge clk_i);

        $display("[T4] t=%0t | Verificare avarie - galben_S=%b verde_p_S=%b",
                 $time, galben_auto_S_o, verde_pietoni_S_o);
        $display("[T4] t=%0t |                    galben_E=%b galben_V=%b galben_N=%b",
                 $time, galben_auto_E_o, galben_auto_V_o, galben_auto_N_o);

        // Asteptam 2s simulate pentru a vedea blink-ul
        repeat(2 * CLK_FREQ_SIM) @(posedge clk_i);
        $display("[T4] t=%0t | Dezactivam SERVICE", $time);
        service_i = 0;
        repeat(10) @(posedge clk_i);

        $display("[T4] Test 4 finalizat!");
    end
endtask

// Secventa principala de testare
initial begin
    $dumpfile("tb_semafor_intersectie_top.vcd");
    $dumpvars(0, tb_semafor_intersectie_top);

    $display("=======================================================");
    $display("  TESTBENCH TOP-LEVEL: Semafor Intersectie - Varianta 11");
    $display("  DUT: semafor_intersectie (modul top)");
    $display("  Parametri: N=28s, S=26s, E=15s, V=29s, C5=10s, C6=9s");
    $display("  Secventa: S -> E -> V -> N");
    $display("  NOTA: Recompilati cu CLK_FREQ=1000 pentru simulare rapida!");
    $display("=======================================================\n");

    apply_reset;

    // TEST 1: Functionare normala fara pietoni
    run_sequence_no_btn;

    apply_reset;
    repeat(10) @(posedge clk_i);

    // TEST 2: Functionare normala cu pietoni
    run_sequence_with_btn;

    apply_reset;
    repeat(10) @(posedge clk_i);

    // TEST 3: Reset in timpul functionarii
    test_reset;

    apply_reset;
    repeat(10) @(posedge clk_i);

    // TEST 4: Stare de avarie
    test_service;

    repeat(20) @(posedge clk_i);
    $display("\n=======================================================");
    $display("  TOATE TESTELE FINALIZATE");
    $display("  Verificati formele de unda in tb_semafor_intersectie_top.vcd");
    $display("=======================================================\n");
    $finish;
end

// Monitor automat - afiseaza schimbarile de stare
always @(posedge verde_auto_S_o)    $display("[MON] t=%0t | SUD:  Verde AUTO activ",    $time);
always @(posedge verde_auto_E_o)    $display("[MON] t=%0t | EST:  Verde AUTO activ",    $time);
always @(posedge verde_auto_V_o)    $display("[MON] t=%0t | VEST: Verde AUTO activ",    $time);
always @(posedge verde_auto_N_o)    $display("[MON] t=%0t | NORD: Verde AUTO activ",    $time);
always @(posedge verde_pietoni_S_o) $display("[MON] t=%0t | SUD:  Verde PIETONI activ", $time);
always @(posedge verde_pietoni_E_o) $display("[MON] t=%0t | EST:  Verde PIETONI activ", $time);
always @(posedge verde_pietoni_V_o) $display("[MON] t=%0t | VEST: Verde PIETONI activ", $time);
always @(posedge verde_pietoni_N_o) $display("[MON] t=%0t | NORD: Verde PIETONI activ", $time);

// Verificare temporizare
reg [63:0] t_start_S, t_start_E, t_start_V, t_start_N;

always @(posedge verde_auto_S_o) t_start_S = $time / CLK_PERIOD;
always @(negedge verde_auto_S_o) begin
    $display("[TIMING] SUD  Verde: %0d cicli (asteptat: %0d)",
             $time/CLK_PERIOD - t_start_S, 26 * CLK_FREQ_SIM);
end

always @(posedge verde_auto_E_o) t_start_E = $time / CLK_PERIOD;
always @(negedge verde_auto_E_o) begin
    $display("[TIMING] EST  Verde: %0d cicli (asteptat: %0d)",
             $time/CLK_PERIOD - t_start_E, 15 * CLK_FREQ_SIM);
end

always @(posedge verde_auto_V_o) t_start_V = $time / CLK_PERIOD;
always @(negedge verde_auto_V_o) begin
    $display("[TIMING] VEST Verde: %0d cicli (asteptat: %0d)",
             $time/CLK_PERIOD - t_start_V, 29 * CLK_FREQ_SIM);
end

always @(posedge verde_auto_N_o) t_start_N = $time / CLK_PERIOD;
always @(negedge verde_auto_N_o) begin
    $display("[TIMING] NORD Verde: %0d cicli (asteptat: %0d)",
             $time/CLK_PERIOD - t_start_N, 28 * CLK_FREQ_SIM);
end

// Timeout de siguranta
initial begin
    #(1_000 * CLK_FREQ_SIM * CLK_PERIOD * 10);
    $display("[TIMEOUT] Simularea a depasit limita de timp!");
    $finish;
end

endmodule