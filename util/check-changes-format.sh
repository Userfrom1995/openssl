#!/bin/sh

# Copyright 2026 The OpenSSL Project Authors. All Rights Reserved.
#
# Licensed under the Apache License 2.0 (the "License").
# You may not use this file except in compliance with the License.
# You can obtain a copy in the file LICENSE in the source distribution
# or at https://www.openssl.org/source/license.html

#
# Validate formatting of new entries in CHANGES.md / NEWS.md.
# Only checks the latest (topmost) release section, since older sections
# use different historical conventions. Catches inconsistent indentation,
# trailing whitespace, and entry format issues that reviewers currently
# have to flag manually.
#
# Usage: check-changes-format.sh [CHANGES.md|NEWS.md]
#

FILE="${1:-CHANGES.md}"

case "$FILE" in
    CHANGES.md)
        HEADER_PATTERN="### Changes between *"
        ENTRY_PATTERN=" * "
        ATTR_PATTERN="   *"
        CONT_PATTERN="   "
        ;;
    NEWS.md)
        HEADER_PATTERN="### Major changes between *"
        ENTRY_PATTERN="  * "
        ATTR_PATTERN="    *"
        CONT_PATTERN="    "
        ;;
    *)
        echo "Usage: $0 [CHANGES.md|NEWS.md]"
        exit 1
        ;;
esac

errors=0
lineno=0
in_scope=0
in_entry=0
found_release=0

while IFS= read -r line; do
    lineno=$((lineno + 1))

    case "$line" in
        $HEADER_PATTERN)
            if [ "$found_release" = 0 ]; then
                in_scope=1
                found_release=1
            else
                break
            fi
            in_entry=0
            continue
            ;;
    esac

    [ "$in_scope" = 0 ] && continue

    case "$line" in
        "OpenSSL "*)
            break
            ;;
    esac

    # trailing whitespace
    case "$line" in
        *" " | *"	")
            echo "$lineno: trailing whitespace"
            errors=$((errors + 1))
            ;;
    esac

    case "$line" in
        "")
            ;;
        "$ENTRY_PATTERN"*)
            in_entry=1
            ;;
        "$ATTR_PATTERN"*)
            in_entry=0
            ;;
        "$CONT_PATTERN"*)
            if [ "$in_entry" = 0 ]; then
                echo "$lineno: unexpected indented line outside an entry"
                errors=$((errors + 1))
            fi
            ;;
        *)
            echo "$lineno: unexpected format: $line"
            errors=$((errors + 1))
            ;;
    esac
done < "$FILE"

if [ "$errors" -gt 0 ]; then
    echo "❌ $errors formatting issue(s) found in $FILE (current release section)"
    exit 1
fi

echo "✅ $FILE format looks good"
