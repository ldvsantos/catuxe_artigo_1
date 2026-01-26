
library(tidyverse)
library(FactoMineR)
library(factoextra)

# Load data
dados <- read.csv("mca_dados_categoricos.csv", stringsAsFactors = TRUE)

# Run MCA
# Exclude ID if present (not present in saved CSV based on script, but script says row.names=FALSE)
# Script says 'dados_mca <- dados %>% select(-ID)'. Saved CSV is 'dados'.
# Let's check headers.
# Assuming content matches what was saved.

# Re-run MCA
mca_result <- MCA(dados, ncp = 5, graph = FALSE)

# 1. Biplot Temporal (colored by Periodo)
p_temporal <- fviz_mca_ind(
  mca_result,
  geom = "point",
  habillage = "Periodo", # Color by Periodo
  addEllipses = TRUE, 
  ellipse.type = "confidence",
  repel = TRUE,
  title = "MCA - Evolução Temporal (Biplot)",
  legend.title = "Período"
) +
  theme_minimal(base_size = 14) +
  theme(plot.title = element_text(face = "bold", hjust = 0.5))

ggsave("mca_biplot_temporal_completo.png", plot = p_temporal, width = 12, height = 8, dpi = 300)

cat("Generated mca_biplot_temporal_completo.png\n")
