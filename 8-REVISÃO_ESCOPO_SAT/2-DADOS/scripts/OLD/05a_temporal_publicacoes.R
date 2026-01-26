################################################################################
# FIGURA: temporal_publicacoes.png
# Revisão de Escopo SAT – Evolução temporal de publicações (2010–2025)
# Saída: ../../2-FIGURAS/2-EN/temporal_publicacoes.png
################################################################################

rm(list = ls())
gc()

packages <- c("bib2df", "tidyverse")
for (pkg in packages) {
  if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
    install.packages(pkg, dependencies = TRUE, repos = "https://cloud.r-project.org")
    library(pkg, character.only = TRUE)
  }
}

# Garantir paths relativos ao arquivo do script
args <- commandArgs(trailingOnly = FALSE)
script_path <- sub("^--file=", "", args[grep("^--file=", args)])
if (length(script_path) > 0) {
  script_dir <- dirname(normalizePath(script_path))
  setwd(script_dir)
}

bib_file <- "../referencias_filtradas/referencias_scopus_wos_filtradas.bib"
out_file <- "../../2-FIGURAS/2-EN/temporal_publicacoes.png"

if (!file.exists(bib_file)) {
  stop("Arquivo .bib não encontrado em: ", bib_file)
}

dir.create(dirname(out_file), recursive = TRUE, showWarnings = FALSE)

bib <- bib2df(bib_file)

df <- bib %>%
  dplyr::select(YEAR) %>%
  dplyr::mutate(YEAR = as.numeric(YEAR)) %>%
  dplyr::filter(!is.na(YEAR), YEAR >= 2010, YEAR <= 2025) %>%
  dplyr::count(YEAR, name = "Total") %>%
  dplyr::arrange(YEAR)

# LOESS + IC 90% ("túnel")
# Intervalo bilateral de 90% => z = qnorm(0.95)
z_90 <- qnorm(0.95)
lo <- loess(Total ~ YEAR, data = df, span = 0.75, degree = 2)

x_seq <- seq(min(df$YEAR), max(df$YEAR), by = 1)
pred <- predict(lo, newdata = data.frame(YEAR = x_seq), se = TRUE)

pred_df <- data.frame(
  YEAR = x_seq,
  fit = as.numeric(pred$fit),
  lwr = as.numeric(pred$fit - z_90 * pred$se.fit),
  upr = as.numeric(pred$fit + z_90 * pred$se.fit)
)

# Evitar faixa negativa
pred_df$lwr <- pmax(0, pred_df$lwr)

p <- ggplot(df, aes(x = YEAR, y = Total)) +
  geom_ribbon(
    data = pred_df,
    aes(x = YEAR, ymin = lwr, ymax = upr),
    inherit.aes = FALSE,
    fill = "#FC4E07",
    alpha = 0.18
  ) +
  geom_line(data = pred_df, aes(x = YEAR, y = upr), inherit.aes = FALSE,
            color = "#FC4E07", linewidth = 0.6, alpha = 0.9) +
  geom_line(data = pred_df, aes(x = YEAR, y = lwr), inherit.aes = FALSE,
            color = "#FC4E07", linewidth = 0.6, alpha = 0.9) +
  geom_line(color = "#2E86AB", linewidth = 1.0) +
  geom_point(color = "#2E86AB", size = 2.2, alpha = 0.85) +
  geom_line(
    data = pred_df,
    aes(x = YEAR, y = fit),
    inherit.aes = FALSE,
    color = "#FC4E07",
    linewidth = 0.9,
    linetype = "dashed"
  ) +
  scale_x_continuous(breaks = seq(2010, 2025, 2)) +
  labs(
    title = "Temporal evolution of publications (SAT, 2010–2025)",
    subtitle = "Dashed line: LOESS trend | Shaded band: 90% confidence interval",
    x = "Year",
    y = "Publications"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    plot.title = element_text(face = "bold", hjust = 0.5, size = 13),
    plot.subtitle = element_text(hjust = 0.5, color = "gray40", size = 11),
    panel.grid.minor = element_blank(),
    plot.margin = margin(8, 8, 8, 8)
  )

# Mesmas dimensões do LaTeX (aprox)
ggsave(out_file, plot = p, width = 10, height = 6, dpi = 300)

cat("✓ Figura gerada: ", out_file, "\n", sep = "")
