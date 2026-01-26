################################################################################
# ANÁLISE DE CLUSTERS (K-MEANS E HIERÁRQUICO) - GGPLOT2
# Machine Learning para Indicações Geográficas
#
# Este script realiza clustering usando factoextra/dendextend
# e gera visualizações elegantes com ggplot2
#
# Outputs:
#   - cluster_elbow_silhouette.png (Determinação do k ótimo)
#   - cluster_kmeans_scatter.png (Visualização dos clusters)
#   - cluster_dendrogram.png (Dendrograma hierárquico)
#   - cluster_heatmap_profiles.png (Perfil de características por cluster)
#   - cluster_relatorio.txt (Análise detalhada)
#   - cluster_resultados.csv (Dados com clusters)
################################################################################

rm(list = ls())
gc()

packages <- c(
  "bib2df",
  "ggplot2",
  "cluster",
  "dendextend",
  "viridis",
  "patchwork",
  "pheatmap",
  "NbClust",
  "grid"
)

for (pkg in packages) {
  if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
    install.packages(pkg, dependencies = TRUE, repos = "https://cloud.r-project.org")
    library(pkg, character.only = TRUE)
  }
}

cat("\n")
cat("================================================================================\n")
cat("ANÁLISE DE CLUSTERS (K-MEANS E HIERÁRQUICO) - GGPLOT2\n")
cat("Machine Learning para Indicações Geográficas\n")
cat("================================================================================\n\n")

################################################################################
# FUNÇÃO: Extrair dados
################################################################################
extrair_dados_clustering <- function(caminho_bib) {
  cat("📚 Extraindo dados do arquivo .bib...\n")
  
  bib_data <- bib2df(caminho_bib)
  texto_completo <- tolower(paste(bib_data$TITLE, bib_data$ABSTRACT, bib_data$KEYWORDS, sep = " "))
  
  dados <- data.frame(
    ID = 1:nrow(bib_data),
    Titulo = bib_data$TITLE,
    Ano = as.numeric(bib_data$YEAR),
    
    # Algoritmos
    RandomForest = as.integer(grepl("random forest|rf\\b", texto_completo)),
    SVM = as.integer(grepl("support vector machine|svm\\b", texto_completo)),
    NeuralNetwork = as.integer(grepl("neural network|deep learning|cnn\\b|lstm\\b|ann\\b", texto_completo)),
    KNN = as.integer(grepl("k-nearest|knn\\b", texto_completo)),
    DecisionTree = as.integer(grepl("decision tree|cart\\b", texto_completo)),
    GradientBoosting = as.integer(grepl("gradient boosting|xgboost|lightgbm", texto_completo)),
    
    # Instrumentos
    NIR = as.integer(grepl("nir\\b|near infrared", texto_completo)),
    FTIR = as.integer(grepl("ftir\\b|fourier transform infrared", texto_completo)),
    GCMS = as.integer(grepl("gc-ms|gas chromatography", texto_completo)),
    LCMS = as.integer(grepl("lc-ms|liquid chromatography|hplc", texto_completo)),
    ICPMS = as.integer(grepl("icp-ms|icp\\b", texto_completo)),
    NMR = as.integer(grepl("nmr\\b|nuclear magnetic", texto_completo)),
    Sensor = as.integer(grepl("sensor|e-nose|electronic nose", texto_completo)),
    
    # Produtos
    Wine = as.integer(grepl("wine|vinho", texto_completo)),
    Coffee = as.integer(grepl("coffee|café", texto_completo)),
    Olive = as.integer(grepl("olive oil|azeite", texto_completo)),
    Honey = as.integer(grepl("honey|mel", texto_completo)),
    Cheese = as.integer(grepl("cheese|queijo", texto_completo)),
    
    # Aplicações
    Authentication = as.integer(grepl("authentication|authenticity|fraud", texto_completo)),
    Classification = as.integer(grepl("classification|classify", texto_completo)),
    OriginDetection = as.integer(grepl("origin|provenance|geographical", texto_completo)),
    
    # Regiões
    Europe = as.integer(grepl("europe|italy|france|spain|portugal", texto_completo)),
    Asia = as.integer(grepl("asia|china|japan|korea", texto_completo)),
    Americas = as.integer(grepl("america|usa|brazil|canada", texto_completo)),
    
    stringsAsFactors = FALSE
  )
  
  cat(sprintf("✓ Total de estudos extraídos: %d\n\n", nrow(dados)))
  return(dados)
}

################################################################################
# FUNÇÃO: Determinar k ótimo
################################################################################
determinar_k_otimo <- function(features_scaled, k_max = 10) {
  cat("🔬 Determinando número ótimo de clusters...\n")
  
  # Método Elbow
  wss <- sapply(1:k_max, function(k) {
    kmeans(features_scaled, centers = k, nstart = 25)$tot.withinss
  })
  
  # Silhouette
  sil_width <- sapply(2:k_max, function(k) {
    km <- kmeans(features_scaled, centers = k, nstart = 25)
    ss <- silhouette(km$cluster, dist(features_scaled))
    mean(ss[, 3])
  })
  
  # Plots
  p1 <- ggplot(data.frame(k = 1:k_max, WSS = wss), aes(x = k, y = WSS)) +
    geom_line(color = "#2E86AB", size = 1.2) +
    geom_point(color = "#2E86AB", size = 3) +
    labs(title = "Elbow Method", x = "Number of Clusters (k)", y = "Within-Cluster Sum of Squares") +
    theme_minimal(base_size = 12) +
    theme(plot.title = element_text(face = "bold", hjust = 0.5))
  
  p2 <- ggplot(data.frame(k = 2:k_max, Silhouette = sil_width), aes(x = k, y = Silhouette)) +
    geom_line(color = "#A23B72", size = 1.2) +
    geom_point(color = "#A23B72", size = 3) +
    labs(title = "Silhouette Score", x = "Number of Clusters (k)", y = "Average Silhouette Width") +
    theme_minimal(base_size = 12) +
    theme(plot.title = element_text(face = "bold", hjust = 0.5))
  
  combined <- p1 | p2
  ggsave("cluster_elbow_silhouette.png", plot = combined, width = 12, height = 5, dpi = 300)
  
  k_otimo <- which.max(sil_width) + 1
  cat(sprintf("✓ k ótimo sugerido: %d (Silhouette = %.3f)\n\n", k_otimo, max(sil_width)))
  
  return(k_otimo)
}

################################################################################
# FUNÇÃO: K-Means Clustering
################################################################################
executar_kmeans <- function(features_scaled, k) {
  cat(sprintf("🔬 Executando K-Means com k=%d...\n", k))
  
  set.seed(42)
  kmeans_result <- kmeans(features_scaled, centers = k, nstart = 50, iter.max = 100)
  
  cat(sprintf("✓ K-Means concluído: %d clusters\n", k))
  cat(sprintf("  Between SS / Total SS: %.2f%%\n\n", 
              100 * kmeans_result$betweenss / kmeans_result$totss))
  
  return(kmeans_result)
}

################################################################################
# FUNÇÃO: Visualizar K-Means
################################################################################
plot_kmeans <- function(features_scaled, kmeans_result, dados, output_file = "cluster_kmeans_scatter.png") {
  cat("📊 Gerando visualização K-Means...\n")
  
  # PCA para redução dimensional
  pca <- prcomp(features_scaled)
  pca_data <- data.frame(
    PC1 = pca$x[, 1],
    PC2 = pca$x[, 2],
    Cluster = as.factor(kmeans_result$cluster),
    Ano = dados$Ano
  )
  
  p <- ggplot(pca_data, aes(x = PC1, y = PC2, color = Cluster)) +
    geom_point(size = 3, alpha = 0.7) +
    stat_ellipse(aes(fill = Cluster), geom = "polygon", alpha = 0.15, level = 0.95) +
    scale_color_viridis_d(option = "plasma", begin = 0.1, end = 0.9) +
    scale_fill_viridis_d(option = "plasma", begin = 0.1, end = 0.9) +
    labs(
      title = "K-Means Clustering no Espaço PCA",
      subtitle = sprintf("%d clusters identificados", length(unique(kmeans_result$cluster))),
      x = sprintf("PC1 (%.1f%% da variância)", 100 * summary(pca)$importance[2, 1]),
      y = sprintf("PC2 (%.1f%% da variância)", 100 * summary(pca)$importance[2, 2]),
      color = "Cluster",
      fill = "Cluster"
    ) +
    theme_minimal(base_size = 14) +
    theme(
      plot.title = element_text(face = "bold", size = 16, hjust = 0.5),
      plot.subtitle = element_text(hjust = 0.5, color = "gray40"),
      legend.position = "right",
      panel.grid.minor = element_blank()
    )
  
  ggsave(output_file, plot = p, width = 12, height = 8, dpi = 300)
  cat(sprintf("✓ Visualização K-Means salva: %s\n", output_file))
}

################################################################################
# FUNÇÃO: Clustering Hierárquico
################################################################################
executar_clustering_hierarquico <- function(features_scaled, k) {
  cat("🔬 Executando Clustering Hierárquico...\n")
  
  # Calcular matriz de distâncias
  dist_matrix <- dist(features_scaled, method = "euclidean")
  
  # Clustering hierárquico (Ward)
  hc <- hclust(dist_matrix, method = "ward.D2")
  
  # Cortar dendrograma
  clusters <- cutree(hc, k = k)
  
  cat(sprintf("✓ Clustering Hierárquico concluído: %d clusters\n\n", k))
  
  return(list(hc = hc, clusters = clusters))
}

################################################################################
# FUNÇÃO: Plot Dendrograma
################################################################################
plot_dendrogram <- function(hc_result, k, output_file = "cluster_dendrogram.png") {
  cat("📊 Gerando dendrograma...\n")
  
  # Converter para dendextend
  dend <- as.dendrogram(hc_result$hc)
  dend <- color_branches(dend, k = k, col = viridis(k, option = "plasma"))
  dend <- color_labels(dend, k = k, col = viridis(k, option = "plasma"))
  
  png(output_file, width = 3600, height = 2400, res = 300)
  par(mar = c(5, 4, 4, 2))
  plot(dend, 
       main = "Dendrograma - Clustering Hierárquico (Ward)",
       ylab = "Distância Euclidiana",
       cex.main = 1.5,
       cex.lab = 1.2)
  dev.off()
  
  cat(sprintf("✓ Dendrograma salvo: %s\n", output_file))
}

################################################################################
# FUNÇÃO: Heatmap de Perfis de Clusters
################################################################################
plot_heatmap_profiles <- function(dados, kmeans_result, output_file = "cluster_heatmap_profiles.png") {
  cat("📊 Gerando heatmap de perfis de clusters...\n")
  
  dados_cluster <- dados
  dados_cluster$Cluster <- as.factor(kmeans_result$cluster)

  features_cols <- setdiff(names(dados), c("ID", "Titulo", "Ano"))
  if (length(features_cols) == 0) {
    stop("❌ Erro: não há colunas de features para o heatmap.")
  }

  # Matriz: clusters (linhas) x features (colunas)
  cluster_profiles <- sapply(features_cols, function(col) {
    tapply(dados_cluster[[col]], dados_cluster$Cluster, mean, na.rm = TRUE)
  })
  # Garantir matriz mesmo quando só 1 feature
  cluster_profiles <- as.matrix(cluster_profiles)

  # Transpor para ter features como linhas e clusters como colunas
  cluster_profiles_t <- t(cluster_profiles)
  
  # Gerar heatmap
  png(output_file, width = 2400, height = 3000, res = 300)
  
  # Criar margem extra para os rótulos dos eixos
  par(oma = c(3, 3, 2, 0))
  
  pheatmap(
    cluster_profiles_t,
    color = colorRampPalette(c("#3B4992", "#FFFFFF", "#EE0000"))(100),
    cluster_rows = TRUE,
    cluster_cols = FALSE,
    fontsize = 10,
    fontsize_row = 9,
    fontsize_col = 12,
    main = "Feature Profile per Cluster",
    angle_col = 0,
    border_color = NA,
    cellwidth = 30,
    cellheight = 10,
    legend_breaks = seq(0, 1, 0.25),
    legend_labels = c("0%", "25%", "50%", "75%", "100%"),
    legend = TRUE,
    annotation_legend = TRUE
  )
  
  # Adicionar rótulos dos eixos e legenda usando grid
  grid.text("Identified Clusters", x = 0.5, y = 0.02, 
            gp = gpar(fontsize = 13, fontface = "bold"))
  grid.text("Methodological Features", x = 0.02, y = 0.5, rot = 90,
            gp = gpar(fontsize = 13, fontface = "bold"))
  
  # Adicionar título da legenda
  grid.text("Mean Occurrence\n(Proportion)", x = 0.92, y = 0.78, 
            gp = gpar(fontsize = 10, fontface = "bold"))
  
  dev.off()
  
  cat(sprintf("✓ Heatmap de perfis salvo: %s\n", output_file))
}

################################################################################
# FUNÇÃO: Relatório
################################################################################
gerar_relatorio <- function(dados, kmeans_result, hc_result, output_file = "cluster_relatorio.txt") {
  cat("\n📝 Gerando relatório estatístico...\n")
  
  dados_cluster <- dados
  dados_cluster$Cluster_KMeans <- as.factor(kmeans_result$cluster)
  dados_cluster$Cluster_HC <- as.factor(hc_result$clusters)
  
  sink(output_file)
  cat("================================================================================\n")
  cat("RELATÓRIO DE ANÁLISE DE CLUSTERS - ML PARA INDICAÇÕES GEOGRÁFICAS\n")
  cat("================================================================================\n\n")
  cat(sprintf("Data de execução: %s\n", Sys.time()))
  cat(sprintf("Total de observações: %d\n", nrow(dados)))
  cat(sprintf("Número de clusters: %d\n\n", length(unique(kmeans_result$cluster))))
  
  cat("--------------------------------------------------------------------------------\n")
  cat("K-MEANS CLUSTERING - ESTATÍSTICAS\n")
  cat("--------------------------------------------------------------------------------\n")
  cat(sprintf("Between SS / Total SS: %.2f%%\n", 
              100 * kmeans_result$betweenss / kmeans_result$totss))
  cat(sprintf("Total Within SS: %.2f\n\n", kmeans_result$tot.withinss))
  
  cat("Tamanho dos clusters (K-Means):\n")
  print(table(kmeans_result$cluster))
  cat("\n")
  
  cat("--------------------------------------------------------------------------------\n")
  cat("CLUSTERING HIERÁRQUICO - ESTATÍSTICAS\n")
  cat("--------------------------------------------------------------------------------\n")
  cat("Tamanho dos clusters (Hierárquico):\n")
  print(table(hc_result$clusters))
  cat("\n")
  
  cat("--------------------------------------------------------------------------------\n")
  cat("PERFIL DOS CLUSTERS (K-Means) - Características Dominantes\n")
  cat("--------------------------------------------------------------------------------\n")
  
  features_cols <- setdiff(names(dados), c("ID", "Titulo", "Ano"))
  
  for (k in sort(unique(kmeans_result$cluster))) {
    cat(sprintf("\n=== CLUSTER %d (n=%d) ===\n", k, sum(kmeans_result$cluster == k)))

    cluster_subset <- dados_cluster[dados_cluster$Cluster_KMeans == k, features_cols, drop = FALSE]
    medias <- colMeans(cluster_subset, na.rm = TRUE)
    cluster_data <- data.frame(Feature = names(medias), Media = as.numeric(medias), row.names = NULL)
    cluster_data <- cluster_data[order(-cluster_data$Media), , drop = FALSE]

    cat("\nTop 10 características mais frequentes:\n")
    print(head(cluster_data, 10))
  }
  
  cat("\n================================================================================\n")
  sink()
  
  cat(sprintf("✓ Relatório estatístico salvo: %s\n", output_file))
}

################################################################################
# FUNÇÃO: Salvar dados
################################################################################
salvar_dados <- function(dados, kmeans_result, hc_result) {
  dados_resultado <- dados
  dados_resultado$Cluster_KMeans <- kmeans_result$cluster
  dados_resultado$Cluster_Hierarquico <- hc_result$clusters
  
  write.csv(dados_resultado, "cluster_resultados.csv", row.names = FALSE)
  cat("\n✓ Dados salvos: cluster_resultados.csv\n")
}

################################################################################
# EXECUÇÃO PRINCIPAL
################################################################################
main <- function() {
  # Diretórios (portável e independente do diretório atual)
  get_script_dir <- function() {
    args <- commandArgs(trailingOnly = FALSE)
    file_arg <- grep("^--file=", args, value = TRUE)
    if (length(file_arg) > 0) {
      script_path <- sub("^--file=", "", file_arg[1])
      return(normalizePath(dirname(script_path), winslash = "/", mustWork = FALSE))
    }
    return(normalizePath(getwd(), winslash = "/", mustWork = FALSE))
  }

  script_dir <- get_script_dir()
  sat_root <- normalizePath(file.path(script_dir, "..", ".."), winslash = "/", mustWork = FALSE)
  cat(sprintf("[03_cluster_analysis] sat_root=%s\n", sat_root))

  clusters_dir <- file.path(sat_root, "2-DADOS", "1-ESTATISTICA", "1-RSTUDIO", "3-CLUSTERS")
  fig_dir_en <- file.path(sat_root, "2-FIGURAS", "2-EN")
  dir.create(clusters_dir, recursive = TRUE, showWarnings = FALSE)
  dir.create(fig_dir_en, recursive = TRUE, showWarnings = FALSE)
  setwd(clusters_dir)

  # Corpus bibliográfico filtrado
  caminho_bib <- file.path(sat_root, "2-DADOS", "referencias_filtradas", "referencias_scopus_wos_filtradas.bib")
  
  if (!file.exists(caminho_bib)) {
    stop("❌ Erro: Arquivo .bib não encontrado em: ", caminho_bib)
  }
  
  # 1. Extrair dados
  dados <- extrair_dados_clustering(caminho_bib)
  
  # 2. Preparar features
  features <- dados[, setdiff(names(dados), c("ID", "Titulo", "Ano")), drop = FALSE]

  # Remover colunas constantes (variância zero) que geram NaN no scale()
  col_var <- apply(features, 2, var, na.rm = TRUE)
  keep_cols <- is.finite(col_var) & col_var > 0
  if (sum(keep_cols) < 2) {
    stop("❌ Erro: poucas features informativas após remover colunas constantes.")
  }
  features_use <- features[, keep_cols, drop = FALSE]
  features_scaled <- scale(features_use)
  features_scaled[is.na(features_scaled)] <- 0
  
  # 3. Determinar k ótimo
  k_otimo <- determinar_k_otimo(features_scaled, k_max = 10)
  
  # 4. K-Means
  kmeans_result <- executar_kmeans(features_scaled, k = k_otimo)
  
  # 5. Clustering Hierárquico
  hc_result <- executar_clustering_hierarquico(features_scaled, k = k_otimo)
  
  # 6. Visualizações
  cat("📊 Gerando visualizações...\n")
  plot_kmeans(features_scaled, kmeans_result, dados)
  plot_dendrogram(hc_result, k = k_otimo, output_file = "cluster_dendrogram.png")
  plot_heatmap_profiles(dados, kmeans_result, output_file = "cluster_heatmap_profiles.png")

  # Exportar figura principal para a pasta do manuscrito (EN)
  heatmap_src <- file.path(getwd(), "cluster_heatmap_profiles.png")
  heatmap_dst <- file.path(fig_dir_en, "cluster_heatmap_profiles.png")
  if (file.exists(heatmap_src)) {
    file.copy(heatmap_src, heatmap_dst, overwrite = TRUE)
    cat(sprintf("✓ Figura do manuscrito salva: %s\n", heatmap_dst))
  } else {
    warning("Heatmap não foi gerado em: ", heatmap_src)
  }
  
  # 7. Relatório
  gerar_relatorio(dados, kmeans_result, hc_result)
  
  # 8. Salvar dados
  salvar_dados(dados, kmeans_result, hc_result)
  
  cat("\n")
  cat("================================================================================\n")
  cat("✅ ANÁLISE DE CLUSTERS CONCLUÍDA COM SUCESSO!\n")
  cat("================================================================================\n")
}

tryCatch({
  main()
}, error = function(e) {
  cat("\n❌ ERRO durante a execução:\n")
  cat(conditionMessage(e), "\n")
  quit(status = 1, save = "no")
})
