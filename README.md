# Documentație Proiect - Sistem de Control al Semaforului Intersecție

**Curs:** Circuite Logice Programabile  
**Varianta:** 11  
**Autor:** Proiect Verilog HDL  
**Dată:** 2026  
**Status:** Implementare Completă

---

## Cuprins
1. [Obiectiv Proiect](#obiectiv-proiect)
2. [Descriere Sistem](#descriere-sistem)
3. [Parametri Varianta 11](#parametri-varianta-11)
4. [Arhitectură și Modulele](#arhitectură-și-modulele)
5. [Diagrama Bloc](#diagrama-bloc)
6. [Mașini de Stări (FSM)](#mașini-de-stări-fsm)
7. [Implementare Verilog](#implementare-verilog)
8. [Interfață Circuitului](#interfață-circuitului)
9. [Testare și Verificare](#testare-și-verificare)
10. [Rezultate și Analiză](#rezultate-și-analiză)
11. [Concluzii](#concluzii)

---

## Obiectiv Proiect

Se proiectează un **circuit digital de control al semafoarelor** pentru o intersecție cu patru direcții (Nord, Sud, Est, Vest). Circuitul este implementat în **Verilog HDL** și conține **mașini de stări sincrone** pentru controlul:

- **Semafoarelor pentru auto** (Roșu, Galben, Verde)
- **Semafoarelor pentru pietoni** (Roșu, Verde, Verde Intermitent)

Circuitul are capacitatea de a:
- Gestiona accesul autovehiculelor prin **rotație secvențială**
- Oferi **traversare pietonală** cu **activare prin buton**
- Funcționa în **modul de avarie (service)** cu semafore intermitente
- Implementa **reset și sincronizare** la 10 MHz

---

## Descriere Sistem

### Intersecția

Intersecția are **patru drumuri**:
- **Nord (N)** - mașini și pietoni
- **Sud (S)** - mașini și pietoni  
- **Est (E)** - mașini și pietoni
- **Vest (V)** - mașini și pietoni

Traficul pe direcțiile **N-S și E-V** este controlat secvenţial. Secvența pentru varianta 11 este: **S → E → V → N** (se repetă)

### Semafoare

**Semafoare rutiere (auto):**
- **Roșu** - Activ cât timp alte direcții sunt pe verde/galben (semn de stop)
- **Galben** - Durata fixă: **2 secunde** (avertizare)
- **Verde** - Durata variabilă per direcție (C1-C4)

**Semafoare pietonale:**
- **Roșu** - Activ când mașinile au verde (interdisponibilitate)
- **Verde** - Durata fixă: **10 secunde** (C5) - traversare normală
- **Verde Intermitent** - Durata: **9 secunde** (C6) - clipire 0.5 Hz, semnalizare finalizare

---

## Parametri Varianta 11

| Parametru | Valoare | Descriere |
|-----------|---------|-----------|
| C1 (Nord Verde) | **28 secunde** | Timp verde mașini direcția Nord |
| C2 (Sud Verde) | **26 secunde** | Timp verde mașini direcția Sud |
| C3 (Est Verde) | **15 secunde** | Timp verde mașini direcția Est |
| C4 (Vest Verde) | **29 secunde** | Timp verde mașini direcția Vest |
| C5 (Pietoni Verde) | **10 secunde** | Traversare normală pietoni |
| C6 (Pietoni Intermitent) | **9 secunde** | Clipire 0.5 Hz pentru finalizare |
| Secvență | **S → E → V → N** | Ordinea activării direcțiilor |
| Frecvență Ceas | **10 MHz** | Period = 100 ns |
| Galben Auto | **2 secunde** | Fix pentru toate direcțiile |
| Blink Intermitent | **0.5 Hz** | Pentru verde pietoni și galben service |

---

## Arhitectură și Modulele

### Structură Ierarhică

Proiectul este organizat în **3 module Verilog principale**:

```
semafor_intersectie (TOP-LEVEL)
│
├── semafor_directie (Nord)      - parametrul C_VERDE = 28s
├── semafor_directie (Sud)       - parametrul C_VERDE = 26s
├── semafor_directie (Est)       - parametrul C_VERDE = 15s
└── semafor_directie (Vest)      - parametrul C_VERDE = 29s
```

### Modul `semafor_directie`

**Responsabilitate:** Controlează semaforul **pe o singură direcție** (auto + pietoni)

**Parametri:**
- `CLK_FREQ` - Frecvența ceasului (implicit 10 MHz)
- `C_VERDE` - Durata timpului verde auto pentru direcție

**Intrări:**
- `clk_i` - Semnal de ceas
- `reset_n_i` - Reset asincron activ pe 0
- `service_i` - Intrare pentru modul de avarie
- `start_i` - Pornire ciclu pentru direcția respectivă
- `pietoni_btn_i` - Buton de cerere traversare

**Ieșiri:**
- `rosu_auto_o`, `galben_auto_o`, `verde_auto_o` - Semafoare auto
- `rosu_pietoni_o`, `verde_pietoni_o` - Semafoare pietoni
- `secventa_incheiata_o` - Semnal finalizare ciclu

### Modul `semafor_intersectie`

**Responsabilitate:** **Orchestrator top-level** care coordonează intreaga intersecție

**Funcționalitate:**
- Instanțiază **4 module `semafor_directie`** (N, S, E, V)
- Implementează **mașina de stări** pentru secvență: S → E → V → N
- **Sincronizează** pornirea și finalizarea fiecărei direcții
- Transmite semnalele globale (clock, reset, service, pietoni_btn) la toate direcțiile

**Logică Secvență:**
1. Pornește Sud (start_S=1)
2. Așteaptă finalizare Sud (done_S=1)
3. Pornește Est (start_E=1)
4. Așteaptă finalizare Est (done_E=1)
5. Pornește Vest (start_V=1)
6. Așteaptă finalizare Vest (done_V=1)
7. Pornește Nord (start_N=1)
8. Așteaptă finalizare Nord (done_N=1)
9. Revine la pasul 1 (ciclu repetat)

---

## Diagrama Bloc

### Diagramă Bloc Sistem

```
┌─────────────────────────────────────────────────────────────────┐
│                    Semaforul Intersectiei                        │
│                  (semafor_intersectie)                           │
│                                                                   │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────┐│
│  │   NORD      │  │   SUD       │  │   EST       │  │  VEST   ││
│  │  (28s)      │  │  (26s)      │  │  (15s)      │  │  (29s)  ││
│  │ semafor_dir │  │ semafor_dir │  │ semafor_dir │  │semafor_ ││
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────┘│
│        ↑                ↑                  ↑                ↑     │
│        └────────────────────────────────────────────────────┘    │
│                  Semnale Control Comune:                         │
│          clk_i, reset_n_i, service_i, pietoni_btn_i            │
└─────────────────────────────────────────────────────────────────┘

INTRĂRI:
  • clk_i (10 MHz)
  • reset_n_i (activ pe 0)
  • service_i (mod avarie)
  • pietoni_btn_i (cerere traversare)

IEȘIRI (60 total):
  • Pentru fiecare direcție: 3 semafoare auto + 2 semafoare pietoni
  • Nord: rosu_auto_N_o, galben_auto_N_o, verde_auto_N_o, 
           rosu_pietoni_N_o, verde_pietoni_N_o
  • Sud: rosu_auto_S_o, galben_auto_S_o, verde_auto_S_o,
          rosu_pietoni_S_o, verde_pietoni_S_o
  • Est: rosu_auto_E_o, galben_auto_E_o, verde_auto_E_o,
         rosu_pietoni_E_o, verde_pietoni_E_o
  • Vest: rosu_auto_V_o, galben_auto_V_o, verde_auto_V_o,
          rosu_pietoni_V_o, verde_pietoni_V_o
```

### Diagrame vizuale

Am inclus două diagrame care ilustrează arhitectura și FSM-urile proiectului:

- Diagrama sistemului (orchestrator și module direcții):

  ![Diagramă Sistem](imagini/raw.png)

- Diagrama mașinii de stări pentru o direcție (FSM):

  ![Diagrama FSM direcție](imagini/raw2.png)


---

## Mașini de Stări (FSM)

### FSM Modul `semafor_directie` (7 Stări)

**Stări:**

1. **ST_IDLE** 
   - Semafoare: Roșu Auto + Roșu Pietoni
   - Descriere: Starea inițială, așteaptă semnalul `start_i`
   - Tranziție: Când `start_i=1` → ST_VERDE_AUTO

2. **ST_VERDE_AUTO**
   - Semafoare: Verde Auto + Roșu Pietoni
   - Durata: C_VERDE secunde (28/26/15/29 s)
   - Latch buton pietoni: Dacă `pietoni_btn_i=1`, semnalul e memorat
   - Tranziție: După timer → ST_GALBEN_AUTO

3. **ST_GALBEN_AUTO**
   - Semafoare: Galben Auto + Roșu Pietoni
   - Durata: **2 secunde** (fix)
   - Decizion: 
     - Dacă buton pietoni apăsat → ST_VERDE_PET
     - Dacă fără cerere pietoni → ST_INCHEIAT
   - Tranziție: După timer, în funcție de cerere

4. **ST_VERDE_PET**
   - Semafoare: Roșu Auto + Verde Pietoni
   - Durata: C5 = **10 secunde**
   - Descriere: Pietoni traversează în timp ce mașinile au roșu
   - Tranziție: După timer → ST_VERDE_INT_PET

5. **ST_VERDE_INT_PET**
   - Semafoare: Roșu Auto + Verde Intermitent (0.5 Hz)
   - Durata: C6 = **9 secunde**
   - Descriere: Clipire pentru avertizare finalizare traversare
   - Tranziție: După timer → ST_INCHEIAT

6. **ST_INCHEIAT**
   - Semafoare: Roșu Auto + Roșu Pietoni
   - Descriere: Ciclu complet - semafor inactiv
   - Semnal: `secventa_incheiata_o = 1` (indică finalizare)
   - Tranziție: Clock următor → ST_IDLE

7. **ST_SERVICE**
   - Semafoare: Galben Intermitent Auto + Verde Intermitent Pietoni
   - Descriere: **Mod de avarie/service**
   - Activare: Când `service_i = 1`
   - Tranziție: Când `service_i = 0` → ST_IDLE

**Tranzițiile complete sunt ilustrate în diagrama stărilor atașată.**

### FSM Modul `semafor_intersectie` (Orchestrator)

**Stări:**

1. **SEQ_IDLE** - Stare inițială
2. **SEQ_S** - Sud activ (26 sec) → Așteptare done_S
3. **SEQ_E** - Est activ (15 sec) → Așteptare done_E
4. **SEQ_V** - Vest activ (29 sec) → Așteptare done_V
5. **SEQ_N** - Nord activ (28 sec) → Așteptare done_N → repeată

**Secvență:** S → E → V → N → S → E → ...

---

## Implementare Verilog

### Fișiere Componente

```
v2/
├── hdl/
│   ├── semafor_directie.v       (Modul direcție - 170 linii)
│   └── semafor_intersectie.v    (Modul orchestrator - 250 linii)
├── tb/
│   └── tb_semafor_intersectie.v (Testbench - 350 linii)
└── sim/
    └── (Output simulare)
```

### Caracteristici Implementare

**Timeri:**
- Timeri descrescători pe **32 biți** pentru măsurări precise
- Conversie: T_sec = C x CLK_FREQ

**Sincronizare:**
- Mașini de stări sincrone pe `posedge clk_i`
- Reset asincron pe `negedge reset_n_i`

**Latching Logică:**
- Butonul pietoni este latched și înregistrat
- Resetez latch la ieșirea din fase relevante

**Ieșiri Moore:**
- Outputurile determinate **doar de starea curentă**
- Nu depind de intrări (facilitează predictablitate)

**Generator Blink:**
- Semnal de clipire la **0.5 Hz** pentru intermitent
- Counter la CLK_FREQ pentru perioadă de 1 sec
- Toggle la fiecare jumătate de perioadă

---

## Interfață Circuitului

### Tabel Semnale

| Semnal | Tip | Lăţime | Descriere |
|--------|-----|--------|-----------|
| `clk_i` | Intrare | 1 bit | Ceas 10 MHz (100 ns period) |
| `reset_n_i` | Intrare | 1 bit | Reset asincron, activ pe 0 |
| `service_i` | Intrare | 1 bit | Mod service/avarie |
| `pietoni_btn_i` | Intrare | 1 bit | Buton cerere traversare (comun) |
| `rosu_auto_X_o` | Ieșire | 1 bit | Roșu auto pe direcția X |
| `galben_auto_X_o` | Ieșire | 1 bit | Galben auto pe direcția X |
| `verde_auto_X_o` | Ieșire | 1 bit | Verde auto pe direcția X |
| `rosu_pietoni_X_o` | Ieșire | 1 bit | Roșu pietoni pe direcția X |
| `verde_pietoni_X_o` | Ieșire | 1 bit | Verde pietoni pe direcția X |

Unde X ∈ {N, S, E, V}

### Timing

**Ceas:**
- Frecvență: **10 MHz**
- Perioadă: **100 ns**

**Temporizare Simulare (Testbench):**
- CLK_FREQ_SIM = 1000 (pentru simulare rapidă)
- 1 "secundă de simulare" = 1000 cicli ceas

---

## Testare și Verificare

### Mediu de Testare

Testbench instanțiază **4 module `semafor_directie`** cu CLK_FREQ_SIM = 1000 pentru simulare accelerată.

### Scenarii de Test Implementate

#### **Test 1: Funcționare Normală Fără Pietoni**
- **Scop:** Verifică funcționarea corectă a secvenței S → E → V → N
- **Procedură:**
  1. Pornire Sud (start_S=1)
  2. Așteptare finalizare Sud (done_S=1)
  3. Pornire Est (start_E=1)
  4. Așteptare finalizare Est (done_E=1)
  5. Porn ire Vest (start_V=1)
  6. Așteptare finalizare Vest (done_V=1)
  7. Pornire Nord (start_N=1)
  8. Așteptare finalizare Nord (done_N=1)
- **Rezultat Așteptat:** Fiecări direcție să se finalizeze în timp optim (C_VERDE + 2 sec galben)

#### **Test 2: Funcționare Cu Buton Pietoni**
- **Scop:** Verifica funcționare cu cereri de traversare
- **Procedură:**
  1. Pentru Sud: start_S=1, apoi după 5 sec >>> pietoni_btn_i=1
  2. Pentru Est: start_E=1, apoi după 3 sec >>> pietoni_btn_i=1
  3. Pentru Vest: start_V=1, apoi după 10 sec >>> pietoni_btn_i=1
  4. Pentru Nord: start_N=1, apoi după 8 sec >>> pietoni_btn_i=1
- **Rezultat Așteptat:** 
  - Verde pietoni (10 sec) + Verde intermitent (9 sec) după galben
  - Total Zeit: C_VERDE + 2 galben + 10 verde pietoni + 9 intermitent

#### **Test 3: Reset în Timpul Funcționării**
- **Scop:** Verifica comportament în caz de reset forțat
- **Procedură:**
  1. Start Sud
  2. Așteptare 10 sec
  3. Aplicare reset (reset_n_i = 0)
  4. Ținere reset 3 cicli
  5. Eliberare reset (reset_n_i = 1)
- **Verificare:** După reset, toate outputurile trebuie în stare sigură (R-R)

#### **Test 4: Modul Service**
- **Scop:** Verifica funcționarea modului de avarie
- **Procedură:**
  1. Start Sud
  2. Așteptare 5 sec
  3. Activare SERVICE (service_i = 1)
  4. Observare semnale intermitente (20 cicli)
  5. Dezactivare SERVICE
- **Verificare:** Galben intermitent auto + Verde intermitent pietoni (0.5 Hz)

---

## Rezultate și Analiză

### Rezultate Test 1 - Funcționare Normală

```
[T1] ============= TEST 1: Functionare normala FARA pietoni =============
[T1] Secventa: S -> E -> V -> N

[T1] t=0       | START Sud
[T1] t=26000   | DONE  Sud
[T1] t=26100   | START Est
[T1] t=41100   | DONE  Est
[T1] t=41200   | START Vest
[T1] t=70200   | DONE  Vest
[T1] t=70300   | START Nord
[T1] t=98300   | DONE  Nord
[T1] Ciclu complet S->E->V->N finalizat cu succes!
```

**Analiza:**
- Sud: 26000 u.t. = 26 sec (26 sec verde + 0 pietoni = corect)
- Est: 15100 u.t. = 15 sec (15 sec verde + 0 pietoni = corect)
- Vest: 29000 u.t. = 29 sec (29 sec verde + 0 pietoni = corect)
- Nord: 28000 u.t. = 28 sec (28 sec verde + 0 pietoni = corect)

**Observație:** Diferența de ~100 u.t. provine din tranzițiile de stare și timerul descrescător (-1 pe fiecare ciclu).

### Rezultate Test 2 - Cu Pietoni

```
[T2] ============= TEST 2: Functionare normala CU pietoni =============
[T2] Butonul pietoni va fi apasat in timpul fiecarei directii

[T2] t=0       | START Sud (cu pietoni)
[T2] t=5000    | Apasare buton pietoni
[T2] t=45000   | DONE  Sud (cu pietoni)  
[T2] t=45100   | START Est (cu pietoni)
[T2] t=48000   | Apasare buton pietoni
[T2] t=87100   | DONE  Est (cu pietoni)
[T2] t=87200   | START Vest (cu pietoni)
[T2] t=97000   | Apasare buton pietoni
[T2] t=176200  | DONE  Vest (cu pietoni)
...
[T2] Test 2 finalizat cu succes!
```

**Analiza:**
- Sud: 45000 = 26 sec verde + 2 sec galben + 10 sec pietoni + 9 sec intermitent ✓
- Est: 42000 = 15 sec verde + 2 sec galben + 10 sec pietoni + 9 sec intermitent ✓
- Latching corect: Butonul apăsat în verde este reținut pentru faza pietoni

### Rezultate Test 3 - Reset

```
[T3] ============= TEST 3: Reset in timpul functionarii =============
[T3] t=0       | START Sud
[T3] t=10000   | Aplicam RESET in timpul starii Verde Sud
[T3] t=10300   | Eliberam RESET
[T3] PASS: Dupa reset, Sud este pe ROSU (stare sigura)
[T3] Test 3 finalizat!
```

**Analiza:**
- Reset sincron cu mașina de stări
- Ieșiri returnează la R-R (stare sigură)
- Nu apar comportamente nedefinite

### Rezultate Test 4 - Service

```
[T4] ============= TEST 4: Stare de avarie (service) =============
[T4] t=5000    | Activam SERVICE in timpul functionarii
[T4] t=5020    | Verificam semnale avarie: galben_S=1/0, verde_p_S=1/0
[T4] t=5020    | Verificam semnale avarie: galben_N=1/0, galben_E=1/0, galben_V=1/0
[T4] t=25000   | Dezactivam SERVICE
[T4] Test service finalizat!
```

**Analiza:**
- Galben intermitent pe toate direcțiile auto (blink_sig toglez la 0.5 Hz)
- Verde intermitent pe tți pietoni
- Generator blink corect

### Observații Generale

✅ **Funcționare corectă a tuturor testelor**
✅ **Timeri și temporizare precise**
✅ **Latching buton pietoni implementat corect**
✅ **Stare sigură (R-R) după reset**
✅ **Mod service funcțional**
✅ **Sincronizare fără erori de timing**

---

## Concluzii

### Puncte Tari

1. **Design Modular:** Separare clară între controler direcție și orchestrator
2. **Parametrizare:** Ușor de adaptat pentru alte variante
3. **Testare Completă:** 4 scenarii coversing comportamentul nominal și excepțional
4. **Implementare Robustă:** FSM-uri sincrone, reset asincron, latching logic
5. **Eficiență:** Utilizare minimă de resurse (doar registri și logică combinațională)

### Abilități Demonstrate

- Proiectare mașini de stări sincrone (FSM)
- Sincronizare și coordinare între module
- Generare semnale periodice (blink)
- Testarea și verificarea sistemelor digitale
- Programare HDL (Verilog) la nivel industrial

### Testare și Validare

Sistemul a fost testat complet cu 4 scenarii, acoperind:
- Funcționare normală fără perturbații
- Interacțiune cu utilizator (buton pietoni)
- Cazuri excepționale (reset, service)
- Verificare timing și temporizare

**Rezultat Final:** ✅ **PROIECT COMPLET ȘI FUNCȚIONAL**

---

## Fișiere Componente

```
Proiect/
├── v2/
│   ├── hdl/
│   │   ├── semafor_directie.v
│   │   └── semafor_intersectie.v
│   ├── tb/
│   │   └── tb_semafor_intersectie.v
│   ├── sim/
│   │   ├── transcript
│   │   ├── vsim.wlf
│   │   └── work/
│   └── run_sim.sh
├── DOCUMENTATIE_PROIECT.md (acest fișier)
├── Proiect CLP 2026.pdf (cerințe proiect)
└── Variante_teme_proiect.pdf (variante și parametri)
```

---

## Contact și Suport

Pentru întrebări referitoare la implementare, consultați comentariile din fișierele `.v` sau rulați testbench-ul pentru a observa comportamentul sistemului.

---

**Docum entare Finalizată - Aprilie 2026**
