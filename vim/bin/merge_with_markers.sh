if [ $# -ne 1 ]
then
  echo "USAGE: $0 FILENAME"
  echo ""
  echo "Will scan file for merge markers, then use hg to pull out the versions of the file from those revisions, then open vim to show you the diffs"
  echo "NOTE: It will replace the given filename with the old tip"
  exit 1
fi

file=$1

modified=$(hg status $1 | wc -l)
if [ $modified -ne 0 ]
then
  echo "'hg status $1' must be clean -- this script will overwrite that file"
  exit 1
fi

dir=$(mktemp -d)

mine=$(grep -m1 '^<<<<<' $file)
base=$(grep -m1 '^|||||' $file)
other=$(grep -m1 '^>>>>>' $file)
echo $mine
echo $base
echo $other

getrev() {
  echo "$1" | sed -e 's/^[^ ]* //g' | sed -e 's/.* \[\?//g' | sed -e 's/\]\?$//g'
}

getfile() {
  orgfile=$(hg status -C --rev "$1" $file|egrep -v " $file")
  if [ $? -ne 0 ]; then
    echo $file
  else
    echo $orgfile
  fi
}

makefile() {
  rev=$1
  file=$2
  out=$3
  (echo "$rev"; hg cat -r $rev $file) > $dir/$out
}

mine_rev=$(getrev "$mine")
base_rev=$(getrev "$base")
other_rev=$(getrev "$other")

mine_file=$(getfile "$mine_rev")
base_file=$(getfile "$base_rev")
other_file=$(getfile "$other_rev")

makefile "$mine_rev" "$mine_file" mine
makefile "$base_rev" "$base_file" base
makefile "$other_rev" "$other_file" other

~/.vim/bin/merge.sh $file $dir/{base,mine,other}
