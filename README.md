# 项目来源
这个项目是fork自openfrontier/docker-gerrit

# 修改原因
目前在openshift部署openfrontier/docker-gerrit 发现容器内部无法dns解析,而使用centos-base就可以
故将base镜像修改为centos

# 增加了什么
同时添加简单gerrit部署方式