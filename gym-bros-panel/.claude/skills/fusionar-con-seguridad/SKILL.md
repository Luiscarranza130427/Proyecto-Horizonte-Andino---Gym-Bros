---
name: fusionar-con-seguridad
description: >-
  Procedimiento para integrar ramas y pull requests en el repositorio de Gym
  Bros sin romper `main`. Usar antes de fusionar cualquier PR, al apilar varias
  ramas dependientes, y siempre que haya más de una PR abierta a la vez.
---

# Fusionar sin romper `main`

Este procedimiento existe porque `main` ya se rompió una vez y una PR se cerró
sola. Ambas cosas eran evitables.

## La regla que resume todo

**Verificar la fusión que se va a hacer, no una parecida.**

Comprobar que unas ramas integran bien en una rama de pruebas propia **no**
equivale a comprobar la fusión que hará GitHub. La base común es distinta y el
resultado puede serlo también.

## 1. Antes de fusionar una PR

```bash
git fetch origin
git checkout -b prueba/fusion origin/main
git merge --no-edit origin/<rama-de-la-pr>
```

Sobre ese resultado exacto:

```bash
npm run lint && npm run format:check && npm run test:coverage && npm run build
```

Y el barrido de declaraciones duplicadas, que es el fallo que Git no marca:

```bash
for f in $(git ls-files 'src/**/*.js' 'src/**/*.vue'); do
  grep -oE "^(const|let|function|class) [a-zA-Z_$][a-zA-Z0-9_$]*" "$f" \
    | sort | uniq -d | sed "s|^|$f: |"
done
```

Si todo está limpio, borrar la rama de prueba y fusionar en GitHub.

> Git puede combinar dos ediciones textualmente compatibles y producir
> JavaScript inválido. Pasó con dos `const cargarMock`: `main` quedó con un
> `SyntaxError` y 21 pruebas rojas. `npm run lint` lo detecta en segundos.

## 2. Si hay PRs apiladas

Una PR apilada es la que tiene como base otra rama, no `main`.

**Nunca borrar una rama que sea la base de otra PR.** GitHub cierra la PR
dependiente y **no se puede reabrir**: hay que crearla de nuevo desde cero.

Orden correcto:

1. Fusionar la PR de abajo **sin** `--delete-branch`.
2. Reapuntar la siguiente: `gh pr edit <N> --base main`.
3. Comprobar que su diff ya sólo contiene sus propios cambios.
4. Repetir hacia arriba.
5. Borrar las ramas al final, cuando ninguna PR las use como base.

Antes de reapuntar, confirmar que la base vieja ya no aporta nada:

```bash
git diff --stat origin/main origin/<base-vieja>   # vacío = seguro reapuntar
```

## 3. Después de fusionar

No basta con haber verificado antes. Sobre `main` ya fusionado:

```bash
git checkout main && git pull --ff-only origin main
npm run lint && npm run test && npm run build
```

Y comprobar que CI terminó en verde de verdad, mirando los pasos:

```bash
gh run list --limit 3
gh run view <id> --json jobs --jq '.jobs[].steps[] | "\(.name) -> \(.conclusion)"'
```

Una ejecución «cancelada» no es una ejecución correcta: relanzarla
(`gh run rerun <id>`) y confirmar que pasa.

## 4. Qué NO hacer

- Fusionar varias PRs seguidas sin verificar `main` entre una y otra. Si la
  segunda rompe, no se sabrá cuál fue.
- Dar por bueno un `merge-tree` sin conflictos: detecta conflictos textuales, no
  semánticos.
- Fusionar trabajo propio sin revisión cuando hay alguien que pueda revisarlo.
