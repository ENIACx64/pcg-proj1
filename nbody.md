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
U nižší hodnoty N ke zrychlení nedochází, naopak dochází ke zpomalení. To je dáno tím, že velikost domény je příliš malá a režie spojená s manipulací s daty na a z GPU přebije benefity výpočtu na GPU.

### Krok 1: Sloučení kernelů
**Došlo ke zrychlení?**
Ano, ke zrychlení došlo.

**Popište hlavní důvody:**
Zrychlení je téměř konstantní a velikost domény na něj prakticky nemá vliv. To je dáno tím, že v kroku 1 došlo pouze ke sloučení kernelů, což ovlivní (zrychlí) výpočet stejně u jakékoliv velikosti domény.

Sloučením kernelů odpadá režie spojená s voláním kernelů. Rovněž se snížila redundance výpočtů, které se v tomto kroku provedly pouze v jednom kernelu.

### Krok 2: Sdílená paměť
**Došlo ke zrychlení?**
Ano, ke zrychlení došlo.

**Popište hlavní důvody:**
Ke zrychlení došlo díky použití sdílené paměti, která je blíže k vláknům a má tedy nižší latenci. Na začátku výpočtu jsou do sdílené paměti přednačtena data z globální paměti, poté se ve výpočtu pracuje se sdílenou pamětí, a až na konci výpočtu se výsledek opět zapíše do globální paměti.

### Krok 3: Výpočet těžiště
**Popište Vaši implementaci redukce:**
Principem redukce je algoritmus Grid-Stride Loop. Nejprve si každé vlákno inicializuje sdílenou paměť a lokální proměnnou v registru, která bude sloužit k akumulaci vážené sumy pozic a celkové váhy. Po dokončení akumulace jsou výsledky zapsány do sdílené paměti. Poté dochází k postupné redukci, kdy se redukuje po dvojicích tak dlouho, dokud nezůstane jediný výsledek. Tento výsledek je pomocí zámku zapsán na adresu ukazatele na strukturu pro těžiště. Výsledky jsou po přenesení z GPU na CPu vyděleny celkovou hmotností, čímž je získán finální výsledek.

**Došlo ke zrychlení?**
Ne, k pozorovatelnému zrychlení nedošlo.

**Popište hlavní důvody:**
Není důvod, aby s dalším výpočtem navíc oproti minulé implementaci došlo ke zrychlení.

### Krok 4: Synchronizace
**Popište Vaše řešení synchronizace:**
V implementaci jsou použity 3 streamy dle doporučení zadání - jeden pro výpočet polohy částic, jeden pro výpočet těžiště a jeden pro kopírování dat. Nejprve je spuštěn kernel pro výpočet nové polohy částice. Poté je vyhodnocena podmínka shouldWrite(s), která určí, zda se bude provádět zbytek cyklu. Pokud ano, spustí se výpočet těžiště. Během výpočtu dochází k přenosu dat nové polohy částice z GPU na CPU. Poté jsou data zapsána do souboru. Po dokončení výpočtu těžiště jsou data přenesena z GPU na CPU a zapsána do souboru. Pak již jen stačí vynulovat data pro strukturu těžiště.

Těsně před deadlinem jsem bohužel zpozoroval, že někde v kódu dochází k nesprávnému indexování kroků - skript compare.sh ukazuje, že hodnota se vždy liší od té referenční o jeden řádek. Bohužel se mi nepodařilo příčinu chyby odhalit před deadlinem.

**Došlo ke zrychlení?**
Ne, k pozorovatelnému zrychlení nedošlo.

**Popište hlavní důvody:**
V tomto kroku je oproti minulé implementaci navíc ukládání mezivýsledků simulace. Aby nedocházelo ke zbytečným prodlevám, je třeba synchronizovat procesy tak, aby se přenosy dat a výpočet co nejvíce vykryly. To nepřináší žádný benefit v podobě zrychlení - spíše to může program zpomalit.

### Krok 5: Měření výkonu
**Jakých jste dosáhli výsledků?**
Algoritmus se podařilo výrazně zrychlit pomocí CUDA a provádění kódu na GPU. Už jen samotná naivní implementace algoritmu na GPU přinesla při větších velikostech domény výrazné zrychlení, které s rostoucí velikostí domény dále stoupalo. Zrychlení bylo dosaženo i díky sloučení kernelů a sdílené paměti, ovšem v tomto případě už šlo o kostantní zrychlení nezávislé na velikosti domény. Poslední dva kroky žádné zrychlení nepřinesly, jelikož jejich to ani nebyl jejich účel. Zajímavé ovšem je, že nepřinesly ani žádné výrazné zpomalení.

**Lze v datech pozorovat nějaké anomálie?**
Za anomálii se dá považovat, že je algoritmus při nižších velikostech domény pomalejší na GPU než na CPU. Jak bylo ovšem vysvětleno výše, je to pravděpodobně způsobeno tím, že v případě takto "malých" dat převýší režie spojená s přenosem na GPU potenciální benefity v podobě vyšší rychlosti.