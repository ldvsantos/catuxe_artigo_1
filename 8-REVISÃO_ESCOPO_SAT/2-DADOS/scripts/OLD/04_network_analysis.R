################################################################################
# NETWORK ANALYSIS (CO-OCCURRENCE NETWORKS) - GGPLOT2
# Machine Learning for Traditional Agricultural Systems (SAT)
#
# This script performs co-occurrence network analysis using igraph/ggraph
# and generates visualizations with ggplot2
#
# Outputs:
#   - network_completa.png (Complete co-occurrence network)
#   - network_algoritmo_produto.png (Specific network)
#   - network_instrumento_produto.png (Specific network)
#   - network_centrality_metrics.png (Centrality metrics)
#   - network_communities.png (Community detection)
#   - network_relatorio.txt (Network metrics)
#   - network_*.graphml (Files for import into Gephi)
################################################################################

rm(list = ls())
gc()

packages <- c("bib2df", "tidyverse", "igraph", "ggraph", "tidygraph", 
              "viridis", "patchwork", "scales")

for (pkg in packages) {
  if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
    install.packages(pkg, dependencies = TRUE, repos = "https://cloud.r-project.org")
    library(pkg, character.only = TRUE)
  }
}

cat("\n")
cat("================================================================================")
cat("NETWORK ANALYSIS (CO-OCCURRENCE NETWORKS) - GGRAPH + GGPLOT2\n")
cat("Machine Learning for Traditional Agricultural Systems (SAT)\n")
cat("================================================================================")

################################################################################
# FUNÇÃO: Extrair co-ocorrências
################################################################################
extrair_coocorrencias <- function(caminho_bib) {
  cat("📚 Extraindo co-ocorrências do arquivo .bib...\n")
  
  bib_data <- bib2df(caminho_bib)
  texto_completo <- tolower(paste(bib_data$TITLE, bib_data$ABSTRACT, bib_data$KEYWORDS, sep = " "))
  
  # Definir categorias
  algoritmos <- c("RandomForest", "SVM", "NeuralNetwork", "KNN", "DecisionTree", 
                  "GradientBoosting", "NaiveBayes", "LogisticRegression")
  instrumentos <- c("NIR", "FTIR", "GCMS", "LCMS", "ICPMS", "NMR", "Sensor")
  produtos <- c("Wine", "Coffee", "Olive", "Honey", "Cheese", "Tea", "Meat")
  regioes <- c("Europe", "Asia", "Americas", "Africa")
  
  # Detectar presença
  presenca <- data.frame(
    # Algoritmos
    RandomForest = grepl("random forest", texto_completo),
    SVM = grepl("svm|support vector", texto_completo),
    NeuralNetwork = grepl("neural|deep learning|cnn|lstm", texto_completo),
    KNN = grepl("k-nearest|knn", texto_completo),
    DecisionTree = grepl("decision tree", texto_completo),
    GradientBoosting = grepl("gradient boosting|xgboost", texto_completo),
    NaiveBayes = grepl("naive bayes", texto_completo),
    LogisticRegression = grepl("logistic regression", texto_completo),
    
    # Instrumentos
    NIR = grepl("nir\\b|near infrared", texto_completo),
    FTIR = grepl("ftir|fourier transform", texto_completo),
    GCMS = grepl("gc-ms|gas chromatography", texto_completo),
    LCMS = grepl("lc-ms|hplc|liquid chromatography", texto_completo),
    ICPMS = grepl("icp-ms|icp\\b", texto_completo),
    NMR = grepl("nmr|nuclear magnetic", texto_completo),
    Sensor = grepl("sensor|e-nose", texto_completo),
    
    # Produtos
    # Observação: usar limites de palavra (\\b) reduz falsos positivos.
    # Exemplo crítico: "tea" casa com "team" se não houver limite.
    Wine = grepl("\\bwine(s)?\\b|\\bvinho(s)?\\b", texto_completo),
    Coffee = grepl("\\bcoffee\\b|\\bcaf(e|é)\\b", texto_completo),
    Olive = grepl("\\bolive(s)?\\b|\\bolive\\s+oil\\b|\\bazeite\\b", texto_completo),
    Honey = grepl("\\bhoney\\b|\\bmel\\b", texto_completo),
    Cheese = grepl("\\bcheese\\b|\\bqueijo\\b", texto_completo),
    Tea = grepl("\\btea\\b|\\bchá\\b", texto_completo),
    Meat = grepl("\\bmeat\\b|\\bcarne\\b", texto_completo),
    
    # Regiões
    Europe = grepl("\\beurope\\b|\\bitaly\\b|\\bfrance\\b|\\bspain\\b|\\bportugal\\b", texto_completo),
    Asia = grepl("\\basia\\b|\\bchina\\b|\\bjapan\\b|\\bkorea\\b", texto_completo),
    Americas = grepl("\\bamerica(s)?\\b|\\busa\\b|\\bbrazil\\b|\\bcanada\\b", texto_completo),
    Africa = grepl("\\bafrica\\b", texto_completo)
  )
  
  cat(sprintf("✓ Total de estudos analisados: %d\n\n", nrow(presenca)))
  
  return(list(presenca = presenca, 
              algoritmos = algoritmos, 
              instrumentos = instrumentos, 
              produtos = produtos,
              regioes = regioes))
}

################################################################################
# FUNÇÃO: Construir rede de co-ocorrências
################################################################################
construir_rede <- function(presenca_data, min_coocorrencia = 3) {
  cat(sprintf("🔬 Construindo rede de co-ocorrências (mínimo: %d)...\n", min_coocorrencia))
  
  # Calcular matriz de co-ocorrências
  cooc_matrix <- t(as.matrix(presenca_data)) %*% as.matrix(presenca_data)
  
  # Remover diagonal (auto-conexões)
  diag(cooc_matrix) <- 0
  
  # Filtrar por mínimo de co-ocorrências
  cooc_matrix[cooc_matrix < min_coocorrencia] <- 0
  
  # Criar grafo
  g <- graph_from_adjacency_matrix(cooc_matrix, mode = "undirected", 
                                    weighted = TRUE, diag = FALSE)
  
  # Remover nós isolados
  g <- delete.vertices(g, degree(g) == 0)
  
  cat(sprintf("✓ Rede construída: %d nós, %d arestas\n\n", vcount(g), ecount(g)))
  
  return(g)
}

################################################################################
# FUNÇÃO: Calcular métricas de rede
################################################################################
calcular_metricas_rede <- function(g) {
  cat("📊 Calculando métricas de rede...\n")
  
  metricas <- data.frame(
    Node = V(g)$name,
    Degree = degree(g),
    Betweenness = betweenness(g, normalized = TRUE),
    Closeness = closeness(g, normalized = TRUE),
    Eigenvector = eigen_centrality(g)$vector,
    stringsAsFactors = FALSE
  )
  
  metricas <- metricas %>% arrange(desc(Degree))
  
  cat("✓ Métricas calculadas\n\n")
  
  return(metricas)
}

################################################################################
# FUNÇÃO: Detectar comunidades
################################################################################
detectar_comunidades <- function(g) {
  cat("🔬 Detectando comunidades (Louvain)...\n")
  
  communities <- cluster_louvain(g)
  V(g)$community <- membership(communities)
  
  cat(sprintf("✓ Comunidades detectadas: %d\n", length(unique(V(g)$community))))
  cat(sprintf("  Modularidade: %.3f\n\n", modularity(communities)))
  
  return(g)
}

################################################################################
# FUNÇÃO: Plot da rede completa
################################################################################
plot_network_completa <- function(g, output_file = "../../2-FIGURAS/2-EN/network_completa.png") {
  cat("📊 Gerando visualização da rede completa...\n")
  dir.create(dirname(output_file), recursive = TRUE, showWarnings = FALSE)
  V(g)$degree <- degree(g)
  V(g)$community <- as.factor(V(g)$community)
  
  # Converter para tidygraph
  tg <- as_tbl_graph(g)
  
  p <- ggraph(tg, layout = "fr") +
    geom_edge_link(aes(width = weight, alpha = weight), color = "gray30", show.legend = TRUE) +
    geom_node_point(aes(size = degree, color = community), alpha = 0.9, show.legend = TRUE) +
    geom_node_text(aes(label = name), repel = TRUE, size = 7, fontface = "bold", color = "gray10", show.legend = FALSE) +
    scale_edge_width(range = c(0.9, 3.6), name = "Weight") +
    scale_edge_alpha(range = c(0.35, 0.85), guide = "none") +
    scale_size_continuous(range = c(5, 18), name = "Degree") +
    scale_color_viridis_d(
      option = "plasma",
      begin = 0.1,
      end = 0.9,
      name = "Community",
      labels = function(x) paste("Community", x)
    ) +
    theme_graph(base_family = "sans", base_size = 22) +
    theme(
      legend.position = "right",
      legend.title = element_text(size = 18, face = "bold"),
      legend.text = element_text(size = 16)
    )
  
  ggsave(output_file, plot = p, width = 20, height = 16, dpi = 600, bg = "white")
  cat(sprintf("✓ Rede completa salva: %s\n", output_file))
}

################################################################################
# FUNÇÃO: Plot de rede específica (Algoritmo × Produto)
################################################################################
plot_network_especifica <- function(presenca_data, categorias1, categorias2, 
                                     titulo, output_file, min_cooc = 2,
                                     type1_label = "Type 1", type2_label = "Type 2") {
  cat(sprintf("📊 Gerando rede: %s...\n", titulo))
  dir.create(dirname(output_file), recursive = TRUE, showWarnings = FALSE)
  
  # Selecionar apenas categorias relevantes (remover espaços do nome GC-MS)
  categorias1 <- gsub("-", "", categorias1)
  categorias2 <- gsub("-", "", categorias2)
  
  # Verificar quais colunas existem
  cols <- c(categorias1, categorias2)
  cols_existentes <- cols[cols %in% colnames(presenca_data)]
  
  if (length(cols_existentes) < 2) {
    cat(sprintf("⚠️  Pulando %s - colunas insuficientes\n", output_file))
    return(invisible(NULL))
  }
  
  presenca_sub <- presenca_data[, cols_existentes]
  
  # Construir rede
  cooc_matrix <- t(as.matrix(presenca_sub)) %*% as.matrix(presenca_sub)
  diag(cooc_matrix) <- 0
  cooc_matrix[cooc_matrix < min_cooc] <- 0
  
  g_sub <- graph_from_adjacency_matrix(cooc_matrix, mode = "undirected", 
                                       weighted = TRUE, diag = FALSE)
  g_sub <- delete.vertices(g_sub, degree(g_sub) == 0)
  
  # Adicionar atributos de tipo
  V(g_sub)$node_type <- ifelse(V(g_sub)$name %in% categorias1, type1_label, type2_label)
  
  # Plot
  tg <- as_tbl_graph(g_sub)
  
  p <- ggraph(tg, layout = "kk") +
    geom_edge_link(aes(width = weight, alpha = weight), color = "gray35") +
    geom_node_point(aes(size = centrality_degree(), color = node_type), alpha = 0.9) +
    geom_node_text(aes(label = name), repel = TRUE, size = 6, fontface = "bold", color = "gray10") +
    scale_edge_width(range = c(0.9, 3.6), name = "Weight") +
    scale_edge_alpha(range = c(0.35, 0.85), guide = "none") +
    scale_size_continuous(range = c(5, 18), name = "Degree") +
    scale_color_brewer(palette = "Set1", name = "Category") +
    labs(title = titulo) +
    theme_graph(base_family = "sans", base_size = 22) +
    theme(
      plot.title = element_text(face = "bold", size = 20, hjust = 0.5),
      legend.position = "right",
      legend.title = element_text(size = 18, face = "bold"),
      legend.text = element_text(size = 16)
    )
  
  ggsave(output_file, plot = p, width = 20, height = 16, dpi = 600, bg = "white")
  cat(sprintf("✓ Rede salva: %s\n", output_file))
}

################################################################################
# FUNÇÃO: Plot de métricas de centralidade
################################################################################
plot_centrality_metrics <- function(metricas, output_file = "../../2-FIGURAS/2-EN/network_centrality_metrics.png") {
  cat("📊 Gerando visualização de métricas de centralidade...\n")
  dir.create(dirname(output_file), recursive = TRUE, showWarnings = FALSE)
  
  # Top 15 nós por grau
  top_nodes <- head(metricas, 15)
  
  # Preparar dados
  metricas_long <- top_nodes %>%
    select(Node, Degree, Betweenness, Closeness, Eigenvector) %>%
    pivot_longer(-Node, names_to = "Metric", values_to = "Value")
  
  p <- ggplot(metricas_long, aes(x = reorder(Node, Value), y = Value, fill = Metric)) +
    geom_col(alpha = 0.8) +
    coord_flip() +
    facet_wrap(~Metric, scales = "free_x") +
    scale_fill_viridis_d(option = "plasma") +
    labs(
      title = "Centrality metrics (Top 15 nodes)",
      x = "Node",
      y = "Value"
    ) +
    theme_minimal(base_size = 18) +
    theme(
      plot.title = element_text(face = "bold", size = 20, hjust = 0.5),
      legend.position = "none",
      strip.text = element_text(face = "bold", size = 16)
    )
  
  ggsave(output_file, plot = p, width = 18, height = 12, dpi = 600, bg = "white")
  cat(sprintf("✓ Métricas de centralidade salvas: %s\n", output_file))
}

################################################################################
# FUNÇÃO: Plot de comunidades
################################################################################
plot_communities <- function(g, output_file = "../../2-FIGURAS/2-EN/network_communities.png") {
  cat("📊 Gerando visualização de comunidades...\n")
  dir.create(dirname(output_file), recursive = TRUE, showWarnings = FALSE)
  V(g)$degree <- degree(g)
  V(g)$community <- as.factor(V(g)$community)
  
  tg <- as_tbl_graph(g)
  
  p <- ggraph(tg, layout = "fr") +
    geom_edge_link(aes(width = weight, alpha = weight), color = "gray30", show.legend = TRUE) +
    geom_node_point(
      aes(size = degree, color = community),
      alpha = 0.9,
      show.legend = TRUE
    ) +
    geom_node_text(
      aes(label = name),
      repel = TRUE,
      size = 6,
      fontface = "bold",
      color = "gray10",
      show.legend = FALSE
    ) +
    scale_edge_width(range = c(0.9, 3.6), name = "Weight") +
    scale_edge_alpha(range = c(0.35, 0.85), guide = "none") +
    scale_size_continuous(range = c(5, 18), name = "Degree") +
    scale_color_viridis_d(
      option = "turbo",
      begin = 0.1,
      end = 0.9,
      name = "Community",
      labels = function(x) paste("Community", x)
    ) +
    theme_graph(base_family = "sans", base_size = 24) +
    theme(
      legend.position = "right",
      legend.title = element_text(size = 18, face = "bold"),
      legend.text = element_text(size = 16)
    )
  
  ggsave(output_file, plot = p, width = 20, height = 16, dpi = 600, bg = "white")
  cat(sprintf("✓ Comunidades salvas: %s\n", output_file))
}

################################################################################
# FUNÇÃO: Relatório
################################################################################
gerar_relatorio <- function(g, metricas, output_file = "network_relatorio.txt") {
  cat("\n📝 Gerando relatório estatístico...\n")
  
  sink(output_file)
  cat("================================================================================")
  cat("NETWORK ANALYSIS REPORT - ML FOR SAT\n")
  cat("================================================================================")
  cat(sprintf("Execution date: %s\n\n", Sys.time()))
  
  cat("--------------------------------------------------------------------------------\n")
  cat("GENERAL NETWORK STATISTICS\n")
  cat("--------------------------------------------------------------------------------\n")
  cat(sprintf("Number of nodes: %d\n", vcount(g)))
  cat(sprintf("Number of edges: %d\n", ecount(g)))
  cat(sprintf("Density: %.4f\n", edge_density(g)))
  cat(sprintf("Transitivity (clustering coefficient): %.4f\n", transitivity(g)))
  cat(sprintf("Network diameter: %d\n", diameter(g)))
  cat(sprintf("Average distance: %.2f\n\n", mean_distance(g)))
  
  cat("--------------------------------------------------------------------------------\n")
  cat("TOP 15 NÓS POR GRAU (DEGREE CENTRALITY)\n")
  cat("--------------------------------------------------------------------------------\n")
  print(head(metricas %>% select(Node, Degree) %>% arrange(desc(Degree)), 15))
  cat("\n")
  
  cat("--------------------------------------------------------------------------------\n")
  cat("TOP 15 NÓS POR BETWEENNESS CENTRALITY\n")
  cat("--------------------------------------------------------------------------------\n")
  print(head(metricas %>% select(Node, Betweenness) %>% arrange(desc(Betweenness)), 15))
  cat("\n")
  
  cat("--------------------------------------------------------------------------------\n")
  cat("TOP 15 NÓS POR EIGENVECTOR CENTRALITY\n")
  cat("--------------------------------------------------------------------------------\n")
  print(head(metricas %>% select(Node, Eigenvector) %>% arrange(desc(Eigenvector)), 15))
  cat("\n")
  
  cat("--------------------------------------------------------------------------------\n")
  cat("COMUNIDADES DETECTADAS (LOUVAIN)\n")
  cat("--------------------------------------------------------------------------------\n")
  communities_table <- table(V(g)$community)
  print(communities_table)
  cat("\n")
  
  for (comm in sort(unique(V(g)$community))) {
    cat(sprintf("\n=== COMUNIDADE %d (n=%d) ===\n", comm, sum(V(g)$community == comm)))
    nodes_comm <- V(g)$name[V(g)$community == comm]
    cat(paste(nodes_comm, collapse = ", "), "\n")
  }
  
  cat("\n================================================================================\n")
  sink()
  
  cat(sprintf("✓ Relatório estatístico salvo: %s\n", output_file))
}

################################################################################
# FUNÇÃO: Salvar grafo
################################################################################
salvar_grafo <- function(g, filename = "network_completa.graphml") {
  write_graph(g, filename, format = "graphml")
  cat(sprintf("✓ Grafo salvo: %s (importável em Gephi)\n", filename))
}

################################################################################
# EXECUÇÃO PRINCIPAL
################################################################################
main <- function() {
  caminho_bib <- "../referencias_filtradas/referencias_scopus_wos_filtradas.bib"
  
  if (!file.exists(caminho_bib)) {
    stop("❌ Erro: Arquivo .bib não encontrado em: ", caminho_bib)
  }
  
  # 1. Extrair co-ocorrências
  dados <- extrair_coocorrencias(caminho_bib)
  
  # 2. Construir rede completa
  g <- construir_rede(dados$presenca, min_coocorrencia = 3)
  
  # 3. Calcular métricas
  metricas <- calcular_metricas_rede(g)
  
  # 4. Detectar comunidades
  g <- detectar_comunidades(g)
  
  # 5. Visualizations
  cat("📊 Generating visualizations...\n")
  plot_network_completa(g)
  plot_network_especifica(dados$presenca, dados$algoritmos, dados$produtos,
                          "Algorithm × Product Network", "../../2-FIGURAS/2-EN/network_algoritmo_produto.png",
                          type1_label = "Algorithm", type2_label = "Product")
  plot_network_especifica(dados$presenca, dados$instrumentos, dados$produtos,
                          "Instrument × Product Network", "../../2-FIGURAS/2-EN/network_instrumento_produto.png",
                          type1_label = "Instrument", type2_label = "Product")
  plot_centrality_metrics(metricas)
  plot_communities(g)
  
  # 6. Relatório
  gerar_relatorio(g, metricas)
  
  # 7. Salvar grafo
  cat("\n")
  salvar_grafo(g)
  
  cat("\n")
  cat("================================================================================")
  cat("✅ NETWORK ANALYSIS COMPLETED SUCCESSFULLY!\n")
  cat("================================================================================")
}

if (sys.nframe() == 0) {
  tryCatch({
    main()
  }, error = function(e) {
    cat("\n❌ ERRO durante a execução:\n")
    cat(conditionMessage(e), "\n")
  })
}
