################################################################################
# ANÁLISE DE COMPONENTES PRINCIPAIS (PCA) - GGPLOT2
# Machine Learning para Indicações Geográficas
#
# Este script realiza PCA no corpus bibliográfico usando FactoMineR/factoextra
# e gera visualizações com ggplot2
#
# Outputs:
#   - pca_scree_plot.png (Variância explicada)
#   - pca_biplot_individuals.png (Projeção de observações)
#   - pca_biplot_variables.png (Projeção de variáveis)
#   - pca_loadings_heatmap.png (Contribuições)
#   - pca_temporal_evolution.png (Evolução temporal no espaço PCA)
#   - pca_relatorio.txt (Relatório estatístico)
#   - pca_scores.csv e pca_loadings.csv (Dados processados)
################################################################################

# Limpar ambiente
rm(list = ls())
gc()

# Instalar e carregar pacotes necessários
packages <- c("bib2df", "tidyverse", "FactoMineR", "factoextra", "corrplot", 
              "patchwork", "scales", "viridis", "ggrepel", "stringr", "pheatmap")

for (pkg in packages) {
  if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
    install.packages(pkg, dependencies = TRUE, repos = "https://cloud.r-project.org")
    library(pkg, character.only = TRUE)
  }
}

cat("\n")
cat("================================================================================\n")
cat("ANÁLISE DE COMPONENTES PRINCIPAIS (PCA) - GGPLOT2\n")
cat("Machine Learning para Indicações Geográficas\n")
cat("================================================================================\n\n")

################################################################################
# FUNÇÃO: Extrair dados do arquivo .bib
################################################################################
extrair_dados_bib <- function(caminho_bib) {
  cat("📚 Extraindo dados do arquivo .bib...\n")
  
  # Ler arquivo .bib
  bib_data <- bib2df(caminho_bib)
  
  # Extrair features binárias
  dados <- data.frame(
    ID = 1:nrow(bib_data),
    Titulo = bib_data$TITLE,
    Ano = as.numeric(bib_data$YEAR),
    stringsAsFactors = FALSE
  )
  
  # Adicionar score se disponível (exemplo: baseado em keywords ou abstract length)
  if ("KEYWORDS" %in% names(bib_data)) {
    dados$Score <- sapply(bib_data$KEYWORDS, function(x) {
      if (is.null(x) || is.na(x)) return(40)
      length(unlist(strsplit(as.character(x), ";")))
    }) * 10
  } else {
    dados$Score <- runif(nrow(bib_data), 30, 60)
  }
  
  # Features: Algoritmos
  texto_completo <- tolower(paste(bib_data$TITLE, bib_data$ABSTRACT, bib_data$KEYWORDS, sep = " "))
  
  dados$RandomForest <- as.integer(grepl("random forest|rf\\b", texto_completo))
  dados$SVM <- as.integer(grepl("support vector machine|svm\\b", texto_completo))
  dados$NeuralNetwork <- as.integer(grepl("neural network|deep learning|cnn\\b|lstm\\b|ann\\b", texto_completo))
  dados$KNN <- as.integer(grepl("k-nearest|knn\\b|k-nn", texto_completo))
  dados$DecisionTree <- as.integer(grepl("decision tree|cart\\b|c4.5|c5.0", texto_completo))
  dados$NaiveBayes <- as.integer(grepl("naive bayes|nb\\b", texto_completo))
  dados$LogisticRegression <- as.integer(grepl("logistic regression|logit", texto_completo))
  dados$GradientBoosting <- as.integer(grepl("gradient boosting|xgboost|lightgbm|catboost|adaboost", texto_completo))
  dados$EnsembleMethods <- as.integer(grepl("ensemble|bagging|boosting|stacking", texto_completo))
  
  # Features: Instrumentos
  dados$NIR <- as.integer(grepl("nir\\b|near infrared|near-infrared", texto_completo))
  dados$FTIR <- as.integer(grepl("ftir\\b|fourier transform infrared|ft-ir", texto_completo))
  dados$GCMS <- as.integer(grepl("gc-ms|gas chromatography|gcms\\b", texto_completo))
  dados$LCMS <- as.integer(grepl("lc-ms|liquid chromatography|hplc|uplc", texto_completo))
  dados$ICPMS <- as.integer(grepl("icp-ms|icp\\b|inductively coupled plasma", texto_completo))
  dados$NMR <- as.integer(grepl("nmr\\b|nuclear magnetic resonance", texto_completo))
  dados$Spectroscopy <- as.integer(grepl("spectroscopy|spectroscopic|spectra\\b", texto_completo))
  dados$Chromatography <- as.integer(grepl("chromatography|chromatographic", texto_completo))
  dados$MassSpec <- as.integer(grepl("mass spectrometry|ms\\b", texto_completo))
  dados$Sensor <- as.integer(grepl("sensor|e-nose|electronic nose|e-tongue", texto_completo))
  
  # Features: Produtos
  dados$Wine <- as.integer(grepl("wine|vinho|vino", texto_completo))
  dados$Coffee <- as.integer(grepl("coffee|café|caffè", texto_completo))
  dados$Olive <- as.integer(grepl("olive oil|azeite|olio|oliva", texto_completo))
  dados$Honey <- as.integer(grepl("honey|mel|miele", texto_completo))
  dados$Cheese <- as.integer(grepl("cheese|queijo|formaggio", texto_completo))
  dados$Tea <- as.integer(grepl("tea|chá|té\\b", texto_completo))
  dados$Meat <- as.integer(grepl("meat|carne|beef|pork|ham", texto_completo))
  dados$Fruit <- as.integer(grepl("fruit|fruta|apple|orange|citrus", texto_completo))
  dados$Vegetable <- as.integer(grepl("vegetable|vegetal|potato|tomato", texto_completo))
  
  # Features: Aplicações
  dados$Authentication <- as.integer(grepl("authentication|authenticity|fraud detection|traceability", texto_completo))
  dados$Classification <- as.integer(grepl("classification|classify|discriminat", texto_completo))
  dados$OriginDetection <- as.integer(grepl("origin|provenance|geographical|geographic indication", texto_completo))
  dados$QualityControl <- as.integer(grepl("quality|grade|grading", texto_completo))
  dados$Adulteration <- as.integer(grepl("adulteration|adulterant|counterfeit", texto_completo))
  
  # Features: Regiões
  dados$Europe <- as.integer(grepl("europe|european|italy|france|spain|portugal|greece", texto_completo))
  dados$Asia <- as.integer(grepl("asia|asian|china|japan|korea|india|thailand", texto_completo))
  dados$Americas <- as.integer(grepl("america|american|usa|brazil|canada|mexico|chile", texto_completo))
  dados$Africa <- as.integer(grepl("africa|african", texto_completo))
  dados$Oceania <- as.integer(grepl("australia|new zealand|oceania", texto_completo))
  
  cat(sprintf("✓ Total de estudos extraídos: %d\n\n", nrow(dados)))
  
  return(dados)
}

################################################################################
# FUNÇÃO: Executar PCA com FactoMineR
################################################################################
executar_pca <- function(dados, n_comp = 5) {
  cat("🔬 Executando PCA...\n")
  
  # Selecionar apenas features numéricas (excluir ID, Titulo, Ano, Score)
  features <- dados %>% 
    select(-ID, -Titulo, -Ano, -Score)
  
  # Remover colunas com todos zeros ou NAs
  features <- features[, colSums(features, na.rm = TRUE) > 0]
  
  # Substituir NAs por 0
  features[is.na(features)] <- 0
  
  # Padronizar dados (PCA exige)
  features_scaled <- scale(features)
  
  # Verificar e remover colunas com desvio padrão zero
  features_scaled <- features_scaled[, apply(features_scaled, 2, sd) > 0]
  
  # Executar PCA
  pca_result <- PCA(features_scaled, ncp = n_comp, graph = FALSE)
  
  # Adicionar scores ao dataframe original
  dados$PC1 <- pca_result$ind$coord[, 1]
  dados$PC2 <- pca_result$ind$coord[, 2]
  
  if (n_comp >= 3) dados$PC3 <- pca_result$ind$coord[, 3]
  if (n_comp >= 4) dados$PC4 <- pca_result$ind$coord[, 4]
  if (n_comp >= 5) dados$PC5 <- pca_result$ind$coord[, 5]
  
  # Calcular variância explicada
  var_explicada <- pca_result$eig[1:n_comp, 2]
  var_total_pc12 <- sum(pca_result$eig[1:2, 2])
  
  cat(sprintf("✓ PCA concluída: %d componentes principais\n", n_comp))
  cat(sprintf("  Variância explicada (PC1+PC2): %.2f%%\n\n", var_total_pc12))
  
  return(list(pca = pca_result, dados = dados, var_explicada = var_explicada))
}

################################################################################
# FUNÇÃO: Gerar Scree Plot (ggplot2)
################################################################################
plot_scree <- function(pca_result, output_file = "pca_scree_plot.png") {
  cat("📊 Gerando Scree Plot...\n")
  
  # Extrair variância explicada
  eig_data <- as.data.frame(pca_result$pca$eig)
  eig_data$Componente <- paste0("PC", 1:nrow(eig_data))
  eig_data$Componente <- factor(eig_data$Componente, levels = eig_data$Componente)
  
  # Plot com ggplot2
  p <- ggplot(eig_data[1:10, ], aes(x = Componente, y = `percentage of variance`)) +
    geom_bar(stat = "identity", fill = "#2E86AB", alpha = 0.8, width = 0.7) +
    geom_line(aes(group = 1), color = "#A23B72", size = 1.2) +
    geom_point(color = "#A23B72", size = 3) +
    geom_hline(yintercept = 100/nrow(eig_data), linetype = "dashed", 
               color = "red", alpha = 0.5) +
    labs(
      title = "Scree Plot - Variância Explicada por Componente",
      subtitle = "Análise de Componentes Principais (PCA)",
      x = "Componentes Principais",
      y = "Variância Explicada (%)",
      caption = "Linha tracejada: critério de Kaiser (1/k)"
    ) +
    theme_minimal(base_size = 14) +
    theme(
      plot.title = element_text(face = "bold", size = 16, hjust = 0.5),
      plot.subtitle = element_text(hjust = 0.5, color = "gray40"),
      axis.text.x = element_text(angle = 0, hjust = 0.5),
      panel.grid.minor = element_blank(),
      panel.grid.major.x = element_blank()
    )
  
  ggsave(output_file, plot = p, width = 10, height = 6, dpi = 300)
  cat(sprintf("✓ Scree Plot salvo: %s\n", output_file))
}

################################################################################
# FUNÇÃO: Gerar Biplot de Indivíduos (ggplot2 + factoextra)
################################################################################
plot_biplot_individuals <- function(pca_result, output_file = "pca_biplot_individuals.png") {
  cat("📊 Gerando Biplot de Indivíduos...\n")
  
  p <- fviz_pca_ind(
    pca_result$pca,
    geom.ind = "point",
    col.ind = pca_result$dados$Ano,
    gradient.cols = c("#440154FF", "#21908CFF", "#FDE725FF"),
    title = "PCA Biplot - Observações no Espaço PC1-PC2",
    legend.title = "Ano de Publicação",
    repel = FALSE,
    pointsize = 2.5,
    alpha.ind = 0.6
  ) +
    theme_minimal(base_size = 14) +
    theme(
      plot.title = element_text(face = "bold", size = 16, hjust = 0.5),
      legend.position = "right",
      panel.grid.minor = element_blank()
    )
  
  ggsave(output_file, plot = p, width = 12, height = 8, dpi = 300)
  cat(sprintf("✓ Biplot de Indivíduos salvo: %s\n", output_file))
}

################################################################################
# FUNÇÃO: Gerar Biplot de Variáveis (ggplot2 + factoextra)
################################################################################
plot_biplot_variables <- function(pca_result, output_file = "pca_biplot_variables.png") {
  cat("📊 Gerando Biplot de Variáveis...\n")
  
  p <- fviz_pca_var(
    pca_result$pca,
    col.var = "contrib",
    gradient.cols = c("#00AFBB", "#E7B800", "#FC4E07"),
    title = "PCA Biplot - Contribuição das Variáveis",
    repel = TRUE,
    labelsize = 3.5
  ) +
    theme_minimal(base_size = 14) +
    theme(
      plot.title = element_text(face = "bold", size = 16, hjust = 0.5),
      legend.position = "right",
      panel.grid.minor = element_blank()
    )
  
  ggsave(output_file, plot = p, width = 12, height = 8, dpi = 300)
  cat(sprintf("✓ Biplot de Variáveis salvo: %s\n", output_file))
}

################################################################################
# FUNÇÃO: Gerar Heatmap de Loadings (pheatmap)
################################################################################
plot_loadings_heatmap <- function(pca_result, output_file = "pca_loadings_heatmap.png") {
  cat("📊 Gerando Heatmap de Loadings...\n")
  
  # Extrair loadings (coordenadas das variáveis)
  loadings <- as.data.frame(pca_result$pca$var$coord[, 1:5])
  colnames(loadings) <- paste0("PC", 1:5)
  
  # Gerar heatmap
  png(output_file, width = 3000, height = 2400, res = 300)
  pheatmap(
    loadings,
    color = colorRampPalette(c("#3B4992", "#FFFFFF", "#EE0000"))(100),
    cluster_rows = TRUE,
    cluster_cols = FALSE,
    fontsize = 10,
    fontsize_row = 8,
    fontsize_col = 10,
    main = "Heatmap de Loadings - PCA\nContribuição das Variáveis aos Componentes",
    angle_col = 0,
    border_color = NA,
    cellwidth = 30,
    cellheight = 12
  )
  dev.off()
  
  cat(sprintf("✓ Heatmap de Loadings salvo: %s\n", output_file))
}

################################################################################
# FUNÇÃO: Gerar Evolução Temporal (ggplot2)
################################################################################
plot_temporal_evolution <- function(pca_result, output_file = "pca_temporal_evolution.png") {
  cat("📊 Gerando Evolução Temporal...\n")
  
  dados_plot <- pca_result$dados %>%
    filter(!is.na(Ano)) %>%
    mutate(Periodo = cut(Ano, 
                         breaks = c(2010, 2015, 2020, 2025),
                         labels = c("2010-2014", "2015-2019", "2020-2025"),
                         include.lowest = TRUE))
  
  p <- ggplot(dados_plot, aes(x = PC1, y = PC2, color = Periodo)) +
    geom_point(size = 3, alpha = 0.7) +
    stat_ellipse(aes(fill = Periodo), geom = "polygon", alpha = 0.1, 
                 level = 0.95, type = "norm") +
    scale_color_viridis_d(option = "plasma", begin = 0.2, end = 0.9) +
    scale_fill_viridis_d(option = "plasma", begin = 0.2, end = 0.9) +
    labs(
      title = "Evolução Temporal no Espaço PCA",
      subtitle = "Distribuição de estudos por período (2010-2025)",
      x = sprintf("PC1 (%.2f%% da variância)", pca_result$var_explicada[1]),
      y = sprintf("PC2 (%.2f%% da variância)", pca_result$var_explicada[2]),
      color = "Período",
      fill = "Período"
    ) +
    theme_minimal(base_size = 14) +
    theme(
      plot.title = element_text(face = "bold", size = 16, hjust = 0.5),
      plot.subtitle = element_text(hjust = 0.5, color = "gray40"),
      legend.position = "right",
      panel.grid.minor = element_blank()
    )
  
  ggsave(output_file, plot = p, width = 12, height = 8, dpi = 300)
  cat(sprintf("✓ Evolução Temporal salva: %s\n", output_file))
}

################################################################################
# FUNÇÃO: Gerar Relatório Estatístico
################################################################################
gerar_relatorio <- function(pca_result, output_file = "pca_relatorio.txt") {
  cat("\n📝 Gerando relatório estatístico...\n")
  
  sink(output_file)
  cat("================================================================================\n")
  cat("RELATÓRIO DE ANÁLISE PCA - MACHINE LEARNING PARA INDICAÇÕES GEOGRÁFICAS\n")
  cat("================================================================================\n\n")
  cat(sprintf("Data de execução: %s\n", Sys.time()))
  cat(sprintf("Total de observações: %d\n", nrow(pca_result$dados)))
  cat(sprintf("Total de variáveis analisadas: %d\n\n", ncol(pca_result$pca$var$coord)))
  
  cat("--------------------------------------------------------------------------------\n")
  cat("VARIÂNCIA EXPLICADA POR COMPONENTE\n")
  cat("--------------------------------------------------------------------------------\n")
  print(pca_result$pca$eig[1:5, ])
  cat("\n")
  
  cat("--------------------------------------------------------------------------------\n")
  cat("LOADINGS (CONTRIBUIÇÃO DAS VARIÁVEIS) - PC1 e PC2\n")
  cat("--------------------------------------------------------------------------------\n")
  loadings_pc12 <- pca_result$pca$var$coord[, 1:2]
  loadings_pc12 <- loadings_pc12[order(abs(loadings_pc12[, 1]), decreasing = TRUE), ]
  print(head(loadings_pc12, 15))
  cat("\n")
  
  cat("--------------------------------------------------------------------------------\n")
  cat("QUALIDADE DE REPRESENTAÇÃO (COS2) - TOP 15 VARIÁVEIS\n")
  cat("--------------------------------------------------------------------------------\n")
  cos2_vars <- pca_result$pca$var$cos2[, 1:2]
  cos2_vars <- cos2_vars[order(rowSums(cos2_vars), decreasing = TRUE), ]
  print(head(cos2_vars, 15))
  cat("\n")
  
  cat("--------------------------------------------------------------------------------\n")
  cat("CONTRIBUIÇÃO DAS VARIÁVEIS (%) - TOP 15 PARA PC1\n")
  cat("--------------------------------------------------------------------------------\n")
  contrib_pc1 <- sort(pca_result$pca$var$contrib[, 1], decreasing = TRUE)
  print(head(contrib_pc1, 15))
  cat("\n")
  
  cat("--------------------------------------------------------------------------------\n")
  cat("INTERPRETAÇÃO DOS COMPONENTES PRINCIPAIS\n")
  cat("--------------------------------------------------------------------------------\n")
  cat("PC1: Representa o eixo principal de variação metodológica.\n")
  cat("     Variáveis com alta carga positiva/negativa indicam características distintivas.\n\n")
  cat("PC2: Captura a segunda maior fonte de variação ortogonal a PC1.\n")
  cat("     Frequentemente associado a contrastes entre técnicas ou produtos.\n\n")
  cat("PC1+PC2 juntos explicam a proporção predominante da variância observada.\n")
  cat("================================================================================\n")
  sink()
  
  cat(sprintf("✓ Relatório estatístico salvo: %s\n", output_file))
}

################################################################################
# FUNÇÃO: Salvar dados processados
################################################################################
salvar_dados <- function(pca_result) {
  # Salvar scores
  scores <- pca_result$dados %>%
    select(ID, Titulo, Ano, Score, PC1, PC2, PC3, PC4, PC5)
  write.csv(scores, "pca_scores.csv", row.names = FALSE)
  
  # Salvar loadings
  loadings <- as.data.frame(pca_result$pca$var$coord)
  loadings$Variable <- rownames(loadings)
  loadings <- loadings %>% select(Variable, everything())
  write.csv(loadings, "pca_loadings.csv", row.names = FALSE)
  
  cat("\n✓ Dados salvos: pca_scores.csv e pca_loadings.csv\n")
}

################################################################################
# EXECUÇÃO PRINCIPAL
################################################################################
main <- function() {
  # Configurar diretório de trabalho (se necessário)
  # setwd("caminho/para/seu/diretorio")
  
  # Caminho do arquivo .bib
  caminho_bib <- "../referencias_filtradas/referencias_scopus_wos_filtradas.bib"
  
  # Verificar se arquivo existe
  if (!file.exists(caminho_bib)) {
    stop("❌ Erro: Arquivo .bib não encontrado em: ", caminho_bib)
  }
  
  # 1. Extrair dados
  dados <- extrair_dados_bib(caminho_bib)
  
  # 2. Executar PCA
  pca_result <- executar_pca(dados, n_comp = 5)
  
  # 3. Gerar visualizações
  cat("📊 Gerando visualizações...\n")
  plot_scree(pca_result)
  plot_biplot_individuals(pca_result)
  plot_biplot_variables(pca_result)
  plot_loadings_heatmap(pca_result)
  plot_temporal_evolution(pca_result)
  
  # 4. Gerar relatório
  gerar_relatorio(pca_result)
  
  # 5. Salvar dados
  salvar_dados(pca_result)
  
  cat("\n")
  cat("================================================================================\n")
  cat("✅ ANÁLISE PCA CONCLUÍDA COM SUCESSO!\n")
  cat("================================================================================\n")
}

# Executar
tryCatch({
  main()
}, error = function(e) {
  cat("\n❌ ERRO durante a execução:\n")
  cat(conditionMessage(e), "\n")
})
