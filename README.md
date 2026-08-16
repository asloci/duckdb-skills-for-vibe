# duckdb-skills-for-vibe
[DuckDB skills](https://github.com/duckdb/duckdb-skills) are Claude-centric, and there’s nothing wrong with that. This repo contains versions of the skills modified for Mistral’s Vibe, where applicable.

## Install

Manually copy the folder for each skill to your home skills folder:

`~/.agents/skills/`

Or use npx to install the kills globally for Vibe to use:

`npx skills add asloci/duckdb-skills-for-vibe -g -y`

## Example usage

Launch Vibe-CLI:

`vibe`

Use /atach-db skill to attach an existing DuckDB file and /query to run some SQL on one of the tables

`/attach-db /path/to/your-database.duckdb`

`/query SELECT * FROM my_table LIMIT 10`

## Includes

```
skills/
├── attach-db/
│   └── SKILL.md
├── convert-file/
│   └── SKILL.md
├── duckdb-docs/
│   └── SKILL.md
├── install-duckdb/
│   ├── SKILL.md
├── query/
│   └── SKILL.md
├── read-file/
│   └── SKILL.md
├── read-memories/
│   └── SKILL.md
├── s3-explore/
│   └── SKILL.md
├── spatial/
│   ├── SKILL.md
│   └── references/
│       ├── functions.md
│       └── overture.md
```

Note: Original README.md file and eval.sh script have been removed.

## Considerations

- I’m new to all of this but I plan to keep the original duckdb-skills in sync for vibe-cli.
- The temperature for mistral-medium-3.5 is set to 1.0 by default. Consider modifying the temperature to 0.7 or lower at `~/.vibe/config.toml`
