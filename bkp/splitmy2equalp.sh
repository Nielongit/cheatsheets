#!/bin/sh

parts_total="$2";
input="$1";

parts=$((parts_total))
for i in $(seq 0 $((parts_total-2))); do
  lines=$(wc -l "$input" | cut -f 1 -d" ")
  #n is rounded, 1.3 to 2, 1.6 to 2, 1 to 1
  n=$(awk  -v lines=$lines -v parts=$parts 'BEGIN { 
    n = lines/parts;
    rounded = sprintf("%.0f", n);
    if(n>rounded){
      print rounded + 1;
    }else{
      print rounded;
    }
  }');
  head -$n "$input" > split${i}
  tail -$((lines-n)) "$input" > .tmp${i}
  input=".tmp${i}"
  parts=$((parts-1));
done
mv .tmp$((parts_total-2)) split$((parts_total-1))
rm .tmp*
