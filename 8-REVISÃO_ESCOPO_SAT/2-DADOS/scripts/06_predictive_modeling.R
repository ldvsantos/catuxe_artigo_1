################################################################################
# MODELAGEM PREDITIVA - GGPLOT2
# Machine Learning para Indicações Geográficas
#
# Este script realiza modelagem preditiva usando caret/ggplot2
# Modelos: Regressão (predizer score) e Classificação (high_score)
#
# Outputs:
#   - model_regressao_comparacao.png (Comparação de modelos de regressão)
#   - model_feature_importance_reg.png (Importância de features - regressão)
#   - model_feature_importance_clf.png (Importância de features - classificação)
#   - model_confusion_matrix.png (Matriz de confusão)
#   - model_metricas_comparacao.png (Comparação de desempenho)
#   - model_relatorio.txt (Relatório de modelagem)
#   - model_dados_completos.csv (Dados com features extraídas)
################################################################################

rm(list = ls())
gc()

packages <- c("bib2df", "tidyverse", "caret", "randomForest", "glmnet", 
              "viridis", "patchwork", "scales", "ggrepel", "pROC")

for (pkg in packages) {
  if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
    install.packages(pkg, dependencies = TRUE, repos = "https://cloud.r-project.org")
    library(pkg, character.only = TRUE)
  }
}

cat("\n")
cat("================================================================================\n")
cat("MODELAGEM PREDITIVA - GGPLOT2\n")
cat("Machine Learning para Indicações Geográficas\n")
cat("================================================================================\n\n")

################################################################################
# FUNÇÃO: Extrair dados para modelagem
################################################################################
extrair_dados_modelagem <- function(caminho_bib) {
  cat("📚 Extraindo dados do arquivo .bib...\n")
  
  bib_data <- bib2df(caminho_bib)
  texto_completo <- tolower(paste(bib_data$TITLE, bib_data$ABSTRACT, bib_data$KEYWORDS, sep = " "))
  
  # Calcular score simulado (baseado em keywords + complexidade)
  score <- sapply(1:nrow(bib_data), function(i) {
    kw_score <- if (!is.null(bib_data$KEYWORDS[[i]]) && !is.na(bib_data$KEYWORDS[[i]])) {
      length(unlist(strsplit(as.character(bib_data$KEYWORDS[[i]]), ";")))
    } else {
      5
    }
    
    # Complexidade técnica
    tech_score <- sum(c(
      grepl("neural|deep learning", texto_completo[i]),
      grepl("ensemble|boosting", texto_completo[i]),
      grepl("cross-validation|hyperparameter", texto_completo[i])
    )) * 5
    
    base_score <- 30 + kw_score * 3 + tech_score + rnorm(1, 0, 3)
    return(round(pmax(pmin(base_score, 70), 25), 1))
  })
  
  dados <- data.frame(
    ID = 1:nrow(bib_data),
    Ano = as.numeric(bib_data$YEAR),
    Score = score,
    
    # Algoritmos
    RandomForest = as.integer(grepl("random forest", texto_completo)),
    SVM = as.integer(grepl("svm|support vector", texto_completo)),
    NeuralNetwork = as.integer(grepl("neural|deep learning|cnn|lstm", texto_completo)),
    KNN = as.integer(grepl("k-nearest|knn", texto_completo)),
    DecisionTree = as.integer(grepl("decision tree", texto_completo)),
    GradientBoosting = as.integer(grepl("gradient boosting|xgboost", texto_completo)),
    EnsembleMethods = as.integer(grepl("ensemble|bagging|boosting", texto_completo)),
    
    # Instrumentos
    NIR = as.integer(grepl("nir\\b|near infrared", texto_completo)),
    FTIR = as.integer(grepl("ftir|fourier transform", texto_completo)),
    GCMS = as.integer(grepl("gc-ms|gas chromatography", texto_completo)),
    LCMS = as.integer(grepl("lc-ms|hplc", texto_completo)),
    ICPMS = as.integer(grepl("icp-ms", texto_completo)),
    NMR = as.integer(grepl("nmr|nuclear magnetic", texto_completo)),
    Spectroscopy = as.integer(grepl("spectroscopy|spectra", texto_completo)),
    
    # Produtos
    Wine = as.integer(grepl("wine|vinho", texto_completo)),
    Coffee = as.integer(grepl("coffee|café", texto_completo)),
    Olive = as.integer(grepl("olive|azeite", texto_completo)),
    Honey = as.integer(grepl("honey|mel", texto_completo)),
    Cheese = as.integer(grepl("cheese|queijo", texto_completo)),
    
    # Aplicações
    Authentication = as.integer(grepl("authentication|authenticity", texto_completo)),
    Classification = as.integer(grepl("classification|classify", texto_completo)),
    OriginDetection = as.integer(grepl("origin|provenance|geographical", texto_completo)),
    QualityControl = as.integer(grepl("quality|grade", texto_completo)),
    
    # Regiões
    Europe = as.integer(grepl("europe|italy|france|spain|portugal", texto_completo)),
    Asia = as.integer(grepl("asia|china|japan|korea", texto_completo)),
    Americas = as.integer(grepl("america|usa|brazil", texto_completo)),
    
    # Metodologia
    CrossValidation = as.integer(grepl("cross-validation|cross validation", texto_completo)),
    FeatureSelection = as.integer(grepl("feature selection|feature extraction", texto_completo)),
    Hyperparameter = as.integer(grepl("hyperparameter|tuning|optimization", texto_completo)),
    
    stringsAsFactors = FALSE
  )
  
  # Criar variável binária high_score
  dados$HighScore <- as.factor(ifelse(dados$Score >= median(dados$Score), "High", "Low"))
  
  cat(sprintf("✓ Total de estudos extraídos: %d\n", nrow(dados)))
  cat(sprintf("  Score médio: %.2f (σ = %.2f)\n\n", mean(dados$Score), sd(dados$Score)))
  
  return(dados)
}

################################################################################
# FUNÇÃO: Preparar dados para modelagem
################################################################################
preparar_dados <- function(dados, test_size = 0.25) {
  cat("🔬 Preparando dados para modelagem...\n")
  
  # Selecionar features (excluir ID, Ano, Score, HighScore)
  features <- dados %>% select(-ID, -Ano, -Score, -HighScore)
  
  # Criar conjuntos de treino/teste
  set.seed(42)
  train_indices <- createDataPartition(dados$Score, p = 1 - test_size, list = FALSE)
  
  # Regressão
  X_train_reg <- features[train_indices, ]
  y_train_reg <- dados$Score[train_indices]
  X_test_reg <- features[-train_indices, ]
  y_test_reg <- dados$Score[-train_indices]
  
  # Classificação
  y_train_clf <- dados$HighScore[train_indices]
  y_test_clf <- dados$HighScore[-train_indices]
  
  cat(sprintf("✓ Treino: %d | Teste: %d\n\n", length(train_indices), nrow(dados) - length(train_indices)))
  
  return(list(
    X_train = X_train_reg,
    y_train_reg = y_train_reg,
    X_test = X_test_reg,
    y_test_reg = y_test_reg,
    y_train_clf = y_train_clf,
    y_test_clf = y_test_clf
  ))
}

################################################################################
# FUNÇÃO: Executar modelos de regressão
################################################################################
executar_regressao <- function(split_data) {
  cat("🔬 Executando modelos de regressão...\n")
  
  train_control <- trainControl(method = "cv", number = 5)
  
  # Linear Regression
  cat("  - Linear Regression...\n")
  model_lm <- train(x = split_data$X_train, y = split_data$y_train_reg,
                    method = "lm", trControl = train_control)
  pred_lm <- predict(model_lm, split_data$X_test)
  rmse_lm <- sqrt(mean((pred_lm - split_data$y_test_reg)^2))
  r2_lm <- cor(pred_lm, split_data$y_test_reg)^2
  
  # Ridge Regression
  cat("  - Ridge Regression...\n")
  model_ridge <- train(x = split_data$X_train, y = split_data$y_train_reg,
                       method = "glmnet", trControl = train_control,
                       tuneGrid = expand.grid(alpha = 0, lambda = seq(0.001, 1, length = 20)))
  pred_ridge <- predict(model_ridge, split_data$X_test)
  rmse_ridge <- sqrt(mean((pred_ridge - split_data$y_test_reg)^2))
  r2_ridge <- cor(pred_ridge, split_data$y_test_reg)^2
  
  # Lasso Regression
  cat("  - Lasso Regression...\n")
  model_lasso <- train(x = split_data$X_train, y = split_data$y_train_reg,
                       method = "glmnet", trControl = train_control,
                       tuneGrid = expand.grid(alpha = 1, lambda = seq(0.001, 1, length = 20)))
  pred_lasso <- predict(model_lasso, split_data$X_test)
  rmse_lasso <- sqrt(mean((pred_lasso - split_data$y_test_reg)^2))
  r2_lasso <- cor(pred_lasso, split_data$y_test_reg)^2
  
  # Random Forest
  cat("  - Random Forest Regression...\n")
  model_rf <- train(x = split_data$X_train, y = split_data$y_train_reg,
                    method = "rf", trControl = train_control,
                    tuneGrid = expand.grid(mtry = c(5, 10, 15)))
  pred_rf <- predict(model_rf, split_data$X_test)
  rmse_rf <- sqrt(mean((pred_rf - split_data$y_test_reg)^2))
  r2_rf <- cor(pred_rf, split_data$y_test_reg)^2
  
  resultados <- data.frame(
    Modelo = c("Linear", "Ridge", "Lasso", "RandomForest"),
    RMSE = c(rmse_lm, rmse_ridge, rmse_lasso, rmse_rf),
    R2 = c(r2_lm, r2_ridge, r2_lasso, r2_rf),
    stringsAsFactors = FALSE
  )
  
  cat("✓ Regressão concluída\n\n")
  
  return(list(
    resultados = resultados,
    models = list(lm = model_lm, ridge = model_ridge, lasso = model_lasso, rf = model_rf),
    predictions = list(lm = pred_lm, ridge = pred_ridge, lasso = pred_lasso, rf = pred_rf)
  ))
}

################################################################################
# FUNÇÃO: Executar modelos de classificação
################################################################################
executar_classificacao <- function(split_data) {
  cat("🔬 Executando modelos de classificação...\n")
  
  train_control <- trainControl(method = "cv", number = 5, classProbs = TRUE)
  
  # Logistic Regression
  cat("  - Logistic Regression...\n")
  model_glm <- train(x = split_data$X_train, y = split_data$y_train_clf,
                     method = "glm", family = "binomial", trControl = train_control)
  pred_glm <- predict(model_glm, split_data$X_test)
  cm_glm <- confusionMatrix(pred_glm, split_data$y_test_clf)
  
  # Random Forest
  cat("  - Random Forest Classification...\n")
  model_rf <- train(x = split_data$X_train, y = split_data$y_train_clf,
                    method = "rf", trControl = train_control,
                    tuneGrid = expand.grid(mtry = c(5, 10, 15)))
  pred_rf <- predict(model_rf, split_data$X_test)
  cm_rf <- confusionMatrix(pred_rf, split_data$y_test_clf)
  
  resultados <- data.frame(
    Modelo = c("Logistic", "RandomForest"),
    Accuracy = c(cm_glm$overall["Accuracy"], cm_rf$overall["Accuracy"]),
    Precision = c(cm_glm$byClass["Precision"], cm_rf$byClass["Precision"]),
    Recall = c(cm_glm$byClass["Recall"], cm_rf$byClass["Recall"]),
    F1 = c(cm_glm$byClass["F1"], cm_rf$byClass["F1"]),
    stringsAsFactors = FALSE
  )
  
  cat("✓ Classificação concluída\n\n")
  
  return(list(
    resultados = resultados,
    models = list(glm = model_glm, rf = model_rf),
    confusion_matrices = list(glm = cm_glm, rf = cm_rf)
  ))
}

################################################################################
# FUNÇÃO: Plot comparação de regressão
################################################################################
plot_regressao_comparacao <- function(reg_results, output_file = "model_regressao_comparacao.png") {
  cat("📊 Gerando comparação de modelos de regressão...\n")
  
  p1 <- ggplot(reg_results$resultados, aes(x = reorder(Modelo, -RMSE), y = RMSE, fill = Modelo)) +
    geom_col(alpha = 0.8) +
    geom_text(aes(label = sprintf("%.2f", RMSE)), vjust = -0.5, fontface = "bold") +
    scale_fill_viridis_d(option = "plasma") +
    labs(title = "RMSE por Modelo", x = "Modelo", y = "RMSE") +
    theme_minimal(base_size = 12) +
    theme(legend.position = "none", plot.title = element_text(face = "bold", hjust = 0.5))
  
  p2 <- ggplot(reg_results$resultados, aes(x = reorder(Modelo, R2), y = R2, fill = Modelo)) +
    geom_col(alpha = 0.8) +
    geom_text(aes(label = sprintf("%.3f", R2)), vjust = -0.5, fontface = "bold") +
    scale_fill_viridis_d(option = "plasma") +
    labs(title = "R² por Modelo", x = "Modelo", y = "R² Score") +
    theme_minimal(base_size = 12) +
    theme(legend.position = "none", plot.title = element_text(face = "bold", hjust = 0.5))
  
  combined <- p1 | p2
  
  ggsave(output_file, plot = combined, width = 12, height = 5, dpi = 300)
  cat(sprintf("✓ Comparação de regressão salva: %s\n", output_file))
}

################################################################################
# FUNÇÃO: Plot feature importance (regressão)
################################################################################
plot_feature_importance_reg <- function(reg_results, output_file = "model_feature_importance_reg.png") {
  cat("📊 Gerando importância de features (regressão)...\n")
  
  # Usar Random Forest para feature importance
  importance <- varImp(reg_results$models$rf)$importance
  importance$Feature <- rownames(importance)
  importance <- importance %>% arrange(desc(Overall)) %>% head(15)
  
  p <- ggplot(importance, aes(x = reorder(Feature, Overall), y = Overall)) +
    geom_col(fill = "#2E86AB", alpha = 0.8) +
    coord_flip() +
    labs(
      title = "Variable Importance: Random Forest (Regression)",
      subtitle = "Top 15 most important variables for quality index prediction",
      x = "Variable",
      y = "Relative Importance"
    ) +
    theme_minimal(base_size = 14) +
    theme(
      plot.title = element_text(face = "bold", size = 14, hjust = 0.5),
      plot.subtitle = element_text(hjust = 0.5, color = "gray40")
    )
  
  ggsave(output_file, plot = p, width = 10, height = 7, dpi = 300)
  cat(sprintf("✓ Feature importance (regressão) salvo: %s\n", output_file))
}

################################################################################
# FUNÇÃO: Plot feature importance (classificação)
################################################################################
plot_feature_importance_clf <- function(clf_results, output_file = "model_feature_importance_clf.png") {
  cat("📊 Gerando importância de features (classificação)...\n")
  
  importance <- varImp(clf_results$models$rf)$importance
  importance$Feature <- rownames(importance)
  importance <- importance %>% arrange(desc(Overall)) %>% head(15)
  
  p <- ggplot(importance, aes(x = reorder(Feature, Overall), y = Overall)) +
    geom_col(fill = "#A23B72", alpha = 0.8) +
    coord_flip() +
    labs(
      title = "Variable Importance: Random Forest (Classification)",
      subtitle = "Top 15 most important variables for high-impact study classification",
      x = "Variable",
      y = "Relative Importance"
    ) +
    theme_minimal(base_size = 14) +
    theme(
      plot.title = element_text(face = "bold", size = 14, hjust = 0.5),
      plot.subtitle = element_text(hjust = 0.5, color = "gray40")
    )
  
  ggsave(output_file, plot = p, width = 10, height = 7, dpi = 300)
  cat(sprintf("✓ Feature importance (classificação) salvo: %s\n", output_file))
}

################################################################################
# FUNÇÃO: Plot matriz de confusão
################################################################################
plot_confusion_matrix <- function(clf_results, output_file = "model_confusion_matrix.png") {
  cat("📊 Gerando matriz de confusão...\n")
  
  cm_rf <- as.data.frame(clf_results$confusion_matrices$rf$table)
  
  p <- ggplot(cm_rf, aes(x = Reference, y = Prediction, fill = Freq)) +
    geom_tile(color = "white", size = 1) +
    geom_text(aes(label = Freq), color = "white", size = 8, fontface = "bold") +
    scale_fill_viridis_c(option = "magma", direction = -1) +
    labs(
      title = "Confusion Matrix: Random Forest (Classification)",
      subtitle = sprintf("Overall Accuracy: %.2f%% | High-Impact Study Prediction", 
                         100 * clf_results$confusion_matrices$rf$overall["Accuracy"]),
      x = "Observed Class",
      y = "Predicted Class"
    ) +
    theme_minimal(base_size = 14) +
    theme(
      plot.title = element_text(face = "bold", size = 14, hjust = 0.5),
      plot.subtitle = element_text(hjust = 0.5, color = "gray40"),
      panel.grid = element_blank()
    )
  
  ggsave(output_file, plot = p, width = 8, height = 7, dpi = 300)
  cat(sprintf("✓ Matriz de confusão salva: %s\n", output_file))
}

################################################################################
# FUNÇÃO: Plot comparação de métricas de classificação
################################################################################
plot_metricas_classificacao <- function(clf_results, output_file = "model_metricas_comparacao.png") {
  cat("📊 Gerando comparação de métricas...\n")
  
  metricas_long <- clf_results$resultados %>%
    pivot_longer(-Modelo, names_to = "Metrica", values_to = "Valor")
  
  p <- ggplot(metricas_long, aes(x = Metrica, y = Valor, fill = Modelo)) +
    geom_col(position = "dodge", alpha = 0.8) +
    geom_text(aes(label = sprintf("%.3f", Valor)), position = position_dodge(width = 0.9),
              vjust = -0.5, size = 3, fontface = "bold") +
    scale_fill_viridis_d(option = "plasma", begin = 0.2, end = 0.8) +
    scale_y_continuous(limits = c(0, 1.1), breaks = seq(0, 1, 0.2)) +
    labs(
      title = "Performance Metrics Comparison: Classification Models",
      subtitle = "Accuracy | Precision | Sensitivity | F1-Score",
      x = "Performance Metric",
      y = "Value (0–1)",
      fill = "Predictive Model"
    ) +
    theme_minimal(base_size = 14) +
    theme(
      plot.title = element_text(face = "bold", size = 14, hjust = 0.5),
      plot.subtitle = element_text(hjust = 0.5, color = "gray40"),
      legend.position = "right"
    )
  
  ggsave(output_file, plot = p, width = 12, height = 7, dpi = 300)
  cat(sprintf("✓ Comparação de métricas salva: %s\n", output_file))
}

################################################################################
# FUNÇÃO: Relatório
################################################################################
gerar_relatorio <- function(reg_results, clf_results, output_file = "model_relatorio.txt") {
  cat("\n📝 Gerando relatório estatístico...\n")
  
  sink(output_file)
  cat("================================================================================\n")
  cat("RELATÓRIO DE MODELAGEM PREDITIVA - ML PARA INDICAÇÕES GEOGRÁFICAS\n")
  cat("================================================================================\n\n")
  cat(sprintf("Data de execução: %s\n\n", Sys.time()))
  
  cat("--------------------------------------------------------------------------------\n")
  cat("REGRESSÃO - PREDIÇÃO DE SCORE\n")
  cat("--------------------------------------------------------------------------------\n")
  print(reg_results$resultados)
  cat("\n")
  
  cat("Melhor modelo (RMSE): ", reg_results$resultados$Modelo[which.min(reg_results$resultados$RMSE)], "\n")
  cat("Melhor modelo (R²): ", reg_results$resultados$Modelo[which.max(reg_results$resultados$R2)], "\n\n")
  
  cat("--------------------------------------------------------------------------------\n")
  cat("CLASSIFICAÇÃO - PREDIÇÃO DE HIGH_SCORE\n")
  cat("--------------------------------------------------------------------------------\n")
  print(clf_results$resultados)
  cat("\n")
  
  cat("Melhor modelo (Accuracy): ", clf_results$resultados$Modelo[which.max(clf_results$resultados$Accuracy)], "\n")
  cat("Melhor modelo (F1-Score): ", clf_results$resultados$Modelo[which.max(clf_results$resultados$F1)], "\n\n")
  
  cat("--------------------------------------------------------------------------------\n")
  cat("MATRIZ DE CONFUSÃO - RANDOM FOREST (CLASSIFICAÇÃO)\n")
  cat("--------------------------------------------------------------------------------\n")
  print(clf_results$confusion_matrices$rf$table)
  cat("\n")
  
  cat("================================================================================\n")
  sink()
  
  cat(sprintf("✓ Relatório estatístico salvo: %s\n", output_file))
}

################################################################################
# FUNÇÃO: Salvar dados
################################################################################
salvar_dados <- function(dados) {
  write.csv(dados, "model_dados_completos.csv", row.names = FALSE)
  cat("\n✓ Dados salvos: model_dados_completos.csv\n")
}

################################################################################
# EXECUÇÃO PRINCIPAL
################################################################################
main <- function() {
  caminho_bib <- "../referencias_filtradas/referencias_scopus_wos_filtradas.bib"
  
  if (!file.exists(caminho_bib)) {
    stop("❌ Erro: Arquivo .bib não encontrado em: ", caminho_bib)
  }
  
  # 1. Extrair dados
  dados <- extrair_dados_modelagem(caminho_bib)
  
  # 2. Preparar dados
  split_data <- preparar_dados(dados)
  
  # 3. Regressão
  reg_results <- executar_regressao(split_data)
  
  # 4. Classificação
  clf_results <- executar_classificacao(split_data)
  
  # 5. Visualizações
  cat("📊 Gerando visualizações...\n")
  plot_regressao_comparacao(reg_results)
  plot_feature_importance_reg(reg_results)
  plot_feature_importance_clf(clf_results)
  plot_confusion_matrix(clf_results)
  plot_metricas_classificacao(clf_results)
  
  # 6. Relatório
  gerar_relatorio(reg_results, clf_results)
  
  # 7. Salvar dados
  salvar_dados(dados)
  
  cat("\n")
  cat("================================================================================\n")
  cat("✅ MODELAGEM PREDITIVA CONCLUÍDA COM SUCESSO!\n")
  cat("================================================================================\n")
}

tryCatch({
  main()
}, error = function(e) {
  cat("\n❌ ERRO durante a execução:\n")
  cat(conditionMessage(e), "\n")
})
