# ============================================================================
# Script Automatizado: Busca e Análise Web of Science
# Data: 16/11/2025
# Autor: Revisão de Escopo - ML + Indicações Geográficas
# ============================================================================

# Configurar CRAN mirror
options(repos = c(CRAN = "https://cran.rstudio.com/"))

# Atualizar pacotes base necessários
if (packageVersion("magrittr") < "2.0.4") {
  cat("📦 Atualizando magrittr...\n")
  install.packages("magrittr", dependencies = TRUE, quiet = TRUE)
}

# Verificar e instalar pacotes necessários
packages <- c("bibliometrix", "dplyr", "readr", "stringr")

cat("\n📦 Verificando pacotes necessários...\n")
for (pkg in packages) {
  if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
    cat(sprintf("   Instalando: %s\n", pkg))
    install.packages(pkg, dependencies = TRUE, quiet = TRUE)
    suppressPackageStartupMessages(library(pkg, character.only = TRUE))
  } else {
    cat(sprintf("   ✓ %s\n", pkg))
  }
}

cat("\n")
cat("================================================================================\n")
cat("          BUSCA AUTOMATIZADA - WEB OF SCIENCE + BIBLIOMETRIX\n")
cat("================================================================================\n\n")

# ============================================================================
# PASSO 1: Definir Query de Busca
# ============================================================================

# Query adaptada para WoS (mesmo critério do Scopus)
wos_query <- 'TS=(
    (
        "traditional agricultural system*" OR "traditional farming system*" OR
        "traditional agriculture" OR "traditional agroecosystem*" OR
        "sistemas agrícolas tradicionais" OR "sistema agrícola tradicional" OR
        "agricultura tradicional" OR
        "indigenous farming" OR "indigenous agriculture" OR
        "shifting cultivation" OR "slash-and-burn" OR
        "ancestral farming" OR "ancient agriculture"
    )
    AND
    (
        "machine learning" OR "artificial intelligence" OR "deep learning" OR
        "random forest" OR "neural network*" OR "support vector machine*" OR
        "SVM" OR "decision tree*" OR "gradient boosting" OR "CNN" OR
        "long short-term memory" OR "LSTM" OR "yolo" OR
        "remote sensing"
    )
) AND PY=(2010-2025)'

cat("📋 QUERY CONFIGURADA:\n")
cat(paste0(substr(wos_query, 1, 150), "...\n\n"))

# Salvar query em arquivo
writeLines(wos_query, "webofscience_query_R.txt")
cat("✅ Query salva em: webofscience_query_R.txt\n\n")

# ============================================================================
# PASSO 2: INSTRUÇÕES PARA EXPORTAÇÃO MANUAL DO WEB OF SCIENCE
# ============================================================================

cat("================================================================================\n")
cat("INSTRUÇÕES PARA BUSCA NO WEB OF SCIENCE:\n")
cat("================================================================================\n\n")

cat("1️⃣  Acesse: https://www.webofscience.com/wos/woscc/basic-search\n")
cat("2️⃣  Cole a query do arquivo 'webofscience_query_R.txt'\n")
cat("3️⃣  Selecione índices: SCI-EXPANDED, SSCI, A&HCI\n")
cat("4️⃣  Execute a busca\n")
cat("5️⃣  Exporte os resultados:\n")
cat("    - Formato: BibTeX ou Plain Text\n")
cat("    - Campos: Full Record and Cited References\n")
cat("    - Salve como: 'wos_export.bib' ou 'wos_export.txt'\n\n")

cat("⏸️  AGUARDANDO... Coloque o arquivo exportado na pasta atual\n")
cat("    Arquivo esperado: 'wos_export.bib' ou 'wos_export.txt'\n\n")

# ============================================================================
# PASSO 3: Verificar se arquivo existe
# ============================================================================

# Procurar por arquivos WoS
wos_files <- list.files(pattern = "^(wos_export|webofscience.*export|savedrecs)\\.(bib|txt)$", 
                        ignore.case = TRUE)

if (length(wos_files) == 0) {
  cat("⚠️  ARQUIVO NÃO ENCONTRADO!\n\n")
  cat("Por favor:\n")
  cat("1. Faça a busca no Web of Science\n")
  cat("2. Exporte os resultados (BibTeX ou Plain Text)\n")
  cat("3. Salve o arquivo nesta pasta como 'wos_export.bib'\n")
  cat("4. Execute este script novamente\n\n")
  
  cat("💡 ALTERNATIVA: Se você já tem o arquivo, defina o caminho:\n")
  cat("   wos_file <- 'caminho/para/seu/arquivo.bib'\n")
  cat("   Depois comente as linhas de verificação e continue o script\n\n")
  
  stop("⛔ Execução interrompida: arquivo WoS não encontrado")
}

# Selecionar arquivo
wos_file <- wos_files[1]
cat(sprintf("✅ Arquivo encontrado: %s\n\n", wos_file))

# ============================================================================
# PASSO 4: Importar dados do Web of Science
# ============================================================================

cat("================================================================================\n")
cat("IMPORTANDO DADOS DO WEB OF SCIENCE\n")
cat("================================================================================\n\n")

# Detectar formato
file_ext <- tolower(tools::file_ext(wos_file))
format_type <- if (file_ext == "bib") "bibtex" else "plaintext"

cat(sprintf("📂 Arquivo: %s\n", wos_file))
cat(sprintf("📋 Formato: %s\n", format_type))
cat("⏳ Processando...\n\n")

# Importar com bibliometrix
tryCatch({
  wos_data <- convert2df(
    file = wos_file,
    dbsource = "wos",
    format = format_type
  )
  
  cat(sprintf("✅ Importação concluída: %d registros\n\n", nrow(wos_data)))
  
}, error = function(e) {
  cat("❌ ERRO na importação:\n")
  cat(sprintf("   %s\n\n", e$message))
  cat("💡 Tente:\n")
  cat("   - Verificar se o arquivo está corrompido\n")
  cat("   - Re-exportar do Web of Science\n")
  cat("   - Usar formato BibTeX (mais confiável)\n\n")
  stop("Falha na importação de dados")
})

# ============================================================================
# PASSO 5: Análise Bibliométrica
# ============================================================================

cat("================================================================================\n")
cat("ANÁLISE BIBLIOMÉTRICA\n")
cat("================================================================================\n\n")

# Análise básica
results <- biblioAnalysis(wos_data, sep = ";")

cat("📊 ESTATÍSTICAS GERAIS:\n")
cat(sprintf("   - Documentos: %d\n", results$Articles))
cat(sprintf("   - Autores: %d\n", results$nAuthors))
cat(sprintf("   - Período: %d - %d\n", results$Years[1], results$Years[length(results$Years)]))
cat(sprintf("   - Fontes (revistas): %d\n", length(results$Sources)))
cat(sprintf("   - Palavras-chave: %d\n", length(results$ID)))
cat("\n")

# Sumário detalhado
cat("📋 SUMÁRIO DETALHADO:\n")
cat("================================================================================\n")
S <- summary(results, k = 10, pause = FALSE, width = 100)

# ============================================================================
# PASSO 6: Análise de Produção Anual
# ============================================================================

cat("\n")
cat("================================================================================\n")
cat("PRODUÇÃO CIENTÍFICA ANUAL\n")
cat("================================================================================\n\n")

if ("PY" %in% colnames(wos_data)) {
  producao_anual <- wos_data %>%
    filter(!is.na(PY)) %>%
    group_by(PY) %>%
    summarise(n_artigos = n(), .groups = 'drop') %>%
    arrange(desc(PY))
  
  print(producao_anual, n = 20)
  cat("\n")
} else {
  cat("⚠️  Campo 'PY' (Publication Year) não encontrado\n\n")
}

# ============================================================================
# PASSO 7: Top Autores
# ============================================================================

cat("================================================================================\n")
cat("TOP 10 AUTORES MAIS PRODUTIVOS\n")
cat("================================================================================\n\n")

if (length(results$Authors) > 0) {
  top_authors <- head(results$Authors, 10)
  for (i in 1:length(top_authors)) {
    cat(sprintf("%2d. %-30s %3d artigos\n", i, names(top_authors)[i], top_authors[i]))
  }
  cat("\n")
}

# ============================================================================
# PASSO 8: Top Revistas
# ============================================================================

cat("================================================================================\n")
cat("TOP 10 REVISTAS (FONTES)\n")
cat("================================================================================\n\n")

if (length(results$Sources) > 0) {
  top_sources <- head(results$Sources, 10)
  for (i in 1:length(top_sources)) {
    cat(sprintf("%2d. %-50s %3d artigos\n", i, names(top_sources)[i], top_sources[i]))
  }
  cat("\n")
}

# ============================================================================
# PASSO 9: Top Palavras-chave
# ============================================================================

cat("================================================================================\n")
cat("TOP 20 PALAVRAS-CHAVE MAIS FREQUENTES\n")
cat("================================================================================\n\n")

if (length(results$ID) > 0) {
  top_keywords <- head(results$ID, 20)
  for (i in 1:length(top_keywords)) {
    cat(sprintf("%2d. %-40s %3d ocorrências\n", i, names(top_keywords)[i], top_keywords[i]))
  }
  cat("\n")
}

# ============================================================================
# PASSO 10: Salvar Resultados
# ============================================================================

cat("================================================================================\n")
cat("SALVANDO RESULTADOS\n")
cat("================================================================================\n\n")

# Criar diretório de saída
output_dir <- "../relatorios"
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

# 1. Salvar dados processados
output_file_rds <- file.path(output_dir, "wos_data_processed.rds")
saveRDS(wos_data, output_file_rds)
cat(sprintf("✅ Dados salvos: %s\n", output_file_rds))

# 2. Salvar CSV com principais campos
output_file_csv <- file.path(output_dir, "wos_articles_summary.csv")
summary_data <- wos_data %>%
  select(any_of(c("AU", "TI", "SO", "PY", "DI", "AB", "DE", "ID"))) %>%
  head(1000)  # Limitar a 1000 registros para CSV

write_csv(summary_data, output_file_csv)
cat(sprintf("✅ Resumo CSV salvo: %s\n", output_file_csv))

# 3. Salvar relatório de análise
output_file_txt <- file.path(output_dir, "wos_analysis_report.txt")
sink(output_file_txt)
cat("RELATÓRIO DE ANÁLISE - WEB OF SCIENCE\n")
cat(sprintf("Data: %s\n", Sys.Date()))
cat(sprintf("Arquivo: %s\n", wos_file))
cat(paste(rep("=", 80), collapse=""), "\n\n")
summary(results, k = 20, pause = FALSE)
sink()
cat(sprintf("✅ Relatório salvo: %s\n", output_file_txt))

cat("\n")

# ============================================================================
# PASSO 11: Comparação com Scopus (se disponível)
# ============================================================================

cat("================================================================================\n")
cat("COMPARAÇÃO COM SCOPUS\n")
cat("================================================================================\n\n")

# Procurar arquivo Scopus
scopus_files <- list.files(pattern = "scopus.*\\.bib$", ignore.case = TRUE)

if (length(scopus_files) > 0) {
  cat(sprintf("📂 Arquivo Scopus encontrado: %s\n", scopus_files[1]))
  cat("⏳ Importando Scopus...\n")
  
  tryCatch({
    scopus_data <- convert2df(
      file = scopus_files[1],
      dbsource = "scopus",
      format = "bibtex"
    )
    
    cat(sprintf("✅ Scopus importado: %d registros\n\n", nrow(scopus_data)))
    
    cat("📊 COMPARAÇÃO:\n")
    cat(sprintf("   - WoS:    %d artigos\n", nrow(wos_data)))
    cat(sprintf("   - Scopus: %d artigos\n", nrow(scopus_data)))
    
    # Combinar bases (remover duplicatas)
    cat("\n⏳ Combinando bases e removendo duplicatas...\n")
    combined <- mergeDbSources(scopus_data, wos_data, remove.duplicated = TRUE)
    
    cat(sprintf("✅ Base combinada: %d artigos únicos\n", nrow(combined)))
    cat(sprintf("   Duplicatas removidas: %d\n", 
                nrow(wos_data) + nrow(scopus_data) - nrow(combined)))
    
    # Salvar base combinada
    output_file_combined <- file.path(output_dir, "combined_scopus_wos.rds")
    saveRDS(combined, output_file_combined)
    cat(sprintf("\n✅ Base combinada salva: %s\n", output_file_combined))
    
  }, error = function(e) {
    cat(sprintf("⚠️  Erro ao processar Scopus: %s\n", e$message))
  })
  
} else {
  cat("ℹ️  Arquivo Scopus não encontrado na pasta atual\n")
  cat("   Para comparação, coloque o arquivo scopus_export.bib aqui\n")
}

cat("\n")

# ============================================================================
# PASSO 12: Visualizações (opcional)
# ============================================================================

cat("================================================================================\n")
cat("VISUALIZAÇÕES\n")
cat("================================================================================\n\n")

cat("💡 Para gerar visualizações, execute:\n\n")
cat("   # Gráfico de produção anual\n")
cat("   plot(results, k = 10, pause = FALSE)\n\n")

cat("   # Interface interativa Biblioshiny\n")
cat("   biblioshiny()\n\n")

cat("   # Mapa de co-citações\n")
cat("   NetMatrix <- biblioNetwork(wos_data, analysis=\"co-citation\", network=\"references\", sep=\";\")\n")
cat("   net <- networkPlot(NetMatrix, n=50, type=\"kamada\", Title=\"Co-Citation Network\")\n\n")

# ============================================================================
# FINALIZAÇÃO
# ============================================================================

cat("================================================================================\n")
cat("✅ ANÁLISE CONCLUÍDA COM SUCESSO!\n")
cat("================================================================================\n\n")

cat("📁 Arquivos gerados em: ../relatorios/\n")
cat("   - wos_data_processed.rds (dados completos)\n")
cat("   - wos_articles_summary.csv (resumo)\n")
cat("   - wos_analysis_report.txt (relatório)\n\n")

cat("💡 Próximos passos sugeridos:\n")
cat("   1. Abrir wos_articles_summary.csv para revisão\n")
cat("   2. Comparar com resultados do Scopus\n")
cat("   3. Aplicar critérios de inclusão/exclusão\n")
cat("   4. Gerar visualizações com biblioshiny()\n\n")

cat(sprintf("⏰ Processamento concluído em: %s\n", Sys.time()))
cat("================================================================================\n")
