################################################################################
# ANÁLISE DE CORRESPONDÊNCIA MÚLTIPLA (MCA) - GGPLOT2
# Machine Learning para Indicações Geográficas
#
# Este script realiza MCA para variáveis categóricas usando FactoMineR
# e gera visualizações elegantes com ggplot2
#
# Outputs:
#   - mca_scree_plot.png (Inércia explicada)
#   - mca_biplot.png (Observações e categorias)
#   - mca_categorias_separadas.png (Visualização por tipo)
#   - mca_contingency_heatmaps.png (Tabelas de contingência)
#   - mca_relatorio.txt (Relatório estatístico)
#   - mca_dados_categoricos.csv e mca_coordenadas_categorias.csv
################################################################################

# Limpar ambiente
rm(list = ls())
gc()

# Instalar e carregar pacotes
packages <- c("bib2df", "tidyverse", "FactoMineR", "factoextra", "patchwork", 
              "viridis", "ggrepel", "reshape2")

for (pkg in packages) {
  if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
    install.packages(pkg, dependencies = TRUE, repos = "https://cloud.r-project.org")
    library(pkg, character.only = TRUE)
  }
}

cat("\n")
cat("================================================================================\n")
cat("ANÁLISE DE CORRESPONDÊNCIA MÚLTIPLA (MCA) - GGPLOT2\n")
cat("Machine Learning para Indicações Geográficas\n")
cat("================================================================================\n\n")

################################################################################
# FUNÇÃO: Extrair dados categóricos
################################################################################
extrair_dados_categoricos <- function(caminho_bib) {
  cat("📚 Extraindo dados categóricos do arquivo .bib...\n")
  
  bib_data <- bib2df(caminho_bib)
  texto_completo <- tolower(paste(bib_data$TITLE, bib_data$ABSTRACT, bib_data$KEYWORDS, sep = " "))
  
  # Categorizar algoritmos
  algoritmo <- case_when(
    grepl("random forest", texto_completo) ~ "RandomForest",
    grepl("svm|support vector", texto_completo) ~ "SVM",
    grepl("neural|deep learning|cnn|lstm", texto_completo) ~ "NeuralNetwork",
    grepl("k-nearest|knn", texto_completo) ~ "KNN",
    grepl("gradient boosting|xgboost", texto_completo) ~ "GradientBoosting",
    grepl("decision tree", texto_completo) ~ "DecisionTree",
    TRUE ~ "Outros"
  )
  
  # Categorizar instrumentos
  instrumento <- case_when(
    grepl("nir\\b|near infrared", texto_completo) ~ "NIR",
    grepl("ftir|fourier transform", texto_completo) ~ "FTIR",
    grepl("gc-ms|gas chromatography", texto_completo) ~ "GC-MS",
    grepl("lc-ms|hplc|liquid chromatography", texto_completo) ~ "LC-MS",
    grepl("icp-ms|icp\\b", texto_completo) ~ "ICP-MS",
    grepl("nmr|nuclear magnetic", texto_completo) ~ "NMR",
    grepl("sensor|e-nose", texto_completo) ~ "Sensor",
    TRUE ~ "Outros"
  )
  
  # Categorizar produtos
  produto <- case_when(
    grepl("wine|vinho", texto_completo) ~ "Wine",
    grepl("coffee|café", texto_completo) ~ "Coffee",
    grepl("olive|azeite", texto_completo) ~ "Olive",
    grepl("honey|mel", texto_completo) ~ "Honey",
    grepl("cheese|queijo", texto_completo) ~ "Cheese",
    grepl("tea|chá", texto_completo) ~ "Tea",
    grepl("meat|carne", texto_completo) ~ "Meat",
    TRUE ~ "Outros"
  )
  
  # Categorizar aplicações
  aplicacao <- case_when(
    grepl("authentication|fraud", texto_completo) ~ "Authentication",
    grepl("classification|discriminat", texto_completo) ~ "Classification",
    grepl("origin|provenance|geographical", texto_completo) ~ "OriginDetection",
    grepl("quality|grade", texto_completo) ~ "QualityControl",
    TRUE ~ "Outros"
  )
  
  # Categorizar regiões
  regiao <- case_when(
    grepl("europe|italy|france|spain|portugal", texto_completo) ~ "Europe",
    grepl("asia|china|japan|korea|india", texto_completo) ~ "Asia",
    grepl("america|usa|brazil|canada|chile", texto_completo) ~ "Americas",
    TRUE ~ "Global"
  )
  
  # Categorizar período
  ano <- as.numeric(bib_data$YEAR)
  periodo <- cut(ano, 
                 breaks = c(2010, 2015, 2020, 2025),
                 labels = c("2010-2014", "2015-2019", "2020-2025"),
                 include.lowest = TRUE)
  
  dados <- data.frame(
    ID = 1:nrow(bib_data),
    Algoritmo = as.factor(algoritmo),
    Instrumento = as.factor(instrumento),
    Produto = as.factor(produto),
    Aplicacao = as.factor(aplicacao),
    Regiao = as.factor(regiao),
    Periodo = as.factor(periodo),
    stringsAsFactors = TRUE
  )
  
  cat(sprintf("✓ Total de estudos categorizados: %d\n\n", nrow(dados)))
  
  return(dados)
}

################################################################################
# FUNÇÃO: Executar MCA
################################################################################
executar_mca <- function(dados) {
  cat("🔬 Executando MCA...\n")
  
  # Remover ID
  dados_mca <- dados %>% select(-ID)
  
  # Executar MCA
  mca_result <- MCA(dados_mca, ncp = 5, graph = FALSE)
  
  # Inércia explicada
  inercia_total <- sum(mca_result$eig[1:5, 2])
  
  cat(sprintf("✓ MCA concluída: 5 dimensões\n"))
  cat(sprintf("  Inércia explicada (Dim1+Dim2): %.2f%%\n\n", sum(mca_result$eig[1:2, 2])))
  
  return(list(mca = mca_result, dados = dados))
}

################################################################################
# FUNÇÃO: Scree Plot
################################################################################
plot_scree <- function(mca_result, output_file = "mca_scree_plot.png") {
  cat("📊 Gerando Scree Plot...\n")
  
  p <- fviz_eig(mca_result$mca, 
                addlabels = TRUE, 
                ylim = c(0, 30),
                barfill = "#2E86AB",
                barcolor = "#2E86AB") +
    labs(title = "Scree Plot - Inércia Explicada (MCA)",
         subtitle = "Análise de Correspondência Múltipla",
         x = "Dimensões",
         y = "Inércia Explicada (%)") +
    theme_minimal(base_size = 14) +
    theme(
      plot.title = element_text(face = "bold", size = 16, hjust = 0.5),
      plot.subtitle = element_text(hjust = 0.5, color = "gray40")
    )
  
  ggsave(output_file, plot = p, width = 10, height = 6, dpi = 300)
  cat(sprintf("✓ Scree Plot salvo: %s\n", output_file))
}

################################################################################
# FUNÇÃO: Biplot MCA
################################################################################
plot_biplot <- function(mca_result, output_file = "mca_biplot.png") {
  cat("📊 Gerando Biplot MCA...\n")
  
  p <- fviz_mca_biplot(
    mca_result$mca,
    repel = TRUE,
    geom.ind = "point",
    col.ind = "gray70",
    alpha.ind = 0.4,
    col.var = "contrib",
    gradient.cols = c("#00AFBB", "#E7B800", "#FC4E07"),
    legend.title = "Contribuição",
    title = "MCA Biplot - Observações e Categorias",
    labelsize = 3.5,
    pointsize = 1.5
  ) +
    theme_minimal(base_size = 14) +
    theme(
      plot.title = element_text(face = "bold", size = 16, hjust = 0.5),
      legend.position = "right"
    )
  
  ggsave(output_file, plot = p, width = 14, height = 10, dpi = 300)
  cat(sprintf("✓ Biplot salvo: %s\n", output_file))
}

################################################################################
# FUNÇÃO: Categorias Separadas
################################################################################
plot_categorias_separadas <- function(mca_result, output_file = "mca_categorias_separadas.png") {
  cat("📊 Gerando gráficos de categorias separadas...\n")
  
  # Extrair coordenadas das categorias
  coords <- as.data.frame(mca_result$mca$var$coord[, 1:2])
  coords$Categoria <- rownames(coords)
  colnames(coords) <- c("Dim1", "Dim2", "Categoria")
  
  # Plot geral - todas as categorias
  p_all <- ggplot(coords, aes(x = Dim1, y = Dim2, label = Categoria)) +
    geom_point(size = 3, alpha = 0.7, color = "#2E86AB") +
    geom_text_repel(size = 2, max.overlaps = 30) +
    labs(title = "Todas as Categorias MCA", x = "Dimensão 1", y = "Dimensão 2") +
    theme_minimal(base_size = 12) +
    theme(plot.title = element_text(face = "bold", hjust = 0.5))
  
  ggsave(output_file, plot = p_all, width = 14, height = 10, dpi = 300)
  cat(sprintf("✓ Categorias separadas salvas: %s\n", output_file))
}

################################################################################
# FUNÇÃO: Heatmaps de Contingência
################################################################################
plot_contingency_heatmaps <- function(mca_result, output_file = "mca_contingency_heatmaps.png") {
  cat("📊 Gerando heatmaps de contingência...\n")
  
  dados <- mca_result$dados %>% select(-ID)
  
  # Algoritmo x Produto
  tab1 <- table(dados$Algoritmo, dados$Produto)
  tab1_df <- as.data.frame(tab1)
  colnames(tab1_df) <- c("Algoritmo", "Produto", "Freq")
  
  p1 <- ggplot(tab1_df, aes(x = Produto, y = Algoritmo, fill = Freq)) +
    geom_tile(color = "white") +
    geom_text(aes(label = Freq), color = "white", size = 3) +
    scale_fill_viridis_c(option = "magma") +
    labs(title = "Algoritmo × Produto") +
    theme_minimal(base_size = 10) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1),
          plot.title = element_text(face = "bold", hjust = 0.5))
  
  # Instrumento x Produto
  tab2 <- table(dados$Instrumento, dados$Produto)
  tab2_df <- as.data.frame(tab2)
  colnames(tab2_df) <- c("Instrumento", "Produto", "Freq")
  
  p2 <- ggplot(tab2_df, aes(x = Produto, y = Instrumento, fill = Freq)) +
    geom_tile(color = "white") +
    geom_text(aes(label = Freq), color = "white", size = 3) +
    scale_fill_viridis_c(option = "plasma") +
    labs(title = "Instrumento × Produto") +
    theme_minimal(base_size = 10) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1),
          plot.title = element_text(face = "bold", hjust = 0.5))
  
  # Regiao x Periodo
  tab3 <- table(dados$Regiao, dados$Periodo)
  tab3_df <- as.data.frame(tab3)
  colnames(tab3_df) <- c("Regiao", "Periodo", "Freq")
  
  p3 <- ggplot(tab3_df, aes(x = Periodo, y = Regiao, fill = Freq)) +
    geom_tile(color = "white") +
    geom_text(aes(label = Freq), color = "white", size = 4) +
    scale_fill_viridis_c(option = "cividis") +
    labs(title = "Região × Período") +
    theme_minimal(base_size = 10) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1),
          plot.title = element_text(face = "bold", hjust = 0.5))
  
  # Aplicacao x Algoritmo
  tab4 <- table(dados$Aplicacao, dados$Algoritmo)
  tab4_df <- as.data.frame(tab4)
  colnames(tab4_df) <- c("Aplicacao", "Algoritmo", "Freq")
  
  p4 <- ggplot(tab4_df, aes(x = Algoritmo, y = Aplicacao, fill = Freq)) +
    geom_tile(color = "white") +
    geom_text(aes(label = Freq), color = "white", size = 3) +
    scale_fill_viridis_c(option = "turbo") +
    labs(title = "Aplicação × Algoritmo") +
    theme_minimal(base_size = 10) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1),
          plot.title = element_text(face = "bold", hjust = 0.5))
  
  combined <- (p1 | p2) / (p3 | p4)
  
  ggsave(output_file, plot = combined, width = 14, height = 10, dpi = 300)
  cat(sprintf("✓ Heatmaps de contingência salvos: %s\n", output_file))
}

################################################################################
# FUNÇÃO: Relatório
################################################################################
gerar_relatorio <- function(mca_result, output_file = "mca_relatorio.txt") {
  cat("\n📝 Gerando relatório estatístico...\n")
  
  sink(output_file)
  cat("================================================================================\n")
  cat("RELATÓRIO DE ANÁLISE MCA - MACHINE LEARNING PARA INDICAÇÕES GEOGRÁFICAS\n")
  cat("================================================================================\n\n")
  cat(sprintf("Data de execução: %s\n", Sys.time()))
  cat(sprintf("Total de observações: %d\n\n", nrow(mca_result$dados)))
  
  cat("--------------------------------------------------------------------------------\n")
  cat("INÉRCIA EXPLICADA POR DIMENSÃO\n")
  cat("--------------------------------------------------------------------------------\n")
  print(mca_result$mca$eig[1:5, ])
  cat("\n")
  
  cat("--------------------------------------------------------------------------------\n")
  cat("COORDENADAS DAS CATEGORIAS - Dim1 e Dim2\n")
  cat("--------------------------------------------------------------------------------\n")
  print(head(mca_result$mca$var$coord[, 1:2], 20))
  cat("\n")
  
  cat("--------------------------------------------------------------------------------\n")
  cat("CONTRIBUIÇÃO DAS CATEGORIAS - TOP 15 para Dim1\n")
  cat("--------------------------------------------------------------------------------\n")
  contrib <- sort(mca_result$mca$var$contrib[, 1], decreasing = TRUE)
  print(head(contrib, 15))
  cat("\n")
  
  cat("================================================================================\n")
  sink()
  
  cat(sprintf("✓ Relatório estatístico salvo: %s\n", output_file))
}

################################################################################
# FUNÇÃO: Salvar dados
################################################################################
salvar_dados <- function(mca_result) {
  write.csv(mca_result$dados, "mca_dados_categoricos.csv", row.names = FALSE)
  
  coords <- as.data.frame(mca_result$mca$var$coord)
  coords$Categoria <- rownames(coords)
  write.csv(coords, "mca_coordenadas_categorias.csv", row.names = FALSE)
  
  cat("\n✓ Dados salvos: mca_dados_categoricos.csv e mca_coordenadas_categorias.csv\n")
}

################################################################################
# EXECUÇÃO PRINCIPAL
################################################################################
main <- function() {
  caminho_bib <- "../referencias_filtradas/referencias_scopus_wos_filtradas.bib"
  
  if (!file.exists(caminho_bib)) {
    stop("❌ Erro: Arquivo .bib não encontrado em: ", caminho_bib)
  }
  
  dados <- extrair_dados_categoricos(caminho_bib)
  mca_result <- executar_mca(dados)
  
  cat("📊 Gerando visualizações...\n")
  plot_scree(mca_result)
  plot_biplot(mca_result)
  plot_categorias_separadas(mca_result)
  plot_contingency_heatmaps(mca_result)
  
  gerar_relatorio(mca_result)
  salvar_dados(mca_result)
  
  cat("\n")
  cat("================================================================================\n")
  cat("✅ ANÁLISE MCA CONCLUÍDA COM SUCESSO!\n")
  cat("================================================================================\n")
}

tryCatch({
  main()
}, error = function(e) {
  cat("\n❌ ERRO durante a execução:\n")
  cat(conditionMessage(e), "\n")
})
