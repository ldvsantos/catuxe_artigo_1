#!/usr/bin/env Rscript
# SCRIPT DE CORREÇÃO DE DEPENDÊNCIAS R
# Author: Assistente IA
# Data: 2025

# Suprimir avisos
options(warn = -1)

# Configurar CRAN mirror
options(repos = c(CRAN = "https://cran.rstudio.com"))

cat("======================================================================\n")
cat("⚙️  INICIANDO CORREÇÃO DE DEPENDÊNCIAS R\n")
cat("======================================================================\n\n")

# Pacotes a serem reinstalados
pacotes_chave <- c("magrittr", "usethis", "devtools", "PRISMA2020", "DiagrammeR", "htmlwidgets")

# 1. Remover pacotes para garantir uma instalação limpa
cat("🧹 Removendo instalações antigas...\n")
for (pacote in pacotes_chave) {
  tryCatch({
    if (require(pacote, character.only = TRUE)) {
      remove.packages(pacote)
      cat(sprintf("  - Pacote '%s' removido.\n", pacote))
    } else {
      cat(sprintf("  - Pacote '%s' não estava instalado.\n", pacote))
    }
  }, error = function(e) {
    cat(sprintf("  - Erro ao remover '%s': %s\n", pacote, e$message))
  })
}

# 2. Instalar pacotes na ordem correta
cat("\n📦 Reinstalando pacotes na ordem correta...\n")

# Dependências básicas
install.packages(c("magrittr", "usethis", "devtools", "DiagrammeR", "htmlwidgets"), quiet = TRUE)
cat("  - Dependências básicas instaladas: magrittr, usethis, devtools, DiagrammeR, htmlwidgets\n")

# Instalar PRISMA2020 do GitHub
cat("  - Instalando PRISMA2020 do GitHub...\n")
tryCatch({
  devtools::install_github("prisma-flowdiagram/PRISMA2020", quiet = TRUE, force = TRUE)
  cat("  - Pacote 'PRISMA2020' instalado com sucesso.\n")
}, error = function(e) {
  cat(sprintf("❌ Erro crítico ao instalar PRISMA2020: %s\n", e$message))
  cat("   A execução pode falhar. Tente executar o script principal mesmo assim.\n")
})


cat("\n======================================================================\n")
cat("✅ CORREÇÃO DE DEPENDÊNCIAS CONCLUÍDA!\n")
cat("======================================================================\n")
cat("🚀 Tente executar o script 'gerar_prisma_interativo.R' agora.\n\n")
