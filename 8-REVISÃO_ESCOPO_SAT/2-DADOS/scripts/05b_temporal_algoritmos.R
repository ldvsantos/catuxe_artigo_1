################################################################################
# FIGURA: temporal_algoritmos.png
# Revisão de Escopo SAT – Tendências temporais por família algorítmica (2010–2025)
# Saída: ../../2-FIGURAS/2-EN/temporal_algoritmos.png
################################################################################

rm(list = ls())
gc()

packages <- c("bib2df", "tidyverse", "viridis")
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
out_file <- "../../2-FIGURAS/2-EN/temporal_algoritmos.png"

if (!file.exists(bib_file)) {
  stop("Arquivo .bib não encontrado em: ", bib_file)
}

dir.create(dirname(out_file), recursive = TRUE, showWarnings = FALSE)

bib <- bib2df(bib_file)
texto <- tolower(paste(bib$TITLE, bib$ABSTRACT, bib$KEYWORDS, sep = " "))

dados <- tibble(
  Ano = as.numeric(bib$YEAR),
  # Famílias algorítmicas (heurísticas por termos comuns)
  DeepLearning = as.integer(grepl("deep learning|cnn|convolutional|lstm|transformer|yolo|unet", texto)),
  RandomForest = as.integer(grepl("random forest|\\brf\\b", texto)),
  SVM = as.integer(grepl("\\bsvm\\b|support vector", texto)),
  GradientBoosting = as.integer(grepl("gradient boosting|xgboost|lightgbm|catboost", texto)),
  DecisionTree = as.integer(grepl("decision tree|\\bcart\\b", texto)),
  KNN = as.integer(grepl("k-nearest|\\bknn\\b", texto)),
  Regression = as.integer(grepl("logistic regression|linear regression|\\bglm\\b", texto))
) %>%
  filter(!is.na(Ano), Ano >= 2010, Ano <= 2025)

# Agregar por ano
cols_to_sum <- setdiff(names(dados), "Ano")
alg_ano <- dados %>%
  group_by(Ano) %>%
  summarise(across(all_of(cols_to_sum), ~sum(.x, na.rm = TRUE)), .groups = "drop")

alg_long <- alg_ano %>%
  pivot_longer(-Ano, names_to = "Familia", values_to = "Frequencia")

# Ordenar legenda por total
order_levels <- alg_long %>%
  group_by(Familia) %>%
  summarise(Total = sum(Frequencia), .groups = "drop") %>%
  arrange(desc(Total)) %>%
  pull(Familia)
alg_long$Familia <- factor(alg_long$Familia, levels = order_levels)

p <- ggplot(alg_long, aes(x = Ano, y = Frequencia, color = Familia, group = Familia)) +
  geom_line(linewidth = 0.9, alpha = 0.85) +
  geom_point(size = 1.9, alpha = 0.85) +
  scale_x_continuous(breaks = seq(2010, 2025, 2)) +
  scale_color_viridis_d(option = "plasma", begin = 0.1, end = 0.9) +
  labs(
    title = "Temporal trends in algorithm-family adoption (2010–2025)",
    subtitle = "Absolute frequency by publication year (SAT corpus)",
    x = "Year",
    y = "Frequency",
    color = "Algorithm family"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    plot.title = element_text(face = "bold", hjust = 0.5, size = 13),
    plot.subtitle = element_text(hjust = 0.5, color = "gray40", size = 11),
    legend.position = "right",
    legend.title = element_text(size = 11, face = "bold"),
    legend.text = element_text(size = 10),
    panel.grid.minor = element_blank(),
    plot.margin = margin(8, 8, 8, 8)
  )

ggsave(out_file, plot = p, width = 10, height = 6, dpi = 300)

cat("✓ Figura gerada: ", out_file, "\n", sep = "")
