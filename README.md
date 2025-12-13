# Zed Toolbox

Singleplayer-only cheat menu for Project Zomboid focused on fast item spawning, curated presets, and a smooth UI experience.

## 🎯 Visão Geral
- **Plataforma:** Project Zomboid (Build 41+)
- **Modo:** Apenas singleplayer (desabilita automaticamente em multiplayer)
- **Atalho padrão:** Insert abre/fecha o menu (configurável em `CheatMenuMain.lua`)
- **Versão:** 1.0.0

## ✨ Recursos Principais
- **Catálogo inteligente:** Varre todos os itens registrados pelo `ScriptManager`, organiza por categoria (Armas, Munição, Bolsas, Comida, Médico, Diversos) e ordena alfabeticamente.
- **Busca instantânea:** Filtra tanto pelo nome exibido quanto pelo `BaseID`, permitindo localizar itens rapidamente.
- **Favoritos persistentes:** Salve combinações frequentes de item + quantidade + destino (inventário/chão) e recupere com um clique. Persistência via `ModData`, sem necessidade de arquivos externos.
- **Presets configuráveis:** Monte listas completas de itens para spawn automático. Perfeito para kits de início, loadouts ou testes rápidos.
- **Spawner flexível:** Escolha entre adicionar direto ao inventário ou derrubar no chão do jogador. Quantidade validada (1–100) para evitar travamentos acidentais.
- **UI polida:** Painel drag-and-drop, listas com highlight, botões de ação primária e indicadores visuais de status (sucesso/erro).
- **Internacionalização:** Strings em inglês (EN) e português brasileiro (PT-BR). Fácil extensão adicionando novos arquivos em `media/lua/shared/Translate/`.
- **Logs robustos:** `ZedToolboxLogger` registra qualquer exceção em `logs/error-<contexto>-<timestamp>.txt`, facilitando suporte e depuração.

## 📦 Instalação
1. **Steam Workshop (recomendado):** publique/assine normalmente; o `mod.info` já referencia `ZedToolbox` como pack.
2. **Instalação manual:**
   - Copie a pasta `ZedToolBox` para `Zomboid/mods/` no seu usuário.
   - Certifique-se de manter a estrutura `media/lua/...` e o arquivo `mod.info` no diretório raiz.
3. Ative o mod pelo menu principal de Project Zomboid antes de carregar o save.

## 🕹️ Como Usar
1. Inicie/continue um save singleplayer.
2. Pressione **Insert** para abrir o menu.
3. Navegue pelas categorias à esquerda, use a busca para filtrar e selecione o item desejado.
4. Defina quantidade e destino (Inventário ou Chão) no painel inferior.
5. Clique em **Spawn** ou dê duplo clique na lista de itens para spawn imediato.

> ✅ O menu só é carregado quando um jogador local (index 0) está pronto, evitando erros na tela de carregamento.

## ⭐ Favoritos & Presets
- **Adicionar favorito:** selecione um item, configure quantidade/destino e clique em **Add Favorite**.
- **Spawn favorito:** escolha na combo de favoritos e use **Spawn Favorite**.
- **Presets:** dê um nome, monte sua lista e salve. Você pode aplicar (preencher campos) ou spawnar todos os itens de uma vez.
- Dados ficam em `ModData["ZedToolbox"]`, permitindo que sobrevivam a múltiplos saves no mesmo perfil.

## 🌎 Tradução
- Arquivos de idioma em `media/lua/shared/Translate/<Locale>/ZedToolbox_<LOCALE>.txt`.
- Para adicionar um novo idioma: duplique o arquivo EN, traduza as chaves e atualize o nome da pasta para o código desejado (ex.: `FR`, `ES`).

## 🛠️ Configuração & Debug
- **Atalho personalizado:** edite `CheatMenuMain.Config.toggleKey` em `CheatMenuMain.lua` para outro código de tecla (`Keyboard.KEY_*`).
- **Resetar catálogo:** chame `CheatMenuItems.refresh()` pelo console para reconstruir a lista após instalar mods que adicionem itens.
- **Logs:** consulte `Zomboid/mods/ZedToolbox/logs/` para investigar erros capturados por `safeCall`.

## 📁 Estrutura Essencial
```
ZedToolBox/
├─ mod.info
└─ media/
   └─ lua/
      ├─ client/
      │  ├─ CheatMenuMain.lua      # Toggle e bindings
      │  ├─ CheatMenuUI.lua        # Painel completo (favoritos, presets, busca)
      │  └─ CheatMenuSpawner.lua   # Lógica de spawn / validação
      └─ shared/
         ├─ CheatMenuItems.lua     # Catálogo e categorização
         ├─ CheatMenuLogger.lua    # Wrapper resiliente de log
         ├─ ZedToolboxLogger.lua   # Escrita de arquivos de log
         └─ CheatMenuText.lua      # Helper de tradução
```

## 🙌 Créditos
- **Autor:** CodeMaster (aka robso)
- **Contribuições:** feedback da comunidade Project Zomboid BR.

Sinta-se à vontade para abrir issues ou Pull Requests com sugestões, traduções adicionais e melhorias gerais. Bons testes e divirta-se dominando Knox County!
