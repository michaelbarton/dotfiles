---
name: uv-scripts
description: Use when writing, editing, or running a standalone Python script (a single .py file outside a packaged project), so it declares its own dependencies and runs without a virtualenv.
---

# Standalone Python scripts with uv

A standalone script carries its own dependency list in PEP 723 inline metadata
and is launched through `uv`, so it runs on any machine with `uv` installed and
needs no venv, `requirements.txt`, or `pip install`.

Start every standalone script like this:

```python
#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.12"
# dependencies = [
#   "requests",
# ]
# ///
```

- Set `requires-python` to the oldest Python the script needs.
- The shebang makes `./script.py` work once the file is executable (`chmod +x`);
  `uv run script.py` works without it.
- Add or change dependencies with `uv add --script script.py <package>` rather
  than editing the block by hand, and use `uv remove --script` to drop one.
- List only what the script imports directly. An empty `dependencies = []` is
  valid for a stdlib-only script.
- Use `uv`, not `pip`, `poetry`, or `pipx`, for installing anything; for a
  packaged project use `uv sync` / `uv run`.
