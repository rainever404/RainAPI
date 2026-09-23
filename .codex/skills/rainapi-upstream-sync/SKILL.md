---
name: rainapi-upstream-sync
description: 同步官方 QuantumNous/new-api 到 RainAPI 二开仓库，保留定制功能与线上配置，记录精确上游提交、验证和发布进度，并整理用户可感知的更新。用于合并官方更新或继续未完成的上游同步。
---

# RainAPI 上游同步

先读仓库 `AGENTS.md`、`deploy/hi-rain/upstream-sync.json` 和
`deploy/hi-rain/UPSTREAM_SYNC.md`。前者保存当前进度，后者保存每次同步的验证与发布证据。
不要仅凭版本标签判断合并进度：以完整 Git SHA 和祖先关系为准。

## 同步与续跑

1. 使用 rain-powershell 执行 Windows 命令。运行本技能的
   `scripts/inspect-upstream.ps1 -Fetch`，核查工作树、远端和待合并范围。
   官方来源必须是 `https://github.com/QuantumNous/new-api.git`，默认分支 `main`；
   RainAPI 的发布分支为 `master`，仅向 RainAPI 的 `origin` 推送。
2. 保留已有改动。用户已要求提交时，先把已确认属于当前任务的本地变更单独提交；
   不能把其他人的改动混入同步提交。创建 `codex/` 分支并固定本轮目标 SHA。
   用户未指定版本时同步本次 fetch 得到的官方主线；发布期间不追逐新的主线提交。
3. 用保留历史的 `git merge --no-ff` 合并，逐处解决冲突。
   参考 [RainAPI 定制与发布边界](references/rainapi-contract.md) 检查自动合并结果，
   不能对冲突文件批量选择 ours/theirs。提交合并后记录 `last_merged_commit` 和 `merge_commit`。
4. 按实际变更执行验证。认证改动读项目要求的 OWASP 指南；计费改动完整读取
   `.agents/rules/billing.md`；插件改动读 `docs/plugin-api/v1.md`；前端改动读
   `web/AGENTS.md` 和项目 shadcn-ui 技能。记录失败和待办，不能把“已合并”写成“已验证”。
5. 在 Windows Docker Desktop 本机构建不可变镜像，并完成前端类型检查、相关 lint/格式、
   测试、根 Go 模块与独立 relaykit 的构建/测试。数据库变更执行 SQLite、MySQL、
   PostgreSQL 的真实实例矩阵；迁移覆盖空库、旧版本带数据升级和二次启动。
   可复用 `deploy/hi-rain/verify-upgrade.py`，具体参数见 `--help`。
6. 发布权限以当前会话为准。用户已要求发布时，完成验证后继续发布，不重复索要同一授权。
   先备份，再传输已验证镜像；服务器只执行 load/pull 和 `compose up -d --no-build`。
   核查实际镜像 ID、健康、登录/业务路径、定价与分组，以及 1Panel 管理一致性。
   出现失败时记录现场，按已验证的回滚方案恢复；数据库升级后不能只凭旧镜像能启动就宣称回滚安全。
7. 更新进度及验证证据，完成用户要求的提交/推送。分别记录 merged、validated、deployed、
   pushed 状态；用 `merge-base --is-ancestor` 与远端 SHA 证明结果。
   最终按用户场景说明官方新增能力和修复，区分已经启用的功能与需要额外配置的能力。

## 记录边界

- `upstream-sync.json` 保存本轮固定目标、最后合入 SHA、发布镜像及阶段；中断时留下明确下一步。
- `UPSTREAM_SYNC.md` 保存范围、冲突决策、真实测试命令/引擎版本、发布验证和用户更新说明。
- 不保存密码、API key、OAuth 凭据、数据库连接密文或生产数据副本。
- 只检查配置状态而没有实际调用时必须如实注明；未测试的上游渠道不能宣称全部可用。
