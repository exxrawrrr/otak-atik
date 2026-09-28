# Quickstart

## Windows alpha path

```powershell
git clone https://github.com/exxrawrrr/otak-atik.git
cd otak-atik

powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1 -DryRun
powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1

otak-atik doctor
```

## Development checks

```powershell
npm run check
```

No `npm install` is required for the current CLI/test baseline because V0.1 intentionally uses only Node platform APIs.

## Explore

```powershell
otak-atik capabilities
otak-atik skills
otak-atik recipes
otak-atik policy
```

## Create a skill

Copy:

```text
templates/skill/
```

then add its metadata to:

```text
registries/skills.json
```

Finally:

```powershell
npm run validate
```
