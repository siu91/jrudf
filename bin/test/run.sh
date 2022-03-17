#!/bin/bash
#
# @CreationTime
#   2022/3/15 下午16:45:20
# @Function
#
# @Usage
# @author Siu

CURRENT_PATH=$(readlink -f "$(dirname "$0")")

##  region 全局参数：当有配置文件覆盖时这里的参数无效
db_ip=$(hostname -I | awk '{gsub(/^\s+|\s+$/, "");print}')
# 总查询的次数 = min(client_queries_limit,client_num * run_times)
client_num=10
run_times=5
# 官方文档说明：Limit each client to approximately this number of queries，实际限制每个 client，而是限制总查询数
client_queries_limit=10
db_schema='ssb'
db_user='root'
db_port='9030'

# 配置文件
conf_file="${CURRENT_PATH}"/config/conf
# jobs
jobs_path="${CURRENT_PATH}"/config/jobs
## endregion

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
	log "$1 执行完成： ${res}"
}

runJobs() {
	if [ ! -d "${jobs_path}" ]; then
		log "jobs 路径不存在：$jobs_path"
		help
		exit 1
	else
		for file in "${jobs_path}"/*; do
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
	fi

}

archiveRes() {
	# 归档测试结果
	echo 'test_name,mode,avg,min,max,client_num,queries_per_client' >"${archive_dir}"/0.csv
	cat "${archive_dir}"/*.csv >"${archive_dir}"/result.csv
	rm -rf "${archive_dir}"/0.csv

	log1 "##########################################################################"
	log1 "测试结果： ${archive_dir}/result.csv "
	# shellcheck disable=SC2002
	resFmt=$(cat "${archive_dir}"/result.csv | column -t -s,)
	log1 "${resFmt}"
	log1 "#########################################################################"
}

main() {
	loadConf
	showArgs
	date_str=$(date "+%Y%m%d%H%M%S%3N")
	archive_dir=./output/test-"${date_str}"
	# 创建归档目录
	mkdir -p "${archive_dir}"
	runJobs
	archiveRes
}

showInfo() {
	echo """
  ================================================
  #                 sql 性能测试工具               #
  # 版本： 1.0.0                                 #
  # 作者： Siu                                   #
  # Support By： mysqlslap                      #
  ================================================

  """

	help
}

loadConf() {
	# shellcheck source=src/
	# 加载配置全局文件
	if [ ! -f "${conf_file}" ]; then
		log "配置文件不存在将使用默认配置或命令行输入参数:${conf_file}"
	else
		. "${conf_file}"
		# shellcheck disable=SC2027
		log "加载配置文件： ${conf_file}"
	fi

}

showArgs() {
	log1 "###############################################################################"
	log1 "测试参数："
	log1 "db_ip=${db_ip}"
	log1 "db_port=${db_port}"
	log1 "db_user=${db_user}"
	log1 "client_num=${client_num}"
	log1 "queries_limit=${client_queries_limit}"
	log1 "###############################################################################"

}

help() {
	echo """
Usage: ./run.sh -f ./myconfig/conf.file
       ./run.sh -j ./jobs
       ./run.sh -h  192.168.1.1
       ./run.sh -p  9001
       ./run.sh -u  admin
       ./run.sh -P  P@ssw0rd

Options:
  -f      配置文件路径，默认：./config/conf
  -s      sql 任务路径，默认：./config/jobs
  -H      数据库IP，默认：本机 IP
  -p      数据库端口，默认：9030
  -u      数据库用户，默认：root
  -P      数据库密码，默认：空
  -c      测试并发数，默认：10
  -q      总查询次数，默认：10
  -h      帮助信息
  -v      工具版本信息

  """
}

#main

#echo original parameters=[$@]

# https://www.jianshu.com/p/6393259f0a13
#-o或--options选项后面是可接受的短选项，如ab:c::，表示可接受的短选项为-a -b -c，
#其中-a选项不接参数，-b选项后必须接参数，-c选项的参数为可选的
#-l或--long选项后面是可接受的长选项，用逗号分开，冒号的意义同短选项。
#-n选项后接选项解析错误时提示的脚本名字
#ARGS=$(getopt -o ab:c:: --long along,blong:,clong:: -n "$0" -- "$@")
ARGS=$(getopt -o vhf:j:H:p:u:c:q: -n "$0" -- "$@")
if [ $? != 0 ]; then
	echo "参数错误，退出..."
	help
	exit 1
fi

#echo ARGS=[$ARGS]
#将规范化后的命令行参数分配至位置参数（$1,$2,...)
eval set -- "${ARGS}"
echo formatted parameters=[$@]

while true; do
	case "$1" in
	-v)
		showInfo
		exit 0
		shift
		;;
	-h)
		help
		exit 0
		shift
		;;
	-f)
		conf_file=$2
		shift 2
		;;
	-j)
		jobs_path=$2
		shift 2
		;;
	-H)
		db_ip=$2
		shift 2
		;;
	-p)
		db_port=$2
		shift 2
		;;
	-u)
		db_user=$2
		shift 2
		;;
	-c)
		client_num=$2
		shift 2
		;;
	-q)
		#echo "option q:$2"
		client_queries_limit=$2
		shift 2
		;;
	--)
		main
		shift
		break
		;;
	*)
		help
		exit 1
		;;
	esac
done
