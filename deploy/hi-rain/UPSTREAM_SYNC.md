# RainAPI 官方上游同步记录

机器可读进度见 [upstream-sync.json](upstream-sync.json)，执行流程见
[项目 skill](../../.codex/skills/rainapi-upstream-sync/SKILL.md)。记录完整 SHA，
下一次从已合并提交继续，不按版本号猜测，也不重新覆盖生产配置。

## 2026-09-23：rc.36 后续更新至 rc.40 主线

### 范围与冲突处理

- 上游：`https://github.com/QuantumNous/new-api.git`，分支 `main`。
- 原上游进度：`4fc9d1f1fa77c0cfdd9719cb59ff9ecc9885d66a`。
- 本轮固定目标：`996adffe5165bd5e311e33a03a86b8aede1fe376`。
- 合入 120 个上游提交；包括 `v1.0.0-rc.37` 至 `v1.0.0-rc.40`，
  以及 rc.40 后的 3 个主线提交。
- 合并提交：`dc7f6b631baaab6927c1f4e2b8c154ab1d452620`。
- 发布版本：`v1.0.0-rc.40-rain.1`。
- 合并前先用 `09978f8e1` 保存已确认的 GPT-6 定价、Preview 路由和安装脚本配置。
- 唯一文本冲突为 `web/src/features/dashboard/components/users/user-charts.tsx`：
  保留 RainAPI 的用户过滤、多选、日期范围，并接入上游统一接口错误处理。
- 将已有 4 个统计筛选测试改为 Vitest 入口，沿用原断言和用例。
- 常规升级不再默认执行生产配置基线 SQL；显式管理员定价优先级和实际分组保持不变。

### 验证与发布进度

当前精确阶段以 JSON 记录为准。镜像在 Windows Docker Desktop 构建；
服务器仅接收已验证镜像，不在服务器编译。

已完成：

- 生产镜像构建：`rainapi:v1.0.0-rc.40-rain.1`。
- 前端 Bun 1.4.0 + Node 22.23.2：类型检查通过，166 个官方测试文件共 2096 个测试通过；
  RainAPI 统计测试文件的 4 个测试单独通过，共 2100 个。
- 本次调整的前端文件 lint / 格式检查通过。
- 全仓 lint 尚有 182 errors / 66 warnings：官方目标 SHA 的原始 `web/` 独立复现完全相同数量。
  这是上游基线，未把全仓 lint 记录为通过。
- 项目 skill 的 `quick_validate.py` 通过；进度检查脚本确认目标上游为 HEAD 祖先，待合入数为 0。

SQLite 3.50.4、MySQL 5.7.44、PostgreSQL 18.1 的 9 条升级路径均已通过，
覆盖空库、线上 rc.36-rain.3 和官方 rc.40 带数据升级；每条路径重复启动两次，
结构稳定，用户/令牌/渠道/密钥/价格/日志保持，登录和 200,000 字节插件源码保存通过。
MySQL/PostgreSQL 同时覆盖独立日志库。SQLite 版本另外用应用相同 Go 驱动执行
`SELECT sqlite_version()` 核实。

根 Go 模块与独立 relaykit 的 vet、build 和全部测试均通过（Go 1.26.1）。
根模块测试配置了真实本地 MySQL/PostgreSQL DSN；按包串行，避免共享测试库相互干扰。
实际执行命令为：

```sh
go vet ./...
go build ./...
go test -p 1 -v ./...
cd relaykit
GOWORK=off go vet ./...
GOWORK=off go build ./...
GOWORK=off go test ./...
```

复用验证入口：

```powershell
chcp 65001 > $null
# 通过 rain-powershell runner 执行下列构建和长任务。
& .\deploy\hi-rain\build-image.ps1 -ImageTag rainapi:verify-go-20260923 -Target builder2
python deploy/hi-rain/verify-upgrade.py `
  --image rainapi:v1.0.0-rc.40-rain.1 `
  --baseline rainapi:v1.0.0-rc.36-rain.3 `
  --baseline calciumion/new-api:v1.0.0-rc.40 `
  --go-image rainapi:verify-go-20260923 `
  --output .local-tests/upgrade-report.json
```

验证脚本使用本机独立网络、随机测试凭据和临时卷。MySQL 与 PostgreSQL 共享测试网络命名空间，
Go 测试通过 `127.0.0.1` 访问它们，符合上游禁止远端数据库测试的保护。
真实环境数据库矩阵检查用户、令牌、渠道、通行密钥、模型组、插件、显式价格和独立日志库；
覆盖空库、当前线上版本及官方最新发布版本升级，并重复启动检查结构稳定。
不会连接生产数据库，也不会删除其他项目容器或数据卷。

前端测试需要 Node 运行时，并挂载根目录 `pkg/billingexpr/testdata` 供前后端共享计费夹具使用；
仅用 Bun 镜像的兼容运行时会造成测试工具错误，不应据此修改产品逻辑。

### 线上发布结果

- 2026-09-23 10:40（Asia/Shanghai）完成发布并通过健康检查，线上版本为
  `v1.0.0-rc.40-rain.1`；应用仍由原 1Panel Compose 项目 `new-api` 管理。
- 本地构建、数据库验证和线上运行使用同一个镜像 ID：
  `sha256:30ac629e6c9a843dba073a2a9a62b84c5a0249bd944787e3e84b53d61d812c01`。
- 生产 Compose 只变更镜像；其余字段与发布前一致，实际 `/data`、`/app/logs` 挂载已独立核对。
- 发布前备份位于 `/opt/1panel/backup/rainapi/upgrade-20260923-upstream-rc40`，
  包含 Compose、环境文件和 PostgreSQL 自定义格式备份；`pg_restore --list` 检查通过。
  既有 1Panel 7 天清理任务启用且最近运行成功，未重复创建。
- 发布瞬间核对用户、令牌、渠道、选项和路由能力的摘要全部一致；用户 9、令牌 17、渠道 4，
  日志随在线请求正常增长。后续验证临时建立了一个 Preview 令牌，测试结束已撤销。
- `Codex专用` 的 Sol Chat Completions、`All Model` 的 Astra Chat Completions、
  `Preview` 的 Astra Responses 流均实际成功；Codex 调用 Astra 返回 `503 model_not_found`，符合限制。
- 上述三个成功请求各消耗输入 10 / 输出 5 tokens：Sol 扣 35 quota，Astra 各扣 175 quota，
  与截图标准价格和分组倍率 1 一致。10 个规范模型价格与基准 JSON 相符，全部 25 条显式表达式保留。
- `/codex/install.ps1`、`/codex/install.sh` 和无后缀入口的 PowerShell/curl 分流逐字匹配仓库脚本，
  默认 `model` / `review_model` 为 `gpt-6-sol`；公网首页和 `/api/status` 正常。
- 用户重新登录后，已在 Chrome 验证新版本标识、用户统计图表、14 天/自定义日期切换、
  6 个可见用户的多选列表，以及系统信息和四个定价分组页面；未通过页面重存生产设置。

### 认证变更核查依据

本轮合入上游多域名 Passkey、旧 GitHub 绑定迁移等认证修改，核查依据为
[OWASP ASVS 5.0.0](https://github.com/OWASP/ASVS/tree/v5.0.0/5.0)、
[Authentication Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html)、
[Session Management Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html)
及 [OAuth2 Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/OAuth2_Cheat_Sheet.html)。
关注身份提供商身份隔离（6.8.1）、服务端会话验证和轮换（7.2.1、7.2.4）、
会话撤销（7.4.1、7.4.2）、敏感操作重新验证（7.5.1）。
保留上游失败、过期、重放、验证绕过和绑定迁移回归；不声称全站已经取得 ASVS 合规认证。
根模块全量测试包含 Passkey 并发完成、挑战隔离、用户验证要求、旧 GitHub 绑定身份凭据检查及迁移等用例，
均已通过；三个数据库的真实登录与会话请求也通过。线上由用户完成真实登录后检查管理页面。

### 用户能感知的更新

| 使用场景 | 更新后可见的变化 |
| --- | --- |
| 配置模型价格 | 可把旧价格转换为表达式草稿，先预览再保存；支持条件、按次、时间和图片缓存计价。已有自定义价格继续优先。 |
| 查看费用与日志 | 扣费来源、订阅费用、任务生成结果和性能信息更清楚；请求模型与实际返回模型不一致时有更准确的提示。 |
| 接入客户端 | API Key 页面可以显示和复制当前站点/默认 API 地址；减少用户手工拼接地址。 |
| 管理渠道与模型 | 新建和编辑渠道使用统一界面；模型重定向更直观；应用上游模型变更前可以预览；模型元数据支持批量选择同步字段。 |
| 管理用户分组 | 分组支持拖动排序，编辑界面更清楚；移动端筛选和弹窗操作按钮更容易使用。 |
| 图片与视频任务 | 任务插件可承接 OpenAI Images 生成/编辑接口；New API 渠道可绑定多个任务插件；较大的插件可上传保存，201/202 提交结果不会再误判失败。 |
| 工具调用带图片 | Claude / Responses 工具返回的图片会按图片传递给上游，避免图片被当作普通文本。 |
| 实时响应与路由 | 增加并扩展 Responses WebSocket、集中请求策略和路由决策记录；适用渠道须按业务需求配置后使用。 |
| 登录和账号绑定 | 可配置多个 Passkey 网站域名，删除域名前预览受影响账号；旧 GitHub 绑定迁移要求有效身份验证。 |

上游来源：[rc.37](https://github.com/QuantumNous/new-api/releases/tag/v1.0.0-rc.37)、
[rc.38](https://github.com/QuantumNous/new-api/releases/tag/v1.0.0-rc.38)、
[rc.39](https://github.com/QuantumNous/new-api/releases/tag/v1.0.0-rc.39)、
[rc.40](https://github.com/QuantumNous/new-api/releases/tag/v1.0.0-rc.40)。
合并提供这些能力；未为本次更新自动新增收费上游、启用全部插件或改变用户套餐。

### RainAPI 保留项

- `Codex专用`：可用 `gpt-6-sol`，不能调用 `gpt-6-astra`。
- `Preview` 与 `All Model`：Astra 经 Preview 渠道路由，与原 Codex 渠道共用既有凭据。
- GPT 系列显式价格以用户 2026-09-23 截图为准，保留长上下文和缓存类别；图片渠道自定义价格保持。
- PowerShell 与 Bash 一键配置脚本默认 `model` / `review_model` 均为 `gpt-6-sol`。
- 用户统计排除名单、多用户选择、自定义日期范围及默认按天统计保持。

### 后续继续

运行 skill 的 `scripts/inspect-upstream.ps1 -Fetch`；从
`996adffe5165bd5e311e33a03a86b8aede1fe376` 后的提交开始核对。
若 JSON 阶段尚未完成，先完成对应验证/发布/推送，不再次合并同一批提交。
