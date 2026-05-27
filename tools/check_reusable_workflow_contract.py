#!/usr/bin/env python3
"""Check that the reusable Packer workflow exposes the documented inputs."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path
from typing import Any


def fail(message: str) -> None:
    raise SystemExit(f"contract-check: {message}")


def indentation(line: str) -> int:
    return len(line) - len(line.lstrip(" "))


def parse_scalar(raw: str) -> Any:
    value = raw.strip()
    if value in {"true", "false"}:
        return value == "true"
    if len(value) >= 2 and value[0] == value[-1] and value[0] in {"'", '"'}:
        return value[1:-1]
    return value


def mapping_key(line: str) -> str | None:
    stripped = line.strip()
    if not stripped or stripped.startswith("#") or not stripped.endswith(":"):
        return None
    key = stripped[:-1].strip()
    if not key or " " in key:
        return None
    return key


def parse_inputs(lines: list[str], inputs_indent: int, *, stop_indent: int | None = None) -> dict[str, dict[str, Any]]:
    inputs: dict[str, dict[str, Any]] = {}
    current: str | None = None

    for line in lines:
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        indent = indentation(line)
        if stop_indent is not None and indent <= stop_indent:
            break
        if indent <= inputs_indent:
            break

        key = mapping_key(line)
        if key is not None and indent == inputs_indent + 2:
            current = key
            inputs[current] = {}
            continue

        if current is None or indent != inputs_indent + 4 or ":" not in line:
            continue

        raw_field, raw_value = line.strip().split(":", 1)
        field = raw_field.strip()
        value = raw_value.strip()
        if value:
            inputs[current][field] = parse_scalar(value)

    return inputs


def load_contract(path: Path) -> tuple[Path, dict[str, dict[str, Any]]]:
    lines = path.read_text(encoding="utf-8").splitlines()
    workflow: Path | None = None
    inputs: dict[str, dict[str, Any]] | None = None

    for index, line in enumerate(lines):
        stripped = line.strip()
        if stripped.startswith("workflow:"):
            workflow = Path(parse_scalar(stripped.split(":", 1)[1]))
        if stripped == "inputs:" and indentation(line) == 0:
            inputs = parse_inputs(lines[index + 1 :], indentation(line))

    if workflow is None:
        fail(f"{path} is missing a workflow path")
    if inputs is None:
        fail(f"{path} is missing top-level inputs")
    return workflow, inputs


def load_workflow_inputs(path: Path) -> dict[str, dict[str, Any]]:
    lines = path.read_text(encoding="utf-8").splitlines()
    workflow_call_indent: int | None = None

    for index, line in enumerate(lines):
        stripped = line.strip()
        indent = indentation(line)
        if stripped == "workflow_call:":
            workflow_call_indent = indent
            continue
        if workflow_call_indent is None:
            continue
        if stripped and indent <= workflow_call_indent:
            break
        if stripped == "inputs:":
            return parse_inputs(lines[index + 1 :], indent, stop_indent=workflow_call_indent)

    fail(f"{path} is missing on.workflow_call.inputs")


def compare_inputs(expected: dict[str, dict[str, Any]], actual: dict[str, dict[str, Any]]) -> list[str]:
    failures: list[str] = []
    expected_names = set(expected)
    actual_names = set(actual)

    missing = sorted(expected_names - actual_names)
    extra = sorted(actual_names - expected_names)
    if missing:
        failures.append(f"missing inputs: {', '.join(missing)}")
    if extra:
        failures.append(f"unexpected inputs: {', '.join(extra)}")

    for name in sorted(expected_names & actual_names):
        for field in ("type", "required", "default"):
            expected_has = field in expected[name]
            actual_has = field in actual[name]
            if expected_has != actual_has:
                failures.append(f"{name}.{field}: expected presence {expected_has}, got {actual_has}")
                continue
            if expected_has and expected[name][field] != actual[name][field]:
                failures.append(f"{name}.{field}: expected {expected[name][field]!r}, got {actual[name][field]!r}")

    return failures


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--contract",
        type=Path,
        default=Path("contract/reusable-packer-framework-build.yaml"),
        help="Contract YAML file to compare against.",
    )
    args = parser.parse_args()

    workflow_path, expected = load_contract(args.contract)
    actual = load_workflow_inputs(workflow_path)
    failures = compare_inputs(expected, actual)
    if failures:
        print("reusable workflow contract mismatch:", file=sys.stderr)
        for failure in failures:
            print(f"  - {failure}", file=sys.stderr)
        return 1

    print(f"reusable workflow contract OK: {workflow_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
