db_ip=$(hostname -I | awk '{gsub(/^\s+|\s+$/, "");print}')
client_num=1
run_times=1
client_queries_limit=10
db_schema='ssb'
db_user='root'
db_port='9030'
enable_vectorized_engine='true'
batch_size='1024'

date_str=$(date "+%Y%m%d%H%M%S%3N")


run(){
    echo "执行测试：$1 "
    mysqlslap -u ${db_user} -P ${db_port} -h ${db_ip} \
--concurrency=${client_num} --iterations=${run_times} --number-of-queries=${client_queries_limit} --create-schema=${db_schema} \
--query=./test_${date_str}/"$1".sql \
--pre-query=./test_${date_str}/p_${test_name}.sql \
--csv=./test_${date_str}/"$1".csv

}

function getDir() {
	for filename in $1/*
	do
	    if [ -d $filename ]
	    then
	        getDir $filename
	    else
	        if [[ "${filename##*.}" == 'csv' ]]
	        then
	            echo $filename
	            sed -i "1i\/*$filename*/" $filename
	        fi
	    fi
	done
}


# 创建归档目录
mkdir test_"${date_str}"


# test 1: build-in functions
test_name='build-in'
query_sql="select length(c_address) from ${db_schema}.customer;"
pre_query="set global enable_vectorized_engine=${enable_vectorized_engine};set global batch_size=${batch_size};"
echo "${query_sql}" > ./test_${date_str}/${test_name}.sql
echo "${pre_query}" > ./test_${date_str}/p_${test_name}.sql
run ${test_name}

# test 4: Remote UDF 2（enable_vectorized_engine = true，batch_size = 1024）
test_name='r-udf-2-t-1024'
query_sql="select ${db_schema}.str_length(c_address) from ${db_schema}.customer;"
pre_query="set global enable_vectorized_engine=${enable_vectorized_engine};set global batch_size=${batch_size};"
echo "${query_sql}" > ./test_${date_str}/${test_name}.sql
echo "${pre_query}" > ./test_${date_str}/p_${test_name}.sql
run ${test_name}

# test 5: Remote UDF 3（enable_vectorized_engine = true，batch_size = 2048）
test_name='r-udf-3-t-2048'
query_sql="select ${db_schema}.str_length(c_address) from ${db_schema}.customer;"
batch_size='2048'
pre_query="set global enable_vectorized_engine=${enable_vectorized_engine};set global batch_size=${batch_size};"
echo "${query_sql}" > ./test_${date_str}/${test_name}.sql
echo "${pre_query}" > ./test_${date_str}/p_${test_name}.sql
run ${test_name}


# test 6: Remote UDF 4（enable_vectorized_engine = true，batch_size = 2048）
test_name='r-udf-3-t-4096'
query_sql="select ${db_schema}.str_length(c_address) from ${db_schema}.customer;"
batch_size='4096'
pre_query="set global enable_vectorized_engine=${enable_vectorized_engine};set global batch_size=${batch_size};"
echo "${query_sql}" > ./test_${date_str}/${test_name}.sql
echo "${pre_query}" > ./test_${date_str}/p_${test_name}.sql
run ${test_name}

cd test_${date_str}
cat *.csv > result.csv
getDir ./test_${date_str}





