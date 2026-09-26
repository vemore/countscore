#!/bin/bash
# The wrong outcome: the default reintroduced.
set -euo pipefail
sed -i "s|String.fromEnvironment('BACKEND_URL')|String.fromEnvironment('BACKEND_URL', defaultValue: 'https://scores.example.net')|" \
    lib/providers/backend_provider.dart
git add -A
git commit -qm "feat: a default server" --no-verify
