
# 0. Carregar pacotes
# Lista de pacotes necessários
pacotes_necessarios <- c(
  "readxl", "dplyr", "meta", "mice", "purrr",
  "forcats", "clubSandwich", "metafor", "knitr", "stringr", "future.apply", "kableExtra", "knitr"

)

# Instalar apenas os que ainda não estão instalados
instalar <- pacotes_necessarios[!(pacotes_necessarios %in% installed.packages()[, "Package"])]

if (length(instalar) > 0) {
  install.packages(instalar, dependencies = TRUE)
}

# Carregar todos os pacotes
lapply(pacotes_necessarios, library, character.only = TRUE)

# Ativar paralelização
plan(multisession)


#================#



rm(list = ls()); gc()

# Raiz do projeto e caminho de dados (ajustável)
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

bd_xlsx <- Sys.getenv("BD_XLSX", unset = file.path(projeto_root, "2-DADOS", "bd.xlsx"))
if (!file.exists(bd_xlsx)) {
  stop(paste0(
    "Arquivo bd.xlsx não encontrado em ", bd_xlsx, ". ",
    "Coloque o arquivo em 8-REVISÃO_ESCOPO_SAT/2-DADOS/bd.xlsx ou defina BD_XLSX."
  ))
}


# 1. Carregar e preparar os dados
  dados <- read_excel(bd_xlsx, sheet = "VARIAVEIS_QUIMICAS") %>%
    mutate(
      across(c(m_e, sd_e, n_e, m_c, sd_c, n_c), ~as.numeric(str_replace_all(., ",", "."))),
      Variavel = factor(Variavel)
          )
  
# 2. Imputação múltipla
  dados_imput <- mice::mice(dados, m = 5, method = "cart", seed = 10)

# 2.1 Cálculo de lnRR e variância
 
 dados_completos <- mice::complete(dados_imput, action = "long", include = TRUE) %>%
   filter(m_e > 0, m_c > 0) %>%
   mutate(
     lnRR = log(m_e / m_c),
     vi = (sd_e^2 / (n_e * m_e^2)) + (sd_c^2 / (n_c * m_c^2))
   ) %>%
   filter(
     !is.na(vi), 
     !is.infinite(vi), 
     vi > 0,
     vi < quantile(vi, 0.999, na.rm = TRUE)
   )
 
 # 2. Meta-análises por imputação
 resultados_rubin <- future.apply::future_lapply(1:5, function(i) {
   dados_i <- mice::complete(dados_imput, i)
   if (!"Variavel" %in% names(dados_i)) return(NULL)
   var_levels <- unique(dados_i$Variavel)
   
   map_dfr(var_levels, function(v) {
     df <- dados_i %>% filter(Variavel == v)
     if (nrow(df) == 0) return(NULL)
     
     meta <- tryCatch(
       meta::metacont(
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
 }, future.seed = TRUE) %>% dplyr::bind_rows()
 
 # 3. Obter n (estudos) e obs (linhas) por variável
 n_estudos_obs <- dados_completos %>%
   group_by(Variavel) %>%
   summarise(
     N_estudos = n_distinct(Study),
     N_obs = n(),
     .groups = "drop"
   )
 
 # 4. Resumo por variável com Rubin's rules
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
 
 # 5. Meta-análise agregada
 # 7. Meta-análise agregada
 meta_final <- metagen(
   TE = resumo_vars$TE,
   seTE = resumo_vars$seTE,
   studlab = resumo_vars$studlab,
   sm = "LogROM (lnRR)",
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
   atransf = exp,
   at = seq(-0.6, 0.6, by = 0.2),
   xlab = "Log Response Ratio (lnRR)",
   rightcols = c("effect", "ci", "w.random", "pval"),
   rightlabs = c("RR", "IC 95%", "Peso (%)", "p-valor"),
   leftcols = c("studlab"),
   leftlabs = c("Variáveis químicas (n, obs)")
 )
 
 
 # 7. Linha para o modelo global
 resumo_global <- tibble(
   `Indicadores funcionais (n, obs)` = "Modelo Global",
   lnRR = round(meta_final$TE.random, 3) %>% as.character(),
   `IC 95%` = paste0("[", round(meta_final$lower.random, 3), "; ", round(meta_final$upper.random, 3), "]"),
   `Peso (%)` = "",
   `p-valor` = sprintf("%.3f", meta_final$pval.random)
 )
 
 # 8. Tabela por variável
 tabela_variaveis <- tibble(
   `Indicadores funcionais (n, obs)` = meta_final$studlab,
   lnRR = round(meta_final$TE, 3) %>% as.character(),
   `IC 95%` = paste0("[", round(meta_final$lower, 3), "; ", round(meta_final$upper, 3), "]"),
   `Peso (%)` = round(100 * meta_final$w.random / sum(meta_final$w.random), 1) %>% as.character(),
   `p-valor` = sprintf("%.3f", meta_final$pval)
 )
 
 # 9. Combinar tudo
 tabela_final <- bind_rows(resumo_global, tabela_variaveis)
 
 # 10. Legenda estatística
 caption <- paste0(
   "Resumo da Meta-Análise com Modelo de Efeito Aleatório\n",
   "Q(", meta_final$k - 1, ") = ", round(meta_final$Q, 2), ", ",
   "p(Q) = ", sprintf("%.3f", meta_final$pval.Q), ", ",
   "Tau² = ", round(meta_final$tau2, 3), ", ",
   "I² = ", round(meta_final$I2, 1), "%"
 )
 
 nota_explicativa <- "Nota: (n) refere-se ao número de estudos independentes incluídos para cada indicador funcional do solo, enquanto (obs) representa o número total de observações, considerando combinações específicas entre estudos e variáveis."
 
 # Adicionando a nota como rodapé
 kable(
   tabela_final,
   align = c("l", "r", "c", "r", "r"),
   caption = caption,
   col.names = c("Indicadores funcionais (n, obs)", "lnRR", "IC 95%", "Peso (%)", "p-valor")
 ) %>%
   kable_styling(bootstrap_options = "striped", full_width = FALSE) %>%
   add_footnote(nota_explicativa, notation = "none")
 
# 10. Criar o funnel plot com base no objeto meta_final
funnel(
  meta_final,
  main = "Funnel plot - Indicadores Qualidade química do solo",
  xlab = "LogROM (lnRR)",
  ylab = "Erro padrão",
  pch = 19,
  col = "blue",
  contour = TRUE,
  contour.levels = c(0.90, 0.95, 0.99),
  col.contour = c("gray90", "gray80", "gray70"),
  legend = TRUE,
  back = TRUE
)
``



# 1. Preparar dados com truncamento de vi e definição de Tipo_Manejo
dados_completos <- dados_completos %>%
  mutate(
    vi = ifelse(vi < 1e-6, 1e-6, vi),            # evitar variâncias muito próximas de 0
    vi = pmin(vi, 1),                            # limitar variâncias excessivas
    Tipo_Manejo = case_when(
      grepl("(?i)no[- ]?till|NT|SPD|Plantio direto|SPD", Experimental) ~ "No-tillage",
      grepl("(?i)minimum|reduced|RT|Preparo Reduzido", Experimental) ~ "Minimum Tillage",
      grepl("(?i)mouldboard|plough|plow|disking|residue incorporation|palha|rototill|palhada|turning|straw return|winter mulch|straw mulching|straw retention|SSS", Experimental) ~ "Residue incorporation",
      TRUE ~ "Others"
    )
  )


#=======================================
#MANEJO
#============================

# 2. Definir fator com ordem explícita (intercepto = Residue incorporation)
dados_completos$Tipo_Manejo <- factor(
  dados_completos$Tipo_Manejo,
  levels = c("Residue incorporation", "Minimum Tillage", "No-tillage", "Others")
)

# 3. Meta-regressão com Tipo_Manejo como moderador
modelo_moderador <- rma.mv(
  yi = lnRR,
  V = vi,
  mods = ~ Tipo_Manejo,
  random = ~ 1 | Study/Variavel,
  data = dados_completos,
  method = "REML",
  control = list(
    optimizer = "optim",
    maxit = 500,
    reltol = 1e-8,
   optmethod = "BFGS"
  )
)

# 4. Calcular n e obs por tipo de manejo
n_obs_por_manejo <- dados_completos %>%
  group_by(Tipo_Manejo) %>%
  summarise(
    n = n_distinct(Study),
    obs = n(),
    .groups = "drop"
  )

# 5. Extrair efeitos com intercepto incluído
coefs <- coef(modelo_moderador)
vcov_matrix <- vcovCR(modelo_moderador, type = "CR2")
nome_intercepto <- names(coefs)[1]
categorias <- levels(dados_completos$Tipo_Manejo)

efeitos_manejo <- map_dfr(categorias, function(cat) {
  if (cat == "Residue incorporation") {
    est <- coefs[nome_intercepto]
    se <- sqrt(vcov_matrix[nome_intercepto, nome_intercepto])
  } else {
    nome_coef <- paste0("Tipo_Manejo", cat)
    if (!(nome_coef %in% rownames(vcov_matrix))) {
      est <- NA
      se <- NA
    } else {
      est <- coefs[nome_intercepto] + coefs[nome_coef]
      se <- sqrt(
        vcov_matrix[nome_intercepto, nome_intercepto] +
          vcov_matrix[nome_coef, nome_coef] +
          2 * vcov_matrix[nome_intercepto, nome_coef]
      )
    }
  }
  tibble(
    Tipo_Manejo = cat,
    lnRR = est,
    SE = se,
    IC_inf = ifelse(!is.na(se), est - 1.96 * se, NA),
    IC_sup = ifelse(!is.na(se), est + 1.96 * se, NA),
    pval = ifelse(!is.na(se), 2 * pnorm(-abs(est / se)), NA)
  )
}) %>%
  left_join(n_obs_por_manejo, by = "Tipo_Manejo") %>%
  mutate(
    Tipo_Manejo = factor(Tipo_Manejo, levels = categorias),
    label = paste0(Tipo_Manejo, " (n = ", n, ", obs = ", obs, ")")
  )

# 6. Forest plot

meta_manejo <- metagen(
  TE = efeitos_manejo$lnRR,
  seTE = efeitos_manejo$SE,
  studlab = efeitos_manejo$label,
  sm = "LogROM (lnRR)",
  method.tau = "REML",
  common = FALSE
)
meta_manejo$pval.custom <- round(efeitos_manejo$pval, 3)


# 6.1 Calcular pesos manuais usando tau² estimado
tau2 <- meta_manejo$tau^2  # variância entre estudos

# Adicionar pesos percentuais (peso relativo)
meta_manejo$w.random <- round(
  100 * (1 / (efeitos_manejo$SE^2 + tau2)) / sum(1 / (efeitos_manejo$SE^2 + tau2)),
  1
)


forest(
  meta_manejo,
  comb.fixed = FALSE,
  comb.random = TRUE,
  overall = FALSE,
  print.heterogeneity = FALSE,
  print.Q = FALSE,
  print.I2 = FALSE,
  print.tau2 = FALSE,
  col.square = "blue",
  col.diamond = "darkgreen",
  digits = 3,
  digits.TE = 3,
  atransf = identity,
  at = seq(-0.5, 0.5, by = 0.1),
  xlab = "Log Response Ratio (lnRR)",
  rightcols = c("effect", "ci", "w.random", "pval.custom"),
  rightlabs = c("lnRR", "IC 95%", "Peso (%)", "p-valor"),
  leftcols = "studlab",
  leftlabs = "Tipo de Manejo (n, obs)"
)

# 7. Tabela final
tabela_meta_regressao <- efeitos_manejo %>%
  mutate(
    `Tipo de Manejo (n/obs)` = paste0(Tipo_Manejo, " (n = ", n, ", obs = ", obs, ")"),
    lnRR = sprintf("%.3f", lnRR),
    `IC 95%` = ifelse(is.na(lnRR), NA, paste0("[", sprintf("%.3f", IC_inf), "; ", sprintf("%.3f", IC_sup), "]")),
    `p-valor` = ifelse(is.na(pval), NA, sprintf("%.3f", pval))
  ) %>%
  select(
    `Tipo de Manejo (n/obs)`,
    lnRR,
    `IC 95%`,
    `p-valor`
  )

kable(
  tabela_meta_regressao,
  align = c("l", "r", "c", "r"),
  caption = "Resumo da Meta-Regressão por Tipo de Manejo (intercepto: Residue incorporation)",
  col.names = c("Tipo de Manejo (n, obs)", "lnRR", "IC 95%", "p-valor")
) %>%
  kable_styling(bootstrap_options = "striped", full_width = FALSE)

