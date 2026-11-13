# FruitPlace

Jogo de fazenda e feira em 3D isométrico pixelado (Godot 4.7). Plante no quintal,
leve a colheita para a feira, atenda clientes e pague as contas toda noite.

## Como jogar

| Tecla | Ação |
|---|---|
| WASD / setas | andar |
| E / Espaço | interagir |
| Q | trocar a semente selecionada |
| I / Tab | inventário |
| Esc | fechar menu / pausar |

O jogo salva sozinho toda manhã (ao acordar). Em **Continuar**, no menu inicial,
você volta para esse dia. O save e as configurações ficam em `user://`
(`save.json` e `settings.cfg`); falência apaga o save. A abertura só toca no
primeiro **Novo jogo** (dá para rever pelo menu).

## Rodar e testar

Use o executável da Godot na raiz do projeto:

```bash
godot --path .                                           # jogar
godot --headless --path . res://tests/test_runner.tscn   # teste de ponta a ponta (código 0 = passou)
godot --path . res://tests/ui_tour.tscn -- <pasta>       # prints da interface (precisa de janela)
godot --path . res://tests/screenshot_tour.tscn -- <pasta>  # prints de cada mapa e horário
godot --headless --path . --import                       # depois de criar scripts com class_name ou novos png/wav
```

O `test_runner` usa arquivos de save próprios (`test_save.json`), então não mexe
no seu progresso.

## Geradores (`tools/`)

Arquivos gerados por código. Rodar de novo **sobrescreve** ajustes feitos à mão
nos arquivos de saída:

```bash
godot --headless --path . -s tools/build_props.gd    # materiais, props (.tscn) e o humanoide
godot --headless --path . -s tools/gen_textures.gd   # assets/textures/*.png
godot --headless --path . -s tools/gen_audio.gd      # assets/audio/*.wav
```

- `scenes/props/**/*.tscn`, `scenes/characters/humanoid.tscn` e `assets/materials/*.tres`
  vêm de `build_props.gd`: mudanças permanentes de forma vão **no gerador**.
- As texturas e os sons podem ser trocados por arquivos próprios mantendo o nome.
- Depois de `gen_textures.gd`, reaplique `detect_3d/compress_to=0` nos `.import` das texturas.

## Estrutura

- `autoload/` — estado global: tempo, economia, inventário, jardim, status do
  jogador, troca de mapas, sons e save.
- `data/` e `resources/` — culturas, adubos, comidas e clientes (`.tres`) e o `Catalog`
  que os indexa.
- `scenes/` — mapas (casa, quintal, feira), jogador, clientes e props.
- `ui/` — HUD, menus, inventário, cinemática e tema.
- `tests/` — teste de ponta a ponta e passeios de captura de tela.
