// ============================================================
// Modul: semafor_directie
// Descriere: Controleaza semaforul pentru o singura directie
//            de deplasare (auto + pietoni)
// Ceas: 10 MHz => 1 tact = 100 ns
// ============================================================
`timescale 1ns/1ps

module semafor_directie #(
    parameter CLK_FREQ   = 10_000_000,
    parameter C_VERDE    = 20
)(
    input  wire clk_i,
    input  wire reset_n_i,
    input  wire service_i,
    input  wire start_i,
    input  wire pietoni_btn_i,

    output reg  rosu_auto_o,
    output reg  galben_auto_o,
    output reg  verde_auto_o,
    output reg  rosu_pietoni_o,
    output reg  verde_pietoni_o,
    output reg  secventa_incheiata_o
);

localparam integer T_VERDE_AUTO    = C_VERDE * CLK_FREQ;
localparam integer T_GALBEN_AUTO   = 2       * CLK_FREQ;
localparam integer T_VERDE_PET     = 10      * CLK_FREQ;
localparam integer T_VERDE_INT_PET = 9       * CLK_FREQ;

localparam [2:0]
    ST_IDLE          = 3'd0,
    ST_VERDE_AUTO    = 3'd1,
    ST_GALBEN_AUTO   = 3'd2,
    ST_VERDE_PET     = 3'd3,
    ST_VERDE_INT_PET = 3'd4,
    ST_INCHEIAT      = 3'd5,
    ST_SERVICE       = 3'd6;

reg [2:0] state;

// Blink 0.5 Hz 
wire blink_sig;
div_frecventa #(.DIV_FACTOR(CLK_FREQ)) inst_blink (
    .clk_i     (clk_i),
    .reset_n_i (reset_n_i),
    .clk_div_o (blink_sig)
);

// Latch buton pietoni
reg btn_latch;
always @(posedge clk_i or negedge reset_n_i) begin
    if (!reset_n_i)
        btn_latch <= 0;
    else if (state == ST_INCHEIAT)
        btn_latch <= 0;
    else if (pietoni_btn_i)
        btn_latch <= 1;
end

// Timer descrescator
reg [31:0] timer;
wire timer_done = (timer == 0);

// FSM + Timer
always @(posedge clk_i or negedge reset_n_i) begin
    if (!reset_n_i) begin
        state <= ST_IDLE;
        timer <= 0;
    end else begin
        case (state)
            ST_IDLE: begin
                if (service_i) begin
                    state <= ST_SERVICE; timer <= 0;
                end else if (start_i) begin
                    state <= ST_VERDE_AUTO; timer <= T_VERDE_AUTO - 1;
                end
            end
            ST_VERDE_AUTO: begin
                if (service_i) begin
                    state <= ST_SERVICE; timer <= 0;
                end else if (timer_done) begin
                    state <= ST_GALBEN_AUTO; timer <= T_GALBEN_AUTO - 1;
                end else
                    timer <= timer - 1;
            end
            ST_GALBEN_AUTO: begin
                if (service_i) begin
                    state <= ST_SERVICE; timer <= 0;
                end else if (timer_done) begin
                    if (btn_latch || pietoni_btn_i) begin
                        state <= ST_VERDE_PET; timer <= T_VERDE_PET - 1;
                    end else begin
                        state <= ST_INCHEIAT; timer <= 0;
                    end
                end else
                    timer <= timer - 1;
            end
            ST_VERDE_PET: begin
                if (service_i) begin
                    state <= ST_SERVICE; timer <= 0;
                end else if (timer_done) begin
                    state <= ST_VERDE_INT_PET; timer <= T_VERDE_INT_PET - 1;
                end else
                    timer <= timer - 1;
            end
            ST_VERDE_INT_PET: begin
                if (service_i) begin
                    state <= ST_SERVICE; timer <= 0;
                end else if (timer_done) begin
                    state <= ST_INCHEIAT; timer <= 0;
                end else
                    timer <= timer - 1;
            end
            ST_INCHEIAT: begin
                if (service_i) begin
                    state <= ST_SERVICE; timer <= 0;
                end else begin
                    state <= ST_IDLE; timer <= 0;
                end
            end
            ST_SERVICE: begin
                if (!service_i) begin
                    state <= ST_IDLE; timer <= 0;
                end
            end
            default: begin state <= ST_IDLE; timer <= 0; end
        endcase
    end
end

// Iesiri Moore
always @(*) begin
    rosu_auto_o          = 1'b0;
    galben_auto_o        = 1'b0;
    verde_auto_o         = 1'b0;
    rosu_pietoni_o       = 1'b0;
    verde_pietoni_o      = 1'b0;
    secventa_incheiata_o = 1'b0;
    case (state)
        ST_IDLE:          begin rosu_auto_o = 1; rosu_pietoni_o = 1; end
        ST_VERDE_AUTO:    begin verde_auto_o = 1; rosu_pietoni_o = 1; end
        ST_GALBEN_AUTO:   begin galben_auto_o = 1; rosu_pietoni_o = 1; end
        ST_VERDE_PET:     begin rosu_auto_o = 1; verde_pietoni_o = 1; end
        ST_VERDE_INT_PET: begin rosu_auto_o = 1; verde_pietoni_o = blink_sig; end
        ST_INCHEIAT:      begin rosu_auto_o = 1; rosu_pietoni_o = 1; secventa_incheiata_o = 1; end
        ST_SERVICE:       begin galben_auto_o = blink_sig; verde_pietoni_o = blink_sig; end
        default:          begin rosu_auto_o = 1; rosu_pietoni_o = 1; end
    endcase
end

endmodule
