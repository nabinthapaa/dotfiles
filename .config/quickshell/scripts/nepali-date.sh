#!/bin/bash
CACHE_FILE="$HOME/.cache/quickshell_nepali_date.txt"
TODAY_EN=$(date +%Y-%m-%d)

# Ensure cache directory exists
mkdir -p "$HOME/.cache"

# If cache file exists and date matches, return cached Nepali date
if [ -f "$CACHE_FILE" ]; then
  CACHED_DATE=$(head -n 1 "$CACHE_FILE")
  if [ "$CACHED_DATE" = "$TODAY_EN" ]; then
    tail -n +2 "$CACHE_FILE"
    exit 0
  fi
fi

# Otherwise, fetch from API
NEPALI_DATE=$(curl -s "https://calendar.bloggernepal.com/api/today" | jq -r '.res | (.days[] | select(.tag == "today") | .bs) + " " + .name + " " + (.year|tostring)')

# If successful, cache it and print it
if [ -n "$NEPALI_DATE" ] && [ "$NEPALI_DATE" != "null  null" ] && [ "$NEPALI_DATE" != "null" ]; then
  echo "$TODAY_EN" > "$CACHE_FILE"
  echo "$NEPALI_DATE" >> "$CACHE_FILE"
  echo "$NEPALI_DATE"
else
  # On API failure, return old cache if available
  if [ -f "$CACHE_FILE" ]; then
    tail -n +2 "$CACHE_FILE"
  fi
fi
