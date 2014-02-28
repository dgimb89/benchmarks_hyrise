cd /home/daniel/hyrise

mkdir /home/daniel/benchmarks_hyrise/profiles
rm --recursive -f /home/daniel/benchmarks_hyrise/profiles/*
Queries=('hashbuild_shared_2cores' 'hashbuild_shared_4cores');
# generate dataset
/home/daniel/benchmarks_hyrise/generate_dataset.sh 100 100000
# start server
/home/daniel/benchmarks_hyrise/run_server.sh &
SERVER_ID=$!
sleep 1


curl -X POST --data-urlencode "query@../benchmarks_hyrise/queries/benchmark/load_table.json" http://localhost:5000/jsonQuery

for name in ${Queries[@]}; do
	curl -X POST --data-urlencode "query@../benchmarks_hyrise/queries/profiling/${name}.json" http://localhost:5000/jsonQuery
	ls | grep *.gprof | xargs pprof --nodefraction=0.005 --pdf ./build/hyrise-server_release > /home/daniel/benchmarks_hyrise/profiles/${name}.pdf
	ls | grep *.gprof | xargs rm
done
# kill old instance
kill -9 ${SERVER_ID}
killall hyrise-server_release
