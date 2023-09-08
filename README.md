# Setup Terraform para Docker Swarm no Azure

Este repositório contém o código Terraform necessário para criar um ambiente Docker Swarm no Azure.

## Pré-requisitos

Antes de começar, certifique-se de ter os seguintes pré-requisitos instalados:

1. Azure CLI
2. Terraform

## Instalação

### 1. Azure CLI

Para instalar o Azure CLI, siga os passos de acordo com o seu sistema operacional:

- **Linux**:

  ```bash
  curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
  ```

- **macOS**:

  ```bash
  brew update && brew install azure-cli
  ```

- **Windows**:

  Baixe o instalador MSI [aqui](https://aka.ms/installazurecliwindows) e siga as instruções na tela.

Após a instalação, faça login no Azure:

```bash
az login
```

Siga as instruções exibidas para autenticação.

### 2. Terraform

Para instalar o Terraform, visite o [site oficial](https://www.terraform.io/downloads.html) e siga as instruções para seu sistema operacional.

## Configuração

1. **Clone o repositório**:

   ```bash
   git clone https://github.com/codions/azure-cluster-terraform.git
   cd azure-cluster-terraform
   ```

2. **Inicialize o Terraform**:

   Isso baixará os plugins necessários para sua configuração.

   ```bash
   terraform init
   ```

3. **Crie um plano Terraform**:

   Este comando criará um plano e mostrará o que será feito quando você executar o comando `apply`.

   ```bash
   terraform plan
   ```

   Verifique se tudo está correto e preste atenção a qualquer erro ou aviso.

4. **Aplicar mudanças**:

   Ao ter certeza de que tudo está correto com o plano, aplique as mudanças.

   ```bash
   terraform apply
   ```

   Este comando perguntará se você deseja aplicar as mudanças. Digite "yes" para prosseguir.

5. **Destruir infraestrutura**:

   Se, por qualquer motivo, você precisar destruir sua infraestrutura criada pelo Terraform, use:

   ```bash
   terraform destroy
   ```

   Novamente, será solicitado que confirme a destruição. Digite "yes" para prosseguir.

## Observações

1. Lembre-se de que qualquer recurso criado pelo Terraform no Azure pode gerar custos. Certifique-se de monitorar seus recursos e custos no portal do Azure.

2. Antes de fazer o `terraform apply`, sempre confira o plano (com `terraform plan`) para evitar surpresas.

3. Mantenha seus arquivos `.tfstate` (gerados após o `apply`) seguros e, idealmente, armazene-os em um backend remoto (como o Azure Blob Storage).