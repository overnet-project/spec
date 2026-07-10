#!/bin/bash
# Prepare the spec repo for Claude Code on the web.
#
# The conformance validator (tools/validate-fixtures) uses only core Perl
# modules, so no dependency installation is required. If the Overnet
# perl 5.42 toolchain built by the sibling repos happens to be present
# (shared container cache), prefer it for consistency; otherwise the
# system perl is sufficient.
#
# Idempotent and non-interactive.
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

PERL_PREFIX=/opt/perl-5.42
if [ -x "$PERL_PREFIX/bin/perl" ]; then
  echo "export PATH=\"$PERL_PREFIX/bin:\$PATH\"" >> "$CLAUDE_ENV_FILE"
fi

echo "[session-start] spec ready; validate with: perl tools/validate-fixtures"
