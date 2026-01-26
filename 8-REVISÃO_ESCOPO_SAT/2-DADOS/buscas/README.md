Este diretório concentra as strings de busca que alimentam a recuperação bibliográfica em bases indexadas e que, por consequência, determinam o universo de registros exportados para análise no pipeline do SAT.

A lógica operacional preserva uma separação entre a definição da estratégia de busca e os scripts de processamento, o que permite ajustar a temática sem reescrever o código. A query para Web of Science está em wos_query.txt e pode ser colada diretamente no campo de busca avançada da plataforma, enquanto a query para Scopus está em scopus_query.txt e segue o formato TITLE-ABS-KEY.

Uma vez realizados os downloads na própria interface das bases, os arquivos exportados devem ser colocados em artigo_1_catuxe/8-REVISÃO_ESCOPO_SAT/2-DADOS/scripts com nomes compatíveis com o pipeline já existente, tipicamente scopus_export.bib e wos_export.bib. Em seguida, o processamento e a deduplicação podem ser executados pelo script analisar_scopus_wos_combinado.py, que consolida as fontes e prepara os artefatos para a etapa de triagem e síntese.

Para Web of Science, se você quiser gerar o arquivo webofscience_query_R.txt automaticamente a partir desta pasta (sem editar o script), execute busca_webofscience_auto.R a partir de artigo_1_catuxe/8-REVISÃO_ESCOPO_SAT/2-DADOS/scripts. Em ambientes Windows onde o comando Rscript não está no PATH, uma forma robusta em PowerShell é usar o executável via $env:ProgramFiles, por exemplo:

```powershell
Push-Location .\artigo_1_catuxe\8-REVISÃO_ESCOPO_SAT\2-DADOS\scripts
& "$env:ProgramFiles\R\R-4.5.1\bin\Rscript.exe" ".\busca_webofscience_auto.R"
Pop-Location
```

O script salva webofscience_query_R.txt e interrompe a execução se não encontrar um arquivo de exportação do WoS (wos_export.bib ou wos_export.txt) na pasta scripts.

Quando houver atualização de escopo ou necessidade de refinamento terminológico, a recomendação é alterar apenas os arquivos de query e manter o restante do fluxo idêntico, garantindo rastreabilidade, reprodutibilidade e comparabilidade entre iterações da busca.
