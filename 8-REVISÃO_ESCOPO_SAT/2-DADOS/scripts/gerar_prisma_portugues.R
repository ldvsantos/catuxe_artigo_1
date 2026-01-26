#!/usr/bin/env Rscript
# GERADOR DE FLUXOGRAMA PRISMA 2020 - VERSÃO EM PORTUGUÊS
# Script para gerar diagramas PRISMA 2020 profissionais em português
# PRISMA2020 baseado no repositório: https://github.com/prisma-flowdiagram/PRISMA2020
# Author: Versão traduzida para português
# Data: 2025

# Supprimir avisos
options(warn = -1)

# Configurar CRAN mirror
options(repos = c(CRAN = "https://cran.rstudio.com"))

# Verificar e instalar pacotes necessários
pacotes_necessarios <- c("devtools", "htmlwidgets", "DiagrammeR")

# Forçar reinstalação do magrittr
install.packages("magrittr", quiet = TRUE)

for (pacote in pacotes_necessarios) {
  if (!require(pacote, character.only = TRUE)) {
    cat(sprintf("📦 Instalando pacote: %s\n", pacote))
    install.packages(pacote, quiet = TRUE)
  }
}

# Forçar reinstalação do PRISMA2020
if (!require("PRISMA2020", character.only = TRUE)) {
    cat("📦 Instalando PRISMA2020 do GitHub...\n")
    devtools::install_github("prisma-flowdiagram/PRISMA2020", quiet = TRUE, force = TRUE)
}

library(PRISMA2020, quietly = TRUE)
library(htmlwidgets, quietly = TRUE)
library(DiagrammeR, quietly = TRUE)

# Carregar dados do CSV
cat("======================================================================\n")
cat("🔄 GERADOR DE FLUXOGRAMA PRISMA 2020 - VERSÃO EM PORTUGUÊS\n")
cat("======================================================================\n\n")

cat("📂 Gerando dados do PRISMA internamente...\n")

script_dir <- dirname(normalizePath(commandArgs(trailingOnly = FALSE)[4]))
setwd(script_dir)

csv_file <- "PRISMA.csv"

if (!file.exists(csv_file)) {
  cat(sprintf("❌ File %s not found!\n", csv_file))
  quit(status = 1)
}

cat(sprintf("📂 Carregando dados do PRISMA (template oficial) de: %s\n", csv_file))

# Ler o template oficial no formato esperado pelo PRISMA2020
data <- read.csv(csv_file, sep = ",", stringsAsFactors = FALSE, check.names = FALSE)

cat("✅ Dados carregados com sucesso\n\n")

# Traduzir textos para português
cat("🌍 Traduzindo textos para português...\n")

# Função para traduzir textos
traduzir_texto <- function(texto) {
  traducoes <- list(
    # Títulos das seções principais
    "Grey title box; Previous studies" = "Caixa cinza; Estudos anteriores",
    "Previous studies" = "Estudos anteriores",
    "Studies included in previous version of review" = "Estudos incluídos na versão anterior da revisão",
    "Reports of studies included in previous version of review" = "Relatórios de estudos incluídos na versão anterior da revisão",

    # Identificação
    "Yellow title box; Identification of new studies via databases and registers" = "Caixa amarela; Identificação de novos estudos via bases de dados e registros",
    "Identification of new studies via databases and registers" = "Identificação de novos estudos via bases de dados e registros",
    "Records identified from: Databases" = "Registros identificados de: Bases de dados",
    "Databases" = "Bases de dados",
    "Records identified from: Databases and Registers" = "Registros identificados de: Bases de dados e Registros",
    "Records identified from: specific databases" = "Registros identificados de: bases de dados específicas",
    "Specific Databases" = "Bases de dados específicas",
    "Records identified from: Registers" = "Registros identificados de: Registros",
    "Registers" = "Registros",
    "Records identified from: specific registers" = "Registros identificados de: registros específicos",
    "Specific Registers" = "Registros específicos",

    # Outros métodos
    "Grey title box; Identification of new studies via other methods" = "Caixa cinza; Identificação de novos estudos via outros métodos",
    "Identification of new studies via other methods" = "Identificação de novos estudos via outros métodos",
    "Records identified from: Websites" = "Registros identificados de: Sites web",
    "Websites" = "Sites web",
    "Records identified from: Websites, Organisations and Citation Searching" = "Registros identificados de: Sites web, Organizações e Busca por citações",
    "Records identified from: Organisations" = "Registros identificados de: Organizações",
    "Organisations" = "Organizações",
    "Records identified from: Citation searching" = "Registros identificados de: Busca por citações",
    "Citation searching" = "Busca por citações",

    # Triagem
    "Duplicate records" = "Registros duplicados",
    "Records marked as ineligible by automation tools" = "Registros marcados como inelegíveis por ferramentas automatizadas",
    "Records removed for other reasons" = "Registros removidos por outros motivos",
    "Records screened (databases and registers)" = "Registros triados (bases de dados e registros)",
    "Records screened" = "Registros triados",
    "Records excluded (databases and registers)" = "Registros excluídos (bases de dados e registros)",
    "Records excluded" = "Registros excluídos",

    # Elegibilidade
    "Reports sought for retrieval (databases and registers)" = "Relatórios procurados para recuperação (bases de dados e registros)",
    "Reports sought for retrieval" = "Relatórios procurados para recuperação",
    "Reports not retrieved (databases and registers)" = "Relatórios não recuperados (bases de dados e registros)",
    "Reports not retrieved" = "Relatórios não recuperados",
    "Reports assessed for eligibility (databases and registers)" = "Relatórios avaliados para elegibilidade (bases de dados e registros)",
    "Reports assessed for eligibility" = "Relatórios avaliados para elegibilidade",
    "Reports excluded (databases and registers)" = "Relatórios excluídos (bases de dados e registros)",
    "Reports excluded" = "Relatórios excluídos",

    # Outros métodos de elegibilidade
    "Reports sought for retrieval (other)" = "Relatórios procurados para recuperação (outros)",
    "Reports not retrieved (other)" = "Relatórios não recuperados (outros)",
    "Reports assessed for eligibility (other)" = "Relatórios avaliados para elegibilidade (outros)",
    "Reports excluded (other)" = "Relatórios excluídos (outros)",

    # Inclusão
    "New studies included in review" = "Novos estudos incluídos na revisão",
    "Reports of new included studies" = "Relatórios de novos estudos incluídos",
    "Total studies included in review" = "Total de estudos incluídos na revisão",
    "Reports of total included studies" = "Relatórios do total de estudos incluídos",
    "Total studies included in meta-analysis" = "Total de estudos incluídos na meta-análise",
    "Reports of total included studies in meta-analysis" = "Relatórios do total de estudos incluídos na meta-análise",

    # Títulos das fases
    "Blue identification box" = "Caixa azul de identificação",
    "Blue screening box" = "Caixa azul de triagem",
    "Blue included box" = "Caixa azul de inclusão",

    # Boxes principais
    "Previous studies" = "Estudos anteriores",
    "Identification" = "Identificação",
    "Screening" = "Triagem",
    "Included" = "Incluídos",
    "Duplicate records" = "Registros duplicados",
    "Records screened" = "Registros triados",
    "Records excluded" = "Registros excluídos",
    "Reports sought for retrieval" = "Relatórios buscados",
    "Reports not retrieved" = "Relatórios não recuperados",
    "Reports assessed for eligibility" = "Relatórios avaliados para elegibilidade",
    "Reports excluded" = "Relatórios excluídos",
    "New studies included in review" = "Novos estudos incluídos na revisão",
    "Total studies included in review" = "Total de estudos incluídos na revisão"
  )

  # Procurar tradução
  if (texto %in% names(traducoes)) {
    return(traducoes[[texto]])
  } else {
    return(texto)  # Retornar original se não encontrar tradução
  }
}

# Aplicar traduções nas colunas do template
if("description" %in% names(data)) data$description <- sapply(data$description, traduzir_texto)
if("boxtext" %in% names(data)) data$boxtext <- sapply(data$boxtext, traduzir_texto)
if("tooltips" %in% names(data)) data$tooltips <- sapply(data$tooltips, traduzir_texto)

cat("✅ Textos traduzidos para português\n\n")

# Processar dados para formato correto
cat("📊 Processando dados PRISMA...\n")
prisma_data <- PRISMA_data(data)

# Gerar o fluxograma PRISMA 2020
cat("🎨 Gerando fluxograma PRISMA 2020 em português...\n")

plot <- PRISMA_flowdiagram(
  prisma_data,
  fontsize = 12,
  font = "Helvetica",
  title_colour = "Goldenrod1",
  greybox_colour = "Gainsboro",
  main_colour = "Black",
  arrow_colour = "Black",
  arrow_head = "normal",
  arrow_tail = "none",
  interactive = FALSE,
  previous = FALSE,
  other = TRUE,
  detail_databases = TRUE,
  detail_registers = FALSE,
  meta_analysis = FALSE,
  side_boxes = TRUE
)

# Salvar em diferentes formatos
output_html <- "prisma_flowdiagram_portugues_interativo.html"
output_pdf <- "prisma_flowdiagram_portugues.pdf"
output_png <- "prisma_flowdiagram_portugues.png"
output_svg <- "prisma_flowdiagram_portugues.svg"

cat("\n📥 Salvando arquivos...\n")

# HTML (com interatividade)
tryCatch({
  PRISMA_save(plot, filename = output_html, filetype = "HTML", overwrite = TRUE)
  cat(sprintf("✅ HTML: %s\n", output_html))
}, error = function(e) {
  cat(sprintf("❌ Erro ao salvar HTML: %s\n", e$message))
})

# PDF
tryCatch({
  PRISMA_save(plot, filename = output_pdf, filetype = "PDF", overwrite = TRUE)
  cat(sprintf("✅ PDF: %s\n", output_pdf))
}, error = function(e) {
  cat(sprintf("⚠️  Aviso ao salvar PDF: %s\n", e$message))
})

# PNG
tryCatch({
  PRISMA_save(plot, filename = output_png, filetype = "PNG", overwrite = TRUE)
  cat(sprintf("✅ PNG: %s\n", output_png))
}, error = function(e) {
  cat(sprintf("⚠️  Aviso ao salvar PNG: %s\n", e$message))
})

# Copiar para a pasta de figuras PT do manuscrito
tryCatch({
  target_png <- file.path("..", "..", "2-FIGURAS", "1-PT", "prisma_flowdiagram_pt.png")
  file.copy(output_png, target_png, overwrite = TRUE)
  cat(sprintf("✅ Copiado para: %s\n", normalizePath(target_png, winslash = "/", mustWork = FALSE)))
}, error = function(e) {
  cat(sprintf("⚠️  Aviso ao copiar PNG: %s\n", e$message))
})

# SVG
tryCatch({
  PRISMA_save(plot, filename = output_svg, filetype = "SVG", overwrite = TRUE)
  cat(sprintf("✅ SVG: %s\n", output_svg))
}, error = function(e) {
  cat(sprintf("⚠️  Aviso ao salvar SVG: %s\n", e$message))
})

cat("\n======================================================================\n")
cat("✨ FLUXOGRAMA PRISMA 2020 EM PORTUGUÊS GERADO COM SUCESSO!\n")
cat("======================================================================\n")
cat(sprintf("📁 Arquivos de saída disponíveis no diretório atual\n"))
cat(sprintf("🌐 Arquivo HTML interativo: %s\n", output_html))
cat("📖 Para visualizar, abra o arquivo HTML em seu navegador\n\n")