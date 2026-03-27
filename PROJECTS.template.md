# Projects

Register your projects here. Each row becomes a menu item in `zoe-launch.sh`.

| key                      | name                      | source                                       | worktree                   | startup                                                                        |
|--------------------------|---------------------------|----------------------------------------------|----------------------------|--------------------------------------------------------------------------------|
| example                  | Example Project           | ~/projects/example                           | ~/zoe-example              |                                                                                |

## Column reference

| Column    | Description                                                              |
|-----------|--------------------------------------------------------------------------|
| key       | Short slug used for the git worktree branch name (lowercase, no spaces)  |
| name      | Display name shown in the launcher menu                                  |
| source    | Path to your project's source code                                       |
| worktree  | Path where the Zoe worktree will be created (default: ~/zoe-<key>)      |
| startup   | Optional shell command to run before launching (e.g. start a service)   |

## Adding projects

Either edit this file directly, or pick an unregistered directory from the launcher menu and it will prompt you and append the row automatically.

## Projects directory

By default the launcher scans `~/projects/` for unregistered directories.
Override by setting `ZOE_PROJECTS_DIR` in your shell environment:

```bash
export ZOE_PROJECTS_DIR=/mnt/data/projects
```
