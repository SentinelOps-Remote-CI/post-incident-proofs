#!/usr/bin/env python3
"""
Policy Lint Script
==================

This script validates policy YAML files for the post-incident-proofs system.
Based on the template from remote-ci/templates/policy_lint.py.
"""

import sys
import yaml
import argparse
from pathlib import Path
from typing import List, Dict, Any


def validate_policy_structure(policy: Dict[str, Any], filename: str) -> List[str]:
    """Validate the structure of a policy file."""
    errors = []

    # Check required top-level keys
    required_keys = ["name", "version", "rules"]
    for key in required_keys:
        if key not in policy:
            errors.append(f"{filename}: Missing required key '{key}'")

    # Validate name
    if "name" in policy and not isinstance(policy["name"], str):
        errors.append(f"{filename}: 'name' must be a string")

    # Validate version
    if "version" in policy and not isinstance(policy["version"], str):
        errors.append(f"{filename}: 'version' must be a string")

    # Validate rules
    if "rules" in policy:
        if not isinstance(policy["rules"], list):
            errors.append(f"{filename}: 'rules' must be a list")
        else:
            for i, rule in enumerate(policy["rules"]):
                if not isinstance(rule, dict):
                    errors.append(f"{filename}: Rule {i} must be a dictionary")
                else:
                    # Validate rule structure
                    if "id" not in rule:
                        errors.append(f"{filename}: Rule {i} missing 'id' field")
                    if "description" not in rule:
                        errors.append(
                            f"{filename}: Rule {i} missing 'description' field"
                        )
                    if "severity" not in rule:
                        errors.append(f"{filename}: Rule {i} missing 'severity' field")
                    elif rule["severity"] not in ["low", "medium", "high", "critical"]:
                        errors.append(
                            f"{filename}: Rule {i} invalid severity '{rule['severity']}'"
                        )

    return errors


def validate_policy_content(policy: Dict[str, Any], filename: str) -> List[str]:
    """Validate the content of a policy file."""
    errors = []

    # Check for empty policy
    if not policy:
        errors.append(f"{filename}: Policy file is empty")
        return errors

    # Check for valid YAML structure
    if not isinstance(policy, dict):
        errors.append(f"{filename}: Policy must be a YAML object")
        return errors

    # Validate specific policy types for post-incident-proofs
    if "type" in policy:
        valid_types = ["security", "compliance", "performance", "observability"]
        if policy["type"] not in valid_types:
            errors.append(f"{filename}: Invalid policy type '{policy['type']}'")

    return errors


def lint_policy_file(filepath: Path) -> List[str]:
    """Lint a single policy file."""
    errors = []

    try:
        with open(filepath, "r", encoding="utf-8") as f:
            try:
                policy = yaml.safe_load(f)
                if policy is None:
                    errors.append(f"{filepath}: Empty or invalid YAML file")
                    return errors

                # Validate structure and content
                errors.extend(validate_policy_structure(policy, str(filepath)))
                errors.extend(validate_policy_content(policy, str(filepath)))

            except yaml.YAMLError as e:
                errors.append(f"{filepath}: YAML parsing error: {e}")

    except FileNotFoundError:
        errors.append(f"{filepath}: File not found")
    except PermissionError:
        errors.append(f"{filepath}: Permission denied")
    except Exception as e:
        errors.append(f"{filepath}: Unexpected error: {e}")

    return errors


def main():
    """Main function to run policy linting."""
    parser = argparse.ArgumentParser(description="Lint policy YAML files")
    parser.add_argument("files", nargs="+", help="Policy files to lint")
    parser.add_argument("--verbose", "-v", action="store_true", help="Verbose output")

    args = parser.parse_args()

    all_errors = []
    files_processed = 0

    for pattern in args.files:
        for filepath in Path(".").glob(pattern):
            if filepath.suffix.lower() in [".yaml", ".yml"]:
                if args.verbose:
                    print(f"Linting {filepath}...")

                errors = lint_policy_file(filepath)
                all_errors.extend(errors)
                files_processed += 1

    # Report results
    if args.verbose:
        print(f"\nProcessed {files_processed} policy files")

    if all_errors:
        print(f"\n❌ Found {len(all_errors)} errors:")
        for error in all_errors:
            print(f"  {error}")
        sys.exit(1)
    else:
        print(f"\n✅ All {files_processed} policy files passed validation")
        sys.exit(0)


if __name__ == "__main__":
    main()
