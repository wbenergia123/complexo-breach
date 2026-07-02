# Checklist de Revisão do Líder

O líder usa este checklist antes de aprovar qualquer Pull Request. Se algum item falhar, o PR volta para o dev com comentários específicos.

## 1. Funcionalidade

- [ ] Testei os passos descritos em "Como testar" e funcionou como esperado
- [ ] Todos os critérios de aceite da task estão atendidos
- [ ] Não encontrei bugs óbvios durante o teste
- [ ] O comportamento em casos extremos foi considerado (ex: jogador sem vida ao morrer)

## 2. Qualidade do código

- [ ] O código está legível e com nomes de variáveis claros
- [ ] Não tem código duplicado que poderia ser uma função
- [ ] Não tem `print()` ou comentários de debug esquecidos
- [ ] Scripts de servidor não têm lógica que deveria estar no cliente e vice-versa
- [ ] Operações de DataStore têm tratamento de erro (`pcall`)

## 3. Performance

- [ ] Não tem loops infinitos sem `task.wait()`
- [ ] Eventos são desconectados quando não precisam mais estar ativos
- [ ] Não tem operações pesadas no `RunService.Heartbeat` sem necessidade
- [ ] Assets importados estão dentro do limite de triângulos do Roblox (20k/mesh)

## 4. Segurança

- [ ] Toda ação importante é validada no servidor, não só no cliente
- [ ] RemoteEvents não aceitam dados sem validação de tipo e range
- [ ] Não tem exploit óbvio (ex: cliente enviando dano diretamente)

## 5. Decisão final

| Decisão | Ação |
|---|---|
| ✅ Aprovado | Merge na main — comunicar o dev |
| ⚠️ Aprovado com ressalvas | Merge mas abrir issue para melhorias futuras |
| ❌ Reprovado | Fechar o PR com comentários específicos — dev reabre após correções |

**Comentários:** _escrever aqui o feedback detalhado em caso de reprovação_
