# Complexo: Breach

FPS tático ambientado numa favela brasileira — desenvolvido no Roblox Studio.

## Stack

| Ferramenta | Uso |
|---|---|
| [Rojo 7.6.1](https://rojo.space) | Sync de scripts locais → Roblox Studio |
| [robloxstudio-mcp](https://github.com/boshyxd/robloxstudio-mcp) | Controle do Studio via Claude Code (70+ tools) |
| [Selene](https://github.com/Kampfkarren/selene) | Lint de Luau |
| [Wally](https://wally.run) | Gerenciador de pacotes Roblox |
| Meshy AI + Blender | Pipeline de modelos 3D |

## Setup local

```bash
# Instalar ferramentas via Rokit
rokit install

# Rodar servidor Rojo
rojo serve

# Rodar servidor MCP (para uso com Claude Code)
tail -f /dev/null | npx -y robloxstudio-mcp@next > /tmp/robloxstudio-mcp.log 2>&1 &
```

Depois no Studio: **Plugins → MCP Server → Connect**

## Estrutura

```
src/
  server/   → scripts do servidor (ServerScriptService)
  client/   → scripts do cliente (StarterPlayerScripts)
  shared/   → módulos compartilhados (ReplicatedStorage)
docs/
  regras-equipe.md          → regras e fluxo do dia a dia
  revisao-lider.md          → checklist de revisão de PR
  robloxstudio-mcp-setup.md → como configurar o MCP
.github/
  pull_request_template.md  → template de PR obrigatório
  ISSUE_TEMPLATE/task.md    → template de task/issue
```

## Docs

- [GDD — Game Design Document](docs/GDD.md)
- [Regras da equipe](docs/regras-equipe.md)
- [Checklist de revisão](docs/revisao-lider.md)
- [Setup MCP](docs/robloxstudio-mcp-setup.md)
