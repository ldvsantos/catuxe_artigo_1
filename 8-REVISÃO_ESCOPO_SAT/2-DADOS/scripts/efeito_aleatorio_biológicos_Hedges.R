# 0. Carregar pacotes
library(readxl)
library(dplyr)
library(mice)
library(meta)
library(tibble)
library(future.apply)
library(purrr)
library(kableExtra)

rm(list = ls()); gc()

# 1. Ler base
dados <- read_excel("C:/Users/vidal/OneDrive/Documentos/ARTIGO_MA/3 - DADOS/bd.xlsx", sheet = "VARIAVEIS_BIOLOGICAS") %>%
  mutate(across(c(m_e, sd_e, n_e, m_c, sd_c, n_c), ~ as.numeric(gsub(",", ".", gsub("[^0-9,.-]", "", as.character(.))))),
         Variavel = factor(Variavel))

# 2. Imputação múltipla via CART
dados_imput <- mice(dados, m = 5, method = "cart", seed = 10)

# 3. Filtrar dados válidos
dados_completos <- complete(dados_imput, action = "long", include = TRUE) %>%
  filter(sd_e > 0, sd_c > 0, !is.na(m_e), !is.na(m_c), !is.na(sd_e), !is.na(sd_c), !is.na(n_e), !is.na(n_c))

# 4. Meta-análises por imputação
resultados_rubin <- future_lapply(1:5, function(i) {
  dados_i <- complete(dados_imput, i)
  if (!"Variavel" %in% names(dados_i)) return(NULL)
  var_levels <- unique(dados_i$Variavel)
  
  map_dfr(var_levels, function(v) {
    df <- dados_i %>% filter(Variavel == v)
    if (nrow(df) == 0) return(NULL)
    
    meta <- tryCatch(
      metacont(
        n.e = n_e, mean.e = m_e, sd.e = sd_e,
        n.c = n_c, mean.c = m_c, sd.c = sd_c,
        studlab = Study, sm = "SMD", method.smd = "Hedges",
        method.tau = "REML", common = FALSE, data = df
      ),
      error = function(e) NULL
    )
    
    if (is.null(meta)) return(NULL)
    
    tibble(
      .imp = i,
      Variavel = v,
      TE = meta$TE.random,
      seTE = meta$seTE.random
    )
  })
}, future.seed = TRUE) %>% bind_rows()

# 5. Contagem de estudos e observações
n_estudos_obs <- dados_completos %>%
  group_by(Variavel) %>%
  summarise(N_estudos = n_distinct(Study), N_obs = n(), .groups = "drop")

# 6. Aplicação das regras de Rubin
resumo_vars <- resultados_rubin %>%
  group_by(Variavel) %>%
  summarise(
    TE = mean(TE, na.rm = TRUE),
    W = mean(seTE^2, na.rm = TRUE),
    B = var(TE, na.rm = TRUE),
    T_var = ifelse(is.na(B), W, W + (1 + 1/5) * B),
    seTE = sqrt(T_var),
    df = ifelse(is.na(B) || B == 0, Inf, (5 - 1) * (1 + W / ((1 + 1/5) * B))^2),
    IC_inf = TE - qt(0.975, df) * seTE,
    IC_sup = TE + qt(0.975, df) * seTE,
    p_value = 2 * pt(-abs(TE / seTE), df),
    .groups = "drop"
  ) %>%
  left_join(n_estudos_obs, by = "Variavel") %>%
  mutate(
    studlab = paste0(Variavel, " (n = ", N_estudos, ", obs = ", N_obs, ")"),
    p_value_fmt = ifelse(is.na(p_value), "NA", sprintf("%.3f", p_value))
  )

# 7. Meta-análise agregada
meta_final <- metagen(
  TE = resumo_vars$TE,
  seTE = resumo_vars$seTE,
  studlab = resumo_vars$studlab,
  sm = "SMD (Hedges)",
  method.tau = "DL",
  common = FALSE,
  random = TRUE
)

# 8. Plotar forest
forest(
  meta_final,
  comb.fixed = FALSE,
  comb.random = TRUE,
  overall = TRUE,
  print.heterogeneity = FALSE,
  print.Q = FALSE,
  print.I2 = FALSE,
  print.tau2 = FALSE,
  col.square = "blue",
  col.diamond = "darkgreen",
  digits = 3,
  digits.TE = 3,
  at = seq(-2, 2, by = 0.5),
  xlab = "D de Cohen (SMD)",
  rightcols = c("effect", "ci", "w.random", "pval"),
  rightlabs = c("D", "IC 95%", "Peso (%)", "p-valor"),
  leftcols = c("studlab"),
  leftlabs = c("Variáveis biológicas (n, obs)")
)

# 9. Tabela resumo
resumo_global <- tibble(
  `Indicadores funcionais (n, obs)` = "Modelo Global",
  `D de Cohen` = round(meta_final$TE.random, 3) %>% as.character(),
  `IC 95%` = paste0("[", round(meta_final$lower.random, 3), "; ", round(meta_final$upper.random, 3), "]"),
  `Peso (%)` = "",
  `p-valor` = sprintf("%.3f", meta_final$pval.random)
)

tabela_variaveis <- tibble(
  `Indicadores funcionais (n, obs)` = meta_final$studlab,
  `D de Cohen` = round(meta_final$TE, 3) %>% as.character(),
  `IC 95%` = paste0("[", round(meta_final$lower, 3), "; ", round(meta_final$upper, 3), "]"),
  `Peso (%)` = round(100 * meta_final$w.random / sum(meta_final$w.random), 1) %>% as.character(),
  `p-valor` = sprintf("%.3f", meta_final$pval)
)

tabela_final <- bind_rows(resumo_global, tabela_variaveis)

# 10. Legenda estatística
caption_smd <- paste0(
  "Resumo da Meta-Análise com Modelo de Efeito Aleatório\n",
  "Q(", meta_final$k - 1, ") = ", round(meta_final$Q, 2), ", ",
  "p(Q) = ", sprintf("%.3f", meta_final$pval.Q), ", ",
  "Tau² = ", round(meta_final$tau2, 3), ", ",
  "I² = ", round(meta_final$I2, 1), "%"
)

nota_explicativa <- "Nota: (n) refere-se ao número de estudos independentes incluídos para cada indicador funcional do solo, enquanto (obs) representa o número total de observações, considerando combinações específicas entre estudos e variáveis."

# 11. Tabela formatada
kable(
  tabela_final,
  align = c("l", "r", "c", "r", "r"),
  caption = caption_smd,
  col.names = c("Indicadores funcionais (n, obs)", "D de Cohen", "IC 95%", "Peso (%)", "p-valor")
) %>%
  kable_styling(bootstrap_options = "striped", full_width = FALSE) %>%
  add_footnote(nota_explicativa, notation = "none")

# 12. Funnel plot
funnel(
  meta_final,
  main = "Funnel plot - Indicadores Biológicos",
  xlab = "D de Cohen (SMD)",
  ylab = "Erro padrão",
  pch = 19,
  col = "blue",
  contour = TRUE,
  contour.levels = c(0.90, 0.95, 0.99),
  col.contour = c("gray90", "gray80", "gray70"),
  legend = TRUE,
  back = TRUE
)
