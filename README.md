# Workshop polná 
Matěj Man - 2025-02-20   
Zpracování dat z mikroklimatických data loggerů TOMST.  
Výpočty odvozených proměnných  

   * denní, měsíční, roční statistiky
   * sumy efektivních teplot (growing, freezing degree days)
   * odhad přítomnosti sněhové pokrývky z přízemní teploty  
   * detekce čidla vykopnutého ze země  

Získání dat z nejbližší meteostanice Českého hydrometeorologického ústavu.  
Porovnání mikroklimatických a staničních dat.  


## Skripty a data
* [mikroklima.R](mikroklima.R)  - skript pro zpracování dat z TOMST loggerů
* [meteo_CHMU_opendata.R](meteo_CHMU_opendata.R)  - skript pro získání dat z meteostanic a porovnání s daty z TOMST loggerů
* složka "data" příklady několika souborů stažených z TOMST Loggerů 

## TOMST data loggery
* čidlo TMS-4 https://tomst.com/web/en/systems/tms/tms-4/ 
* software pro stahování dat https://tomst.com/web/en/systems/tms/software/ 
* odborný článek o čidlu TMS4 [Wild 2019.pdf](Wild2019.pdf)

## myClim skriptovací knihovna 
* repozitář https://github.com/ibot-geoecology/myClim  
* nápověda https://labgis.ibot.cas.cz/myclim/index.html 
* tutoriál https://labgis.ibot.cas.cz/myclim/articles/myclim-demo.html
* odborný článek [Man 2023.pdf](Man2023.pdf)

## myClimGUI interaktivní prohlížečka
* myClimGUI https://github.com/ibot-geoecology/myClimGui
* nápověda https://labgis.ibot.cas.cz/myclim/gui/index.html 
* tutotriál https://labgis.ibot.cas.cz/myclim/gui/articles/myClimGui-tutorial.html

## CHMI otevřená meteorologická data
* kde data stáhnout https://opendata.chmi.cz/
* popis a struktura dat (dokumentace) https://opendata.chmi.cz/meteorology/climate/Klimatologicka_data_popis.pdf 
* historická (končí koncem minulého roku) - denní krok https://opendata.chmi.cz/meteorology/climate/historical/
* recentní (od začátku letošního roku do včera) - krok denní, 1 hodiny, 10 minut https://opendata.chmi.cz/meteorology/climate/recent/



