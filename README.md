# Easy Asset — App Mobile

Aplicativo Android do **Easy Asset**, o sistema de gestão de laboratórios e ativos do Projeto Integrador IV (ADS, SENAI Roberto Mange). Feito em **Flutter**, consome a mesma API REST do [back-end Django](https://github.com/MiguelSantos1910/ProjetoIntegrador_Backend) usada pelo [painel web](https://github.com/MiguelSantos1910/ProjetoIntegrador_Frontend).

O app leva a operação até o laboratório: **identifica o equipamento pelo QR Code**, mostra os dados do ativo sobre a imagem da câmera, **abre e acompanha chamados de manutenção** e mostra **em que sala** cada ativo está. As permissões são decididas pela API; o app só esconde o que o papel do usuário não pode usar.

## Sumário

- [Funcionalidades](#funcionalidades)
- [Papéis e permissões no app](#papéis-e-permissões-no-app)
- [Tecnologias](#tecnologias)
- [Arquitetura](#arquitetura)
- [Estrutura do projeto](#estrutura-do-projeto)
- [Executando o app](#executando-o-app)
- [Gerando o APK](#gerando-o-apk)
- [Usuários de teste](#usuários-de-teste)
- [Endpoints da API usados](#endpoints-da-api-usados)
- [Permissões do Android](#permissões-do-android)
- [Requisitos do plano atendidos](#requisitos-do-plano-atendidos)
- [Limitações conhecidas](#limitações-conhecidas)
- [Créditos e licenças](#créditos-e-licenças)
- [Repositórios](#repositórios)

## Funcionalidades

### Login e cadastro
- Login com usuário e senha (JWT). Mensagens claras para senha errada, **bloqueio após 5 tentativas** e falta de conexão.
- Cadastro público (nome, usuário, e-mail e senha): toda conta nasce como **aluno**. Os erros de validação da API (senha fraca, usuário já existente) aparecem embaixo de cada campo.

### Início (dashboard)
- Saudação com o nome do usuário.
- **Resumo dos ativos** (total, disponíveis, em manutenção e devolvidos) e gráficos por status.
- **Chamados em aberto**: os 5 mais recentes, com atalho para a lista completa.
- **Movimentações recentes**: os últimos eventos do histórico dos ativos (cadastro, manutenção, devolução, inativação, reativação e retorno ao uso), com quem fez e quando.

### Escanear QR Code
- Câmera com moldura de leitura, lanterna e troca de câmera.
- Ao ler o QR do ativo (gerado no painel web), consulta a API e mostra **sobre a câmera** o nome, o status, o tipo, o patrimônio e o local.
- Professor e suporte podem **abrir um chamado** direto do resultado.
- Reconhece QR de outros sistemas ("QR Code não reconhecido") sem consultar a API.
- **Digitar código**: consulta convencional quando a câmera não funciona ou a permissão é negada.

### Ativos
- Lista em cards, com busca por nome, patrimônio, tipo, sala ou código QR, e filtro por status (inativos ocultos por padrão).
- Detalhe do ativo com tipo, patrimônio, local, código QR e datas, e botão **Abrir chamado**.

### Chamados (ordens de manutenção)
- **Abrir chamado**: escolha do ativo (lista com busca), descrição, responsável e custo estimado. Opção de marcar o ativo como **"Em manutenção"**, o que registra a movimentação no histórico.
- **Acompanhar chamados**: lista com filtros (abertos, por status ou todos) e busca por número, ativo, descrição ou responsável.
- **Detalhe do chamado**: dados do ativo, responsável, datas, custo, descrição e **histórico** (linha do tempo dos logs). Professor e suporte podem **iniciar o atendimento**, **concluir** (com a opção de devolver o ativo ao uso) ou **cancelar**.

### Localizar ativo
- Busca um ativo e mostra **em que sala ele está**.
- Lista as salas com a quantidade de ativos e o resumo por status; tocar numa sala lista os ativos dela.
- Professor e suporte podem **mover o ativo de sala**.

### Configurações
- Perfil (nome, usuário, e-mail e papel). Nome e e-mail são editáveis só pelo professor, como no back-end.
- **Alterar a própria senha** (todos os papéis), com as regras de força da API.
- **Conexão**: servidor da API em uso e botão **Testar conexão** (mostra "Online · N ms" ou "Sem resposta").
- Sobre o app e **Sair da conta** (invalida a sessão também no servidor).

## Papéis e permissões no app

| Ação | Aluno | Suporte | Professor |
|---|:-:|:-:|:-:|
| Consultar ativos, chamados, salas e histórico | ✅ | ✅ | ✅ |
| Ler QR Code e ver os dados do ativo | ✅ | ✅ | ✅ |
| Abrir chamado | ❌ | ✅ | ✅ |
| Iniciar, concluir ou cancelar chamado | ❌ | ✅ | ✅ |
| Mover ativo de sala | ❌ | ✅ | ✅ |
| Editar nome e e-mail do perfil | ❌ | ❌ | ✅ |
| Alterar a própria senha | ✅ | ✅ | ✅ |

Quem decide de verdade é a API, que responde `403` a qualquer operação não permitida. O app lê o papel em `GET /api/contas/me/` só para esconder os botões.

## Tecnologias

| Tecnologia | Uso |
|---|---|
| Flutter 3.47 / Dart 3.12 | Aplicativo Android |
| [provider](https://pub.dev/packages/provider) | Estado da sessão (tokens e usuário logado) |
| [http](https://pub.dev/packages/http) | Chamadas à API REST |
| [mobile_scanner](https://pub.dev/packages/mobile_scanner) | Câmera e leitura do QR Code |
| [flutter_svg](https://pub.dev/packages/flutter_svg) | Ícone do Easy Asset |

## Arquitetura

```text
 presentation/pages      telas (uma por rota)
 presentation/widgets    componentes reutilizáveis (FormData, BotaoApp, CardApp,
                         CardChamado, StatusBadge, LinhaDetalhe...)
 presentation/providers  SessaoProvider: tokens, usuário, papel, login e logout
        │
        ▼
 data/repositories       AtivosService, OrdensService, UsuariosService (HTTP)
 data/models             Ativo, OrdemManutencao, LogOrdem, Movimentacao, Usuario
        │
        ▼
 core/api                ApiConfig (URL da API) e ApiException (erros prontos)
        │  HTTP + JWT
        ▼
 API Django (back-end)
```

- **Sessão:** o `SessaoProvider` guarda os tokens **só em memória** (fechou o app, é preciso entrar de novo). O método `comToken` envia o token em cada chamada e, se a API responder `401`, **renova o token** e repete; se não der, encerra a sessão e volta ao login.
- **Erros:** os serviços lançam `ApiException` com uma mensagem pronta e os erros por campo do Django REST Framework, que as telas mostram embaixo de cada campo.
- **Acentos:** as respostas são decodificadas em UTF-8 de forma explícita, porque a API não envia o charset.

## Estrutura do projeto

```text
lib/
├── core/
│   ├── api/                 # api_config.dart (URL), api_exception.dart
│   └── utils/               # formatar_data.dart
├── data/
│   ├── models/              # modelos da API
│   └── repositories/        # serviços HTTP
├── presentation/
│   ├── pages/               # login, cadastro, homePage, ativos, qrCode,
│   │                        # ordemServico, statusOrdem, localizador, configuracoes
│   ├── providers/           # sessao_provider.dart
│   └── widgets/
│       ├── layout/          # MainLayout (barra de navegação inferior)
│       └── shared/          # componentes reutilizáveis e tema
├── routes/                  # routes.dart (rotas protegidas pela sessão)
└── main.dart
android/                     # projeto Android (manifesto e Gradle)
```

## Executando o app

### Pré-requisitos

- Flutter 3.47 ou mais recente (`flutter doctor` com o **Android toolchain** em ✓)
- Android SDK (instalado pelo Android Studio)
- Celular Android 7.0+ com depuração USB, ou um emulador
- [Back-end](https://github.com/MiguelSantos1910/ProjetoIntegrador_Backend) rodando

### Passo a passo

```bash
# 1. Dependências
flutter pub get

# 2. Back-end acessível pela rede (na pasta do back-end)
python manage.py runserver 0.0.0.0:8000

# 3. App, informando o endereço da API
flutter run --dart-define=API_URL=http://10.0.2.2:8000/api       # emulador
flutter run --dart-define=API_URL=http://192.168.0.10:8000/api   # celular na mesma rede
```

Sem `--dart-define`, o app usa `http://127.0.0.1:8000/api`, que no celular ou no emulador é **o próprio aparelho**. No celular, use o IP do computador onde o back-end está rodando.

Para o app e o painel web mostrarem os mesmos dados, os dois precisam apontar para **a mesma API**. Em **Configurações → Conexão** o app mostra o endereço em uso e permite testar a conexão.

## Gerando o APK

```bash
flutter build apk --release --dart-define=API_URL=http://<endereço-da-api>/api
# arquivo gerado: build/app/outputs/flutter-apk/app-release.apk
```

Para instalar, copie o `.apk` para o celular, abra o arquivo e permita a instalação de fonte desconhecida **só para ele**. Na primeira leitura de QR, permita o uso da câmera.

## Usuários de teste

Use uma conta de cada papel. As mesmas contas valem no painel web, desde que os dois usem a mesma API.

| Usuário sugerido | Papel |
|---|---|
| `professor_teste` | `PROFESSOR` |
| `suporte_teste` | `SUPORTE` |
| `aluno_teste` | `ALUNO` |

As contas são criadas pelo terminal do back-end (comandos na seção [Usuários de teste](https://github.com/MiguelSantos1910/ProjetoIntegrador_Backend#usuários-de-teste) do README dele) ou pela tela de **cadastro** do app (toda conta nasce aluno; o professor muda o papel no painel web, em Perfis). As senhas **não ficam no repositório** e são entregues à banca separadamente.

## Endpoints da API usados

| Tela | Método e endpoint |
|---|---|
| Login | `POST /api/token/`, `POST /api/token/refresh/`, `GET /api/contas/me/` |
| Cadastro | `POST /api/contas/usuarios/` |
| Início | `GET /api/ativos/`, `GET /api/ordens_manutencao/`, `GET /api/historico/` |
| Escanear QR | `GET /api/ativos/?codigo_qr=<código>` |
| Ativos | `GET /api/ativos/` |
| Abrir chamado | `POST /api/ordens_manutencao/`, `PATCH /api/ativos/<id>/` (status) |
| Detalhe do chamado | `GET /api/ordens_manutencao/<id>/`, `GET /api/ordens_manutencao/<id>/logs/`, `PATCH /api/ordens_manutencao/<id>/` (status), `GET /api/ativos/<id>/` |
| Localizar ativo | `GET /api/ativos/`, `PATCH /api/ativos/<id>/` (sala) |
| Configurações | `PATCH /api/contas/usuarios/<id>/`, `PATCH /api/contas/usuarios/<id>/senha/`, `GET /api/health/` |
| Sair | `POST /api/contas/logout/` |

A documentação completa da API está no [README do back-end](https://github.com/MiguelSantos1910/ProjetoIntegrador_Backend#endpoints-da-api).

## Permissões do Android

| Permissão | Por quê |
|---|---|
| `INTERNET` | Chamadas à API |
| `CAMERA` | Leitura do QR Code (pedida na primeira leitura) |
| `usesCleartextTraffic="true"` | Libera HTTP, porque a API ainda não tem HTTPS. **Risco aceito para a demonstração** (R9 em `docs/seguranca.md` do back-end); deve sair quando a API tiver certificado. |

O app não pede localização nem outros dados do aparelho.

## Requisitos do plano atendidos

**1.3.2 Aplicações Mobile**

| Entrega | Onde |
|---|---|
| Tela de login e acesso ao sistema | Login |
| Leitura de QR Code para identificar o ativo | Escanear QR |
| Consulta com nome, patrimônio, local e situação | Escanear QR, Ativos e Localizar ativo |
| Registro de uma ação (movimentação ou ordem de serviço) | Abrir chamado (com a movimentação "Em manutenção") e ações do detalhe do chamado |
| Arquivo instalável e instruções | [Gerando o APK](#gerando-o-apk) |

**1.3.6 Realidade Aumentada**

| Entrega | Onde |
|---|---|
| Reconhecer um código associado a um ativo | Escanear QR |
| Três ou mais informações sobre a imagem da câmera | Nome, status, tipo, patrimônio e local |
| Dados pela API | `GET /api/ativos/?codigo_qr=` |
| Consulta convencional como alternativa | Digitar código, Ativos e Localizar ativo |

## Limitações conhecidas

- **HTTP sem criptografia** enquanto a API não tiver HTTPS (ver permissões acima).
- **Sem testes automatizados** no app; a validação das regras e permissões está nos testes do back-end.
- **Sessão só em memória:** ao fechar o app, é preciso entrar de novo.
- **APK de demonstração:** o `applicationId` ainda é `com.example.mobile_integrador` e o build de release usa a chave de depuração. Para publicar em loja, é preciso trocar o identificador e assinar com uma chave própria.
- **"Responsável" do ativo** não existe na API; o app mostra o local (sala) e a situação.
- **Mudar a sala** não gera evento no histórico do ativo (limitação do back-end).
- **Resumo da Home:** os cards por status não incluem os ativos inativos.
- **Troca de senha** não pede a senha atual (regra do back-end).

## Créditos e licenças

- Flutter e Dart: BSD-3-Clause.
- Pacotes: provider (MIT), http (BSD-3-Clause), mobile_scanner (BSD-3-Clause; no Android usa o Google ML Kit, sob os termos do Google), flutter_svg (MIT), cupertino_icons (MIT), flutter_launcher_icons (MIT).
- Fonte Roboto e Material Icons: Apache 2.0.
- Ícone e logo do Easy Asset: identidade visual do projeto (`lib/assets/`).
- Os dados mostrados nas demonstrações são fictícios.

## Repositórios

| Parte | Repositório |
|---|---|
| App mobile (este) | https://github.com/MiguelSantos1910/ProjetoIntegrador_Mobile |
| Back-end (API) | https://github.com/MiguelSantos1910/ProjetoIntegrador_Backend |
| Painel web | https://github.com/MiguelSantos1910/ProjetoIntegrador_Frontend |

**Projeto:** Easy Asset, Projeto Integrador IV, ADS, SENAI Roberto Mange.
