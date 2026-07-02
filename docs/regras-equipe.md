# Regras da Equipe — Complexo: Breach

> Sem regras combinadas, projetos de jogo quebram por causa de comunicação, não de código.

## Regras de código

- Nunca commitar diretamente na branch `main` — sempre via Pull Request
- Nunca modificar código fora do escopo da sua task sem avisar o líder
- Todo script novo precisa de comentário explicando o que faz
- Erros de lint do Selene devem ser resolvidos antes de abrir PR
- Usar nomes em inglês para variáveis e funções — padrão do Roblox

## Regras de comunicação

- Avisar no Discord se vai atrasar mais de 1 dia em relação ao prazo
- Dúvidas sobre a task vão para o canal `#dev` antes de perguntar direto ao líder
- Prints ou vídeos de progresso são bem-vindos e motivam a equipe
- Pull Request sem resposta por mais de 48h: dev pode cobrar o líder

## Regras de branches

- Nomenclatura obrigatória: `feature/nome`, `fix/nome`, `build/nome`, `hotfix/nome`
- Deletar a branch após o merge ser aprovado
- Fazer `git pull` na main antes de criar uma branch nova
- Nunca trabalhar na mesma branch que outro dev sem avisar

## Fluxo completo do dia a dia

| Etapa | Quem / O que acontece |
|---|---|
| 1. Líder cria a task | Abre Issue com template → atribui ao dev |
| 2. Dev aceita | Comenta na Issue → cria branch com o nome da task |
| 3. Dev desenvolve | Codifica → testa localmente → Selene sem erros |
| 4. Dev abre PR | Preenche template de PR → abre Pull Request para main |
| 5. Líder revisa | Usa checklist → testa → aprova ou reprova com comentários |
| 6a. Aprovado | Merge na main → fecha a Issue → avisa a equipe |
| 6b. Reprovado | Dev corrige → atualiza o mesmo PR → volta para etapa 5 |
| 7. Deploy | Líder publica nova versão no Roblox Studio |

## Comandos git do dia a dia

```bash
git pull origin main                    # atualiza sua main local
git checkout -b feature/minha-task      # cria nova branch
git add .                               # prepara arquivos para commit
git commit -m 'feat: descrição curta'   # salva o progresso
git push origin feature/minha-task      # sobe para o GitHub
git checkout main && git pull           # volta pra main atualizada
```
