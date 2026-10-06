# 白泽插件源（baize-plugins）

[**白泽（Baize）**](https://github.com/HDKL0802/baize-public) 的**插件总仓** —— 官方的和社区的插件都在这里，
一处就能查到全部。

插件源就是**一堆静态文件**：一个 `index.json` 加若干 `packages/*.zip`。
所以它**不需要任何服务器** —— 这个仓用 GitHub raw 直链就能直接当源用。

```
写插件目录  →  tools/build.ps1 打 zip + 算 sha256 + 写 index.json  →  推上来  →  白泽里填 raw 直链
```

---

## 板块与分类

```
baize-plugins/
├── index.json                     生成物：货架（含 板块/阶段/分类 + sha256）
├── packages/<插件id>-<版本>.zip    生成物：插件包
├── official/                      官方板块
│   ├── stable/<分类>/<插件id>/      正式版
│   │   ├── plugin.json
│   │   └── skills/<技能slug>/SKILL.md
│   └── beta/<分类>/<插件id>/        测试版
├── community/                     社区板块（结构同 official：<阶段>/<分类>/<插件id>/）
└── tools/build.ps1                发布脚本（维护者跑；投稿者也能用它自查）
```

- **板块**：`official`（官方）/ `community`（社区）。
- **阶段**：`stable`（正式版）/ `beta`（测试版）。**官方板块必须分这两种**，社区也可以自己标。
- **分类**：板块内的分组，**目录名就是显示名**（中文即可，如 `调研写作`）。

**目录结构就是唯一事实来源**：阶段和分类由插件所在的目录决定，不用在 `plugin.json` 里再写一遍
（写重了反而会不一致）。插件 id 仍然是插件目录名，且只允许小写字母/数字/`-`/`.`/`_`。

现有的分类（尽量复用，别搞出两个意思一样的）：

| 分类 | 放什么 |
|---|---|
| `调研写作` | 查资料、写东西、整理成文 |
| `开发` | 代码、仓库、命令行相关的活 |
| `知识管理` | 笔记、星图、记忆 |
| `跨端设备` | 把活派到你的电脑/手机 |
| `自动化` | 定时任务、批量流程 |
| `生活` | 日程、清单、生活杂事 |
| `其他` | 实在归不进去的 |

## 在白泽里用它

**插件市场 → 插件源 → 添加**，地址填：

```
https://raw.githubusercontent.com/HDKL0802/baize-plugins/main/index.json
```

也可以用接口加：

```bash
curl -X POST http://<白泽后端>/api/agent/plugins -H 'Content-Type: application/json' \
  -d '{"action":"addSource","name":"白泽插件源","url":"https://raw.githubusercontent.com/HDKL0802/baize-plugins/main/index.json"}'
```

> 离线/内网也能用：地址填本机路径（如 `D:\baize-plugins\index.json`）同样有效。
> 白泽后端**自带一份内置官方源**（随二进制分发，离线可用），装不了网的时候也有官方插件可用。

---

## 投稿社区插件

1. Fork 本仓。
2. 新建 `community/<阶段>/<分类>/<插件id>/`，放入 `plugin.json` 与 `skills/<slug>/SKILL.md`。
3. 本地跑一次 `powershell -ExecutionPolicy Bypass -File tools\build.ps1` 自查（有问题会直接报错停下）。
4. 提 PR：**只提交你那个插件目录**；`index.json` 和 `packages/` 由维护者合并后统一重跑生成。

硬要求与注意事项见 [`community/README.md`](community/README.md)。

---

## 插件格式

### `plugin.json`

```json
{
  "schema": 1,
  "id": "my-plugin",
  "name": "我的插件",
  "version": "1.0.0",
  "description": "一句话说清这个插件是干什么的。",
  "author": "你的名字",
  "homepage": "https://github.com/你的账号/你的仓",
  "license": "MIT",
  "tags": ["工具"],
  "minBaize": "0.9.22",
  "mcp": [
    { "name": "my-mcp", "transport": "http", "url": "http://127.0.0.1:3000/mcp", "enabled": true }
  ]
}
```

| 字段 | 必填 | 说明 |
|---|---|---|
| `schema` | 是 | 格式版本，现在是 `1` |
| `id` | 是 | 插件 id，**必须与目录名一致** |
| `name` | 是 | 展示名（可中文） |
| `version` | 是 | 改了内容就**递增它**，白泽那边才会显示「有更新」 |
| `description` | 是 | 货架上一句话说明 |
| `author` / `homepage` / `license` / `minBaize` | 否 | 展示信息；`minBaize` 提示需要的最低白泽版本 |
| `tags` | 否 | 标签（展示用） |
| `mcp` | 否 | 要登记进白泽配置的 MCP 服务；**同名不覆盖**（用户已配过的会被跳过） |

**板块 / 阶段 / 分类不在 `plugin.json` 里**，它们由目录决定（见上文）。

### `SKILL.md`

```markdown
---
name: 展示名（可中文，界面与技能清单显示的就是它）
description: 一句话说清"什么时候该用我"，整行不超过 60 个字。
---

正文：照着做的步骤。每步都写到白泽**真实存在**的工具名上。
```

两条硬规矩：

1. **`description` 不超过 60 个字。** 它进的是白泽系统提示里的技能清单，超了会被截断 ——
   先写"触发场景"，别写成目录。
2. **工具名必须是真的。** 技能是给白泽照着做的，写错工具名等于这份技能是坏的。
   真实工具清单看白泽仓库 `agent/internal/tools/`（`Name()` 方法）与 `agent/internal/kb/tools.go`。
   例：`web_fetch` / `web_search` / `browser` / `fs_read` / `fs_write` / `file_search` / `note` /
   `memory` / `cron` / `cron_remove` / `device_list` / `device_run` / `skill_manage`。

一个插件可以带**多个技能**（`skills/` 下多个目录）；`references/`、`templates/`、`scripts/`、`assets/`
是约定的支持文件目录，会跟着技能一起装到用户机器上。

---

## 维护（本仓维护者）

### 发布 / 更新

```powershell
powershell -ExecutionPolicy Bypass -File tools\build.ps1
```

脚本会先把每个插件**校验一遍**（id 与目录名一致、必要字段齐、每个技能有 `SKILL.md` 且 front-matter 含
name/description、zip 根目录有 `plugin.json`），再打 `packages/<id>-<版本>.zip`、算 sha256 与大小、
汇总写 `index.json`。**任一处不对直接报错停下**，绝不产出一个坏源。

然后提交 `index.json` + `packages/`（**两者必须来自同一次构建**，别手改）。

### 官方板块怎么同步

白泽主仓里也有一份官方插件（`agent/internal/plugins/official/`，`go:embed` 随二进制走，保证离线可用）。
**两边目录结构完全一致**，所以同步就是原样拷贝：

```powershell
# 现在是手工一次（将来可以脚本化）
xcopy /E /I <白泽主仓>\agent\internal\plugins\official  official
powershell -ExecutionPolicy Bypass -File tools\build.ps1
```

这样内置版与在线版**永远出自同一份内容**，不会各自漂。

---

## 关于安全（白泽那边的口径）

- 源里给了 `sha256`（本脚本会写）就**逐字节校验**；没给就会在安装说明里**明说"没做完整性校验"**。
- 解包会挡 **zip slip**（`../`、绝对路径）、**符号链接**与**解压炸弹**。
- 包里声明的 `id` 与索引里登记的不一致 → **直接拒装**（防"货不对板"）。
- 与用户现有同名的技能 / MCP 服务 → **跳过**，并如实写进安装说明
  （**插件的优先级永远低于用户自己那摊**）。
- 卸载是**归档**（技能与原始包一起挪进 `plugins/_removed/`，能捞回来）；停用是把技能挪进
  `plugins/store/<id>/.off`（保留用户改动），启用再挪回来。

## 许可

本仓（脚本与官方插件）以 **MIT** 发布（见 `LICENSE`）。
社区插件各自的许可以它自己 `plugin.json` 的 `license` 为准。
