# Git 自动提交与推送

在终端运行：

```bash
# 先预览变更和推送目标
./scripts/git-auto-push.sh --dry-run

# 自动生成带时间的提交说明，并推送
./scripts/git-auto-push.sh

# 自定义提交说明
./scripts/git-auto-push.sh -m "docs: 更新笔记"
```

脚本定位到自身所在仓库，因此可以通过绝对路径从其他目录调用。需要已安装 Git，并已配置提交身份和远程仓库的推送凭据。

默认使用 `git add --all` 提交全部变更，包括已暂存内容、新文件和删除的文件；遵守 `.gitignore`。本仓库已跟踪的 `.obsidian/workspace.json` 有变化时也会提交。

已有 upstream 时推送到该远程分支；没有 upstream 时使用 `origin`，首次推送设置同名分支的 upstream。没有文件变更时仍会推送已有提交。

遇到冲突、未完成的合并/rebase 或 detached HEAD 会停止。提交失败时停止推送；推送失败时保留本地提交并返回非零退出码。远程分支有新提交导致拒绝推送时，需要自行同步和处理冲突，再重新运行。

此脚本每次调用执行一次。如需周期执行，可由系统定时任务调用脚本的绝对路径。
