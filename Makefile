# Node 版本（与 Dockerfile 一致）
NODE_VERSION ?= 24
IMAGE_NAME   := big-sell-frontend
CONTAINER_NAME := big-sell-dev
WORKDIR      := /app

.PHONY: install dev build dev-all dev-mock docker-build docker-up docker-down docker-install docker-shell
.PHONY: docker-dev-web docker-dev-uni docker-dev-admin docker-dev-mock docker-dev-all docker-build-all clean

# 检查 Node 版本
node-check:
	@node -v | grep -q "v$(NODE_VERSION)" || (echo "请使用 Node $(NODE_VERSION).x (当前: $$(node -v))" && exit 1)

# ---- 本地执行（不挂 Docker）----
# 安装依赖：各项目独立，需在各自目录执行或使用下方 docker-install
install: node-check
	cd apps/web && npm install
	cd apps/uni-app && npm install
	cd apps/admin && npm install
	cd apps/mock && npm install

# 开发：按需在对应子项目下执行
dev:
	npm run dev

# 同时启动 Mock（5176）+ 三个端（前台 5173 / uni-app H5 5174 / 管理端 5175）
dev-all:
	@(cd apps/mock && node server.js) & (cd apps/web && npm run dev) & (cd apps/uni-app && npm run dev:h5) & (cd apps/admin && npm run dev); wait

# 仅启动 Mock 数据服务（端口 5176，三端共用）
dev-mock:
	cd apps/mock && node server.js

# 前台网站 / uni-app H5 / 管理后台
dev-web:
	cd apps/web && npm run dev
dev-uni:
	cd apps/uni-app && npm run dev:h5
dev-admin:
	cd apps/admin && npm run dev

# 构建全部（各项目目录内 npm run build）
build:
	cd apps/web && npm run build; cd ../uni-app && npm run build; cd ../admin && npm run build

# ---- Docker：仅提供 Node 环境，代码与 node_modules 均挂载 ----
docker-build:
	docker build -t $(IMAGE_NAME):latest -f docker/Dockerfile .

# 启动容器（挂载当前目录，映射端口），后台常驻，供后续 docker exec 使用
docker-up:
	docker run -d --rm \
		-v $$(pwd):$(WORKDIR) \
		-p 5173:5173 -p 5174:5174 -p 5175:5175 -p 5176:5176 \
		--name $(CONTAINER_NAME) \
		$(IMAGE_NAME):latest

# 在容器内为各项目安装依赖（需先 make docker-up）
docker-install:
	docker exec $(CONTAINER_NAME) sh -c "cd apps/web && npm ci 2>/dev/null || npm install"
	docker exec $(CONTAINER_NAME) sh -c "cd apps/uni-app && npm ci 2>/dev/null || npm install"
	docker exec $(CONTAINER_NAME) sh -c "cd apps/admin && npm ci 2>/dev/null || npm install"
	docker exec $(CONTAINER_NAME) sh -c "cd apps/mock && npm ci 2>/dev/null || npm install"

# 在容器内启动各服务（需先 make docker-up、docker-install；每个终端运行一个）
docker-dev-web:
	docker exec -it $(CONTAINER_NAME) sh -c "cd apps/web && npm run dev"
docker-dev-uni:
	docker exec -it $(CONTAINER_NAME) sh -c "cd apps/uni-app && npm run dev:h5"
docker-dev-admin:
	docker exec -it $(CONTAINER_NAME) sh -c "cd apps/admin && npm run dev"
docker-dev-mock:
	docker exec -it $(CONTAINER_NAME) sh -c "cd apps/mock && node server.js"

# 在容器内同时启动 Mock + 三个前端服务（后台运行，需先 make docker-up、docker-install）
docker-dev-all:
	docker exec -d $(CONTAINER_NAME) sh -c "cd apps/mock && node server.js"
	docker exec -d $(CONTAINER_NAME) sh -c "cd apps/web && npm run dev"
	docker exec -d $(CONTAINER_NAME) sh -c "cd apps/uni-app && npm run dev:h5"
	docker exec -d $(CONTAINER_NAME) sh -c "cd apps/admin && npm run dev"

# 在容器内构建各项目（需先 make docker-up、docker-install）
docker-build-all:
	docker exec $(CONTAINER_NAME) sh -c "cd apps/web && npm run build"
	docker exec $(CONTAINER_NAME) sh -c "cd apps/uni-app && npm run build"
	docker exec $(CONTAINER_NAME) sh -c "cd apps/admin && npm run build"

docker-shell:
	docker exec -it $(CONTAINER_NAME) sh

docker-down:
	docker stop $(CONTAINER_NAME) 2>/dev/null || true

clean:
	rm -rf node_modules apps/*/node_modules apps/*/dist
