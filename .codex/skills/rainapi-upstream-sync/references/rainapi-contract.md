# RainAPI 定制与发布边界

合并前读取现场配置，下列路径用于定位，不能替代实时核查。

## 需要保留的定制

- 用户统计：排除 `poppy`、`mgfly`、`anshuo`；支持多选用户、空选择、自定义起止日期，
  汇总、Top-N 与图表使用同一份过滤后数据。入口为
  `web/src/features/dashboard/components/users/` 和 `lib/user-statistics-filter.ts`。
- 仪表盘日粒度默认值，以及 RainAPI 的现有站点配置。保留官方 New API / QuantumNous 归属与许可证。
- Codex 的 Chat Completions 到 Responses 转换：流式调用上游，非流式客户端接收标准 JSON；
  保留上游缺少 Content-Type 时的 SSE 识别与工具调用结果。
- `deploy/hi-rain/openai-standard-pricing.json` 为用户确认的定价来源；线上管理员显式覆盖
  优先于上游内置默认值。合并和发布不得自动重置管理员价格、用户余额、密钥或渠道。
- 已设定路由：渠道 1 为 `All Model,Codex专用`，Sol 可用、Astra 不可用；
  渠道 4 `Preview` 为 `All Model,Preview`，仅 Astra/compact。Preview 按用户要求复用现有账号凭据。
  `Codex专用` 不应通过可选分组绕过 Astra 限制。图像生成分组与自定义定价独立保留。
- 托管安装脚本 `deploy/hi-rain/codex/install.ps1`、`install.sh` 默认模型与 review_model 为
  `gpt-6-sol`；检查两个固定后缀 URL 及 `/codex/install` 的 PowerShell/curl 分流。

## 本地验证与生产交付

- Docker Desktop 是本地运行环境；遵循用户级规则，测试数据库使用隔离的项目资源，
  不连接生产库、不修改其它项目容器或卷。现有缓存卷可复用以减少重复下载。
- `deploy/hi-rain/build-image.ps1` 负责本机构建；前端沿用仓库 Bun 锁文件。
  镜像标签和 `VERSION` 必须一致，记录实际 image ID；不要重用已发布标签。
- 生产主机为 `hi-rain`。连接前读 rain-device-info 的当前管理策略，使用 PuTTY，
  不复用 `.local-tests` 中历史主机地址或旧口令变量。
- 当前应用由 1Panel Apps 管理，Compose 位于
  `/opt/1panel/apps/new-api/new-api/docker-compose.yml`。维持项目/容器名 `new-api`、
  PostgreSQL 业务库、挂载与端口，不为套模板搬迁已有面板管理对象。
- 发布只替换镜像并运行 `docker compose up -d --no-build`。读取现有 Compose，
  不用仓库示例整体覆盖线上 `.env`。`apply-production-settings.sql` 是基线，
  全量执行会覆盖配置；本次发布不需要变更配置时不要运行它。
- 备份根目录为 `/opt/1panel/backup/rainapi`，遵循 7 天自动保留策略。
  核查既有 1Panel 清理任务的启用、168 小时条件和最近成功记录，不重复建任务。
- 发布前后分别记录关键表数量与业务配置摘要；活动日志/用量可以随在线请求增长，
  不把合法增长误判成迁移损坏。凭据只在服务端比较，不能写进审计或 Git。
