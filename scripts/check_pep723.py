#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# dependencies = []
# ///
"""Fail if an executable tracked .py script imports non-stdlib packages
without declaring them in a PEP 723 `# /// script` metadata block.

Without this, a script's dependency declaration silently rots the first time
someone adds an import and forgets the block — the exact failure mode this
repo hit with 8 of its 11 standalone scripts.
"""

import ast
import subprocess
import sys


def top_level_imports(tree: ast.Module) -> set[str]:
    modules: set[str] = set()
    for node in ast.walk(tree):
        if isinstance(node, ast.Import):
            for alias in node.names:
                modules.add(alias.name.split(".")[0])
        elif isinstance(node, ast.ImportFrom):
            if node.level == 0 and node.module:
                modules.add(node.module.split(".")[0])
    return modules


def main() -> None:
    result = subprocess.run(
        ["git", "ls-files", "*.py"], capture_output=True, text=True, check=True
    )
    stdlib = sys.stdlib_module_names

    failures: list[tuple[str, list[str]]] = []
    for path in result.stdout.splitlines():
        with open(path, "rb") as f:
            first_line = f.readline()
        if not first_line.startswith(b"#!"):
            continue

        with open(path, encoding="utf-8") as f:
            content = f.read()
        if "# /// script" in content:
            continue

        tree = ast.parse(content, filename=path)
        third_party = sorted(top_level_imports(tree) - stdlib)
        if third_party:
            failures.append((path, third_party))

    if failures:
        print("Executable scripts import non-stdlib packages without a PEP 723 block:")
        for path, mods in failures:
            print(f"  {path}: {', '.join(mods)}")
        sys.exit(1)


if __name__ == "__main__":
    main()
