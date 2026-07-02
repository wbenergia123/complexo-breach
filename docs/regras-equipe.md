# Regras da Equipe — Complexo: Breach

> Sem regras combinadas, projetos de jogo quebram por causa de comunicação, não de código.

## Papéis da equipe

| Papel | Responsabilidades |
|---|---|
| **Pai** (admin GitHub) | Define tasks, revisa PR, aprova merge, publica o jogo |
| **Filho** (Collaborator) | Cria branch, codifica/builda, abre Pull Request |
| **Ambos** | Testam juntos no Roblox |

## Fluxo do dia a dia

```
Pai define a tarefa (Issue no GitHub)
       ↓
Pai ou Filho cria branch → codifica/builda
       ↓
Filho abre Pull Request
       ↓
Pai revisa → aprova → merge na main
       ↓
Ambos testam juntos no Roblox
       ↓
Próxima feature
```

> **Regra principal:** ninguém commita direto na `main`. Tudo passa por branch + Pull Request. Isso protege o jogo de quebrar por erro de alguém.

## Regras de código

- Nunca commitar diretamente na branch `main` — sempre via Pull Request
- Nunca modificar código fora do escopo da sua task sem avisar o pai
- Todo script novo precisa de comentário explicando o que faz
- Erros de lint do Selene devem ser resolvidos antes de abrir PR
- Usar nomes em inglês para variáveis e funções — padrão do Roblox

## Regras de branches

- Nomenclatura obrigatória: `feature/nome`, `fix/nome`, `build/nome`, `hotfix/nome`
- Deletar a branch após o merge ser aprovado
- Fazer `git pull` na main antes de criar uma branch nova

## Comandos git do dia a dia

```bash
git pull origin main                    # atualiza sua main local
git checkout -b feature/minha-task      # cria nova branch
git add .                               # prepara arquivos para commit
git commit -m 'feat: descrição curta'   # salva o progresso
git push origin feature/minha-task      # sobe para o GitHub
git checkout main && git pull           # volta pra main atualizada
```
