# PCG projekt 1
- autor: Jindřich Vodák
- login: xvodak06

## Měření výkonu (čas / 100 kroků simulace)

### Karolina A100
|   N    |  CPU [s] | Step 0 [s] | Zrychlení vs. CPU | Step 1 [s] | Zrychlení vs. Step 0 | Step 2 [s] | Zrychlení vs. Step 1 |
|:------:|:--------:|:----------:|:-----------------:|:----------:|:--------------------:|:----------:|:--------------------:|
|   1024 |   0.0409 |     0.0607 |                   |     0.0473 |                      |            |                      |
|   2048 |   0.0480 |     0.1210 |                   |     0.0948 |                      |            |                      |
|   4096 |   0.2318 |     0.2409 |                   |     0.1891 |                      |            |                      |
|   8192 |   0.5964 |     0.4829 |                   |     0.3798 |                      |            |                      |
|  16384 |   1.6740 |     0.9680 |                   |     0.7612 |                      |            |                      |
|  32768 |   8.2773 |     1.9368 |                   |     1.5233 |                      |            |                      |
|  65536 |  26.8663 |     6.3333 |                   |     5.0107 |                      |            |                      |
| 131072 | 108.4233 |    18.9343 |                   |    14.9461 |                      |            |                      |
| 262144 | 468.5436 |    61.2022 |                   |    48.3047 |                      |            |                      |

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


**Vyskytla se nějaká anomále v naměřených časech? Pokud ano, vysvětlete:**


### Krok 1: Sloučení kernelů
**Došlo ke zrychlení?**


**Popište hlavní důvody:**


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
