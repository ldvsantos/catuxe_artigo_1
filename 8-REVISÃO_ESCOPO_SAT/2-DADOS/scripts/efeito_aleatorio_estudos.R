# 0. Carregar pacotes
library(readxl)
library(dplyr)
library(meta)
library(tibble)

Pasta1 <- read_excel("C:/Users/vidal/Downloads/Pasta1.xlsx")
View(Pasta1)



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
funnel(meta_final, studlab = TRUE)

# 4.2 Testes de viés
metabias(meta_final, method.bias = "Egger")
metabias(meta_final, method.bias = "Begg")

# 4.3 Trim-and-fill (preenchimento de estudos ausentes)
meta_tf <- trimfill(meta_geral)
funnel(meta_tf, studlab = TRUE)

# 5. ANÁLISE DE SENSIBILIDADE
# 5.1 Baujat plot
baujat(meta_final)

# 5.2 Leave-one-out (exclui estudo específico)
meta_leaveoneout <- update(meta_geral, subset = (Study != "Conraads"))
print(summary(meta_leaveoneout))








