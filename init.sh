#!/usr/bin/env bash
# 根据 docs/项目前端初始化框架文档.md 中的初始化步骤，构建 apps 目录结构及各前端初始化文件。
# 使用：在项目根目录执行 ./init.sh

set -e
ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

echo "[init] 创建目录结构..."
mkdir -p apps/web apps/uni-app apps/admin apps/mock packages/shared docker

# ---- apps/web：Vue3 + Vite + TS ----
if [ ! -f apps/web/package.json ]; then
  echo "[init] 初始化 apps/web (Vite Vue TS)..."
  npm create vite@latest apps/web -- --template vue-ts
else
  echo "[init] apps/web 已存在，跳过"
fi

# ---- apps/uni-app：占位 + 说明，完整脚手架需 HBuilderX 或 CLI 手动创建 ----
if [ ! -f apps/uni-app/package.json ]; then
  echo "[init] 创建 apps/uni-app 占位（完整项目请用 HBuilderX 或 uni-app CLI 创建）..."
  cat > apps/uni-app/package.json << 'PKG'
{
  "name": "big-sell-uni-app",
  "version": "0.0.0",
  "private": true,
  "scripts": {
    "dev:h5": "echo '请使用 HBuilderX 或 uni-app 官方 CLI 重新初始化此项目'",
    "build": "echo '请先完成 uni-app 项目初始化'"
  }
}
PKG
else
  echo "[init] apps/uni-app 已存在，跳过"
fi

# ---- apps/admin：Vben Admin 模板（degit） ----
if [ ! -f apps/admin/package.json ]; then
  echo "[init] 拉取 Vben Admin 模板到 apps/admin..."
  if command -v npx &>/dev/null; then
    npx --yes degit vbenjs/vue-vben-admin apps/admin || {
      echo "[init] degit 失败，创建 apps/admin 占位，可稍后手动：npx degit vbenjs/vue-vben-admin apps/admin"
      mkdir -p apps/admin
      cat > apps/admin/package.json << 'PKG'
{
  "name": "big-sell-admin",
  "version": "0.0.0",
  "private": true,
  "scripts": {
    "dev": "echo '请运行: npx degit vbenjs/vue-vben-admin apps/admin'",
    "build": "echo '请先完成 admin 项目初始化'"
  }
}
PKG
    }
  else
    echo "[init] 未找到 npx，创建 admin 占位"
    cat > apps/admin/package.json << 'PKG'
{
  "name": "big-sell-admin",
  "version": "0.0.0",
  "private": true,
  "scripts": {
    "dev": "echo '请运行: npx degit vbenjs/vue-vben-admin apps/admin'",
    "build": "echo '请先完成 admin 项目初始化'"
  }
}
PKG
  fi
else
  echo "[init] apps/admin 已存在，跳过"
fi

# ---- apps/mock：Mock 服务（Express + config.json） ----
if [ ! -f apps/mock/server.js ]; then
  echo "[init] 创建 apps/mock (server.js + config.json)..."
  cat > apps/mock/package.json << 'PKG'
{
  "name": "big-sell-mock",
  "version": "0.0.0",
  "private": true,
  "type": "commonjs",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^4.21.0"
  }
}
PKG
  cat > apps/mock/config.json << 'CFG'
{
  "port": 5176,
  "routes": [
    {
      "path": "/api/login",
      "method": "post",
      "responses": {
        "success": { "status": 200, "body": { "code": 0, "data": { "token": "mock-token" } } },
        "wrongPassword": { "status": 200, "body": { "code": 40001, "message": "密码错误" } },
        "userLocked": { "status": 200, "body": { "code": 40002, "message": "账号已锁定" } },
        "serverError": { "status": 500, "body": { "message": "Internal Server Error" } }
      }
    },
    {
      "path": "/api/user",
      "method": "get",
      "responses": {
        "success": { "status": 200, "body": { "code": 0, "data": { "name": "张三" } } },
        "unauthorized": { "status": 401, "body": { "message": "未登录" } }
      }
    }
  ]
}
CFG
  cat > apps/mock/server.js << 'SRV'
const path = require('path')
const fs = require('fs')
const express = require('express')
const app = express()
app.use(express.json())

const configPath = path.join(__dirname, 'config.json')
const config = JSON.parse(fs.readFileSync(configPath, 'utf8'))

config.routes.forEach((route) => {
  const method = (route.method || 'get').toLowerCase()
  app[method](route.path, (req, res) => {
    const scenario = req.query.__scenario || req.get('X-Mock-Scenario') || 'success'
    const response = route.responses[scenario] || route.responses.success
    if (!response) return res.status(404).json({ message: 'Mock scenario not found' })
    res.status(response.status || 200).json(response.body || {})
  })
})

app.listen(config.port || 5176, () => {
  console.log(`Mock server at http://localhost:${config.port || 5176}`)
})
SRV
else
  echo "[init] apps/mock 已存在，跳过"
fi

# ---- docker/Dockerfile：轻量 Node 环境 ----
if [ ! -f docker/Dockerfile ] || ! grep -q 'sleep infinity' docker/Dockerfile 2>/dev/null; then
  echo "[init] 写入 docker/Dockerfile（轻量 Node 环境）..."
  cat > docker/Dockerfile << 'DF'
# 仅提供 Node 24 环境，不复制代码、不安装依赖
FROM node:24-alpine
WORKDIR /app
CMD ["sleep", "infinity"]
DF
else
  echo "[init] docker/Dockerfile 已为轻量版，跳过"
fi

echo "[init] 完成。下一步：在各子项目内安装依赖（make install 或 cd apps/xxx && npm install），并按文档配置 TailwindCSS 与 API base URL。"
echo "  - 前台：apps/web"
echo "  - uni-app：apps/uni-app（占位，完整项目请用 HBuilderX 或 CLI 创建）"
echo "  - 管理端：apps/admin"
echo "  - Mock：apps/mock（已含 server.js + config.json）"
