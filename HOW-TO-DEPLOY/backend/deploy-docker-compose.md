# 通过Docker-compose部署

## 1.开发环境部署
### ~~1.1 环境配置文件预先~~(废弃，看1.1a)

### 文件夹权限

` chmod -R 775 ./mydata`

**logstash**

首先在目标文件夹 "mydata/logstash" 复制准备好的文件
![img.png](imgs/img_logstash_conf.png)

**Nginx**

需要拷贝nginx配置文件，否则挂载时会因为没有配置文件而启动失败。

```bash
# 创建目录之后将nginx.conf文件以及mime.types上传到该目录下面
mydata/nginx/conf/
```
![nginx配置文件](imgs/img_nginx_conf.png)

**RabbitMq**

在`mydata`父级路径命令行执行

```shell
mkdir -p ./mydata/rabbitmq/data
mkdir -p ./mydata/rabbitmq/log
sudo chmod -R 777 ./mydata/rabbitmq/log

```



### 1.1a 脚本执行预置环境

将`init.sh`放入目标文件夹执行

```sh

chmod +x init.sh # 赋予脚本执行权限

./init.sh #执行权限

```







### 1.2 docker-compose启动环境容器组

移动compose文件，然后
`docker-compose -f docker-compose-env.yml up -d`

![img.png](imgs/img_3.png)
启动后如果有容器三个失败：rabbitmq，nginx，es。代表你之前的操作没有完成
![启动后有三个失败](imgs/img.png)



### 1.3 对具体容器配置



~~**LogStash**~~（1.1a已经优化，废弃）

- 将`logstash.conf`移动到  `mydata/logstash/`

- 需要安装`json_lines`插件，并重新启动。

```bash
docker exec -it logstash /bin/bash
logstash-plugin install logstash-codec-json_lines
docker restart logstash
```


**MySQL**

- 进入mysql容器并执行如下操作：

```bash
#进入mysql容器
docker exec -it mysql /bin/bash
#连接到mysql服务
mysql -uroot -proot --default-character-set=utf8
#创建远程访问用户
grant all privileges on *.* to 'reader' @'%' identified by '123456';
#创建mall数据库
create database mall character set utf8;
#使用mall数据库
use mall;
#导入mall.sql脚本/ 这里你用可视化工具navicat也可以
source /mall.sql;
```

**MongoDB**




**RabbitMQ**

访问 `http://localhost:15672/`

1,RabbitMQ创建帐号mall:mall，并设置其角色为管理员；
![img.png](imgs/img5.png)
2,创建一个新的虚拟host为，名称为/mall；
![img.png](imgs/img2.png)
3,点击mall用户进入用户配置页面；
![img.png](imgs/img3.png)
给mall用户配置该虚拟host的权限，至此，RabbitMQ的配置完成。
![img.png](imgs/img4.png)

**ES**
ES 需要安装ik分词器到 plugins

这里解压复制文件夹到` mydata/elasticsearch/plugins/ `

**Nacos**

导入压缩包


# 3.安装完毕

前端访问后登录

推荐俩账号
macro:macro123
admin:macro123