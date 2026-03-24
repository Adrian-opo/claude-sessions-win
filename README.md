# Claude Sessions Manager for Windows

Dashboard nativo Windows para gerenciar sessões do Claude Code.

## Features

- ✅ **Table Dashboard** - Veja todas as sessões ativas
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
# Dashboard principal
.\claude-sessions.ps1

# Dashboard (alias)
.\claude-sessions.ps1 view

# JSON output (pra scripting)
.\claude-sessions.ps1 json

# Criar nova sessão
.\claude-sessions.ps1 new

# Resume sessão existente
.\claude-sessions.ps1 resume

# Pular pra próxima sessão aguardando input
.\claude-sessions.ps1 next
```

## Keybindings (Dashboard)

| Tecla | Ação |
|-------|------|
| `j` / `↓` | Próxima sessão |
| `k` / `↑` | Sessão anterior |
| `Enter` | Abrir sessão no terminal |
| `i` | Pular pra próxima Input |
| `x` | Matar sessão |
| `r` | Refresh |
| `q` | Sair |

## Status das Sessões

| Status | Descrição | Cor |
|--------|-----------|-----|
| **Working** | Claude está respondendo ou rodando tools | 🟢 Verde |
| **Input** | Aguardando aprovação/permissão | 🟠 Laranja |
| **Idle** | Aguardando seu próximo prompt | 🔵 Azul |
| **New** | Sem interação ainda | ⚪ Cinza |

## Como Funciona

O script lê os arquivos de sessão que o Claude Code cria:

```
~/.claude/sessions/{PID}.json
~/.claude/projects/{hash}/state.json
```

Detecta o status analisando o state.json de cada sessão.

## Requisitos

- Windows 10/11
- PowerShell 5.1+
- Claude Code instalado

## Roadmap

- [ ] Tamagotchi view (criaturas pixel art)
- [ ] Notificações quando sessão precisar de input
- [ ] Histórico de sessões
- [ ] Atalho no teclado global

## Licença

MIT
