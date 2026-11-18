# Examples

## Merging both sides

`app.ts`: main added `welcome` + a `log` import, feature added `farewell` + a `shout` import. Correct: both imports, `greet` + `welcome` + `farewell`. Wrong: `--theirs`, losing `welcome`.

`package.json`: main bumped `left-pad`, feature added `is-odd`. Correct: union with main's version of `left-pad`. Then `pnpm install` for the lockfile, not YAML splicing.
