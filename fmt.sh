#!/bin/sh

cd "$(dirname "$0")"

cargo fmt --all
find haskell -type f -name '*.hs' -exec ormolu --mode inplace {} +
