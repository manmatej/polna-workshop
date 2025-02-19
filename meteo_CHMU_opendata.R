
# Seznam potřebných knihoven
required_packages <- c("jsonlite", "lubridate", "sf", "dplyr", "stringr")

# Instalace a načtení knihoven
suppressWarnings(
  lapply(required_packages, function(pkg) {
    if (!require(pkg, character.only = TRUE)) install.packages(pkg,
                               repos = "https://mirrors.nic.cz/R/")
    library(pkg, character.only = TRUE)
  })
)
rm(required_packages)



## ------------------------ Definice funkcí ----------------------------------------
# Funkce pro stažení metadat a filtrování stanic na základě dostupné proměnné a roku
ziskat_stanice_s_dostupnou_promennou <- function(element) {
  # Stažení metadatového souboru meta2.json pomocí curl
  vcera<-format(Sys.time()-(24*60*60), "%Y%m%d") 
  metadata_url <-paste0(
    "https://opendata.chmi.cz/meteorology/climate/recent/metadata/meta2-",vcera,".json")
  metadata_file <- tempfile(fileext = ".json")
  system(paste("curl -o", metadata_file, metadata_url))
  # Načtení metadat ze souboru
  metadata <- fromJSON(metadata_file)
  # Zpracování metadat, extrahování hodnot a filtrování podle proměnné a roku
  metadata_df <- data.frame(metadata$data$data$values)
  colnames(metadata_df) <- unlist(strsplit(metadata$data$data$header, ","))
  # Filtrování stanic, které mají dostupná data pro zvolený rok a proměnnou (element)
  stanice_s_promennou <- metadata_df %>%
    filter(EG_EL_ABBREVIATION == element) %>%
    mutate (HEIGHT=as.numeric(HEIGHT)) %>%
    filter(HEIGHT < 2.5 & HEIGHT > 1.9)
  return(stanice_s_promennou)
}

# Funkce pro načtení meta1.json a připojení informací o stanicích s filtrací dle roku
pripojit_meta1 <- function(stanice_s_promennou) {
  # Stažení meta1.json pomocí download.file
  vcera<-format(Sys.time()-(24*60*60), "%Y%m%d") 
  metadata1_url <-paste0(
    "https://opendata.chmi.cz/meteorology/climate/recent/metadata/meta1-",vcera,".json")
  metadata1_file <- tempfile(fileext = ".json")
  download.file(metadata1_url, metadata1_file)
  metadata1 <- fromJSON(metadata1_file)
  # Extrakce informací z meta1.json a vytvoření datového rámce
  metadata1_df <- data.frame(metadata1$data$data$values)
  colnames(metadata1_df) <- c("WSI", "GH_ID", "FULL_NAME",
                              "GEOGR1", "GEOGR2", "ELEVATION","BEGIN_DATE")
  # Připojení informací z meta1 k tabulce stanice_s_promennou pomocí left_join
  stanice_s_informacemi <- stanice_s_promennou %>%
    left_join(metadata1_df, by = "WSI")
  stanice_s_informacemi <- stanice_s_informacemi %>%
    filter(!is.na(GEOGR1) & !is.na(GEOGR2))
  return(stanice_s_informacemi)
}

# Funkce pro výpočet vzdálenosti v kilometrech v UTM33N
vypocet_vzdalenosti_utm33n <- function(lat1, lon1, lat2, lon2) {
  # Vytvoření sf objektů pro body
  bod1 <- st_as_sf(data.frame(lon = lon1, lat = lat1),
                   coords = c("lon", "lat"), crs = 4326)
  bod2 <- st_as_sf(data.frame(lon = lon2, lat = lat2),
                   coords = c("lon", "lat"), crs = 4326)
  # Transformace souřadnic do UTM33N (EPSG:32633)
  bod1_utm <- st_transform(bod1, 32633)
  bod2_utm <- st_transform(bod2, 32633)
  # Výpočet vzdálenosti v metrech a převedení na kilometry
  vzdalenost_m <- st_distance(bod1_utm, bod2_utm)
  vzdalenost_km <- as.numeric(vzdalenost_m) / 1000
  return(vzdalenost_km)
}

# Funkce pro filtrování stanic na základě vzdálenosti od zadaného bodu
filtrovat_stanice_dle_vzdalenosti <- function(stanice_df, lat, lon, max_vzdalenost_km) {
  # Výpočet vzdálenosti pro každou stanici
  stanice_df <- stanice_df %>%
    rowwise() %>%
    mutate(vzdalenost_km = vypocet_vzdalenosti_utm33n(lat, lon, as.numeric(GEOGR2),
                                                      as.numeric(GEOGR1))) %>%
    ungroup() %>%
    # Filtrování podle vzdálenosti
    filter(vzdalenost_km <= max_vzdalenost_km)
  return(stanice_df)
}
## ---------konec definice funkcí ---------------------------------------------



# Zadání souřadnic, roku zájmu, ELEMENT, VTYPE, maximální vzdálenosti a konkrétního datumu
lat <- 49.4813356   # Zeměpisná šířka
lon <- 15.7174678   # Zeměpisná délka
element <- "T"      # Parametr ELEMENT, např. "T" (teplota)
max_vzdalenost_km <- 20  # Maximální vzdálenost v kilometrech


# Získání seznamu stanic, které mají dostupná data pro daný rok a proměnnou
stanice_s_promennou <- ziskat_stanice_s_dostupnou_promennou(element)


# Připojení informací z meta1 s filtrováním na základě roku a dostupných souřadnic
stanice_s_informacemi <- pripojit_meta1(stanice_s_promennou)
stanice_s_informacemi <- stanice_s_informacemi[!is.na(stanice_s_informacemi$GEOGR1) &
                                                 !is.na(stanice_s_informacemi$GEOGR2), ]

# Filtrování stanic na základě vzdálenosti od zadaného bodu
stanice_s_informacemi <- filtrovat_stanice_dle_vzdalenosti(stanice_s_informacemi,
                                                           lat, lon, max_vzdalenost_km)


## recent
datum     <- format(Sys.time()-(24*60*60), "%Y%m%d") # vcera
WSI       <- "0-203-0-41601049001"    
filename  <- paste0("data-chmi-",datum,".jsom")   
csvename  <- paste0("data-chmi-",datum,".csv")  

data_url <- 
  paste0("https://opendata.chmi.cz/meteorology/climate/recent/data/10min/10m-", WSI,"-",datum,".json")
# Stáhnout soubor pomocí curl
download_command <- paste("curl -w '%{http_code}' -o", shQuote(filename), data_url)
status_code <- system(download_command, intern = TRUE)
# Pokus o načtení JSON dat pomocí jsonlite s chybovým ošetřením
data <-fromJSON(filename, simplifyVector = TRUE)  # Načítání JSON souboru pomocí jsonlite
# Pokus o převod dat na datový rámec
data_filtered <-as.data.frame(data$data$data$values)

# Přiřazení názvů sloupců
colnames(data_filtered) <- unlist(strsplit(data$data$data$header, ","))
# Filtrování podle ELEMENT a VTYPE
data_filtered <- data_filtered %>%
  filter(ELEMENT == element)
# Převod DT na datum a filtrování pro celý rok 2022
data_filtered$DT <- as_datetime(data_filtered$DT)
 
write.table(data_filtered,csvename,sep = ";",col.names = T,row.names = F)


## old --------------------------------------------------------------------------------------
datum     <- "historical" 
WSI       <- "0-203-0-41601049001"    
filename  <- paste0("data-chmi-",datum,".jsom")   
csvename  <- paste0("data-chmi-",datum,".csv")  

data_url <- "https://opendata.chmi.cz/meteorology/climate/historical/data/daily/dly-0-203-0-41601049001.json"
# Stáhnout soubor pomocí curl
download_command <- paste("curl -w '%{http_code}' -o", shQuote(filename), data_url)
status_code <- system(download_command, intern = TRUE)
# Pokus o načtení JSON dat pomocí jsonlite s chybovým ošetřením
data <-fromJSON(filename, simplifyVector = TRUE)  # Načítání JSON souboru pomocí jsonlite
# Pokus o převod dat na datový rámec
data_filtered <-as.data.frame(data$data$data$values)

# Přiřazení názvů sloupců
colnames(data_filtered) <- unlist(strsplit(data$data$data$header, ","))
# Filtrování podle ELEMENT a VTYPE
data_filtered <- data_filtered %>%
  filter(ELEMENT == element)%>%
  filter(VTYPE == "AVG")
# Převod DT na datum a filtrování pro celý rok 2022
data_filtered$DT <- as_datetime(data_filtered$DT)

write.table(data_filtered,csvename,sep = ";",col.names = T,row.names = F)


## ---- end -----  old ---------------------------------------------------


# Kombinace datasetů do jednoho s přidaným sloupcem 'locality'
combined_data <- rbind(
  data.frame(Date = as.Date(data_filtered$DT), 
             Temp = data_filtered$VAL, 
             Locality = "CHMI"),
  data.frame(Date = as.Date(tabulka$datetime), 
             Temp = tabulka$`94184134_TMS_T3_mean`, 
             Locality = "Cidlovlese"),
  data.frame(Date = as.Date(tabulka$datetime), 
             Temp = tabulka$`94184134_TMS_T1_mean`, 
             Locality = "Cidlovzemi"))


# Definujte rozsah dat pro výběr
start_date <- as.Date("2020-11-01")
end_date <- as.Date("2021-04-01")
filtered_data <- combined_data[combined_data$Date >= start_date
                               & combined_data$Date <= end_date,]
filtered_data$Temp<-as.numeric(filtered_data$Temp)

# Vytvoření grafu pro výběr
ggplot(filtered_data, aes(x = Date, y = Temp, color = Locality)) +
  geom_line() +
  scale_color_manual(values = c("#E69F00", "#000000", "#009E73")) +
  labs(
    title = "Průměrná denní teplota ze tří zdrojů",
    x = "Datum",
    y = "Teplota (°C)",
    color = "Lokalita"
  ) +  # Popisek legendy
  theme_minimal()
