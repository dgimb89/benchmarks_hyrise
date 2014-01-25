cd ../hyrise
Benchmark_name='hashbuild'
rm --recursive -f ../benchmarks_hyrise/logs/${Benchmark_name}
mkdir ../benchmarks_hyrise/logs ../benchmarks_hyrise/logs/${Benchmark_name}
Benchmarks=('hashbuild' 'hashbuild_nonshared_8cores' 'hashbuild_nonshared_16cores' 'hashbuild_nonshared_32cores' 'hashbuild_shared_8cores' 'hashbuild_shared_16cores' 'hashbuild_shared_32cores');
Warehouse_numbers=(5000 10000 25000 50000 100000 200000);
rowCount=50000000;
for numWarehouses in ${Warehouse_numbers[@]}; do
	let numItems=${rowCount}/${numWarehouses}
	mkdir ../benchmarks_hyrise/logs/${Benchmark_name}/w${numWarehouses}i${numItems}

	# generate dataset
	if [ -f ../benchmars_hyrise/stock_w${numWarehouses}i${numItems}.tbl ]
	then
	    mv ../benchmars_hyrise/stock_w${numWarehouses}i${numItems}.tbl ../benchmars_hyrise/stock.tbl
	else
	    ../benchmarks_hyrise/generate_dataset.sh ${numItems} ${numWarehouses}
	fi
	
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
	mv ../benchmars_hyrise/stock.tbl ../benchmars_hyrise/stock_w${numWarehouses}i${numItems}.tbl
done
