# Examples

The user is the logged-in `gh` user. Here it is a synthetic user, Kari Nordmann, with the login `kari-nordmann`.

## Markdown

```bash
scripts/signature.sh output_format=markdown model="<model>" editor="<editor>"
```

```text
🤖 Generated with AI by [Kari Nordmann](https://github.com/kari-nordmann) with <model> in <editor>
```

## GitHub

```bash
scripts/signature.sh output_format=GitHub model="<model>" editor="<editor>"
```

```text
🤖 Generated with AI by @kari-nordmann with <model> in <editor>
```

## Norwegian, with a source line

```bash
scripts/signature.sh output_format=markdown language=no model="<model>" editor="<editor>" basis="renewal-service logs, 2026-11-10 to 2026-11-16, n=4120"
```

```text
Kilde: renewal-service logs, 2026-11-10 to 2026-11-16, n=4120

🤖 Generert med KI av [Kari Nordmann](https://github.com/kari-nordmann) med <model> i <editor>
```

## Jira fragment

```bash
scripts/signature.sh output_format=JIRA model="<model>" editor="<editor>"
```

```json
{"type":"paragraph","content":[{"type":"text","text":"🤖 Generated with AI by Kari Nordmann with <model> in <editor>","marks":[{"type":"em"}]}]}
```

## Not logged in

```text
Error: no logged-in GitHub user. Run 'gh auth login' and try again.
```
