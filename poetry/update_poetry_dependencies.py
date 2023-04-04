#!/usr/bin/env python3
import functools
import operator
from typing import Optional

import toml
import requests
from packaging import specifiers
from packaging import version


def get_specifier(version_specifier: str) -> Optional[specifiers.SpecifierSet]:
    try:
        return functools.reduce(
            lambda a, b: a & b, [specifiers.SpecifierSet(s) for s in version_specifier.split(",")]
        )
    except specifiers.InvalidSpecifier as e:
        print(f"Error parsing {version_specifier}: {e}")
        return None


def get_latest_package_release(package_name: str):
    try:
        url = f"https://pypi.org/pypi/{package_name}/json"
        response = requests.get(url)
        response.raise_for_status()
        data = response.json()
        return max(
            [
                version.parse(release_version)
                for release_version in data["releases"]
                if "rc" not in release_version
            ]
        )
    except Exception as e:
        print(f"Error fetching latest version for {package_name}: {e}")
        return None


def update_dependencies(pyproject_path):
    with open(pyproject_path, "r") as f:
        pyproject_data = toml.load(f)

    dependencies = pyproject_data.get("tool", {}).get("poetry", {}).get("dependencies", {})

    for package, version_specifier in dependencies.items():
        if package in ("python", "platformdirs") or not isinstance(version_specifier, str):
            continue
        version_specifier = version_specifier.replace("^", "~=")

        specs = get_specifier(version_specifier)
        if not specs:
            continue

        latest_version = get_latest_package_release(package)
        if not latest_version:
            print(f"Error parsing {package} = {version_specifier}")
            continue

        if latest_version not in specs:
            dependencies[package] = f"^{latest_version}"

    with open(pyproject_path, "w") as f:
        toml.dump(pyproject_data, f)


if __name__ == "__main__":
    update_dependencies("pyproject.toml")
