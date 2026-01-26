# 0. Carregar pacotes
library(readxl)
library(dplyr)
library(meta)
library(tibble)

get_script_dir <- function() {
  args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", args, value = TRUE)
  if (length(file_arg) > 0) {
    return(dirname(normalizePath(sub("^--file=", "", file_arg[1]), winslash = "/")))
  }
  if (!is.null(sys.frames()[[1]]$ofile)) {
    return(dirname(normalizePath(sys.frames()[[1]]$ofile, winslash = "/")))
  }
  getwd()
}

script_dir <- get_script_dir()
projeto_root <- normalizePath(file.path(script_dir, "..", ".."), winslash = "/", mustWork = FALSE)

pasta1_xlsx <- Sys.getenv("PASTA1_XLSX", unset = file.path(projeto_root, "2-DADOS", "Pasta1.xlsx"))
if (!file.exists(pasta1_xlsx)) {
  stop(paste0(
    "Arquivo Pasta1.xlsx não encontrado em ", pasta1_xlsx, ". ",
    "Coloque o arquivo em 8-REVISÃO_ESCOPO_SAT/2-DADOS/Pasta1.xlsx ou defina PASTA1_XLSX."
  ))
}

Pasta1 <- read_excel(pasta1_xlsx)



# 1. CARREGAR DADOS
dados <- Pasta1 %>%
  rename(
    Study    = Study,
    n_e      = n_e,
    m_e      = m_e,
    sd_e     = sd_e,
    n_c      = n_c,
    m_c      = m_c,
    sd_c     = sd_c,
    Variavel = Variavel
  ) %>%
  mutate(Variavel = factor(Variavel),
         across(c(n_e, m_e, sd_e, n_c, m_c, sd_c), as.numeric))

# 2. META-ANÁLISE GERAL (todos os estudos juntos)
meta_geral <- metacont(
  n.e = n_e,
  mean.e = m_e,
  sd.e = sd_e,
  n.c = n_c,
  mean.c = m_c,
  sd.c = sd_c,
  studlab = Study,
  sm = "SMD",
  method.smd = "Hedges",
  method.tau = "PM",
  common = FALSE,
  data = dados
)

# 2.1 Forest plot geral

forest(
  meta_geral,
  comb.fixed = FALSE,
  comb.random = TRUE,
  overall = TRUE,
  xlab = "Hedges d (efeito geral)",
  col.square = "red",
  col.diamond = "darkgreen",
  digits.sd = 2
)



# 4. ANÁLISES DE VIÉS DE PUBLICAÇÃO (baseado na meta geral)

# 4.1 Funnel plot
funnel(meta_geral, studlab = TRUE)

# 4.2 Testes de viés
metabias(meta_geral, method.bias = "Egger")
metabias(meta_geral, method.bias = "Begg")

# 4.3 Trim-and-fill (preenchimento de estudos ausentes)
meta_tf <- trimfill(meta_geral)
funnel(meta_tf, studlab = TRUE)

# 5. ANÁLISE DE SENSIBILIDADE
# 5.1 Baujat plot
baujat(meta_geral)

# 5.2 Leave-one-out (exclui estudo específico)
meta_leaveoneout <- update(meta_geral, subset = (Study != "Conraads"))
print(summary(meta_leaveoneout))








