#!/bin/bash
#
# @CreationTime
#   2022/3/15 下午16:45:20
# @Function
#
# @Usage
# @author Siu

CURRENT_PATH=$(readlink -f "$(dirname "$0")")
# shellcheck source=src/
. "${CURRENT_PATH}"/config/conf

date_str=$(date "+%Y%m%d%H%M%S%3N")
archive_dir=./output/test-"${date_str}"
# 创建归档目录
mkdir -p "${archive_dir}"

## 记录日志
log() {
	date_str=$(date "+%Y-%m-%d %H:%M:%S.%3N")
	echo "$(hostname -s)" "${date_str}" "$1"
	# shellcheck disable=SC2086
	echo "$(hostname -s)" "${date_str}" $1 >>"${archive_dir}"/run.log
}

log1() {
	echo "$1"
	# shellcheck disable=SC2086
	echo $1 >>"${archive_dir}"/run.log
}

runMss() {
	mysqlslap -u ${db_user} -P ${db_port} -h ${db_ip} \
	--concurrency=${client_num} --iterations=${run_times} --number-of-queries=${client_queries_limit} --create-schema=${db_schema} \
	--query=./"${archive_dir}"/"$1".sql \
	--pre-query=./"${archive_dir}"/p_"$1".sql \
	--csv=./"${archive_dir}"/"$1".csv

	tmp=$(cat ./"${archive_dir}"/"$1".csv)
	tmp1=$1${tmp}
	echo "$tmp1" >./"${archive_dir}"/"$1".csv

	res=$(cat ./"${archive_dir}"/"$1".csv)
	log "$1 执行完成： ${res}"

}

runJob() {
	test_name=$1
	query_sql=$2
	pre_query=$3
	echo "${query_sql}" >./"${archive_dir}"/"${test_name}".sql
	echo "${pre_query}" >./"${archive_dir}"/p_"${test_name}".sql

	log1 "====================================================================================================================================="
	log "执行测试：${test_name} "
	log "执行预处理：${pre_query}"
	log "执行测试 SQL：${query_sql}"
	runMss "${test_name}"
}

runJobs() {
	for file in "${CURRENT_PATH}"/config/jobs/*; do
		if test -f $file; then
			#log "加载：$file"
			# shellcheck disable=SC1090
			. "$file"
			test_name=$(basename "$file")
			runJob "${test_name}" "${query_sql}" "${pre_query}"
		fi
		if test -d "$file"; then
			log "dir:$file"
		fi
	done
}

archiveRes() {
	# 归档测试结果
	echo 'test_name,mode,avg,min,max,client_num,queries_per_client' >"${archive_dir}"/0.csv
	cat "${archive_dir}"/*.csv >"${archive_dir}"/result.csv
	rm -rf "${archive_dir}"/0.csv

	log1 "##########################################################################"
	log1 "全局参数："
	log1 "client_num=${client_num}"
	log1 "queries_num=${client_queries_limit}"
	log1 "测试结果： ${archive_dir}/result.csv "
	# shellcheck disable=SC2002
	resFmt=$(cat "${archive_dir}"/result.csv | column -t -s,)
	log1 "${resFmt}"
	log1 "#########################################################################"
}

main() {
	runJobs
	archiveRes
}

main
