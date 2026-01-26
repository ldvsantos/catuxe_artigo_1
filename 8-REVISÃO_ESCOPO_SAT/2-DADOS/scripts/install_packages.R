# Script para instalar pacotes necessários

# Configurar CRAN mirror
options(repos = c(CRAN = "https://cloud.r-project.org"))

# Instalar pacman
if (!require("pacman", quietly = TRUE)) {
  install.packages("pacman", repos = "https://cloud.r-project.org")
}

# Carregar pacman e instalar demais pacotes
library(pacman)

# Instalar todos os pacotes necessários
pacman::p_load(
  tidyverse, metafor, meta, ggplot2, patchwork,
  viridis, gridExtra, knitr, kableExtra, forcats,
  install = TRUE
)

cat("\n✓ Todos os pacotes foram instalados com sucesso!\n")
