module semafor_intersectie(
    input wire clk_i,
    input wire reset_n_i,
    input wire service_i,
    input wire start_init_i, // Puls pentru a porni prima dată ciclul
    input wire [3:0] btns_pietoni_i, // [3]=V, [2]=S, [1]=E, [0]=N
    
    // Ieșiri pentru Nord
    output wire [2:0] auto_n, output wire [1:0] piet_n,
    // Ieșiri pentru Est
    output wire [2:0] auto_e, output wire [1:0] piet_e,
    // Ieșiri pentru Sud
    output wire [2:0] auto_s, output wire [1:0] piet_s,
    // Ieșiri pentru Vest
    output wire [2:0] auto_v, output wire [1:0] piet_v
);

    wire done_s, done_e, done_v, done_n;

    // Proiect 11 Ordine: Sud -> Est -> Vest -> Nord

    // 1. SUD (C2=26s, C5=10s, C6=9s)
    semafor_directie #(.VERDE_AUTO_SEC(26), .VERDE_PIET_SEC(10), .FLASH_PIET_SEC(9)) 
    inst_SUD (
        .clk_i(clk_i), .reset_n_i(reset_n_i), .service_i(service_i),
        .start_i(start_init_i | done_n), // Repornește după Nord
        .pietoni_btn_i(btns_pietoni_i[2]),
        .rosu_auto_o(auto_s[2]), .galben_auto_o(auto_s[1]), .verde_auto_o(auto_s[0]),
        .rosu_pietoni_o(piet_s[1]), .verde_pietoni_o(piet_s[0]),
        .secventa_incheiata_o(done_s)
    );

    // 2. EST (C3=15s, C5=10s, C6=9s)
    semafor_directie #(.VERDE_AUTO_SEC(15), .VERDE_PIET_SEC(10), .FLASH_PIET_SEC(9)) 
    inst_EST (
        .clk_i(clk_i), .reset_n_i(reset_n_i), .service_i(service_i),
        .start_i(done_s),
        .pietoni_btn_i(btns_pietoni_i[1]),
        .rosu_auto_o(auto_e[2]), .galben_auto_o(auto_e[1]), .verde_auto_o(auto_e[0]),
        .rosu_pietoni_o(piet_e[1]), .verde_pietoni_o(piet_e[0]),
        .secventa_incheiata_o(done_e)
    );

    // 3. VEST (C4=29s, C5=10s, C6=9s)
    semafor_directie #(.VERDE_AUTO_SEC(29), .VERDE_PIET_SEC(10), .FLASH_PIET_SEC(9)) 
    inst_VEST (
        .clk_i(clk_i), .reset_n_i(reset_n_i), .service_i(service_i),
        .start_i(done_e),
        .pietoni_btn_i(btns_pietoni_i[3]),
        .rosu_auto_o(auto_v[2]), .galben_auto_o(auto_v[1]), .verde_auto_o(auto_v[0]),
        .rosu_pietoni_o(piet_v[1]), .verde_pietoni_o(piet_v[0]),
        .secventa_incheiata_o(done_v)
    );

    // 4. NORD (C1=28s, C5=10s, C6=9s)
    semafor_directie #(.VERDE_AUTO_SEC(28), .VERDE_PIET_SEC(10), .FLASH_PIET_SEC(9)) 
    inst_NORD (
        .clk_i(clk_i), .reset_n_i(reset_n_i), .service_i(service_i),
        .start_i(done_v),
        .pietoni_btn_i(btns_pietoni_i[0]),
        .rosu_auto_o(auto_n[2]), .galben_auto_o(auto_n[1]), .verde_auto_o(auto_n[0]),
        .rosu_pietoni_o(piet_n[1]), .verde_pietoni_o(piet_n[0]),
        .secventa_incheiata_o(done_n)
    );

endmodule