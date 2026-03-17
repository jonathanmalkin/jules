#!/bin/bash
# inject-datetime.sh — UserPromptSubmit hook
# Injects current date and time (Central timezone) into every message context.
# Overrides the static currentDate from auto-memory, which drifts between sessions.

DATETIME=$(TZ="America/Chicago" date "+%A, %B %d, %Y %I:%M %p %Z")

printf '{"context": "Current date and time: %s"}\n' "$DATETIME"
