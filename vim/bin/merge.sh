#!/usr/bin/env bash

set -e

output=$1
base=$2
mine=$3
other=$4

echo "output = '$output'"
echo "base = '$base'"
echo "mine = '$mine'"
echo "other = '$other'"

# merge the files, keeping local changes if there is a conflict
diff3 $mine $base $other -3m > $output

# merge the files, keeping incoming changes if there is a conflict
other_merge=$(mktemp)
diff3 $other $base $mine -3m > $other_merge

vim \
  -d $output $other_merge \
  -c ":tabe $mine" \
  -c ":vert diffs $base" \
  -c ":tabe $other" \
  -c ":vert diffs $base" \
  -c ":tabfir"
