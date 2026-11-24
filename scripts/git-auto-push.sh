#!/usr/bin/env bash
# 提交并推送脚本所在仓库；兼容 macOS 自带 Bash。
set -euo pipefail

usage() {
  cat <<'EOF'
用法：./scripts/git-auto-push.sh [-m "提交说明"] [--dry-run]

提交仓库全部变更（包括新增、修改、删除），然后 push 当前分支。
默认提交说明：chore: auto commit <本地时间>
已有 upstream 时推送到该目标，否则推送到 origin 的同名分支。
--dry-run 仅显示状态和推送目标，不暂存、不提交、不推送。
EOF
}

fail() { printf '错误：%s\n' "$*" >&2; exit 1; }
message=""
dry_run=false
while (($#)); do
  case "$1" in
    -m|--message)
      (($# >= 2)) || fail "$1 缺少提交说明"
      [[ -n "$2" ]] || fail "提交说明不能为空"
      message=$2
      shift 2
      ;;
    --dry-run) dry_run=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) fail "未知参数：$1（使用 --help 查看用法）" ;;
  esac
done

command -v git >/dev/null 2>&1 || fail "未安装 git"
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo=$(git -C "$script_dir/.." rev-parse --show-toplevel) || fail "脚本必须放在 Git 仓库的 scripts 目录中"
cd -- "$repo"
branch=$(git symbolic-ref --quiet --short HEAD) || fail "当前为 detached HEAD，请先切换到分支"

for marker in MERGE_HEAD CHERRY_PICK_HEAD REVERT_HEAD rebase-merge rebase-apply sequencer; do
  [[ ! -e "$(git rev-parse --git-path "$marker")" ]] || fail "存在未完成的合并、rebase 或拣选操作，请先处理"
done
[[ -z "$(git ls-files --unmerged)" ]] || fail "存在未解决的冲突"

remote=$(git config --get "branch.$branch.remote" || true)
target=$(git config --get "branch.$branch.merge" || true)
set_upstream=false
if [[ -z "$remote" || -z "$target" ]]; then
  remote=origin
  target="refs/heads/$branch"
  set_upstream=true
fi
[[ "$remote" != . ]] || fail "upstream 指向本地仓库，请配置远程 upstream"
git remote get-url --push "$remote" >/dev/null || fail "找不到远程仓库 $remote"
[[ "$target" == refs/heads/* ]] || fail "upstream 目标不是分支：$target"

[[ -n "$message" ]] || message="chore: auto commit $(date '+%Y-%m-%d %H:%M:%S')"
printf '仓库：%s\n分支：%s\n推送目标：%s/%s\n' "$repo" "$branch" "$remote" "${target#refs/heads/}"
if "$dry_run"; then
  git status --short
  printf '提交说明：%s\n预览结束，未修改仓库。\n' "$message"
  exit 0
fi

git add --all
if git diff --cached --quiet; then
  printf '没有需要提交的变更，继续推送已有提交。\n'
else
  git commit -m "$message"
fi

push_args=("$remote" "HEAD:$target")
if "$set_upstream"; then push_args=(--set-upstream "${push_args[@]}"); fi
if ! git push "${push_args[@]}"; then
  fail "push 失败，本地提交已保留。请处理认证、网络或远程分支更新后重新运行脚本"
fi
printf '提交与推送完成。\n'
