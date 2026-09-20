# config-server

**Servidor de configuração** do sistema. Centraliza as propriedades de todos os microsserviços, servindo-as a partir de um repositório Git.

## Stack

| Item | Versão |
|---|---|
| Java | 21 |
| Spring Boot | 4.1.1 |
| Spring Cloud | 2025.1.3 |

| Porta |
|---|
| 8888 |

## Como funciona

As configurações ficam em um repositório Git separado, com uma pasta por aplicação:

```
repositorio-cofiguracao-sistema-prd/
├── application.yml                  # propriedades comuns a todos
├── autenticacao-service/
│   └── autenticacao-service.yml
├── energia-service/
│   └── energia-service.yml
└── ...
```

Cada serviço busca a sua configuração no arranque:

```yaml
spring:
  config:
    import: 'vault://, configserver:http://config-server:8888'
```

Os valores sensíveis não ficam no Git: os arquivos trazem **placeholders** (`${autenticacaoDBPass}`) que o próprio serviço resolve contra o **Vault**.

## Consultando a configuração

```bash
curl -u <usuario>:<senha> http://localhost:8888/<aplicacao>/<perfil>
```

## Segurança

Protegido por **HTTP Basic**, com as credenciais vindas de `configServerUser` e `configServerPass` no Vault. O endpoint `/actuator/**` usa um usuário separado, com o perfil `ROLE_ACTUATOR`.

## Configuração

A aplicação não guarda configuração própria: ela busca tudo no arranque, via `spring.config.import`.

| Origem | O que vem de lá |
|---|---|
| **Vault** (`secret/application`) | segredos compartilhados: `JWTSecret`, credenciais de e-mail, AWS, Eureka |
| **Vault** (`secret/<nome-do-serviço>`) | segredos próprios, como as credenciais do banco |
| **Config Server** | `server.port`, `context-path`, datasource e demais propriedades |

### Variável de ambiente obrigatória

| Variável | Para que serve |
|---|---|
| `VAULT_TOKEN` | token de acesso ao Vault |

`VAULT_TOKEN` **não tem valor padrão**. Sem ela, o Spring envia a string literal `${VAULT_TOKEN}` ao Vault, recebe `403` e — como `spring.cloud.vault.fail-fast` vem desligado — o erro só aparece bem depois, disfarçado de placeholder não resolvido (`${...} is malformed`). Se quiser que a falha apareça na hora, ligue `spring.cloud.vault.fail-fast: true`.

Também são necessários `VAULT_HOST`, `VAULT_PORT` e `VAULT_SCHEME` quando o Vault não está em `localhost:8200` via `http`, e `CONFIG_SERVER_USER` / `CONFIG_SERVER_PASS` nos serviços que leem do Config Server.

## Como executar

```bash
# build
./mvnw clean package

# execução
VAULT_TOKEN=<seu-token> java -jar target/config-server-*.jar --spring.profiles.active=dev
```

A aplicação sobe em `http://localhost:8888`.

### Docker

O `Dockerfile` espera o jar já na raiz do projeto, com o nome `sistema-config-server.jar`:

```bash
./mvnw clean package
cp target/config-server-*.jar sistema-config-server.jar

docker build \
  --build-arg VAULT_HOST=<host> \
  --build-arg VAULT_TOKEN=<token> \
  -t config-server .
```
