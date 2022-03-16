db_ip=$(hostname -I | awk '{gsub(/^\s+|\s+$/, "");print}')
client_num=10
run_times=5
client_queries_limit=10
db_schema='ssb'
db_user='root'
db_port='9030'

date_str=$(date "+%Y%m%d%H%M%S%3N")

## 记录日志
log() {
  date_str=$(date "+%Y-%m-%d %H:%M:%S.%3N")
  echo "$(hostname -s)" ${date_str} $1
}

run(){
    echo "========================================================================"
    log "执行测试：$1 "
    log "执行预处理："
    cat ./"${archive_dir}"/p_"$1".sql
    log "执行测试 SQL："
    cat ./"${archive_dir}"/"$1".sql


    mysqlslap -u ${db_user} -P ${db_port} -h ${db_ip} \
--concurrency=${client_num} --iterations=${run_times} --number-of-queries=${client_queries_limit} --create-schema=${db_schema} \
--query=./"${archive_dir}"/"$1".sql \
--pre-query=./"${archive_dir}"/p_"$1".sql \
--csv=./"${archive_dir}"/"$1".csv

    tmp=$(cat ./"${archive_dir}"/"$1".csv)
    tmp1=$1${tmp}
    echo "$tmp1" > ./"${archive_dir}"/"$1".csv

    log "$1 执行完成:"
    cat ./"${archive_dir}"/"$1".csv

}


# 创建归档目录
archive_dir=test-"${date_str}"
mkdir ${archive_dir}

# test 1: build-in functions
test_name='build-in'
query_sql="select length(c_address) from ${db_schema}.customer;"
pre_query="set global enable_vectorized_engine=true;set global batch_size=1024;"
echo "${query_sql}" > ./"${archive_dir}"/${test_name}.sql
echo "${pre_query}" > ./"${archive_dir}"/p_${test_name}.sql
run ${test_name}


# test 2：Native UDF
test_name='n-udf-f'
query_sql="select ${db_schema}.get_string_length(c_address) from ${db_schema}.customer;"
pre_query="set global enable_vectorized_engine=false;"
echo "${query_sql}" > ./"${archive_dir}"/${test_name}.sql
echo "${pre_query}" > ./"${archive_dir}"/p_${test_name}.sql
run ${test_name}

# r-udf 测试sql
query_sql="select ${db_schema}.str_length(c_address) from ${db_schema}.customer;"

# test 3：Remote UDF 1 （enable_vectorized_engine = false）
test_name='r-udf-1-f'
pre_query="set global enable_vectorized_engine=false;"
echo "${query_sql}" > ./"${archive_dir}"/${test_name}.sql
echo "${pre_query}" > ./"${archive_dir}"/p_${test_name}.sql
#run ${test_name}


# test 4: Remote UDF 2（enable_vectorized_engine = true，batch_size = 1024）
test_name='r-udf-2-t-1024'
pre_query="set global enable_vectorized_engine=true;set global batch_size=1024;"
echo "${query_sql}" > ./"${archive_dir}"/${test_name}.sql
echo "${pre_query}" > ./"${archive_dir}"/p_${test_name}.sql
run ${test_name}

# test 5: Remote UDF 3（enable_vectorized_engine = true，batch_size = 2048）
test_name='r-udf-3-t-2048'
pre_query="set global enable_vectorized_engine=true;set global batch_size=2048;"
echo "${query_sql}" > ./"${archive_dir}"/${test_name}.sql
echo "${pre_query}" > ./"${archive_dir}"/p_${test_name}.sql
run ${test_name}

# test 6: Remote UDF 4（enable_vectorized_engine = true，batch_size = 4096）
test_name='r-udf-4-t-4096'
pre_query="set global enable_vectorized_engine=true;set global batch_size=4096;"
echo "${query_sql}" > ./"${archive_dir}"/${test_name}.sql
echo "${pre_query}" > ./"${archive_dir}"/p_${test_name}.sql
run ${test_name}

# test 7: Remote UDF 5（enable_vectorized_engine = true，batch_size = 8192）
test_name='r-udf-5-t-8192'
pre_query="set global enable_vectorized_engine=true;set global batch_size=8192;"
echo "${query_sql}" > ./"${archive_dir}"/${test_name}.sql
echo "${pre_query}" > ./"${archive_dir}"/p_${test_name}.sql
run ${test_name}


# 归档测试结果
echo 'test_name,mode,avg,min,max,client_num,queries_per_client' > "${archive_dir}"/0.csv
cat "${archive_dir}"/*.csv > "${archive_dir}"/result.csv
rm -rf "${archive_dir}"/0.csv

echo "####################################################################"
log "测试结果："
cat "${archive_dir}"/result.csv | column -t -s,
echo "###################################################################"


