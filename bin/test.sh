db_ip=$(hostname -I | awk '{gsub(/^\s+|\s+$/, "");print}')
# 总查询的次数 = min(client_queries_limit,client_num * run_times)
client_num=10
run_times=5
# 官方文档说明：Limit each client to approximately this number of queries，实际限制每个 client，而是限制总查询数
client_queries_limit=10
db_schema='ssb'
db_user='root'
db_port='9030'

date_str=$(date "+%Y%m%d%H%M%S%3N")
archive_dir=test-"${date_str}"

## 记录日志
log() {
  date_str=$(date "+%Y-%m-%d %H:%M:%S.%3N")
  echo "$(hostname -s)" "${date_str}" "$1"
  # shellcheck disable=SC2086
  echo "$(hostname -s)" "${date_str}" $1 >> "${archive_dir}"/run.log
}

log1() {
  echo "$1"
  # shellcheck disable=SC2086
  echo $1 >> "${archive_dir}"/run.log
}

run(){
    mysqlslap -u ${db_user} -P ${db_port} -h ${db_ip} \
--concurrency=${client_num} --iterations=${run_times} --number-of-queries=${client_queries_limit} --create-schema=${db_schema} \
--query=./"${archive_dir}"/"$1".sql \
--pre-query=./"${archive_dir}"/p_"$1".sql \
--csv=./"${archive_dir}"/"$1".csv

    tmp=$(cat ./"${archive_dir}"/"$1".csv)
    tmp1=$1${tmp}
    echo "$tmp1" > ./"${archive_dir}"/"$1".csv

    res=$(cat ./"${archive_dir}"/"$1".csv)
    log "$1 执行完成： ${res}"


}

runSingle(){
  test_name=$1
  query_sql=$2
  pre_query=$3
  echo "${query_sql}" > ./"${archive_dir}"/"${test_name}".sql
  echo "${pre_query}" > ./"${archive_dir}"/p_"${test_name}".sql

  log1 "====================================================================================================================================="
  log "执行测试：${test_name} "
  log "执行预处理：${pre_query}"
  log "执行测试 SQL：${query_sql}"
  run "${test_name}"
}


# 创建归档目录
mkdir "${archive_dir}"

# test 1: build-in functions
test_name='build-in'
query_sql="select length(c_address) from ${db_schema}.customer;"
pre_query="set global enable_vectorized_engine=true;set global batch_size=1024;"
runSingle ${test_name} "${query_sql}" "${pre_query}"


# test 2：Native UDF
test_name='n-udf-f'
query_sql="select ${db_schema}.get_string_length(c_address) from ${db_schema}.customer;"
pre_query="set global enable_vectorized_engine=false;"
runSingle ${test_name} "${query_sql}" "${pre_query}"

# r-udf 测试sql
query_sql="select ${db_schema}.str_length(c_address) from ${db_schema}.customer;"

# test 3：Remote UDF 1 （enable_vectorized_engine = false）
test_name='r-udf-1-f'
pre_query="set global enable_vectorized_engine=false;"
#runSingle ${test_name} "${query_sql}" "${pre_query}"



# test 4: Remote UDF 2（enable_vectorized_engine = true，batch_size = 1024）
test_name='r-udf-2-t-1024'
pre_query="set global enable_vectorized_engine=true;set global batch_size=1024;"
runSingle ${test_name} "${query_sql}" "${pre_query}"

# test 5: Remote UDF 3（enable_vectorized_engine = true，batch_size = 2048）
test_name='r-udf-3-t-2048'
pre_query="set global enable_vectorized_engine=true;set global batch_size=2048;"
runSingle ${test_name} "${query_sql}" "${pre_query}"

# test 6: Remote UDF 4（enable_vectorized_engine = true，batch_size = 4096）
test_name='r-udf-4-t-4096'
pre_query="set global enable_vectorized_engine=true;set global batch_size=4096;"
runSingle ${test_name} "${query_sql}" "${pre_query}"

# test 7: Remote UDF 5（enable_vectorized_engine = true，batch_size = 8192）
test_name='r-udf-5-t-8192'
pre_query="set global enable_vectorized_engine=true;set global batch_size=8192;"
runSingle ${test_name} "${query_sql}" "${pre_query}"

# test 8: Remote UDF 6（enable_vectorized_engine = true，batch_size = 16384）
test_name='r-udf-6-t-16384'
pre_query="set global enable_vectorized_engine=true;set global batch_size=16384;"
runSingle ${test_name} "${query_sql}" "${pre_query}"


# 归档测试结果
echo 'test_name,mode,avg,min,max,client_num,queries_per_client' > "${archive_dir}"/0.csv
cat "${archive_dir}"/*.csv > "${archive_dir}"/result.csv
rm -rf "${archive_dir}"/0.csv

log1 "##########################################################################"
log1 "测试全局参数："
log1 "client_num=${client_num}"
log1 "queries_num=${client_queries_limit}"
log1 "测试结果： ${archive_dir}/result.csv "
# shellcheck disable=SC2002
resFmt=$(cat "${archive_dir}"/result.csv | column -t -s,)
log1 "${resFmt}"
log1 "#########################################################################"


