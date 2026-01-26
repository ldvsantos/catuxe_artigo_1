#!/usr/bin/env Rscript
# =============================================================================
# FOREST PLOT: META-ANÁLISE POR ALGORITMO
# Script independente para gerar forest plot limpo e a figura final do manuscrito
# =============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(metafor)
})

# Diretórios (portável)
sat_root <- normalizePath(getwd(), winslash = "/", mustWork = FALSE)
if (grepl("/2-DADOS/scripts$", sat_root)) {
  sat_root <- normalizePath(file.path(sat_root, "..", ".."), winslash = "/", mustWork = FALSE)
}

meta_dir <- file.path(sat_root, "2-DADOS", "1-ESTATISTICA", "1-RSTUDIO", "9-META_ANALISE")
fig_dir_en <- file.path(sat_root, "2-FIGURAS", "2-EN")
dir.create(meta_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(fig_dir_en, recursive = TRUE, showWarnings = FALSE)

input_csv <- file.path(meta_dir, "meta_analise_por_algoritmo.csv")
if (!file.exists(input_csv)) {
  stop(
    paste0(
      "Arquivo não encontrado: ", input_csv, "\n",
      "Rode primeiro: 09_meta_analise.R (gera meta_analise_por_algoritmo.csv)."
    )
  )
}

# Ler dados consolidados (gerado por 09_meta_analise.R)
acuracias_algoritmo <- read.csv(input_csv, stringsAsFactors = FALSE, check.names = FALSE)
required_cols <- c("algoritmo", "acuracia_pooled", "ic_inferior", "ic_superior", "n_estudos")
missing_cols <- setdiff(required_cols, names(acuracias_algoritmo))
if (length(missing_cols) > 0) {
  stop(
    paste0(
      "Colunas obrigatórias ausentes em meta_analise_por_algoritmo.csv: ",
      paste(missing_cols, collapse = ", ")
    )
  )
}

acuracias_algoritmo <- acuracias_algoritmo %>%
  mutate(
    algoritmo = trimws(algoritmo),
    grupo = case_when(
      algoritmo %in% c("Random Forest", "XGBoost", "Decision Tree") ~ "Ensemble",
      algoritmo == "PLS-DA" ~ "Quimiometria",
      algoritmo %in% c("SVM", "Neural Network", "Deep Learning") ~ "Kernel/Neural",
      TRUE ~ "Outros"
    ),
    grupo = factor(grupo, levels = c("Ensemble", "Quimiometria", "Kernel/Neural", "Outros"))
  ) %>%
  arrange(desc(acuracia_pooled))

# -----------------------------------------------------------------------------
# 2. PREPARAR PARA metafor (transformação logit)
# -----------------------------------------------------------------------------

clamp01 <- function(x, eps = 1e-4) pmin(pmax(x, eps), 1 - eps)

acuracias_algoritmo <- acuracias_algoritmo %>%
  mutate(
    p_pooled = clamp01(acuracia_pooled / 100),
    p_low = clamp01(ic_inferior / 100),
    p_high = clamp01(ic_superior / 100),
    yi = transf.logit(p_pooled),
    sei = (transf.logit(p_high) - transf.logit(p_low)) / (2 * 1.96),
    studlab = paste0(algoritmo, " (n=", n_estudos, ")"),
    peso_pct = (n_estudos / sum(n_estudos)) * 100
  )

meta_alg <- rma(yi, sei = sei, data = acuracias_algoritmo, method = "REML")

# -----------------------------------------------------------------------------
# 3. CORES E SÍMBOLOS POR GRUPO
# -----------------------------------------------------------------------------

cores_grupo <- c(
  "Ensemble" = "#0072B2",
  "Quimiometria" = "#009E73",
  "Kernel/Neural" = "#D55E00",
  "Outros" = "#666666"
)

# Mapear cores por algoritmo
cores_por_algo <- sapply(acuracias_algoritmo$grupo, function(g) cores_grupo[as.character(g)])

# Mapear símbolos: quadrado=Ensemble, diamante=Quimiometria, triângulo=Kernel/Neural
shapes_por_algo <- sapply(acuracias_algoritmo$grupo, function(g) {
  switch(
    as.character(g),
    "Ensemble" = 15,
    "Quimiometria" = 18,
    "Kernel/Neural" = 17,
    "Outros" = 16
  )
})

render_forest <- function(output_png, width, height, units = "in", res = 300) {

  png(output_png, width = width, height = height, units = units, res = res, pointsize = 13)

  # ---------------------------------------------------------------------------
  # Layout "tradicional": mais margem esquerda para a tabela; topo limpo
  # ---------------------------------------------------------------------------
  op <- par(no.readonly = TRUE)
  on.exit({ par(op); dev.off() }, add = TRUE)

  par(mar = c(4.4, 14.5, 2.3, 2.4))  # (baixo, esquerda, topo, direita)
  par(cex = 1.05)

  k <- nrow(acuracias_algoritmo)

  # Linhas: estudos de cima para baixo; diamante do modelo embaixo
  # (aumenta espaçamento para evitar sobreposição/empilhamento vertical)
  row_step <- 3.2
  rows_studies <- seq(from = (k - 1) * row_step + 4, to = 4, by = -row_step)
  row_model <- 1

  # Pesos (tamanho do símbolo proporcional) — “visual padrão” de meta-análise
  w_iv <- weights(meta_alg)                          # pesos IV do modelo
  psize_vec <- 0.8 + 2.2 * sqrt(w_iv / max(w_iv))    # escala suave e legível

  # Eixo em proporção, mas internamente tudo em logit (yi/sei)
  x_ticks_p <- c(0.80, 0.85, 0.90, 0.95)             # marcas em proporção
  at_logit <- transf.logit(x_ticks_p)
  alim_logit <- transf.logit(c(0.75, 0.98))          # limites do “miolo” do forest em logit

  # xlim em logit: mais área à esquerda para espaçamento horizontal adequado
  xlim_logit <- c(-7.8, 7.0)

  # Posições das colunas (em logit) com maior espaçamento horizontal entre Estudo/n/acurácia/IC/peso
  x_n <- -6.90
  x_acc <- -5.70
  x_ci <- -4.20
  x_w <- -2.60
  ilab_x <- c(x_n, x_acc, x_ci, x_w)

  # ---------------------------------------------------------------------------
  # Forest plot
  # ---------------------------------------------------------------------------
  metafor::forest(
    meta_alg,
    slab = acuracias_algoritmo$algoritmo,          # nome do algoritmo (coluna Study)
    rows = rows_studies,

    ylim = c(0, max(rows_studies) + 3.2),

    atransf = transf.ilogit,                       # exibir em proporção
    xlim = xlim_logit,
    alim = alim_logit,
    at = at_logit,

    xlab = "Acurácia consolidada (proporção)",
    refline = meta_alg$beta,                       # refline em logit (coerente)

    # Colunas adicionais à esquerda
    ilab = cbind(
      acuracias_algoritmo$n_estudos,
      sprintf("%.1f", acuracias_algoritmo$acuracia_pooled),
      sprintf("[%.1f; %.1f]", acuracias_algoritmo$ic_inferior, acuracias_algoritmo$ic_superior),
      sprintf("%.1f", acuracias_algoritmo$peso_pct)
    ),
    ilab.xpos = ilab_x,
    ilab.pos = 4,

    # Estética tradicional
    pch = 15,
    col = "black",
    bg = "gray70",
    psize = psize_vec,

    # Mantém as colunas de texto ancoradas, evitando “invadir” o miolo
    # Joga a coluna de estimativa para a direita (separação visual clara)
    textpos = c(xlim_logit[1] + 0.2, 6.5),

    header = c("Estudo", "Estimativa [IC 95%]"),
    cex = 1.02,
    cex.lab = 1.08,
    cex.axis = 0.98,
    digits = 3
  )

  # Cabeçalho das colunas à esquerda (alinhado com ilab.xpos)
  text(
    x = ilab_x,
    y = max(rows_studies) + 1.4,
    labels = c("n", "% acurácia", "IC 95%", "Peso (%)"),
    pos = 4, font = 2, cex = 1.00
  )

  # Linha vertical do efeito global (leve, padrão)
  abline(v = as.numeric(meta_alg$beta), lty = 3, col = "gray55")

  # Diamante do modelo (embaixo)
  metafor::addpoly(
    meta_alg,
    row = row_model,
    atransf = transf.ilogit,
    mlab = "Modelo de efeitos aleatórios (REML)",
    col = "gray85",
    border = "black",
    cex = 1.02
  )

  # Pequena separação visual entre estudos e modelo
  abline(h = 2, col = "gray80")
}

# -----------------------------------------------------------------------------
# 4. FOREST PLOT (arquivo de trabalho)
# -----------------------------------------------------------------------------

plot_limpo <- file.path(meta_dir, "plot_forest_algoritmos_limpo.png")
render_forest(plot_limpo, width = 12, height = 8, units = "in", res = 300)
cat("✓ Forest plot salvo: ", plot_limpo, "\n")

# -----------------------------------------------------------------------------
# 4b. EXPORTAR FIGURA FINAL DO MANUSCRITO (padrão IG)
# - Reduzimos a dimensão física para garantir que a fonte fique legível
# - 14x8 polegadas a 300 DPI
# -----------------------------------------------------------------------------

out_manuscript <- file.path(fig_dir_en, "meta_analise_algoritmos.png")
render_forest(out_manuscript, width = 12, height = 8, units = "in", res = 300)
cat("✓ Figura do manuscrito salva: ", out_manuscript, "\n")

cat("\n✓ Análise concluída!\n")

# -----------------------------------------------------------------------------
# 5. TABELA DE RESUMO (opcional)
# -----------------------------------------------------------------------------

if (requireNamespace("kableExtra", quietly = TRUE)) {
  suppressPackageStartupMessages({
    library(kableExtra)
  })

# Linha do modelo global
resumo_global <- tibble::tibble(
  `Algoritmo (n, obs)` = "Modelo de Efeitos Aleatórios",
  `% Acurácia` = sprintf("%.1f", transf.ilogit(meta_alg$beta) * 100),
  `IC 95%` = sprintf("[%.1f, %.1f]", 
                     transf.ilogit(meta_alg$ci.lb) * 100,
                     transf.ilogit(meta_alg$ci.ub) * 100),
  `Peso (%)` = "",
  `p-valor` = sprintf("%.3f", meta_alg$pval)
)

# Linhas por algoritmo
tabela_algoritmos <- tibble::tibble(
  `Algoritmo (n, obs)` = acuracias_algoritmo$studlab,
  `% Acurácia` = sprintf("%.1f", acuracias_algoritmo$acuracia_pooled),
  `IC 95%` = sprintf("[%.1f, %.1f]", acuracias_algoritmo$ic_inferior, acuracias_algoritmo$ic_superior),
  `Peso (%)` = sprintf("%.1f", acuracias_algoritmo$peso_pct),
  `p-valor` = "-"
)

# Combinar
tabela_final <- bind_rows(resumo_global, tabela_algoritmos)

# Caption
caption_meta <- sprintf(
  "Meta-Análise de Acurácias por Algoritmo (k = %d estudos)\nI² = %.1f%%, Tau² = %.3f, Q(df=%d) = %.2f, p(Q) = %.3f",
  meta_alg$k, meta_alg$I2, meta_alg$tau2, meta_alg$k - 1, meta_alg$QE, meta_alg$QEp
)

# Exibir tabela
  caption_meta <- sprintf(
    "Meta-Análise de Acurácias por Algoritmo (k = %d estudos)\nTau² = %.3f, Q = %.2f, p(Q) = %.3f",
    meta_alg$k,
    meta_alg$tau2,
    meta_alg$QE,
    meta_alg$QEp
  )

  print(
    kable(tabela_final,
      align = c("l", "r", "c", "r", "r"),
      caption = caption_meta
    ) %>%
      kable_styling(bootstrap_options = "striped", full_width = FALSE)
  )
}
