# 社区插件（community）

第三方投稿的插件放这里。目录结构：

```
community/<阶段 stable|beta>/<分类>/<插件id>/
├── plugin.json
└── skills/<技能slug>/SKILL.md
```

例：`community/stable/写作/typo-checker/plugin.json`

## 怎么投

1. Fork 本仓，按上面的结构把你的插件放进去。
2. 本地先自查一遍（会校验清单字段与 SKILL.md front-matter，有问题会直接报错）：

   ```powershell
   powershell -ExecutionPolicy Bypass -File tools\build.ps1
   ```

3. 提 PR。**只需要提交 `community/` 下的插件目录**；
   `index.json` 与 `packages/` 由维护者合并后统一重跑生成，你不用管（也不用提交）。

## 几条硬要求（PR 会被按这个看）

- **只能带技能（SKILL.md）和 MCP 服务**，不许夹带可执行二进制；技能里出现的工具名**必须是白泽真实注册的工具**。
- `plugin.json` 的 `id` 要与目录名一致；`license` 必须写清（自己写的用 MIT 就行，转载别人的要符合对方许可）。
- 技能 `description` **不超过 60 个字**：它进的是白泽系统提示里的技能清单，超了会被截断。
- 技能 slug **不要和内置技能撞名**（`make-skill`、`file-reader`、`office-files`、`cron`、`note-taking`），
  撞了装上去会被"同名已存在"整个跳过。
- 插件里别做**偷偷联网上传 / 删用户文件**这类事。带 MCP 服务的话，远端地址要把用途写清楚 ——
  用户那侧还有 `allowRemote` 开关和审批闸门兜着，但别指望它们替你圆场。

细节看仓库根目录的 `README.md`。
