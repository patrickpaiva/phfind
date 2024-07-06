# phfind

`phfind` é um script shell para buscar arquivos e diretórios com base em vários critérios, como nome, tipo, tamanho, data de modificação, arquivos mais recentes que um arquivo de referência e expressões regulares. Foi inspirado no Find tradicional do Linux para fixação de conhecimentos de Shell Script.

## Uso

```bash
phfind [diretório(s)] [opções]
```

### Opções

- `-name [padrão]`: Nome do arquivo ou parte do nome (com suporte a curingas)
- `-type [d|f]`: Tipo de arquivo (d para diretório, f para arquivo)
- `-size [+-][N][c|k|M]`: Tamanho do arquivo (+ maior que, - menor que, N exato)
- `-mtime [+-]N`: Arquivos modificados há N dias (+ mais antigo, - mais recente)
- `-cnewer [arquivo]`: Arquivos mais recentes que o arquivo de referência
- `-regex [padrão]`: Expressão regular para correspondência de caminho completo
- `-help`: Exibe a mensagem de ajuda

## Exemplos

Caso não seja passado um diretório, será considerado o diretório corrente.

### Encontrar arquivos com nome específico

```bash
./phfind.sh /path -name "example.txt"
```

### Encontrar diretórios

```bash
./phfind.sh -type d
```

### Encontrar arquivos maiores que 1MB

```bash
./phfind.sh -size +1M
```

### Encontrar arquivos mais recentes que um arquivo de referência

```bash
./phfind.sh -cnewer reference.txt
```

### Usar expressão regular para encontrar arquivos com extensões .log ou .txt

```bash
./phfind.sh -regex '.*\.(log|txt)$'
```

### Encontrar arquivos em dois diretórios

```bash
./phfind.sh /path/to/first_directory /path/to/second_directory -type f -name "*.txt"
```


## Créditos

Desenvolvido por Patrick Paiva e Hugo Nascimento.