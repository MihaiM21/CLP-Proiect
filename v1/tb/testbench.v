`timescale 1ns / 1ps

module tb_semafor();
    // Semnale de intrare (reg)
    reg clk_i;
    reg reset_n_i;
    reg service_i;
    reg start_init_i;
    reg [3:0] btns_pietoni_i;

    // Semnale de ieșire (wire) pentru monitorizare
    wire [2:0] auto_n, auto_e, auto_s, auto_v;
    wire [1:0] piet_n, piet_e, piet_s, piet_v;

    // Instanțierea Designului (Intersecția Completă)
    semafor_intersectie dut (
        .clk_i(clk_i),
        .reset_n_i(reset_n_i),
        .service_i(service_i),
        .start_init_i(start_init_i),
        .btns_pietoni_i(btns_pietoni_i),
        .auto_n(auto_n), .piet_n(piet_n),
        .auto_e(auto_e), .piet_e(piet_e),
        .auto_s(auto_s), .piet_s(piet_s),
        .auto_v(auto_v), .piet_v(piet_v)
    );

    // Generare Ceas: 10 MHz (perioadă 100ns)
    always #50 clk_i = ~clk_i;

    initial begin
        // --- Inițializare semnale ---
        clk_i = 0;
        reset_n_i = 0;
        service_i = 0;
        start_init_i = 0;
        btns_pietoni_i = 4'b0000;

        // --- Pas 1: Aplicare Reset ---
        #200 reset_n_i = 1;
        #100;

        // --- Pas 2: Pornire Ciclu (Start Init) ---
        // Se pornește prima direcție (SUD conform temei 11)
        start_init_i = 1;
        #100 start_init_i = 0;

        // --- Pas 3: Simulare Funcționare fără Pietoni ---
        // Așteptăm să treacă un ciclu auto (Verde Sud = 26s etc.)
        // Pentru a grăbi simularea în ModelSim, poți modifica CLK_FREQ în module.
        #1000; 

        // --- Pas 4: Simulare cu Buton Pietoni (Scenariul 2) ---
        // Apăsăm butonul pentru Sud în timp ce e pe verde
        wait(auto_s[0] == 1); // Așteaptă verde auto la Sud
        #500 btns_pietoni_i[2] = 1; // Apasă buton pietoni Sud
        #200 btns_pietoni_i[2] = 0; // Eliberează buton

        // --- Pas 5: Testare Avarie (Service) ---
        #5000 service_i = 1;
        #2000 service_i = 0;

        // Finalizare simulare după un timp suficient
        #10000 $stop;
    end

    // Monitorizare în consolă
    initial begin
        $monitor("Timp: %0t | S:%b E:%b V:%b N:%b", $time, auto_s, auto_e, auto_v, auto_n);
    end

endmodule