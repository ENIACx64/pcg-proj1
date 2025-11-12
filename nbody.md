# PCG projekt 1
- autor: Jindřich Vodák
- login: xvodak06

## Měření výkonu (čas / 100 kroků simulace)

### Karolina A100
|   N    |  CPU [s] | Step 0 [s] | Zrychlení vs. CPU | Step 1 [s] | Zrychlení vs. Step 0 | Step 2 [s] | Zrychlení vs. Step 1 |
|:------:|:--------:|:----------:|:-----------------:|:----------:|:--------------------:|:----------:|:--------------------:|
|   1024 |   0.0409 |     0.0607 |           0.6738x |     0.0473 |              1.2833x |     0.0440 |              1.0750x |
|   2048 |   0.0480 |     0.1210 |           0.3967x |     0.0948 |              1.2764x |     0.0872 |              1.0872x |
|   4096 |   0.2318 |     0.2409 |           0.9622x |     0.1891 |              1.2739x |     0.1736 |              1.0893x |
|   8192 |   0.5964 |     0.4829 |           1.2350x |     0.3798 |              1.2714x |     0.3466 |              1.0958x |
|  16384 |   1.6740 |     0.9680 |           1.7293x |     0.7612 |              1.2717x |     0.6925 |              1.0992x |
|  32768 |   8.2773 |     1.9368 |           4.2737x |     1.5233 |              1.2715x |     1.3856 |              1.0994x |
|  65536 |  26.8663 |     6.3333 |           4.2421x |     5.0107 |              1.2640x |     4.6283 |              1.0826x |
| 131072 | 108.4233 |    18.9343 |           5.7263x |    14.9461 |              1.2668x |    13.8210 |              1.0814x |
| 262144 | 468.5436 |    61.2022 |           7.6557x |    48.3047 |              1.2670x |    44.7351 |              1.0798x |

<!---
### Barbora V100 (dobrovolné)
|    N   | Step 0 [s] | Step 1 [s] | Zrychlení vs. Step 0 | Step 2 [s] | Zrychlení vs. Step 1 |
|:------:|:----------:|:----------:|:--------------------:|:----------:|:--------------------:|
|   1024 |            |            |                      |            |                      |
|   2048 |            |            |                      |            |                      |
|   4096 |            |            |                      |            |                      |
|   8192 |            |            |                      |            |                      |
|  16384 |            |            |                      |            |                      |
|  32768 |            |            |                      |            |                      |
|  65536 |            |            |                      |            |                      |
| 131072 |            |            |                      |            |                      |
| 262144 |            |            |                      |            |                      |
-->

<!---
### Jiné GPU: [MODEL] (dobrovolné)
|    N   | Step 0 [s] | Step 1 [s] | Zrychlení vs. Step 0 | Step 2 [s] | Zrychlení vs. Step 1 |
|:------:|:----------:|:----------:|:--------------------:|:----------:|:--------------------:|
|   1024 |            |            |                      |            |                      |
|   2048 |            |            |                      |            |                      |
|   4096 |            |            |                      |            |                      |
|   8192 |            |            |                      |            |                      |
|  16384 |            |            |                      |            |                      |
|  32768 |            |            |                      |            |                      |
|  65536 |            |            |                      |            |                      |
| 131072 |            |            |                      |            |                      |
| 262144 |            |            |                      |            |                      |
-->

## Otázky

### Krok 0: Základní implementace
**Došlo ke zrychlení?**
Ano, ke zrychlení došlo. Zrychlení se zvyšuje s rostoucím počtem částic, protože GPU je oproti CPU schopno zpracovat souběžně velké množství dat. S rostoucím počtem částic se proto bude CPU projevovat více jako úzké hrdlo.


**Vyskytla se nějaká anomále v naměřených časech? Pokud ano, vysvětlete:**


### Krok 1: Sloučení kernelů
**Došlo ke zrychlení?**
Ano, ke zrychlení došlo.

**Popište hlavní důvody:**
Zrychlení je téměř konstantní a velikost domény na něj prakticky nemá vliv. To je dáno tím, že v kroku 1 došlo pouze ke sloučení kernelů, což ovlivní (zrychlí) výpočet stejně u jakékoliv velikosti domény.

Sloučením kernelů odpadá režie spojená s voláním kernelů. Rovněž se snížila redundance výpočtů, které se v tomto kroku provedly pouze v jednom kernelu.

### Krok 2: Sdílená paměť
**Došlo ke zrychlení?**


**Popište hlavní důvody:**


### Krok 3: Výpočet těžiště
**Popište Vaši implementaci redukce:**


**Došlo ke zrychlení?**


**Popište hlavní důvody:**


### Krok 4: Synchronizace
**Popište Vaše řešení synchronizace:**


**Došlo ke zrychlení?**


**Popište hlavní důvody:**


### Krok 5: Měření výkonu
**Jakých jste dosáhli výsledků?**


**Lze v datech pozorovat nějaké anomálie?**
