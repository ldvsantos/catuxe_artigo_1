#!/usr/bin/env Rscript
# =============================================================================
# FOREST PLOT: META-ANÁLISE POR ALGORITMO (layout acadêmico convencional)
# - Tabela 100% manual (sem ilab/annotate do metafor)
# - Cabeçalho estilo APA (texto entre duas linhas)
# - Remove a “3ª linha” indesejada (linhas horizontais auxiliares do forest)
# =============================================================================

suppressPackageStartupMessages({
  library(metafor)
})

# -----------------------------------------------------------------------------
# 1) Diretórios (portável)
# -----------------------------------------------------------------------------
# Preferir o diretório do próprio script (robusto contra getwd() diferente)
get_script_dir <- function() {
  args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", args, value = TRUE)
  if (length(file_arg) == 0) {
    return(NULL)
  }
  script_path <- sub("^--file=", "", file_arg[1])
  if (nzchar(script_path)) {
    return(dirname(normalizePath(script_path, winslash = "/", mustWork = FALSE)))
  }
  NULL
}

script_dir <- get_script_dir()
if (!is.null(script_dir)) {
  sat_root <- normalizePath(file.path(script_dir, "..", ".."), winslash = "/", mustWork = FALSE)
} else {
  sat_root <- normalizePath(getwd(), winslash = "/", mustWork = FALSE)
  if (grepl("/2-DADOS/scripts$", sat_root)) {
    sat_root <- normalizePath(file.path(sat_root, "..", ".."), winslash = "/", mustWork = FALSE)
  }
}

cat("[plot_forest_algoritmos] sat_root=", sat_root, "\n")

meta_dir   <- file.path(sat_root, "2-DADOS", "1-ESTATISTICA", "1-RSTUDIO", "9-META_ANALISE")
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

# -----------------------------------------------------------------------------
# 2) Ler dados consolidados
# -----------------------------------------------------------------------------
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

acuracias_algoritmo$algoritmo <- trimws(acuracias_algoritmo$algoritmo)
acuracias_algoritmo <- acuracias_algoritmo[order(-acuracias_algoritmo$acuracia_pooled), , drop = FALSE]

# -----------------------------------------------------------------------------
# 3) Preparar para metafor (logit)
# -----------------------------------------------------------------------------
clamp01 <- function(x, eps = 1e-4) pmin(pmax(x, eps), 1 - eps)

acuracias_algoritmo$p_pooled <- clamp01(acuracias_algoritmo$acuracia_pooled / 100)
acuracias_algoritmo$p_low    <- clamp01(acuracias_algoritmo$ic_inferior / 100)
acuracias_algoritmo$p_high   <- clamp01(acuracias_algoritmo$ic_superior / 100)
acuracias_algoritmo$yi       <- transf.logit(acuracias_algoritmo$p_pooled)
acuracias_algoritmo$sei      <- (transf.logit(acuracias_algoritmo$p_high) - transf.logit(acuracias_algoritmo$p_low)) / (2 * 1.96)
acuracias_algoritmo$peso_pct <- (acuracias_algoritmo$n_estudos / sum(acuracias_algoritmo$n_estudos)) * 100

meta_alg <- rma(yi, sei = sei, data = acuracias_algoritmo, method = "REML")

# -----------------------------------------------------------------------------
# 4) Função de plot (tabela manual + forest puro)
# -----------------------------------------------------------------------------
render_forest <- function(output_png, width = 12, height = 8, units = "in", res = 300) {

  png(output_png, width = width, height = height, units = units, res = res, pointsize = 12)

  op <- par(no.readonly = TRUE)
  on.exit({ par(op); dev.off() }, add = TRUE)

  # Margens: topo e rodapé com folga (evita corte), esquerda larga (tabela)
  par(mar = c(5.8, 18.5, 3.2, 2.8))
  par(cex = 0.98)
  # Aproximar o rótulo do eixo X da linha do eixo
  par(mgp = c(2.2, 0.7, 0))
  # Evita a borda do plot (frame) caso algum device desenhe box
  par(bty = "n")

  k <- nrow(acuracias_algoritmo)

  # Linhas (de cima para baixo)
  rows_studies <- k:1
  row_model <- 0

  # ylim enxuto: sem “vazio” e sem cortar texto no rodapé
  ylim <- c(-1.2, k + 2.2)

  # Pesos para tamanhos dos quadrados
  w_iv <- weights(meta_alg)
  psize_vec <- 0.95 + 2.15 * sqrt(w_iv / max(w_iv))

  # Eixo em proporção (ticks), mas tudo interno em logit
  x_ticks_p  <- c(0.75, 0.80, 0.85, 0.90, 0.95)
  at_logit   <- transf.logit(x_ticks_p)
  alim_logit <- transf.logit(c(0.73, 0.99))

  # xlim em logit: mais largo à direita para não cortar "Estimativa [IC 95%]"
  xlim_logit <- c(-9.2, 9.4)
  xr <- diff(xlim_logit)

  # Define onde começa/termina o forest (miolo)
  forest_left <- alim_logit[1]
  forest_right <- alim_logit[2]

  # Reservar faixa para a tabela (à esquerda)
  table_left <- xlim_logit[1] + 0.02 * xr
  gap_table_forest <- 0.35
  table_right <- forest_left - gap_table_forest
  table_width <- table_right - table_left

  # Posições X (em logit) para a tabela
  x_estudo <- table_left
  x_n     <- table_left + 0.40 * table_width
  x_acc   <- table_left + 0.58 * table_width
  x_ic    <- table_left + 0.80 * table_width
  x_peso  <- table_left + 0.96 * table_width

  # Coluna da direita (texto de estimativa)
  gap_forest_est <- 0.25
  x_est_txt <- forest_right + gap_forest_est

  # ---------------------------------------------------------------------------
  # 4.1) Forest “puro”: sem tabela e sem anotação automática
  # ---------------------------------------------------------------------------
  metafor::forest(
    meta_alg,
    atransf = transf.ilogit,
    at      = at_logit,
    alim    = alim_logit,
    xlim    = xlim_logit,
    ylim    = ylim,
    rows    = rows_studies,

    annotate = FALSE,
    header   = FALSE,
    addfit   = FALSE,
    slab     = rep("", k),

    pch   = 15,
    col   = "black",
    bg    = "black",
    psize = psize_vec,

    # Remove linhas horizontais auxiliares (a “3ª linha” indesejada)
    lty = c(1, 1, 0),

    refline = meta_alg$beta,
    xlab = "Acurácia consolidada (proporção)",
    cex.axis = 1.15,
    cex.lab  = 1.00
  )

  # ---------------------------------------------------------------------------
  # 4.2) Cabeçalho (estilo APA)
  # ---------------------------------------------------------------------------
  y_header <- k + 1.10
  y_rule_top <- y_header + 0.24
  y_rule_bottom <- y_header - 0.24

  segments(x0 = xlim_logit[1], y0 = y_rule_top,    x1 = xlim_logit[2], y1 = y_rule_top)
  segments(x0 = xlim_logit[1], y0 = y_rule_bottom, x1 = xlim_logit[2], y1 = y_rule_bottom)

  text(x_estudo,  y_header, "Estudo",               pos = 4, font = 2, cex = 0.98)
  text(x_n,       y_header, "n",                    pos = 2, font = 2, cex = 0.90)
  text(x_acc,     y_header, "% acurácia",           pos = 2, font = 2, cex = 0.90)
  text(x_ic,      y_header, "IC 95%",               pos = 2, font = 2, cex = 0.90)
  text(x_peso,    y_header, "Peso (%)",             pos = 2, font = 2, cex = 0.90)
  text(x_est_txt, y_header, "Estimativa [IC 95%]",  pos = 4, font = 2, cex = 0.98)

  # ---------------------------------------------------------------------------
  # 4.3) Linhas da tabela (manual, alinhada)
  # ---------------------------------------------------------------------------
  for (i in seq_len(k)) {
    y <- rows_studies[i]

    text(x_estudo, y, acuracias_algoritmo$algoritmo[i], pos = 4, cex = 0.95)

    text(x_n,    y, sprintf("%d",   acuracias_algoritmo$n_estudos[i]),        pos = 2, cex = 0.95)
    text(x_acc,  y, sprintf("%.1f", acuracias_algoritmo$acuracia_pooled[i]),  pos = 2, cex = 0.95)
    text(x_ic,   y, sprintf("[%.1f; %.1f]",
                            acuracias_algoritmo$ic_inferior[i],
                            acuracias_algoritmo$ic_superior[i]),             pos = 2, cex = 0.95)
    text(x_peso, y, sprintf("%.1f", acuracias_algoritmo$peso_pct[i]),         pos = 2, cex = 0.95)

    text(x_est_txt, y,
         sprintf("%.3f [%.3f, %.3f]",
                 acuracias_algoritmo$p_pooled[i],
                 acuracias_algoritmo$p_low[i],
                 acuracias_algoritmo$p_high[i]),
         pos = 4, cex = 0.95)
  }

  # ---------------------------------------------------------------------------
  # 4.4) Separador + Modelo (UMA VEZ)
  # ---------------------------------------------------------------------------
  y_sep_model <- (min(rows_studies) + row_model) / 2
  segments(x0 = xlim_logit[1], y0 = y_sep_model, x1 = xlim_logit[2], y1 = y_sep_model, col = "gray70")

  text(x_estudo, row_model, "Modelo de efeitos aleatórios (REML)", pos = 4, cex = 0.95)

  metafor::addpoly(
    meta_alg,
    row = row_model,
    atransf = transf.ilogit,
    mlab = "",
    col = "gray85",
    border = "black",
    cex = 0.95
  )

  text(x_est_txt, row_model,
       sprintf("%.3f [%.3f, %.3f]",
               transf.ilogit(meta_alg$b),
               transf.ilogit(meta_alg$ci.lb),
               transf.ilogit(meta_alg$ci.ub)),
       pos = 4, cex = 0.95)

  abline(v = as.numeric(meta_alg$beta), lty = 3, col = "gray55")
}

# -----------------------------------------------------------------------------
# 5) Gerar figuras
# -----------------------------------------------------------------------------
plot_limpo <- file.path(meta_dir, "plot_forest_algoritmos_limpo.png")
render_forest(plot_limpo, width = 12, height = 8, units = "in", res = 300)
cat("✓ Forest plot salvo: ", plot_limpo, "\n")

out_manuscript <- file.path(fig_dir_en, "meta_analise_algoritmos.png")
render_forest(out_manuscript, width = 12, height = 8, units = "in", res = 300)
cat("✓ Figura do manuscrito salva: ", out_manuscript, "\n")

# Cópia com nome único (evita cache e facilita comparação)
debug_name <- paste0("meta_analise_algoritmos_debug_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".png")
debug_path <- file.path(fig_dir_en, debug_name)
file.copy(out_manuscript, debug_path, overwrite = TRUE)
cat("✓ Cópia debug salva: ", debug_path, "\n")

cat("\n✓ Análise concluída!\n")
