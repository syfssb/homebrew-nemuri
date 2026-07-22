# homebrew-nemuri（tap 仓内容 + 创建 runbook）

本目录 = GitHub 上 tap 仓 `syfssb/homebrew-nemuri` 的内容。tap 仓只需要一个
`Casks/nemuri.rb`（Homebrew 约定：tap 名去掉 `homebrew-` 前缀即 `nemuri`）。
`Casks/nemuri.rb` 已按 v1.0.0 回填并本地核对完毕，可直接推。

## 已锁死的事实（改 DMG 必同步改 cask）

- **version**：`1.0.0`（== app bundle 的 `CFBundleShortVersionString`，dist DMG 内实测）
- **sha256**：`658b64f64f0427de0df13ebea4ba503ee69a2bd3927218d0a685054f30c3fd0e`
  - 来自 `shasum -a 256 dist/Nemuri-1.0.0.dmg`
  - 该 DMG 已 **Developer ID 签名（Yunfeng Sun C36DGH2H9S）+ 公证 + stapler 装订**
    （`spctl -a`：Notarized Developer ID；`xcrun stapler validate` 通过），字节已定稿。
- **url**：`https://github.com/syfssb/nemuri/releases/download/v1.0.0/Nemuri-1.0.0.dmg`

> 铁律：GitHub release 必须上传【与 `dist/Nemuri-1.0.0.dmg` 完全相同的那一份】。
> 公证票已装订、字节不会再变，所以现在的 sha256 就是最终值——**不要重新构建 DMG**，
> 重构建会改 sha256，`brew install --cask` 下载后校验失配直接报错。

## 创建并 push tap 仓（人工按此执行，前置：`gh auth status` 已登录）

```bash
set -euo pipefail
DMG=/Users/sunyunfeng/Desktop/agnetawake/dist/Nemuri-1.0.0.dmg   # 换成本机实际路径
CASK=/Users/sunyunfeng/Desktop/agnetawake/docs/release/homebrew-nemuri/Casks/nemuri.rb

# --- 1) 先把主仓转公开 + 发 release 上传那一份 DMG（cask 的 url/sha256 依赖它） ---
#     syfssb/nemuri 已 public；若未 public 需先 `gh repo edit syfssb/nemuri --visibility public`
gh release create v1.0.0 "$DMG" \
  --repo syfssb/nemuri \
  --title "Nemuri 1.0.0" \
  --notes "First public build. Close the lid, your AI agents keep working."

# --- 2) 校验线上资源 sha256 与 cask 完全一致（不一致就别建 tap，先查 DMG） ---
online=$(curl -fsSL https://github.com/syfssb/nemuri/releases/download/v1.0.0/Nemuri-1.0.0.dmg | shasum -a 256 | awk '{print $1}')
echo "online=$online"
test "$online" = "658b64f64f0427de0df13ebea4ba503ee69a2bd3927218d0a685054f30c3fd0e" \
  && echo "sha256 OK" || { echo "sha256 MISMATCH，停"; exit 1; }

# --- 3) 建同名公开 tap 仓，只放 Casks/nemuri.rb ---
gh repo create syfssb/homebrew-nemuri --public \
  -d "Homebrew tap for Nemuri — close the lid, your AI agents keep working"
work=$(mktemp -d)
git -C "$work" init -q
mkdir -p "$work/Casks"
cp "$CASK" "$work/Casks/nemuri.rb"
ruby -c "$work/Casks/nemuri.rb"                      # 语法自检
git -C "$work" add Casks/nemuri.rb
git -C "$work" commit -q -m "feat: nemuri cask v1.0.0"
git -C "$work" branch -M main
git -C "$work" remote add origin https://github.com/syfssb/homebrew-nemuri.git
git -C "$work" push -u origin main

# --- 4) 端到端验一次（可选，会真的装到本机） ---
brew install --cask syfssb/nemuri/nemuri
```

## 用户安装方式

```bash
brew install --cask syfssb/nemuri/nemuri
```

（`brew install --cask <user>/<repo 去 homebrew- 前缀>/<cask 名>` 会自动 `brew tap`。）
升级由 app 内置 Sparkle 完成（cask 标了 `auto_updates true`，`brew upgrade` 默认跳过，
不会和 Sparkle 打架）。

## 发布新版本时（tap 无需审核，push 即生效）

1. 构建 → 签名 → 公证 → **stapler 装订** DMG，`shasum -a 256 Nemuri-<版本>.dmg` 记下值
2. `gh release create v<版本> Nemuri-<版本>.dmg --repo syfssb/nemuri ...`（上传那一份）
3. tap 仓 `Casks/nemuri.rb` 改 `version` 与 `sha256`（务必是上传那一份的 hash），
   `ruby -c` 过后 commit push
4. `brew update && brew upgrade --cask nemuri`（或用户端等 Sparkle 自更新）

## 迁入官方 homebrew-cask 的条件（以后有量再说）

官方仓 `brew audit --new-cask` 有 notability 门槛：GitHub 仓库需要
**>75 stars，或 >30 forks，或 >30 watchers**（以当时官方文档为准）。
达标后按官方流程向 Homebrew/homebrew-cask 提 PR，合并后用户可直接
`brew install --cask nemuri`，届时本 tap 仓归档并在 README 指路官方源。
在那之前，自有 tap 是零门槛且完全够用的头号渠道（PLAN §8）。
