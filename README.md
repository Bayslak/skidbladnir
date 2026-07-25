<p align="center">
  <img src="assets/skidbladnir_logo.png" alt="skidbladnir" width="256">
</p>

# skidbladnir

A minimal Unix-style shell written in [Odin](https://odin-lang.org/), built as a
project to learn the language and, maybe, to end up genuinely useful day to day.

The name comes from Skíðblaðnir, the ship in Norse myth that folds up small
enough to carry in a pocket. Fitting for a compact shell.

## Features

- Runs external programs and a set of built-in commands.
- A hand-written lexer that tokenizes input, with quoted arguments
  (`echo "bay is learning"` is one argument).
- **Pipelines** of any length: `cat file | grep foo | wc -l`.
- **Redirection**: `>`, `>>` (append), and `<` (input), including combinations
  like `grep TODO < in.txt > out.txt`.
- An interactive **line editor** built on raw terminal mode:
  - character echo and mid-line editing,
  - backspace,
  - command **history** (up/down arrows), named after Odin's raven Muninn,
  - **left/right cursor movement** with insert and delete at any position.

## Built-in commands

| Command | Description |
| --- | --- |
| `cd <dir>` | Change the current working directory. |
| `pwd` | Print the current working directory. |
| `munin` | Print the session command history. |
| `munin <n>` | Re-run the command at history index `n`. |
| `edda` | List all built-in commands and their descriptions. |
| `exit` | Exit the shell. |

## Line editor keys

| Key | Action |
| --- | --- |
| Left / Right | Move the cursor within the line. |
| Up / Down | Walk backward / forward through history. |
| Backspace | Delete the character before the cursor. |
| Esc Esc | Clear the current line. |
| Enter | Run the command. |

## Building and running

Requires the [Odin compiler](https://odin-lang.org/docs/install/). From the
project root:

```sh
odin run .
```

Or build a binary and run it:

```sh
odin build . -out:bin/skidbladnir
./bin/skidbladnir
```

### Platform note

skidbladnir targets Linux (including WSL). The line editor uses POSIX terminal
control (`termios`), which is Unix-only, so build and run it from a Linux
environment. On Windows, use WSL.

## Project layout

```
main.odin     Entry point and the read–eval loop
inputs/       Raw-mode line editor: keystrokes, history, cursor
parser/       Lexer, tokens, and command dispatch (built-ins + externals)
ter/          Terminal raw/canonical mode handling
display/      Prompt rendering
memory/       Tracking-allocator setup for leak detection
```