# Seznam potřebných knihoven
required_packages <-
  c("dplyr", "tidyr", "stringr", "openxlsx", "ggplot2")

# Instalace chybějících balíčků a načtení knihoven
suppressWarnings(lapply(required_packages, function(pkg) {
  if (!require(pkg, character.only = TRUE))
    install.packages(pkg, repos = "https://mirrors.nic.cz/R/")
  library(pkg, character.only = TRUE)
}))


remotes::install_github("https://github.com/ibot-geoecology/myClim")
remotes::install_github("https://github.com/ibot-geoecology/myClimGui")

library(myClim)
library(myClimGui)
setwd(r"(d:\Git\polna-workshop\)")

tms <- mc_read_files("./data/",dataformat_name = "TOMST")
l<-mc_info_logger(tms)
i<-mc_info(tms)

## Statické zobrazení průběhu teplot a půdní vlhkosti TOMST TMS-4 loggeru 
## liniový graf
mc_plot_line(tms,
             sensors = c("TMS_T3","TMS_moist"),
             color_by_logger = TRUE)

## rastrový graf
mc_plot_raster(tms,
             sensors = c("TMS_T3","TMS_T1"))


## Detekce vykopnutého TMS4 (bez kontaktu s půdou) 
tms <- mc_prep_TMSoffsoil(tms)

## vizualizace detailu vykopnutého čidla
mc_plot_line(tms,
             sensors = c("TMS_moist","off_soil"),
             color_by_logger = TRUE)

## Kontrola vykopnutí na všech lokalitách 
mc_plot_line(micro.data.prep, sensors = "off_soil")

## ## spuštění aplikace, načtení dat do myClimGUI
myClimGui::mcg_run(tms)

## vyhodíme čidlo, které nebylo v zemi
tms<-mc_filter(tms,localities = "94184242",reverse = T)


## výpočty proměnných 

# Pro příklad použijeme TMS_T3 senzor 15 cm nad zemí, z TMS-4 TOMST loggeru 
micro.data <- mc_calc_gdd(tms, sensor = "TMS_T3", t_base = 5)
micro.data <- mc_calc_fdd(micro.data, sensor = "TMS_T3", t_base = 5)

## výpis senzorů, které jsou v myClim objektu k dispozici pro výpočty
levels(factor(mc_info(micro.data)$sensor_name))

## vybereme teplotní senzory a požadované agregační funkce
micro.agreg <- mc_agg(micro.data,
                      period = "day",
                      percentiles = c(5,95),
                      min_coverage = 0.9,
                      fun=list(
                        FDD0="sum",
                        GDD5="sum",
                        TMS_T1=c("mean","percentile","range"),
                        TMS_T2=c("mean","percentile","range"),
                        TMS_T3=c("mean","percentile","range")))

## výpis výsledných senzorů
levels(factor(mc_info(micro.agreg)$sensor_name))

## převod z myClim objektu na prostou tabulku, dlouhý formát
tabulka <- mc_reshape_wide(micro.agreg[-4]) 


## Detekce sněhu na základě přízemních teplot (TMS_T2)
## Výstup uložen jako virtuální senzor "snih"
micro.snow <- mc_calc_snow(tms, 
                           sensor = "TMS_T2", 
                           output_sensor = "snih")
## Vizualizace
mc_plot_line(micro.snow, sensors = c("TMS_T2","snih"))




