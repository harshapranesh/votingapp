# example-voting-app 中文快速开始

## 启动
docker compose up -d
docker compose ps

## 访问
- 投票页: http://localhost:8080
- 结果页: http://localhost:8081

## 停止
docker compose down

## 常见问题
- 拉镜像超时: 配置 Docker registry mirror
- 端口打不开: 检查虚拟机 IP、防火墙和端口映射
- 权限问题: 将用户加入 docker 组后重新登录
