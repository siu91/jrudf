# Doris  Remote UDF 开发和调试



## Remote UDF 介绍

>  参考官方的文档。

Remote UDF Service 支持通过 RPC 的方式访问用户提供的 UDF Service，以实现用户自定义函数的执行。相比于 Native 的 UDF 实现，Remote UDF Service 有如下优势和限制：

优势

- 跨语言：可以用 Protobuf 支持的各类语言编写 UDF Service。
- 安全：UDF 执行失败或崩溃，仅会影响 UDF Service 自身，而不会导致 Doris 进程崩溃。
- 灵活：UDF Service 中可以调用任意其他服务或程序库类，以满足更多样的业务需求。

使用限制

- 性能：相比于 Native UDF，UDF Service 会带来额外的网络开销，因此性能会远低于 Native UDF。同时，UDF Service 自身的实现也会影响函数的执行效率，用户需要自行处理高并发、线程安全等问题。
- 单行模式和批处理模式：Doris 原先的的基于行存的查询执行框架会对每一行数据执行一次 UDF RPC 调用，因此执行效率非常差，而在新的向量化执行框架下，会对每一批数据（默认2048行）执行一次 UDF RPC 调用，因此性能有明显提升。实际测试中，基于向量化和批处理方式的 Remote UDF 性能和基于行存的 Native UDF 性能相当，可供参考



**所以， Doris Remote UDF 开发，其实就是开发一个 RPC 服务，以 RPC 访问的方式提供 UDF 服务。**





## RPC Server 



### 设计

![](./arch.svg)

### 开发

#### 编译 proto

***需要安装 protoc 环境***

从官方 proto file进行编译，当前已经编译放在 `libs/doris-rudf-grpclib.jar`

#### 代码结构 

```shell
.
├── libs
│   └── doris-rudf-grpclib.jar # proto 编译的包，作为 local lib
├── proto # 原始 proto 文件
│   ├── function_service.proto
│   └── types.proto
├── src
│   └── main
│       ├── java
│       │   ├── com
│       │   │   └── siu
│       │   │       └── udf
│       │   │           └── SubFunction.java # 实现 IFunction，会以 SPI 的方式注册到 Functions 
│       │   └── org
│       │       └── apache
│       │           └── doris
│       │               └── udf
│       │                   ├── Main.java # 入口
│       │                   ├── func
│       │                   │   ├── Functions.java # 单例，以SPI 方式加载 UDF
│       │                   │   └── IFunction.java # 函数接口定义，需要实现 call(),check(),getName()
│       │                   └── server
│       │                       ├── FunctionServiceImpl.java # Doris Remote UDF 定义的接口，这里需要实现 checkFn(), callFn(),handShake()
│       │                       └── RpcServer.java
│       └── resources
│           └── META-INF
│               └── services
│                   └── org.apache.doris.udf.func.IFunction # SPI 定义文件
└── target # target code
```



#### 编码



#### 编译

```shell
mvn package
```

#### 运行

```shell
java -jar jrudf-jar-with-dependencies.jar 9000
```
`9000` 是默认端口，可以不传

#### 远程调试
远程服务器上启动服务
```shell
java -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=[ip]:5005 -jar jrudf-jar-with-dependencies.jar
# 后台运行
nohup java -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=[ip]:5005 -jar jrudf-jar-with-dependencies.jar >jrudf.log 2>&1 &
```
本地 IDEA 添加 Remote 配置:
`Edit Configurtions-> Add New Configrution->Remote JVM Debug`



## 测试

### 在 Doris 上创建 UDF
目前暂不支持 UDAF 和 UDTF
```sql
CREATE FUNCTION
name ([,...])
[RETURNS] rettype
PROPERTIES (["key"="value"][,...])
```
说明：
```txt
PROPERTIES中symbol表示的是 rpc 调用传递的方法名，这个参数是必须设定的。
PROPERTIES中object_file表示的 rpc 服务地址，目前支持单个地址和 brpc 兼容格式的集群地址，集群连接方式 参考 格式说明 (opens new window)。
PROPERTIES中type表示的 UDF 调用类型，默认为 Native，使用 Rpc UDF时传 RPC。
name: 一个function是要归属于某个DB的，name的形式为dbName.funcName。当dbName没有明确指定的时候，就是使用当前session所在的db作为dbName。

```

***注：特别说明，PROPERTIES.symbol 和 name 强制一致，发现在 set enable_vectorized_engine=true 调用传的函数名是 name，false 时传 symbol***

示例：

```sql
CREATE FUNCTION rpc_add(INT, INT) RETURNS INT PROPERTIES (
"SYMBOL"="add_int",
"OBJECT_FILE"="127.0.0.1:9000",
"TYPE"="RPC"
);
```

### 使用 UDF
用户使用 UDF 必须拥有对应数据库的 SELECT 权限。

UDF 的使用与普通的函数方式一致，唯一的区别在于，内置函数的作用域是全局的，而 UDF 的作用域是 DB内部。当链接 session 位于数据内部时，直接使用 UDF 名字会在当前DB内部查找对应的 UDF。否则用户需要显示的指定 UDF 的数据库名字，例如 dbName.funcName。

### 删除 UDF
当你不再需要 UDF 函数时，你可以通过下述命令来删除一个 UDF 函数, 可以参考 DROP FUNCTION



## Native UDF 和 Remote UDF 性能对比

> #### 说明
>
> Native UDF 在性能上有天然的优势，所以比较性能时，需要开启 Doris 的向量化引擎才有比较的意义，这里只是简单的设计几个对照组，每组执行10次，分别为：
>
> - Native UDF
> - Remote UDF 1 （enable_vectorized_engine = false）
> - Remote UDF 2（enable_vectorized_engine = true，batch_size = 1024）
> - Remote UDF 3（enable_vectorized_engine = true，batch_size = 2048）
> - Remote UDF 4（enable_vectorized_engine = true，batch_size = 4096）
>
> ***注：UDF 的实现逻辑 str.length()***









## 编译 Doris

***由于当前版本（0.15）不支持 Remote UDF，所以编译 Doris 最新版本进行功能验证***

### 安装 Docker 环境 （略）
***推荐使用 Docker 集成的编译环境去进行 Doris 编译***

### 下载编译集成环境镜像

```shell
docker pull apache/incubator-doris:build-env-ldb-toolchain-latest
```
### 下载 Doris 源码

```shell
mkdir -p /opt/doris && cd /opt/doris
git clone https://github.com/apache/incubator-doris.git
```
### 运行编译集成环境
```shell
docker run -it -v /root/.m2:/root/.m2 -v /opt/doris/incubator-doris/:/root/incubator-doris/ apache/incubator-doris:build-env-ldb-toolchain-latest
```

### 编译
```shell
cd /root/incubator-doris/
sh build.sh --clean --be --fe --ui
```

### 打包构建
```shell
tar zcvf apache-doris-latest-454b45b-incubating.tar.gz ./output
```
***454b45b 是源码的 commit hash id***



## 问题

- proto 编译要修改官方的 pom文件中 `protoc` 环境的位置

```xml
<protocCommand>${doris.thirdparty}/installed/bin/protoc</protocComm> <!-- 修改成 protoc 的安装位置 -->
```

- Doris 源码编译时 gcc  找不到，版本不对

  需要 which 一下看看 gcc 的位置，在 `env.sh` 中设置一下 `${DORIS_GCC_HOME}`