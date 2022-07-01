#!/bin/bash

YEAR=$(date +%Y)
MONTH=$(date +%m)
DAY=$(date +%d)
DATE="${YEAR}${MONTH}${DAY}"

git add .
git commit -m "${DATE}"
