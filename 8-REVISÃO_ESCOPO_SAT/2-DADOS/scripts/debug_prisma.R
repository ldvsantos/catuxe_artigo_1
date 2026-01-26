
library(PRISMA2020)

cat("\nTeste 3: Minimal e formato 'tool' rigoroso\n")
prisma_data_3 <- data.frame(
  box = c("database_results", "duplicates", "screened", "excluded", 
          "full_text_retrieval", "not_retrieved", "full_text_assessed", 
          "studies_included"),
  tool = c("Scopus (n = 404); WoS (n = 50)", 
           "Duplicatas removidas (n = 5)", 
           "Registros triados", 
           "Excluídos por título/resumo", 
           "Relatórios buscados", 
           "Não recuperados", 
           "Avaliados para elegibilidade", 
           "Incluídos na revisão"),
  n = c(454, 5, 449, 214, 235, 0, 235, 235),
  url = NA,
  stringsAsFactors = FALSE
)

tryCatch({
    p3 <- PRISMA_data(prisma_data_3)
    # print(p3)
    cat("Sucesso Teste 3\n")
}, error = function(e) cat("Erro Teste 3:", conditionMessage(e), "\n"))


cat("\nTeste 4: Apenas database_results\n")
prisma_data_4 <- data.frame(
  box = c("database_results"),
  tool = c("Scopus (n = 449)"),
  n = c(449),
  url = NA,
  stringsAsFactors = FALSE
)
tryCatch({
    p4 <- PRISMA_data(prisma_data_4)
    cat("Sucesso Teste 4\n")
}, error = function(e) cat("Erro Teste 4:", conditionMessage(e), "\n"))
