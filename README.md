# Claude Sessions Manager for Windows

Dashboard nativo Windows para gerenciar sessões do Claude Code.

![Features](https://img.shields.io/badge/features-table%20%7C%20tamagotchi%20%7C%20git%20info-green)
![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-blue)
![License](https://img.shields.io/badge/license-MIT-blue)

## Features

- ✅ **Table Dashboard** - Veja todas as sessões ativas
- ✅ **Tamagotchi View** - Criaturas pixel art para cada sessão
- ✅ **Git Branch Info** - Mostra repo::branch de cada sessão
- ✅ **Context Bar** - Uso de tokens com cores (verde/amarelo/vermelho)
- ✅ **Status em Tempo Real** - Working, Input, Idle, New
- ✅ **Nativo Windows** - Sem WSL, sem tmux
- ✅ **PowerShell TUI** - Interface no terminal
- ✅ **Auto-detecção** - Encontra sessões automaticamente

## Instalação

```powershell
# Clone o repositório
git clone https://github.com/Adrian-opo/claude-sessions-win.git
cd claude-sessions-win

# Execute
.\claude-sessions.ps1
```

## Uso

```powershell
# Table Dashboard (padrão)
.\claude-sessions.ps1

# Tamagotchi View
.\claude-sessions.ps1 view

# Table View (explícito)
.\claude-sessions.ps1 table

# JSON output
.\claude-sessions.ps1 json

# Criar nova sessão
.\claude-sessions.ps1 new

# Resume sessão existente
.\claude-sessions.ps1 resume

# Pular pra próxima Input
.\claude-sessions.ps1 next
```

## Keybindings (Table View)

| Tecla | Ação |
|-------|------|
| `j` / `↓` | Próxima sessão |
| `k` / `↑` | Sessão anterior |
| `Enter` | Abrir sessão |
| `i` | Pular pra próxima Input |
| `x` | Matar sessão |
| `v` | Alternar pra Tamagotchi View |
| `r` | Refresh |
| `q` | Sair |

## Keybindings (Tamagotchi View)

| Tecla | Ação |
|-------|------|
| `j` | Próxima página |
| `k` | Página anterior |
| `v` | Alternar pra Table View |
| `q` | Sair |

## Status das Sessões

| Status | Descrição | Cor | Criatura |
|--------|-----------|-----|----------|
| **Working** | Claude está respondendo ou rodando tools | 🟢 Verde | Happy blob com sparkles |
| **Input** | Aguardando aprovação/permissão | 🟠 Laranja | Angry blob |
| **Idle** | Aguardando seu próximo prompt | 🔵 Azul | Sleeping blob com Zzz |
| **New** | Sem interação ainda | ⚪ Cinza | Egg |

## Screenshots

### Table View
```
+------+------------------+----------+----------------------+------------------+----------+--------+
| #    | Session          | Status   | Repo/Branch          | Model            | Context  | Last   |
+------+------------------+----------+----------------------+------------------+----------+--------+
| 1    | iog-services     | Working  | iog-services::feat   | sonnet           | 45k/200k | <1m    |
| 2    | frontend         | Input    | iog-new-frontend     | opus             | 12k/200k | 2m     |
+------+------------------+----------+----------------------+------------------+----------+--------+
```

### Tamagotchi View
```
  ┌────────────────────────────────────┐
  │ Room: iog-services                 │
  │ Sessions: 2                        │
  │                                    │
  │   ▄▄▄▄▄▄     ▄▄▄▄▄▄               │
  │   █●●●●█     █▼▼▼▼█               │
  │   █●●●●█     █▼▼▼▼█               │
  │   █●▀▀●█     █▼▄▄▼█               │
  │   █●●●●█     █▼▼▼▼█               │
  │   ▀▀█▀█▀     ▀▀█▀█▀               │
  │     █ █        █ █                 │
  │     ▀ ▀        ▀ ▀                 │
  │  iog-services  frontend            │
  └────────────────────────────────────┘
```

## Como Funciona

O script lê os arquivos que o Claude Code cria:

```
~/.claude/sessions/{PID}.json
~/.claude/projects/{hash}/*.jsonl
```

**Detecta o status analisando:**
- Se o processo tá rodando
- Context tokens do JSONL
- Timestamp da última mensagem
- Tipo de entry (user/assistant)

**Extrai Git info:**
- Lê `.git/HEAD` pra pegar branch atual
- Lê `.git/config` pra pegar nome do repo

## Requisitos

- Windows 10/11
- PowerShell 5.1+
- Claude Code instalado

## Roadmap

- [ ] Park/Unpark sessions (salvar e restaurar)
- [ ] Notificações Windows quando sessão precisar de input
- [ ] Histórico de sessões passadas
- [ ] Atalho global (Ctrl+Alt+C)
- [ ] Overlay mode (popup)

## Licença

MIT

## Contribuições

Issues e PRs são bem-vindos! 🚀
