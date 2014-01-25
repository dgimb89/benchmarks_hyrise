cd ../hyrise
Benchmark_name='groupby'
rm --recursive -f ../benchmarks_hyrise/logs/${Benchmark_name}
mkdir ../benchmarks_hyrise/logs ../benchmarks_hyrise/logs/${Benchmark_name}
Benchmarks=('groupby/groupby' 'groupby/parallel_groupby_2cores' 'groupby/parallel_groupby_3cores' 'groupby/parallel_groupby_4cores');
Warehouse_numbers=(5000 10000 25000 50000 100000 200000);
Itemset_sizes=(200);
for numItems in ${Itemset_sizes[@]}; do
	for numWarehouses in ${Warehouse_numbers[@]}; do
		mkdir ../benchmarks_hyrise/logs/${Benchmark_name}/w${numWarehouses}i${numItems}

		# generate dataset
		../benchmarks_hyrise/generate_dataset.sh ${numItems} ${numWarehouses}
		# start server
		../benchmarks_hyrise/run_server.sh &
		SERVER_ID=$!
		sleep 1

	
		curl -X POST --data-urlencode "query@../benchmarks_hyrise/queries/benchmark/load_table.json" http://localhost:5000/jsonQuery

		for i in 1 2 3; do
			for name in ${Benchmarks[@]}; do
			  curl -X POST --data-urlencode "query@../benchmarks_hyrise/queries/benchmark/${Benchmark_name}/${name}.json" --data performance=true http://localhost:5000/jsonQuery > ../benchmarks_hyrise/logs/${Benchmark_name}/w${numWarehouses}i${numItems}/${name}_${i}.log
			done
		done
		# kill old instance
		kill -9 ${SERVER_ID}
		killall hyrise-server_release
	done
done
