#!/bin/bash
# ============================================================
# Script compilare si simulare - Proiect CLP Varianta 11
# Necesita: iverilog + vvp (pachet iverilog)
# ============================================================

echo "============================================"
echo " Compilare proiect CLP - Varianta 11"
echo "============================================"

# Compilare
iverilog -o sim_semafor \
    semafor_directie.v \
    semafor_intersectie.v \
    tb_semafor_intersectie.v \
    -Wall

if [ $? -ne 0 ]; then
    echo "[EROARE] Compilarea a esuat!"
    exit 1
fi

echo "[OK] Compilare reusita!"
echo ""
echo "============================================"
echo " Rulare simulare"
echo "============================================"

vvp sim_semafor

echo ""
echo "============================================"
echo " Simulare finalizata!"
echo " Fisier VCD: tb_semafor_intersectie.vcd"
echo " Vizualizare: gtkwave tb_semafor_intersectie.vcd"
echo "============================================"
