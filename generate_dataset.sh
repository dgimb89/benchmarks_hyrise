rm ../benchmarks_hyrise/stock.tbl
./build/hyrise-perf-datagen_release -i$1 -w$2 -c0 -o0 -n0 --hyrise -d ../benchmarks_hyrise
