# =============================================================================
# MCA Temporal – Script Revisado, Otimizado e Organizado
# Autor: Diego Vidal
# =============================================================================

library(FactoMineR)
library(factoextra)
library(ggplot2)
library(dplyr)

# Garantir paths relativos ao arquivo do script (para execuções via Rscript)
args <- commandArgs(trailingOnly = FALSE)
script_path <- sub("^--file=", "", args[grep("^--file=", args)])
if (length(script_path) > 0) {
  script_dir <- dirname(normalizePath(script_path))
  setwd(script_dir)
}

# =============================================================================
# 1. CARREGAMENTO DOS DADOS
# =============================================================================

data_completo <- read.csv(
  "model_dados_completos.csv"
)

cat("✓ Dados carregados — linhas:", nrow(data_completo), " | colunas:", ncol(data_completo), "\n")


# =============================================================================
# 2. FUNÇÕES AUXILIARES PARA CONVERSÃO
# =============================================================================

criar_categoria_binaria <- function(df, colunas, mapa, default = "Other") {
  apply(df[, colunas], 1, function(x) {
    idx <- which(x == 1)
    if (length(idx) == 0) return(default)
    valores <- mapa[colunas[idx]]
    if (length(valores) > 1) return(paste(valores, collapse = "+"))
    return(valores)
  })
}

# =============================================================================
# 3. CRIAÇÃO DE CATEGORIAS
# =============================================================================

# Mapas
algo_map <- c(RandomForest="RF", SVM="SVM", NeuralNetwork="NN",
              KNN="KNN", DecisionTree="DT", GradientBoosting="GB",
              EnsembleMethods="EM")

instr_map <- c(NIR="NIR", FTIR="FTIR", GCMS="GC-MS",
               LCMS="LC-MS", ICPMS="ICP-MS", NMR="NMR",
               Spectroscopy="Spec")

prod_map <- c(Wine="Wine", Coffee="Coffee", Olive="Olive",
              Honey="Honey", Cheese="Cheese")

app_map <- c(Authentication="Auth", Classification="Class",
             OriginDetection="OrgDet", QualityControl="QC")

regioes <- c("Europe", "Asia", "Americas")

# Aplicação das funções
data_completo$Algoritmo  <- criar_categoria_binaria(data_completo, names(algo_map), algo_map)
data_completo$Instrumento <- criar_categoria_binaria(data_completo, names(instr_map), instr_map)
data_completo$Produto     <- criar_categoria_binaria(data_completo, names(prod_map), prod_map)
data_completo$Aplicacao   <- criar_categoria_binaria(data_completo, names(app_map), app_map)

# Região
data_completo$Regiao <- apply(data_completo[, regioes], 1, function(x) {
  idx <- which(x == 1)
  if (length(idx) != 1) return("Global")
  return(regioes[idx])
})

# Período
data_completo$Periodo <- cut(
  data_completo$Ano,
  breaks = c(2009, 2018, 2021, 2025),
  labels = c("2010-18", "2019-21", "2022-25"),
  include.lowest = TRUE
)

cat("✓ Categorias criadas!\n")


# =============================================================================
# 4. PREPARAÇÃO DOS DADOS PARA MCA
# =============================================================================

vars_mca <- c("Algoritmo", "Instrumento", "Produto", "Aplicacao", "Regiao")
mca_data <- data_completo[, c(vars_mca, "Periodo")]

mca_data[] <- lapply(mca_data, as.factor)

cat("Dataset MCA:", dim(mca_data), "\n")


# =============================================================================
# 5. EXECUÇÃO DA MCA
# =============================================================================

res.mca <- MCA(mca_data[, vars_mca], graph = FALSE, ncp = 5)

cat("Inércia Dim1:", round(res.mca$eig[1, 2], 2), "%\n")
cat("Inércia Dim2:", round(res.mca$eig[2, 2], 2), "%\n")


# =============================================================================
# 6. PREPARAR COORDENADAS PARA PLOT
# =============================================================================

coord_ind <- res.mca$ind$coord[, 1:2]
coord_var <- res.mca$var$coord[, 1:2]

dados_plot <- data.frame(
  Dim1 = coord_ind[, 1],
  Dim2 = coord_ind[, 2],
  Periodo = mca_data$Periodo,
  Algoritmo = data_completo$Algoritmo,
  Instrumento = data_completo$Instrumento,
  Produto = data_completo$Produto,
  Aplicacao = data_completo$Aplicacao
)

# Determinar o TIPO principal de cada estudo (Algoritmo, Instrumento ou Aplicação)
dados_plot$Tipo <- apply(dados_plot[, c("Algoritmo", "Instrumento", "Aplicacao")], 1, function(row) {
  if (row["Algoritmo"] != "Other") return("Algorithm")
  if (row["Instrumento"] != "Other") return("Instrument")
  if (row["Aplicacao"] != "Other") return("Application")
  return("Other")
})

# Filtrar ponto outlier (Cheese com Dim1 > 7)
dados_plot <- dados_plot[!(dados_plot$Produto == "Cheese" & dados_plot$Dim1 > 7), ]

var_labels <- data.frame(
  Dim1 = coord_var[, 1],
  Dim2 = coord_var[, 2],
  Label = rownames(coord_var)
)


# =============================================================================
# 7. IDENTIFICAÇÃO DE CATEGORIAS DE VARIÁVEIS
# =============================================================================

# Extrair apenas os nomes das variáveis (remover prefixos)
var_labels$VarName <- sapply(strsplit(var_labels$Label, "_"), function(x) {
  if(length(x) > 1) paste(x[-1], collapse = "_") else x[1]
})

algo_names <- algo_map
instr_names <- instr_map
prod_names <- prod_map
app_names  <- app_map
reg_names  <- regioes

var_labels$Category <- case_when(
  var_labels$VarName %in% algo_names ~ "Algorithm",
  var_labels$VarName %in% instr_names ~ "Instrument",
  var_labels$VarName %in% prod_names ~ "Product",
  var_labels$VarName %in% app_names  ~ "Application",
  var_labels$VarName %in% reg_names  ~ "Region",
  TRUE ~ "Other"
)

# Verificar distribuição das categorias
cat("\n=== DISTRIBUIÇÃO DAS CATEGORIAS ===\n")
print(table(var_labels$Category))

# Verificar se há duplicatas nos labels
cat("\n=== VERIFICAÇÃO DE DUPLICATAS ===\n")
duplicatas <- var_labels$Label[duplicated(var_labels$Label)]
if(length(duplicatas) > 0) {
  cat("Labels duplicados encontrados:", duplicatas, "\n")
} else {
  cat("Nenhuma duplicata encontrada nos labels.\n")
}

# Verificar quais labels estão sendo categorizados como "Other"
other_labels <- var_labels$Label[var_labels$Category == "Other"]
if(length(other_labels) > 0) {
  cat("\nLabels categorizados como 'Other':\n")
  print(unique(other_labels))
}

# Shapes distintos - APENAS 3 CATEGORIAS
shape_map <- c(
  "Algorithm" = 21,     # círculo
  "Instrument" = 22,    # quadrado
  "Application" = 24    # triângulo
)

# Fill para símbolos - APENAS 3 CATEGORIAS
fill_map <- c(
  "Algorithm" = "#FF9999",
  "Instrument" = "#99CCFF",
  "Application" = "#FFCC99"
)

# Cores para período
cores_periodo <- c(
  "2010-18" = "#1B9E77",
  "2019-21" = "#D95F02",
  "2022-25" = "#7570B3"
)

# =============================================================================
# 8. CRIAÇÃO DO BIPLOT — VERSÃO FINAL COM APENAS var_labels
# =============================================================================

biplot_final <- ggplot(dados_plot, aes(x = Dim1, y = Dim2)) +

  # Elipses representando os períodos temporais (95%)
  stat_ellipse(
    aes(color = Periodo, group = Periodo),
    alpha = 0.8,
    level = 0.95,
    type = "norm",
    linewidth = 1.5,
    fill = NA,
    show.legend = TRUE
  ) +

  # Pontos dos estudos com formas baseadas no Tipo
  geom_point(
    aes(shape = Tipo, fill = Tipo),
    size = 6,
    stroke = 0.5,
    alpha = 0.8
  ) +
  
  # Rótulos de produtos sobre os pontos
  geom_text(
    aes(label = ifelse(Produto != "Other", Produto, "")),
    size = 4.2,
    vjust = -1.2,
    color = "black",
    fontface = "bold"
  ) +

  # PONTOS DAS VARIÁVEIS — shapes e cores
  geom_point(
    data = var_labels,
    aes(x = Dim1, y = Dim2,
        shape = Category,
        fill = Category),
    size = 4.0,
    stroke = 0,
    color = NA,
    inherit.aes = FALSE
  ) +

  # Escalas
  scale_color_manual(values = cores_periodo, name = "Períodos Temporais") +
  scale_fill_manual(values = fill_map, name = "Categorias de Variáveis") +
  scale_shape_manual(values = shape_map, name = "Categorias de Variáveis") +

  # Fundo limpo da legenda
  theme(
    legend.key = element_rect(fill = "white", color = NA)
  ) +

  # Linhas de referência
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey70") +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey70") +

  # Limitar os eixos para focar na área principal
  coord_cartesian(xlim = c(-2, 2), ylim = c(-2, 2)) +

  # Títulos e texto
  labs(
    title = "Biplot da Análise de Correspondência Múltipla: Evolução das Aplicações de ML para Autenticação de Indicações Geográficas",
    subtitle = "Elipses (95%): períodos temporais | Formas: categorias de variáveis",
    x = paste0("Dimensão 1 (", round(res.mca$eig[1, 2], 2), "%)"),
    y = paste0("Dimensão 2 (", round(res.mca$eig[2, 2], 2), "%)")
  ) +

  # Tema
  theme_minimal(base_size = 11) +
  theme(
    plot.title = element_text(size = 13, face = "bold", hjust = 0.5),
    plot.subtitle = element_text(size = 11, hjust = 0.5, color = "grey40"),
    legend.position = "left",
    legend.title = element_text(face = "bold", size = 11),
    legend.text = element_text(size = 10),
    legend.key.size = unit(1.0, "cm"),
    panel.grid.minor = element_blank(),
    plot.margin = margin(10, 10, 10, 10)
  )

print(biplot_final)



# =============================================================================
# 9. SALVAR RESULTADOS
# =============================================================================

ggsave(
  "../../2-FIGURAS/2-EN/mca_biplot_temporal_completo.png",
  biplot_final,
  width = 28,
  height = 20,
  dpi = 300,
  units = "cm"
)

saveRDS(res.mca, "res_mca_temporal_completo.rds")

write.csv(
  data_completo[, c("Algoritmo", "Instrumento", "Produto", "Aplicacao",
                    "Regiao", "Periodo", "Ano")],
  "mca_dados_categorizados.csv",
  row.names = FALSE
)

cat("\n✓ Script final executado com sucesso!\n")
