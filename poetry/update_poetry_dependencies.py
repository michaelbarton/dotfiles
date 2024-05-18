#!/usr/bin/env python3

import functools
import logging
from typing import Optional

import toml
import requests
from packaging import specifiers, version
from rich.logging import RichHandler

# Configure logging with Rich
logging.basicConfig(
    level=logging.INFO, format="%(message)s", datefmt="[%X]", handlers=[RichHandler()]
)

logger = logging.getLogger("rich")


def get_specifier(version_specifier: str) -> Optional[specifiers.SpecifierSet]:
    """
    Parses a version specifier string into a SpecifierSet object.

    Args:
        version_specifier (str): A version specifier string (e.g., ">=1.0.0,<2.0.0").

    Returns:
        Optional[specifiers.SpecifierSet]: A SpecifierSet object if the string is valid, None otherwise.
    """
    try:
        return functools.reduce(
            lambda a, b: a & b, [specifiers.SpecifierSet(s) for s in version_specifier.split(",")]
        )
    except specifiers.InvalidSpecifier as e:
        logger.error(f"Error parsing {version_specifier}: {e}")
        return None


def get_latest_package_release(package_name: str) -> Optional[version.Version]:
    """
    Fetches the latest non-pre-release version of a package from PyPI.

    Args:
        package_name (str): The name of the package.

    Returns:
        Optional[version.Version]: The latest version of the package if available, None otherwise.
    """
    try:
        url = f"https://pypi.org/pypi/{package_name}/json"
        with requests.get(url) as response:
            response.raise_for_status()
            data = response.json()
            return max(
                [
                    version.parse(release_version)
                    for release_version in data["releases"]
                    if "rc" not in release_version
                    and not version.parse(release_version).is_prerelease
                ],
                default=None,
            )
    except requests.RequestException as e:
        logger.error(f"Error fetching latest version for {package_name}: {e}")
        return None
    except ValueError as e:
        logger.error(f"Error parsing version for {package_name}: {e}")
        return None


def update_dependencies(pyproject_path: str) -> None:
    """
    Updates the dependencies in the pyproject.toml file to the latest compatible versions.

    Args:
        pyproject_path (str): The path to the pyproject.toml file.
    """
    try:
        with open(pyproject_path, "r") as f:
            pyproject_data = toml.load(f)
    except (FileNotFoundError, toml.TomlDecodeError) as e:
        logger.error(f"Error loading pyproject.toml: {e}")
        return

    dependencies = pyproject_data.get("tool", {}).get("poetry", {}).get("dependencies", {})
    if not isinstance(dependencies, dict):
        logger.error("Dependencies section is missing or invalid in pyproject.toml")
        return

    for package, version_specifier in dependencies.items():
        if package in ("python", "platformdirs") or not isinstance(version_specifier, str):
            continue
        version_specifier = version_specifier.replace("^", "~=")

        specs = get_specifier(version_specifier)
        if not specs:
            logger.error(f"Invalid specifier for {package}: {version_specifier}")
            continue

        latest_version = get_latest_package_release(package)
        if not latest_version:
            continue

        if latest_version not in specs:
            old_version = dependencies[package]
            dependencies[package] = f"^{latest_version}"
            logger.info(f"Updated {package} from version {old_version} to version {latest_version}")

    try:
        with open(pyproject_path, "w") as f:
            toml.dump(pyproject_data, f)
    except IOError as e:
        logger.error(f"Error writing to pyproject.toml: {e}")


if __name__ == "__main__":
    update_dependencies("pyproject.toml")
