##############################################################################
# Codigo para generacion de las bases de datos que usan los Mapas Electorales
# Data Frames generados:
#    secciones: Incluye los poligonos e información geoestadística
#    dfelec: Base de los resultados electorales
##############################################################################

library(dplyr)

#**********************************************
# Descarga datos desde la WEB
#**********************************************

# Descarga archivo de las elecciones 2016 del IEZZ
fUrl <- "http://resultadospreliminares.ieez.org.mx/PREP20152016/20160606_2144_BD_ZACATECAS.zip"
download.file(fUrl, destfile = "elecciones_2016.zip")
unzip("elecciones_2016.zip", files = "ZACATECAS_GOBERNADOR_2016.csv")

# Descarga archivo shapefile de las secciones electorales de INEGI
fUrl <- "http://cartografia.ife.org.mx//descargas/distritacion2017/federal/32/32.zip"
download.file(fUrl, destfile = "estado_32.zip")
unzip("estado_32.zip")

# Descarga archivo de las localidades de INEGI
fUrl <- "http://cartografia.ife.org.mx/tmp/zips/CLS-32.zip"
download.file(fUrl, destfile = "localidad_32.zip")
unzip("localidad_32.zip", files = "Catalogo de Localidades Con Seccion.txt")

#********************************************
# Construye data frame de los resultados de las elecciones para Gobernador
#********************************************
# Funciones que usa tapply
primero <- function(x) { as.numeric(x[1]) }
sumnum <- function(x){ sum(x, na.rm=TRUE)}
sumchr <- function(x) { sum(suppressWarnings(as.numeric(x)), na.rm=TRUE) }
# Lee archivo CSV de las elecciones
tb2016 <- read.table(file="ZACATECAS_GOBERNADOR_2016.csv", header=TRUE, sep=",", 
                     skip=5, stringsAsFactors = FALSE)
# Elimina registro MESA DE ESCRUTINIO Y COMPUTO VOTO EXTRANJERO
tb2016 <- tb2016[!is.na(suppressWarnings(as.numeric(tb2016$SECCION))),]
# Genera data frame cuidando tipo de dato
dfelec <- data.frame(
  id = tapply(tb2016$SECCION, tb2016$SECCION, primero),
  dtoloc = tapply(tb2016$ID_DISTRITO, tb2016$SECCION, primero),
  pan_prd = tapply(tb2016$PAN, tb2016$SECCION, sumchr) +
    tapply(tb2016$PRD, tb2016$SECCION, sumchr) +
    tapply(tb2016$PANPRD, tb2016$SECCION, sumchr),
  pri_pvem_panal = tapply(tb2016$PRI, tb2016$SECCION, sumchr) +
    tapply(tb2016$PVEM, tb2016$SECCION, sumchr) +
    tapply(tb2016$NA., tb2016$SECCION, sumchr) +
    tapply(tb2016$PRIPVNA, tb2016$SECCION, sumchr) +
    tapply(tb2016$PRIPV, tb2016$SECCION, sumchr) +
    tapply(tb2016$PRINA, tb2016$SECCION, sumchr) +
    tapply(tb2016$PVNA, tb2016$SECCION, sumchr),
  pt = tapply(tb2016$PT, tb2016$SECCION, sumchr),
  pes = tapply(tb2016$SOCIAL, tb2016$SECCION, sumchr),
  morena = tapply(tb2016$MORENA, tb2016$SECCION, sumchr),
  candi = tapply(tb2016$CAND_IND_1, tb2016$SECCION, sumchr) +
    tapply(tb2016$CAND_IND_2, tb2016$SECCION, sumchr),
  nreg = tapply(tb2016$NO_REGISTRADOS, tb2016$SECCION, sumchr),
  nulos = tapply(tb2016$NULOS, tb2016$SECCION, sumchr),
  tvotos = tapply(tb2016$TOTAL_VOTOS, tb2016$SECCION, sum),
  ln = tapply(tb2016$LISTA_NOMINAL, tb2016$SECCION, sumchr))
dfelec <- as.data.frame(as.matrix(dfelec))
# Agrega partido ganador
dfelec$partido = factor(x = apply(dfelec[,3:8], 1, which.max), levels = 1:6, 
            labels = c("PAN-PRD", "PRI-PVEM-PANAL", "PT", "PES", "MORENA", "C.IND."))
#++++++++++++++++++++++++
# Lee localidad de archivo
tbloc <- read.table(file="Catalogo de Localidades Con Seccion.txt", 
                    header=TRUE, sep="|", stringsAsFactors = FALSE,
                    fileEncoding = "WINDOWS-1252")
dbine <- data.frame(
  id = as.numeric(tapply(tbloc$SECCION, tbloc$SECCION, primero)),
  loc = as.character(tapply(tbloc$NOMBRE.LOCALIDAD, tbloc$SECCION, function(x){x[1]})),
stringsAsFactors = FALSE)
dfelec <- merge(dfelec, select(dbine, id, loc), by = "id")
# Distrito locales de acuerdo al documento:
# http://cartografia.ife.org.mx//descargas/distritacion2017/local/32/D32.pdf
# Algunas secciones no instalaron casillas, por eso necesitamos la configuracion
# de las 1868 secciones para la base del mapa
dbine$dtoloc <- 0
dbine$dtoloc[dbine$id %in% c(1791:1794, 1796, 1806, 1815:1870)] <- 1
dbine$dtoloc[dbine$id %in% c(40:60, 945:953, 1772:1790, 1795, 1797:1805,
                              1807:1814, 1871:1882)] <- 2
dbine$dtoloc[dbine$id %in% c(460:462, 471:510, 534:545, 551, 1904,
                              1907:1909)] <- 3
dbine$dtoloc[dbine$id %in% c(463:470, 511:515, 517:524, 546:547, 549,
                              1883:1903, 1905:1906, 1601:1608)] <- 4
dbine$dtoloc[dbine$id %in% c(137:147, 153:155, 157, 218:232, 242:252,
                              261:262, 265:266, 268:278, 300:306, 
                              330:332, 336, 338:340, 344 )] <- 5
dbine$dtoloc[dbine$id %in% c(149:152, 156, 158:162, 164:211, 213:217,
                              297:299, 307:308, 316:318, 345:346,
                              378:384)] <- 6
dbine$dtoloc[dbine$id %in% c(135:136, 148, 163, 212, 233:241, 253:260,
                              263:264, 267, 279:296, 309:315, 319:329,
                              333:335, 337, 341, 343, 347:348, 1525:1564,
                              1566:1594, 1596:1600)] <- 7
dbine$dtoloc[dbine$id %in% c(436:459, 1036:1039, 1041, 1045:1046, 1050:1058,
                              1060:1064, 1068:1070, 1075:1076, 1079,
                              1675:1686, 516, 525:533, 548)] <- 8
dbine$dtoloc[dbine$id %in% c(763:793, 1020:1035, 1659:1674)] <- 9
dbine$dtoloc[dbine$id %in% c(606:699, 701, 703:707, 914:919, 921:929, 
                              931:936, 938, 940:941, 943, 1384:1387,
                              1433:1440, 1442:1464)] <- 10
dbine$dtoloc[dbine$id %in% c(103:113, 359:377, 794:807, 1040, 1042:1044,
                              1047:1049, 1059, 1065:1067, 1071:1074,
                              1077:1078, 1711:1753, 1755:1766, 1769:1770)] <- 11
dbine$dtoloc[dbine$id %in% c(73:80, 82:99, 101:102, 808:824, 826:839,
                              841:847, 849:851, 853:856, 858:867, 868:871,
                              873:875, 1080:1093, 1283:1288, 1609:1650,
                              1652:1658)] <- 12
dbine$dtoloc[dbine$id %in% c(14:21, 428:435, 552:605, 965:984, 986:990,
                              992:1008, 1010:1016, 1018:1019, 1388:1411)] <- 13
dbine$dtoloc[dbine$id %in% c(1:13, 22:39, 349:354, 356, 358, 742:758,
                              760:762, 876:881, 883, 906:913, 954:964,
                              1412:1432, 1465:1468, 1475:1476, 1478:1481,
                              1484, 1485:1524, 1469:1474, 1482:1483)] <- 14
dbine$dtoloc[dbine$id %in% c(1094:1167, 1169:1191, 1687:1710)] <- 15
dbine$dtoloc[dbine$id %in% c(61:71, 1195:1198, 1203:1205, 1207:1224, 
                              1227:1232, 1235:1253, 1255, 1256:1282)] <- 16
dbine$dtoloc[dbine$id %in% c(114:134, 708:717, 1289:1383)] <- 17
dbine$dtoloc[dbine$id %in% c(386:427, 718:740, 884:904, 1192:1194,
                              1199:1202, 1206, 1225:1226, 1233:1234)] <- 18

#******************************************************************
# Construye data frame para las secciones electorales de los mapas
#******************************************************************
library(rgdal)     # readOGR, psTransform
library(broom)     # tidy

# Lee shapefile de las secciones electorales
seccs_utm <- rgdal::readOGR("32", layer = "SECCION", stringsAsFactors = FALSE)
# Transforma coordenadas a longitud y latitud
seccs_ll <- spTransform(seccs_utm, CRS("+proj=longlat +datum=WGS84"))
secciones <- tidy(seccs_ll, region = "seccion")
secciones$id <- as.numeric(secciones$id)
# Agrega ids geograficos a data frame
seccs_data <- data.frame(dtofed = as.numeric(seccs_ll@data$distrito),
                         muni = as.numeric(seccs_ll@data$municipio),
                         id = as.numeric(seccs_ll@data$seccion))
secciones$id_dtofed <- 0
secciones$id_muni <- 0
secciones$id_dtoloc <- 0
secciones$id_loc <- ""
secciones$partido <- 7
dfelec$long <- 0  
dfelec$lat <- 0
for (sc in seccs_data$id) {
  fsecc1 <- secciones$id == sc
  fsecc2 <- seccs_data$id == sc
  fsecc3 <- dbine$id == sc
  fsecc4 <- dfelec$id == sc
  secciones$id_dtofed[fsecc1] <- seccs_data$dtofed[fsecc2]
  secciones$id_muni[fsecc1] <- seccs_data$muni[fsecc2]
  secciones$id_dtoloc[fsecc1] <- dbine$dtoloc[fsecc3]
  secciones$id_loc[fsecc1] <- dbine$loc[fsecc3]
  if (sum(fsecc4) > 0) {
      secciones$partido[fsecc1] <- as.numeric(dfelec$partido[fsecc4])
      dfelec$long[fsecc4] <- mean(secciones$long[fsecc1])
      dfelec$lat[fsecc4] <- mean(secciones$lat[fsecc1])
  }
}
secciones$partido <- factor(secciones$partido, levels = 1:7,
      labels = c("PAN-PRD", "PRI-PVEM-PANAL", "PT", "PES", "MORENA", "C.IND", "NR"))

# Agrega distrito federal y municipio
dfelec <- merge(dfelec, data.frame(id = seccs_data$id, dtofed = seccs_data$dtofed, 
                                   muni = seccs_data$muni), by = "id")

#****************************************
# Guarda data frames en un archivo
#****************************************
save(secciones, file = "secciones.RData")
save(dfelec, file = "dfelec.RData")
