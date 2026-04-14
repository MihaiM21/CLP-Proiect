module semafor_directie #(
    parameter VERDE_AUTO_SEC = 26,
    parameter VERDE_PIET_SEC = 10,
    parameter FLASH_PIET_SEC = 9
)(
    input wire clk_i, 
    input wire reset_n_i, 
    input wire service_i, 
    input wire start_i, 
    input wire pietoni_btn_i,
    output reg rosu_auto_o, 
    output reg galben_auto_o, 
    output reg verde_auto_o,
    output reg rosu_pietoni_o, 
    output reg verde_pietoni_o, 
    output reg secventa_incheiata_o
);

    // Parametri pentru ceasul de 10MHz
    localparam CLK_FREQ = 10000000;
    
    // Definire stări
    localparam IDLE         = 3'd0;
    localparam VERDE_AUTO   = 3'd1;
    localparam GALBEN_AUTO  = 3'd2;
    localparam VERDE_PIET   = 3'd3;
    localparam FLASH_PIET   = 3'd4;
    localparam DONE         = 3'd5;
    localparam SERVICE      = 3'd6;

    reg [2:0] state;
    reg [31:0] clk_cnt;
    reg [31:0] sec_cnt;
    reg ped_latched; // Memorează dacă butonul a fost apăsat

    always @(posedge clk_i or negedge reset_n_i) begin
        if (!reset_n_i) begin
            state <= IDLE;
            clk_cnt <= 0;
            sec_cnt <= 0;
            ped_latched <= 0;
        end else if (service_i) begin
            state <= SERVICE;
            clk_cnt <= (clk_cnt >= CLK_FREQ - 1) ? 0 : clk_cnt + 1;
        end else begin
            case (state)
                IDLE: begin
                    if (start_i) state <= VERDE_AUTO;
                    sec_cnt <= 0;
                    clk_cnt <= 0;
                    ped_latched <= 0;
                end

                VERDE_AUTO: begin
                    if (pietoni_btn_i) ped_latched <= 1;
                    if (clk_cnt >= CLK_FREQ - 1) begin
                        clk_cnt <= 0;
                        if (sec_cnt >= VERDE_AUTO_SEC - 1) begin
                            state <= GALBEN_AUTO;
                            sec_cnt <= 0;
                        end else sec_cnt <= sec_cnt + 1;
                    end else clk_cnt <= clk_cnt + 1;
                end

                GALBEN_AUTO: begin
                    if (pietoni_btn_i) ped_latched <= 1;
                    if (clk_cnt >= CLK_FREQ - 1) begin
                        clk_cnt <= 0;
                        if (sec_cnt >= 1) begin // 2 secunde galben
                            state <= ped_latched ? VERDE_PIET : DONE;
                            sec_cnt <= 0;
                        end else sec_cnt <= sec_cnt + 1;
                    end else clk_cnt <= clk_cnt + 1;
                end

                VERDE_PIET: begin
                    if (clk_cnt >= CLK_FREQ - 1) begin
                        clk_cnt <= 0;
                        if (sec_cnt >= VERDE_PIET_SEC - 1) begin
                            state <= FLASH_PIET;
                            sec_cnt <= 0;
                        end else sec_cnt <= sec_cnt + 1;
                    end else clk_cnt <= clk_cnt + 1;
                end

                FLASH_PIET: begin
                    if (clk_cnt >= CLK_FREQ - 1) begin
                        clk_cnt <= 0;
                        if (sec_cnt >= FLASH_PIET_SEC - 1) begin
                            state <= DONE;
                            sec_cnt <= 0;
                        end else sec_cnt <= sec_cnt + 1;
                    end else clk_cnt <= clk_cnt + 1;
                end

                DONE: begin
                    state <= IDLE;
                end

                SERVICE: begin
                    if (!service_i) state <= IDLE;
                end
            endcase
        end
    end

    // Logica ieșirilor
    always @(*) begin
        // Valori implicite (Roșu)
        rosu_auto_o = 1; galben_auto_o = 0; verde_auto_o = 0;
        rosu_pietoni_o = 1; verde_pietoni_o = 0; secventa_incheiata_o = 0;

        case (state)
            VERDE_AUTO: begin rosu_auto_o = 0; verde_auto_o = 1; end
            GALBEN_AUTO: begin rosu_auto_o = 0; galben_auto_o = 1; end
            VERDE_PIET: begin rosu_pietoni_o = 0; verde_pietoni_o = 1; end
            FLASH_PIET: begin
                rosu_pietoni_o = 0;
                verde_pietoni_o = (clk_cnt < CLK_FREQ / 2); // 0.5 Hz
            end
            DONE: secventa_incheiata_o = 1;
            SERVICE: begin
                rosu_auto_o = 0;
                galben_auto_o = (clk_cnt < CLK_FREQ / 2);
                rosu_pietoni_o = 0;
                verde_pietoni_o = (clk_cnt < CLK_FREQ / 2);
            end
        endcase
    end
endmodule