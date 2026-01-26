
# ================================
# Meta-análise com Imputação Múltipla e Forestplot por Grupo Funcional
# ================================

# 0. Carregar pacotes
library(readxl)
library(dplyr)
library(mice)
library(meta)
library(tibble)
library(future.apply)
library(purrr)
library(kableExtra)
library(ggplot2)
library(forcats)

rm(list = ls()); gc()

# 1. Ler base de dados
dados <- read_excel("C:/Users/vidal/OneDrive/Documentos/ARTIGO_MA/3 - DADOS/bd.xlsx", sheet = "MANEJO") %>%
  mutate(across(c(m_e, sd_e, n_e, m_c, sd_c, n_c), ~ as.numeric(gsub(",", ".", gsub("[^0-9,.-]", "", as.character(.))))),
         Variavel = factor(Variavel))

# 2. Imputação múltipla via CART
dados_imput <- mice(dados, m = 5, method = "cart", seed = 10)

# 3. Calcular lnRR e variância
dados_completos <- complete(dados_imput, action = "long", include = TRUE) %>%
  filter(m_e > 0, m_c > 0) %>%
  mutate(
    lnRR = log(m_e / m_c),
    vi = (sd_e^2 / (n_e * m_e^2)) + (sd_c^2 / (n_c * m_c^2))
  ) %>%
  filter(!is.na(vi), !is.infinite(vi), vi > 0, vi < quantile(vi, 0.999, na.rm = TRUE))

# 4. Meta-análises por imputação
resultados_rubin <- future_lapply(1:5, function(i) {
  dados_i <- complete(dados_imput, i)
  if (!"Variavel" %in% names(dados_i)) return(NULL)
  var_levels <- unique(dados_i$Variavel)
  
  map_dfr(var_levels, function(v) {
    df <- filter(dados_i, Variavel == v)
    if (nrow(df) == 0) return(NULL)
    
    meta <- tryCatch(
      metacont(
        n.e = n_e, mean.e = m_e, sd.e = sd_e,
        n.c = n_c, mean.c = m_c, sd.c = sd_c,
        studlab = Study, sm = "ROM", log = TRUE,
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
}) %>% bind_rows()

# 5. Contagem de estudos
n_estudos_obs <- dados_completos %>%
  group_by(Variavel) %>%
  summarise(N_estudos = n_distinct(Study), N_obs = n(), .groups = "drop")

# 6. Combinação por Rubin
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
    p_value = ifelse(is.infinite(df), 2 * pnorm(-abs(TE / seTE)), 2 * pt(-abs(TE / seTE), df)),
    .groups = "drop"
  ) %>%
  left_join(n_estudos_obs, by = "Variavel")

# 7. Classificação das variáveis por grupo funcional
mapa_grupos <- tibble(
  Variavel_original = unique(as.character(resumo_vars$Variavel))
) %>%
  mutate(
    Variavel_padrao = toupper(gsub("[^A-Za-z]", "", Variavel_original)),
    Grupo_temp = case_when(
      # Químico
      Variavel_padrao %in% c("SOILORGANICCARBONSOC", "SOC") ~ "Químico",
      Variavel_padrao %in% c("SOILPH", "PH") ~ "Químico",
      Variavel_padrao %in% c("TOTALNITROGENTN", "TN") ~ "Químico",
      Variavel_padrao %in% c("AVAILABLETOTALPHOSPHORUSATP", "ATP") ~ "Químico",
      Variavel_padrao %in% c("AVAILABLEPOTASSIUMAK", "AK") ~ "Químico",
      Variavel_padrao %in% c("AVAILABLEMAGNESIUMAMG", "AMG") ~ "Químico",
      # Físico
      Variavel_padrao %in% c("SOILBULKDENSITYPB", "SOILBULKDENSITY", "BULKDENSITY", "PB") ~ "Físico",
      Variavel_padrao %in% c("PLANTAVAILABLEWATERCAPACITYPAWC", "PAWC") ~ "Físico",
      Variavel_padrao %in% c("MACROPOROSITYEMACRO", "MACROPOROSITYMACRO", "EMACRO") ~ "Físico",
      Variavel_padrao %in% c("PENETRATIONRESISTANCEPR", "PR") ~ "Físico",
      Variavel_padrao %in% c("WATERSTABLEAGGREGATESWSA", "WSA") ~ "Físico",
      Variavel_padrao %in% c("RUNOFFQ", "Q") ~ "Físico",
      Variavel_padrao %in% c("EROSIONRATEER", "ER", "EROSIONRATE") ~ "Físico",
      # Biológico
      Variavel_padrao %in% c("MICROBIALBIOMASSCARBONMBC", "MBC") ~ "Biológico",
      Variavel_padrao %in% c("BASALRESPIRATIONBR", "BR") ~ "Biológico",
      Variavel_padrao %in% c("MICROBIALQUOTIENTQMIC", "QMIC") ~ "Biológico",
      Variavel_padrao %in% c("QCO2", "QCO") ~ "Biológico",  # <- ajuste aqui
      # Outros
      TRUE ~ "Outros"
    )
  )

# 8. Unir ao resumo, padronizar e gerar rótulos únicos
resumo_vars <- resumo_vars %>%
  mutate(
    Variavel = trimws(gsub("\t", " ", as.character(Variavel))),
    Variavel_padrao = toupper(gsub("[^A-Za-z]", "", Variavel))
  ) %>%
  left_join(mapa_grupos %>% select(Variavel_padrao, Grupo = Grupo_temp), by = "Variavel_padrao") %>%
  mutate(
    Grupo = factor(Grupo, levels = c("Físico", "Químico", "Biológico", "Outros")),
    Variavel_ord = fct_inorder(Variavel)
  ) %>%
  group_by(Variavel_ord) %>%
  mutate(
    studlab = paste0(Variavel_ord, " (n = ", N_estudos, ", obs = ", N_obs, ")"),
    studlab = ifelse(n() > 1, paste0(studlab, " [", row_number(), "]"), studlab)
  ) %>%
  ungroup()

# 9. Criar metagen com rótulos únicos
meta_final <- metagen(
  TE = resumo_vars$TE,
  seTE = resumo_vars$seTE,
  studlab = resumo_vars$studlab,
  sm = "LogROM (lnRR)",
  method.tau = "DL",
  common = FALSE,
  random = TRUE
)

# Criar vetor de cores com base nos grupos
cores_por_grupo <- c("Físico" = "#0072B2", "Químico" = "#009E73", "Biológico" = "#D55E00", "Outros" = "#0072B2")
# Vetor de cores para cada variável (ordem igual à de resumo_vars)
cores_variaveis <- cores_por_grupo[as.character(resumo_vars$Grupo)]


# Forestplot com cores por grupo
forest(
  meta_final,
  comb.fixed = FALSE,
  comb.random = TRUE,
  overall = TRUE,
  print.heterogeneity = FALSE,
  print.Q = FALSE,
  print.I2 = FALSE,
  print.tau2 = FALSE,
  col.square = cores_variaveis,
  col.diamond = "black",
  digits = 3,
  digits.TE = 3,
  atransf = exp,
  at = seq(-0.6, 0.6, by = 0.2),
  xlab = "Log Response Ratio (lnRR)",
  rightcols = c("effect", "ci", "w.random", "pval"),
  rightlabs = c("RR", "IC 95%", "Peso (%)", "p-valor"),
  leftcols = c("studlab"),
  leftlabs = c("Indicadores funcionais")
)







# 11. Gráfico com ggplot2
ggplot(resumo_vars, aes(x = TE, y = Variavel_ord, fill = Grupo, shape = Grupo)) +
  geom_point(size = 4, color = "black", stroke = 1.1) +
  geom_errorbarh(aes(xmin = IC_inf, xmax = IC_sup), height = 0.2, color = "gray30") +
  geom_vline(xintercept = 0, linetype = "dashed", color = "gray30") +
  scale_fill_manual(values = c("Físico" = "#0072B2", "Químico" = "#009E73", "Biológico" = "#D55E00", "Outros" = "gray60")) +
  scale_shape_manual(values = c("Físico" = 21, "Químico" = 22, "Biológico" = 24, "Outros" = 23)) +
  labs(
    title = "Forestplot por tipo de indicador funcional",
    x = "Log Response Ratio (lnRR)",
    y = "Indicadores funcionais",
    fill = "Grupo funcional",
    shape = "Grupo funcional"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    legend.position = "top",
    panel.grid.major.y = element_blank(),
    axis.text.y = element_text(size = 10)
  )
