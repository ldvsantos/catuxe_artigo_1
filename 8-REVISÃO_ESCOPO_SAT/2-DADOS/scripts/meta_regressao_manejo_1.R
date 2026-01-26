# 1. Carregar pacotes essenciais
library(readxl)
library(dplyr)
library(data.table)
library(mice)
library(meta)
library(stringr)
library(purrr)
library(future.apply)
library(metafor)
library(clubSandwich)
library(knitr)
library(kableExtra)

# Ativar paralelização
plan(multisession)

rm(list = ls()); gc()

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

manejo_csv <- Sys.getenv("MANEJO_CSV", unset = file.path(projeto_root, "2-DADOS", "MANEJO.csv"))
if (!file.exists(manejo_csv)) {
  stop(paste0(
    "Arquivo MANEJO.csv não encontrado em ", manejo_csv, ". ",
    "Coloque o arquivo em 8-REVISÃO_ESCOPO_SAT/2-DADOS/MANEJO.csv ou defina MANEJO_CSV."
  ))
}

# 2. Carregar e preparar os dados
dados <- fread(manejo_csv, encoding = "UTF-8") %>%
  mutate(
    across(
      c(m_e, sd_e, n_e, m_c, sd_c, n_c),
      ~ as.numeric(na_if(str_replace_all(as.character(.), ",", "."), ""))
    ),
    Experimental = factor(Experimental)
  )

# 3. Imputar dados faltantes
imput <- mice(dados, m = 3, method = "cart", seed = 10)

dados_completos <- complete(imput, action = "long", include = TRUE) %>%
  filter(m_e > 0, m_c > 0) %>%
  mutate(
    lnRR = log(m_e / m_c),
    vi = (sd_e^2 / (n_e * m_e^2)) + (sd_c^2 / (n_c * m_c^2)),
    vi = ifelse(vi < 1e-6, 1e-6, vi),
    vi = pmin(vi, 1),
    Tipo_Manejo = case_when(
      grepl("(?i)no[- ]?till|NT|SPD|Plantio direto", Experimental) ~ "No-tillage",
      grepl("(?i)minimum|reduced|RT|Preparo Reduzido|disking", Experimental) ~ "Minimum Tillage",
      grepl("(?i)residue incorporation|straw return|winter mulch|straw mulching|straw retention|palha|palhada", Experimental) ~ "Straw Management",
      grepl("(?i)agrofloresta|saf|agroecol[oó]gico|org[aâ]nico|organic|coffee-based|silvopastoral", Experimental) ~ "Agroforestry/Organic",
      TRUE ~ "Others"
    )
  ) %>%
  filter(!is.na(Experimental), !is.na(lnRR), !is.na(vi))

# 4. Reordenar fator
dados_completos$Tipo_Manejo <- factor(
  dados_completos$Tipo_Manejo,
  levels = c("Straw Management", "Minimum Tillage", "No-tillage", "Agroforestry/Organic", "Others")
)

# 5. Meta-regressão
modelo_moderador <- rma.mv(
  yi = lnRR,
  V = vi,
  mods = ~ Tipo_Manejo,
  random = ~ 1 | Experimental,
  data = dados_completos,
  method = "ML",
  #control = list(optimizer = "optim", optmethod = "Nelder-Mead")
  control = list(optimizer = "optim", maxit = 1000, reltol = 1e-6, optmethod = "Nelder-Mead")
  
)
# 6. Agregar resultados
n_obs_por_manejo <- dados_completos %>%
  group_by(Tipo_Manejo) %>%
  summarise(n = n_distinct(Experimental), obs = n(), .groups = "drop")

coefs <- coef(modelo_moderador)
vcov_matrix <- vcovCR(modelo_moderador, type = "CR2")
categorias <- levels(dados_completos$Tipo_Manejo)
nome_intercepto <- names(coefs)[1]



# Incluir corretamente o efeito do intercepto (primeira categoria)
efeitos_manejo <- map_dfr(categorias, function(cat) {
  if (cat == categorias[1]) {
    est <- coefs[nome_intercepto]
    se <- sqrt(vcov_matrix[nome_intercepto, nome_intercepto])
  } else {
    nome_coef <- paste0("Tipo_Manejo", cat)
    if (!(nome_coef %in% names(coefs)) || !(nome_coef %in% rownames(vcov_matrix))) {
      return(tibble(
        Tipo_Manejo = cat,
        lnRR = NA,
        SE = NA,
        IC_inf = NA,
        IC_sup = NA,
        pval = NA
      ))
    }
    est <- coefs[nome_intercepto] + coefs[nome_coef]
    se <- sqrt(
      vcov_matrix[nome_intercepto, nome_intercepto] +
        vcov_matrix[nome_coef, nome_coef] +
        2 * vcov_matrix[nome_intercepto, nome_coef]
    )
  }
  tibble(
    Tipo_Manejo = cat,
    lnRR = est,
    SE = se,
    IC_inf = est - 1.96 * se,
    IC_sup = est + 1.96 * se,
    pval = 2 * pnorm(-abs(est / se))
  )
})

# Adicionar contagem e labels
efeitos_manejo <- efeitos_manejo %>%
  left_join(n_obs_por_manejo, by = "Tipo_Manejo") %>%
  mutate(
    Tipo_Manejo = factor(Tipo_Manejo, levels = categorias),
    label = ifelse(
      is.na(n),
      paste0(Tipo_Manejo, " (sem dados)"),
      paste0(Tipo_Manejo, " (n = ", n, ", obs = ", obs, ")")
    )
  )

# Filtrar apenas os efeitos válidos
efeitos_validos <- efeitos_manejo %>%
  filter(!is.na(lnRR), !is.na(SE))

# 7. Meta-análise final
meta_manejo <- metagen(
  TE = efeitos_validos$lnRR,
  seTE = efeitos_validos$SE,
  studlab = efeitos_validos$label,
  sm = "LogROM (lnRR)",
  method.tau = "REML",
  common = FALSE
)

meta_manejo$pval.custom <- round(efeitos_validos$pval, 3)
tau2 <- meta_manejo$tau^2
meta_manejo$w.random <- round(
  100 * (1 / (efeitos_validos$SE^2 + tau2)) / sum(1 / (efeitos_validos$SE^2 + tau2)),
  1
)

# 8. Forest plot
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

# 9. Tabela final
tabela_meta_regressao <- efeitos_validos %>%
  mutate(
    `Tipo de Manejo (n/obs)` = label,
    lnRR = sprintf("%.3f", lnRR),
    `IC 95%` = paste0("[", sprintf("%.3f", IC_inf), "; ", sprintf("%.3f", IC_sup), "]"),
    `p-valor` = sprintf("%.3f", pval)
  ) %>%
  select(`Tipo de Manejo (n/obs)`, lnRR, `IC 95%`, `p-valor`)

kable(
  tabela_meta_regressao,
  align = c("l", "r", "c", "r"),
  caption = "Resumo da Meta-Regressão por Tipo de Manejo (intercepto: Straw Management)",
  col.names = c("Tipo de Manejo (n, obs)", "lnRR", "IC 95%", "p-valor")
) %>%
  kable_styling(bootstrap_options = "striped", full_width = FALSE)








#===============
#AJUSTES
#==================

cat("\n--- Modelo Geral da Meta-Análise ---\n")
print(meta_manejo, digits = 3)
