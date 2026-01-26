# 0. Carregar pacotes
library(readxl)
library(dplyr)
library(meta)
library(metafor)
library(clubSandwich)
library(tibble)
library(mice)
library(ggplot2)
library(forcats)

# 1. Carregar base
dados <- read_excel("C:/Users/vidal/OneDrive/Documentos/ARTIGO_MA/3 - DADOS/bd.xlsx", sheet = "VARIAVEIS_FISICAS") %>%
  
# 2. Preparar dados
dados <- dados_brutos %>%
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
  mutate(across(c(n_e, m_e, sd_e, n_c, m_c, sd_c), as.numeric))

# 3. Imputação múltipla para variâncias ausentes
dados_imput <- mice(dados, m = 20, method = "cart", seed = 123)
dados_completos <- complete(dados_imput, "long", include = TRUE)

# ⚠️ Garantir que Variavel é fator
dados_completos$Variavel <- factor(dados_completos$Variavel)
dados_completos$Variavel <- relevel(dados_completos$Variavel, ref = "Soil Organic Carbon (SOC)")

# 4. Calcular lnRR e variância
dados_completos <- dados_completos %>%
  mutate(
    lnRR = log(m_e / m_c),
    vi = (sd_e^2 / (n_e * m_e^2)) + (sd_c^2 / (n_c * m_c^2))
  )

# 5. Meta-análise multivariada
system.time({
  modelo_mv <- rma.mv(
    yi = lnRR,
    V = vi,
    mods = ~ Variavel,
    random = ~ 1 | Study/Variavel,
    data = dados_completos,
    method = "REML"
  )
})

# 6. Correção robusta
robusto <- coef_test(modelo_mv, vcov = "CR2", cluster = dados_completos$Study)

# 7. Resumo por variável
resumo <- robusto %>%
  as.data.frame() %>%
  rownames_to_column("Variavel") %>%
  rename(
    lnRR = beta,
    se_lnRR = SE,
    p_value = p_Satt
  )

# 7.1 Calcular número de estudos
frequencia_estudos <- dados %>%
  group_by(Variavel) %>%
  summarise(N_estudos = n_distinct(Study), .groups = "drop")

# 7.2 Ajustar nomes e calcular ICs
resumo <- resumo %>%
  mutate(Variavel_limpa = case_when(
    Variavel == "intrcpt" ~ levels(dados_completos$Variavel)[1],
    TRUE ~ gsub("^Variavel", "", Variavel)
  )) %>%
  left_join(frequencia_estudos, by = c("Variavel_limpa" = "Variavel")) %>%
  mutate(
    IC_inf = lnRR - 1.96 * se_lnRR,
    IC_sup = lnRR + 1.96 * se_lnRR,
    p_value_fmt = sprintf("%.3f", p_value),
    Variavel_com_n = paste0(Variavel_limpa, " (n = ", N_estudos, ")"),
    Variavel = fct_reorder(Variavel_com_n, lnRR)
  )

# 7.3 Filtrar observações válidas
resumo_filtrado <- resumo %>%
  filter(!is.na(lnRR), !is.na(se_lnRR), !is.infinite(lnRR), !is.infinite(se_lnRR))

# 8. Criar objeto metagen
meta_lnRR <- metagen(
  TE = resumo_filtrado$lnRR,
  seTE = resumo_filtrado$se_lnRR,
  studlab = resumo_filtrado$Variavel_com_n,
  sm = "Efeito estimado lnRR",  # Mantém como diferença de médias logarítmicas
  method.tau = "REML",
  common = FALSE,
  random = TRUE
)

# Adicionar p-valor formatado
meta_lnRR$pval <- resumo_filtrado$p_value_fmt

# 9. Plotar forest em lnRR
forest(
  meta_lnRR,
  comb.fixed = FALSE,
  comb.random = TRUE,
  overall = TRUE,
  overall.hetstat = FALSE,
  print.tau2 = TRUE,
  col.square = "blue",
  col.diamond = "darkgreen",
  digits = 3,
  digits.TE = 3,
  digits.se = 3,
  atransf = identity,
  at = seq(-1, 1, by = 0.2),
  xlab = "Efeito estimado (lnRR)",
  rightcols = c("effect", "ci", "w.random", "pval"),
  rightlabs = c("lnRR", "IC 95%", "Peso (%)", "p-valor"),
  leftcols = c("studlab"),
  leftlabs = c("Indicadores funcionais (n)")
)

# 10. Tabela final
resumo_final <- resumo_filtrado %>%
  select(
    `Indicador Funcional (n)` = Variavel_com_n,
    `Efeito (lnRR)` = lnRR,
    `Erro padrão` = se_lnRR,
    `IC 95% Inferior` = IC_inf,
    `IC 95% Superior` = IC_sup,
    `p-valor` = p_value_fmt
  )

print(resumo_final)

# 11. Exportar como CSV
write.csv(resumo_final, "resumo_meta_lnRR.csv", row.names = FALSE)
