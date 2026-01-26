################################################################################
# ADVANCED VISUALIZATION OF LOUVAIN COMMUNITIES
# Machine Learning for Traditional Agricultural Systems (SAT)
#
# This script generates detailed visualizations of the three modules identified
# by the Louvain algorithm, creating a composite figure that complements
# Table 5 of the manuscript.
#
# Outputs:
#   - louvain_modules_detailed.png (Detailed figure of 3 modules)
#   - louvain_modules_summary.png (Summary figure for manuscript)
################################################################################

rm(list = ls())
gc()

# Garantir paths relativos ao arquivo do script (para execuções via Rscript)
args <- commandArgs(trailingOnly = FALSE)
script_path <- sub("^--file=", "", args[grep("^--file=", args)])
if (length(script_path) > 0) {
  script_dir <- dirname(normalizePath(script_path))
  setwd(script_dir)
}

packages <- c("bib2df", "tidyverse", "igraph", "ggraph", "tidygraph", 
              "viridis", "patchwork", "scales", "ggforce")

for (pkg in packages) {
  if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
    install.packages(pkg, dependencies = TRUE, repos = "https://cloud.r-project.org")
    library(pkg, character.only = TRUE)
  }
}

cat("\n")
cat("================================================================================\n")
cat("VISUALIZAÇÃO DETALHADA DAS COMUNIDADES DE LOUVAIN\n")
cat("Machine Learning aplicado a SAT\n")
cat("================================================================================\n\n")

################################################################################
# CARREGAR DADOS E REDE (reutilizando funções do script anterior)
################################################################################
source("04_network_analysis.R", encoding = "UTF-8")

# Construir rede
caminho_bib <- "../referencias_filtradas/referencias_scopus_wos_filtradas.bib"
dados <- extrair_coocorrencias(caminho_bib)
g <- construir_rede(dados$presenca, min_coocorrencia = 3)
g <- detectar_comunidades(g)

################################################################################
# FUNÇÃO: Criar visualização detalhada de um módulo específico
################################################################################
plot_module_detail <- function(g, module_id, module_name, module_color) {
  # Extrair nós do módulo
  nodes_in_module <- V(g)$name[V(g)$community == module_id]
  
  # Criar subgrafo
  g_sub <- induced_subgraph(g, V(g)[V(g)$community == module_id])
  
  # Adicionar categoria aos nós
  algoritmos <- c("RandomForest", "SVM", "NeuralNetwork", "KNN", "DecisionTree", 
                  "GradientBoosting")
  instrumentos <- c("NIR", "FTIR", "GCMS", "LCMS", "Sensor")
  produtos <- c("Wine", "Honey", "Meat", "Olive", "Cheese", "Tea")
  regioes <- c("Africa", "Asia", "Europe")
  
  V(g_sub)$category <- case_when(
    V(g_sub)$name %in% algoritmos ~ "Algorithm",
    V(g_sub)$name %in% instrumentos ~ "Instrument",
    V(g_sub)$name %in% produtos ~ "Product",
    V(g_sub)$name %in% regioes ~ "Region",
    TRUE ~ "Other"
  )
  
  # Converter para tidygraph
  tg <- as_tbl_graph(g_sub)
  
  # Plot
  p <- ggraph(tg, layout = "stress") +
    geom_edge_link(aes(width = weight), alpha = 0.6, color = "gray50") +
    geom_node_point(aes(size = degree(g_sub), color = V(g_sub)$category), 
                    alpha = 0.85, stroke = 1.5) +
    geom_node_text(aes(label = name), repel = TRUE, size = 5.6, 
                   fontface = "bold", max.overlaps = 20) +
    scale_edge_width(range = c(0.8, 3.5), guide = "none") +
    scale_size_continuous(range = c(5, 12), guide = "none") +
    scale_color_manual(
      values = c(
        "Algorithm" = "#E63946",
        "Instrument" = "#457B9D",
        "Product" = "#2A9D8F",
        "Region" = "#F4A261"
      )
    ) +
    labs(
      title = module_name,
      color = "Category"
    ) +
    theme_graph(base_family = "sans", base_size = 18) +
    theme(
      plot.title = element_text(face = "bold", size = 16, hjust = 0.5),
      legend.position = "none",
      plot.background = element_rect(fill = "white", color = NA),
      panel.background = element_rect(fill = "white", color = NA)
    )
  
  return(p)
}

################################################################################
# FUNÇÃO: Selecionar módulos (top N) e descrever
################################################################################
get_top_modules <- function(g, n = 3) {
  comm <- V(g)$community
  comm_ids <- sort(unique(comm))
  sizes <- sapply(comm_ids, function(id) sum(comm == id, na.rm = TRUE))
  comm_ids[order(sizes, decreasing = TRUE)][seq_len(min(n, length(comm_ids)))]
}

describe_module <- function(g, module_id, top_k = 3) {
  g_sub <- induced_subgraph(g, V(g)[V(g)$community == module_id])
  if (vcount(g_sub) == 0) return("(empty)")
  deg <- sort(degree(g_sub), decreasing = TRUE)
  top_nodes <- names(deg)[seq_len(min(top_k, length(deg)))]
  paste(top_nodes, collapse = " + ")
}

infer_module_theme <- function(node_names) {
  x <- tolower(node_names)
  has <- function(pattern) any(grepl(pattern, x, perl = TRUE))

  tags <- character(0)

  if (has("neural|deep|cnn|lstm|transformer")) tags <- c(tags, "Deep learning")
  if (has("svm|knn|randomforest|decisiontree|gradientboost|xgboost")) tags <- c(tags, "Classical ML")
  if (has("remote|sensing|landsat|sentinel|ndvi|gis|hyperspectral|nir|ftir|sar|satellite")) tags <- c(tags, "Remote sensing")
  if (has("spatial|geospatial|regional|region|mapping|gis|amazon|madagascar|vietnam|laos|brazil|china|india|americas|africa|asia|europe")) tags <- c(tags, "Spatial/Regional")
  if (has("sensor|iot|aiot")) tags <- c(tags, "Sensors/IoT")
  if (has("deforestation|land use|land-use|shifting cultivation|degradation")) tags <- c(tags, "Land-use dynamics")

  if (length(tags) == 0) return("Mixed")
  # manter no máximo 2 rótulos para não poluir
  unique(tags)[seq_len(min(2, length(unique(tags))))]
}

infer_module_label <- function(g, module_id) {
  g_sub <- induced_subgraph(g, V(g)[V(g)$community == module_id])
  if (vcount(g_sub) == 0) return("Empty")
  deg <- sort(degree(g_sub), decreasing = TRUE)
  top_nodes <- names(deg)[seq_len(min(10, length(deg)))]
  paste(infer_module_theme(top_nodes), collapse = " & ")
}

################################################################################
# FUNÇÃO: Criar figura composta dos três módulos
################################################################################
plot_three_modules <- function(g) {
  cat("📊 Generating visualization of three Louvain modules...\n")

  # Selecionar automaticamente os 3 maiores módulos existentes
  top_ids <- get_top_modules(g, n = 3)
  module_colors <- c("#E76F51", "#2A9D8F", "#264653")

  plots <- lapply(seq_along(top_ids), function(i) {
    id <- top_ids[i]
    theme_label <- infer_module_label(g, id)
    title <- sprintf("%s", theme_label)
    plot_module_detail(g, id, title, module_colors[i])
  })

  combined <- wrap_plots(plots, ncol = length(plots)) +
    plot_annotation(
      title = "Technological Modules Identified",
      theme = theme(
        plot.title = element_text(face = "bold", size = 18, hjust = 0.5)
      )
    )
  
  # Salvar
    ggsave("../../2-FIGURAS/2-EN/louvain_modules_detailed.png", plot = combined, 
      width = 18, height = 10, dpi = 600, bg = "white")
  
  cat("✓ Figura detalhada dos módulos salva: ../../2-FIGURAS/2-EN/louvain_modules_detailed.png\n")
  
  return(combined)
}

################################################################################
# FUNÇÃO: Criar figura resumo com anotações para manuscrito
################################################################################
plot_modules_summary <- function(g) {
  cat("📊 Generating summary figure for manuscript...\n")

  top_ids <- get_top_modules(g, n = 3)
  module_colors <- c("#E76F51", "#2A9D8F", "#264653")
  labels <- sapply(seq_along(top_ids), function(i) {
    infer_module_label(g, top_ids[i])
  })
  values_map <- setNames(module_colors[seq_along(top_ids)], as.character(top_ids))
  labels_map <- setNames(labels, as.character(top_ids))
  
  # Add more information to nodes
  V(g)$size_scaled <- degree(g)
  V(g)$module_name <- as.character(V(g)$community)
  
  # Converter para tidygraph
  tg <- as_tbl_graph(g)
  
  # Plot principal
  p <- ggraph(tg, layout = "fr") +
    geom_edge_link(aes(width = weight, alpha = weight), color = "gray60") +
    geom_node_point(aes(size = size_scaled, fill = as.factor(V(g)$community)),
                    shape = 21, color = "white", stroke = 1.2, alpha = 0.9) +
    geom_node_text(aes(label = name), repel = TRUE, size = 4.0,
                   fontface = "bold", max.overlaps = 25,
                   segment.color = "gray70", segment.size = 0.3) +
    scale_edge_width(range = c(0.3, 2.5), guide = "none") +
    scale_edge_alpha(range = c(0.3, 0.7), guide = "none") +
    scale_size_continuous(range = c(3, 15), guide = "none") +
    scale_fill_manual(
      name = "Technological Module",
      values = values_map,
      labels = labels_map
    ) +
    labs(
      title = "Technological Modules Identified"
    ) +
    theme_graph(base_family = "sans") +
    theme(
      plot.title = element_text(face = "bold", size = 16, hjust = 0.5, 
                                margin = margin(b = 5)),
      legend.position = "bottom",
      legend.title = element_text(face = "bold", size = 12),
      legend.text = element_text(size = 11),
      plot.background = element_rect(fill = "white", color = NA),
      panel.background = element_rect(fill = "white", color = NA),
      plot.margin = margin(15, 15, 15, 15)
    ) +
    guides(fill = guide_legend(override.aes = list(size = 6)))
  
  # Salvar
    ggsave("../../2-FIGURAS/2-EN/louvain_modules_summary.png", plot = p,
      width = 14, height = 10, dpi = 300, bg = "white")
  
  cat("✓ Figura resumo salva: louvain_modules_summary.png\n")
  
  return(p)
}

################################################################################
# FUNÇÃO: Criar tabela visual dos módulos (complemento à Tabela 5)
################################################################################
create_module_table_visual <- function(g) {
  cat("📊 Criando visualização em tabela dos módulos...\n")
  
  # Preparar dados
  modules_data <- tibble(
    Module = c("M1", "M2", "M3"),
    Size = c(6, 6, 8),
    Algorithms = c(
      "RandomForest\nDecisionTree\nGradient Boosting",
      "SVM\nKNN",
      "Neural Networks\nCNN\nDeep Learning"
    ),
    Techniques = c(
      "NIR\nQuimiometria",
      "GC-MS\nLC-MS\nHPLC",
      "NIR, FTIR\ne-nose"
    ),
    Products = c(
      "Vinho\nMel",
      "Carnes\nProdutos\nRegionais",
      "Azeite\nQueijo\nChá"
    ),
    Region = c("África\nEuropa", "Ásia", "Europa\nÁsia"),
    Color = c("#E76F51", "#2A9D8F", "#264653")
  )
  
  # Criar visualização
  p <- ggplot(modules_data, aes(x = 1, y = Module)) +
    geom_tile(aes(fill = Color), color = "white", size = 2, alpha = 0.3) +
    geom_text(aes(x = 0.7, label = paste0(Module, "\n(n=", Size, ")")),
              fontface = "bold", size = 5) +
    geom_text(aes(x = 1.3, label = Algorithms), size = 3.5, hjust = 0) +
    geom_text(aes(x = 2.0, label = Techniques), size = 3.5, hjust = 0) +
    geom_text(aes(x = 2.7, label = Products), size = 3.5, hjust = 0) +
    geom_text(aes(x = 3.3, label = Region), size = 3.5, hjust = 0) +
    scale_fill_identity() +
    scale_x_continuous(
      breaks = c(0.7, 1.3, 2.0, 2.7, 3.3),
      labels = c("Módulo", "Algoritmos", "Técnicas", "Produtos", "Região")
    ) +
    labs(
      title = "Composição dos Três Módulos Tecnológicos",
      subtitle = "Análise de Comunidades de Louvain"
    ) +
    theme_minimal(base_size = 9) +
    theme(
      plot.title = element_text(face = "bold", size = 11, hjust = 0.5),
      plot.subtitle = element_text(hjust = 0.5, color = "gray40"),
      axis.title = element_blank(),
      axis.text.y = element_blank(),
      axis.text.x = element_text(face = "bold", size = 9),
      panel.grid = element_blank(),
      plot.background = element_rect(fill = "white", color = NA)
    )
  
  ggsave("../../2-FIGURAS/2-EN/louvain_modules_table_visual.png", plot = p,
         width = 14, height = 6, dpi = 300, bg = "white")
  
  cat("✓ Tabela visual salva: ../../2-FIGURAS/2-EN/louvain_modules_table_visual.png\n")
  
  return(p)
}

################################################################################
# EXECUÇÃO PRINCIPAL
################################################################################
main_viz <- function() {
  cat("\n📊 Gerando visualizações avançadas das comunidades...\n\n")
  
  # 1. Figura detalhada dos três módulos lado a lado
  p_detailed <- plot_three_modules(g)
  
  # 2. Figura resumo para o manuscrito
  p_summary <- plot_modules_summary(g)
  
  # 3. Tabela visual
  p_table <- create_module_table_visual(g)
  
  cat("\n")
  cat("================================================================================")
  cat("✅ ADVANCED VISUALIZATIONS COMPLETED!\n")
  cat("================================================================================")
  cat("\nGenerated files:\n")
  cat("  1. louvain_modules_detailed.png - Detailed figure of 3 modules\n")
  cat("  2. louvain_modules_summary.png - Summary figure for manuscript\n")
  cat("  3. louvain_modules_table_visual.png - Complementary visual table\n")
  cat("\nRecommendation: Use louvain_modules_summary.png as Figure 9\n")
  cat("                Table 5 (markdown) remains in text\n")
  cat("================================================================================")
}

tryCatch({
  main_viz()
}, error = function(e) {
  cat("\n❌ ERRO durante a execução:\n")
  cat(conditionMessage(e), "\n")
})
