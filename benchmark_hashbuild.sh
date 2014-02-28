#!/bin/bash
cd ../hyrise
Benchmark_name='hashbuild'
rm --recursive -f ../benchmarks_hyrise/logs/${Benchmark_name}
mkdir ../benchmarks_hyrise/logs ../benchmarks_hyrise/logs/${Benchmark_name}
Benchmarks=(	'hashbuild' 
		'hashbuild_2cores' 'hashbuild_3cores' 'hashbuild_4cores'
		#'hashbuild_shared_2cores' 'hashbuild_shared_3cores' 'hashbuild_shared_4cores'
);
Warehouse_numbers=(10000 25000 50000 100000 250000 500000 1000000);
rowCount=10000000;
for numWarehouses in ${Warehouse_numbers[@]}; do

	rm ../benchmarks_hyrise/stock.tbl

	let numItems=${rowCount}/${numWarehouses}
	mkdir ../benchmarks_hyrise/logs/${Benchmark_name}/w${numWarehouses}i${numItems}

	# generate dataset
	if [ ! -f ../benchmarks_hyrise/stock_w${numWarehouses}i${numItems}.tbl ]; then
		../benchmarks_hyrise/generate_dataset.sh ${numItems} ${numWarehouses}
		mv ../benchmarks_hyrise/stock.tbl ../benchmarks_hyrise/stock_w${numWarehouses}i${numItems}.tbl
	fi

	ln -s ../benchmarks_hyrise/stock_w${numWarehouses}i${numItems}.tbl ../benchmarks_hyrise/stock.tbl
	
	# start server
	../benchmarks_hyrise/run_server.sh &
	SERVER_ID=$!
	sleep 5


	curl -X POST --data-urlencode "query@../benchmarks_hyrise/queries/benchmark/load_table.json" http://localhost:5000/jsonQuery
	for name in ${Benchmarks[@]}; do
		echo ${name}
		for i in 1 2 3; do
		curl -X POST --data-urlencode "query@../benchmarks_hyrise/queries/benchmark/${Benchmark_name}/${name}.json" --data performance=true http://localhost:5000/jsonQuery > ../benchmarks_hyrise/logs/${Benchmark_name}/w${numWarehouses}i${numItems}/${name}_${i}.log
		done
	done
	# kill old instance
	kill -9 ${SERVER_ID}
	killall hyrise-server_release
	killall hyrise-server_release
	sleep 5
done
