### Klassegrenser
# Funksjon til NI_vannf
# ved Hanno Sandvik
# desember 2023
# se https://github.com/NINAnor/NI_vannf
###



hentKlassegrenser <- function(filKlasser) {
  
  filOK <- TRUE
  KlasseGrenser <- NULL
  if (file.exists(filKlasser)) {
    klassegrenser <- try(as.data.frame(read_xlsx(filKlasser, col_types =
                                                   c("text", rep("numeric", 8)))))
    if (inherits(klassegrenser, "try-error")) {
      filOK <- FALSE
      skriv("Fila \"", filKlasser, "\" kunne ikke leses inn. Det skal være ",
            "et excel-regneark med ni kolonner, hvorav den første inneholder ",
            "tekst og de resterende åtte inneholder tall. ",
            "Feilen må rettes opp før analysen." , 
            pre = "FEIL: ", linjer.over = 1, linjer.under = 1)
    } else {
      if (is.numeric(unlist(klassegrenser[, 2:8]))) {
        #if (all(klassegrenser[, 3:8] >= klassegrenser[, 2:7]) %=% FALSE &
        #    all(klassegrenser[, 3:8] <= klassegrenser[, 2:7]) %=% FALSE) {
        if (!any(!(klassegrenser[, 3:8] >= klassegrenser[, 2:7])) |
            !any(!(klassegrenser[, 3:8] <= klassegrenser[, 2:7]))) {
          if (all(klassegrenser[, 1] %in% c("L", "R", "C")) &
              klassegrenser[, 1] %=% unique(klassegrenser[, 1])) {
            KlasseGrenser <- as.matrix(klassegrenser[, 2:9])
            rownames(KlasseGrenser) <- klassegrenser[, 1]
          } else {
            "%&%" <- function(a,b) rep(a, each=length(b)) %+% rep(b, length(a))
            L <- "L" %&% 
              c("E", "F", "M", "N", "S", "W") %&%   # region
              c("L", "M", "H") %&%                  # sone
              1:4 %&%                               # størrelse
              1:8 %&%                               # alkalitet
              0:4 %&%                               # humusinnhold
              1:3 %&%                               # turbiditet
              1:3                                   # dyp
            R <- "R" %&% 
              c("E", "F", "M", "N", "S", "W") %&%   # region
              c("L", "M", "H") %&%                  # sone
              1:8 %&%                               # størrelse
              1:8 %&%                               # alkalitet
              0:4 %&%                               # humusinnhold
              1:3                                   # turbiditet
            C <- "C" %&% 
              c("B", "G", "H", "M", "N", "S") %&%   # region
              1:8 %&%                               # kysttype
              1:7 %&%                               # salinitet
              1:2 %&%                               # tidevann
              1:3 %&%                               # eksponering
              1:3 %&%                               # miksing
              1:3 %&%                               # oppholdstid
              1:3                                   # strøm
            KlasseGrenser <- matrix(NA, length(L) + length(R) + length(C), 8)
            colnames(KlasseGrenser) <- 
              c("min", "SD_nedre", "SD_D", "D_M", "M_G", "G_SG", "SG_øvre", "max")
            rownames(KlasseGrenser) <- c(L, R, C)
            for (k in 1:nrow(klassegrenser)) {
              kl <- toupper(klassegrenser[k, 1])
              hvilke <- NA
              if (kl %in% rownames(KlasseGrenser)) {
                hvilke <- kl
              } else {
                source("R/gamletyp.R")
                if (kl %in% toupper(names(gamleTyper))) {
                  names(gamleTyper) <- toupper(names(gamleTyper))
                  hvilke <- gamleTyper[[kl]]
                } else {
                  bokst <- unlist(strsplit(kl, ""))
                  if (bokst[1] %=% "L") {
                    hvilke <- "L"
                    for (b in 2:8) {
                      if (is.na(bokst[b])) {
                        hvilke <- hvilke %&% Vanntyper[[b]]
                      } else {
                        if (bokst[b] %=% ".") {
                          hvilke <- hvilke %&% Vanntyper[[b]]
                        } else {
                          hvilke <- hvilke %+% bokst[b]
                        }
                      }
                    }
                  } else {
                    if (bokst[1] %=% "R") {
                      hvilke <- "R"
                      for (b in 2:7) {
                        if (is.na(bokst[b])) {
                          hvilke <- hvilke %&% Vanntyper[[b]]
                        } else {
                          if (bokst[b] %=% ".") {
                            hvilke <- hvilke %&% Vanntyper[[b]]
                          } else {
                            hvilke <- hvilke %+% bokst[b]
                          }
                        }
                      }
                    } else {
                      if (bokst[1] %=% "C") {
                        hvilke <- "C"
                        for (b in 2:9) {
                          if (is.na(bokst[b])) {
                            hvilke <- hvilke %&% Vanntyper[[c(1:2, 9:15)[b]]]
                          } else {
                            if (bokst[b] %=% ".") {
                              hvilke <- hvilke %&% Vanntyper[[c(1:2, 9:15)[b]]]
                            } else {
                              hvilke <- hvilke %+% bokst[b]
                            }
                          }
                        }
                      } else {
                        filOK  <- FALSE
                        hvilke <- NA
                      }
                    }
                  }
                }
              }
              if (filOK) {
                for (h in hvilke) {
                  if (h %in% rownames(KlasseGrenser)) {
                    KlasseGrenser[h, ] <- unlist(klassegrenser[k, 2:9])
                  }
                }
              }
            }
          }
        } else {
          filOK <- FALSE
          skriv("Det ble oppdaga en numerisk feil i klassegrensene. ",
                "(Klassegrensene var ikke monotont økende eller synkende.) ",
                "Feilen må rettes opp før analysen." , 
                pre = "FEIL: ", linjer.over = 1, linjer.under = 1)
        }
        if (!filOK) {
          skriv("Vanntypene i klassegrensefila kunne ikke tolkes. ",
                "Feilen må rettes opp før analysen." , 
                pre = "FEIL: ", linjer.over = 1, linjer.under = 1)
        }
      } else {
        filOK <- FALSE
        skriv("Klassegrensene var ikke numeriske. ",
              "Feilen må rettes opp før analysen." , 
              pre = "FEIL: ", linjer.over = 1, linjer.under = 1)
      }
    }
  } else {
    filOK <- FALSE
    skriv("Analysen forutsetter et excel-regneark ved navn \"", filKlasser, 
          "\", som inneholder klassegrenser for parameteren. Fila ble ikke funnet,",
          " og analysen må derfor avbrytes.", 
          pre = "FEIL: ", linjer.over = 1, linjer.under = 1)
  }
  if (filOK) {
    return(KlasseGrenser)
  } else {
    return(NULL)
  }
}


