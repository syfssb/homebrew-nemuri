# Nemuri cask（M4 发布时复制进 tap 仓 syfssb/homebrew-nemuri 的 Casks/ 目录）。
# version / sha256 已回填并本地核对：
#   - version 1.0.0 == app bundle 的 CFBundleShortVersionString（dist/Nemuri-1.0.0.dmg 内实测）
#   - sha256 == `shasum -a 256 dist/Nemuri-1.0.0.dmg`，该 DMG 已 Developer ID 签名 +
#     公证 + stapler 装订（spctl: Notarized Developer ID / stapler validate 通过）。
# 铁律：GitHub release 必须上传【这一份完全相同的 dist/Nemuri-1.0.0.dmg】——不要重新构建。
# DMG 已装订公证票，字节已定稿，重构建会改变 sha256 导致 `brew install` 校验失败。
# 若确需换 DMG：重跑 `shasum -a 256` 并同步改本行。步骤见 docs/RELEASING.md。
cask "nemuri" do
  version "1.1.1"
  sha256 "3096c8f4b496f638e63c3f222cd1d88ec1ee2139107ad6ddf8b40fa0722d60b7"

  # 私有仓的 release 资源公众拉不到——发布前仓库必须转公开（PLAN §8 硬依赖）
  url "https://github.com/syfssb/nemuri/releases/download/v#{version}/Nemuri-#{version}.dmg"
  name "Nemuri"
  desc "Close the lid, your AI agents keep working - and your Mac sleeps when they're done"
  homepage "https://nemuri.app/"

  auto_updates true # Sparkle 自更新（cask 不负责升级，避免和 Sparkle 打架）
  depends_on macos: ">= :ventura" # LSMinimumSystemVersion 13.0（SMAppService 依赖）

  app "Nemuri.app"

  # 卸载：只 quit app（其退出兜底经 helper XPC 恢复休眠；即使 quit 失败，helper 的
  # 看门狗路径 1 也会在连接断开 15s 后恢复）。launchctl 绝不能放 uninstall：
  # brew 的 ORDERED_DIRECTIVES 固定 :launchctl 先于 :quit 执行（cask 里写的先后无效），
  # 若先杀 helper（无 SIGTERM 处理），quit 时 XPC 已死、看门狗也随 helper 死了，
  # Agent Mode 开启时卸载会让 disablesleep=1 永久残留（破坏硬性不变量 1）。
  uninstall quit: "app.nemuri.Nemuri"

  # helper 的 launchd 注销放 zap：zap 阶段在 uninstall 之后跑，届时 quit / 看门狗
  # 已恢复休眠，bootout 只是清理注册项
  zap launchctl: "app.nemuri.helper",
      trash: [
    # 用户级数据：hook 桥二进制、集成备份、license.json、socket、restore_failed 标记
    "~/Library/Application Support/Nemuri",
    "~/Library/Preferences/app.nemuri.Nemuri.plist",
    # 系统/Sparkle 按 bundle id 生成的用户级残留（手动「检查更新…」后才会出现）
    "~/Library/Caches/app.nemuri.Nemuri",
    "~/Library/HTTPStorages/app.nemuri.Nemuri",
    "~/Library/Saved Application State/app.nemuri.Nemuri.savedState",
  ]
  # 说明：/Library/Application Support/Nemuri（看门狗哨兵文件）是系统级（root）路径，
  # zap trash 没有权限清理；helper 的 launchd 注册项由上面的 zap launchctl 注销（sudo），
  # plist 本体在 app bundle 内（Contents/Library/LaunchDaemons/app.nemuri.helper.plist），
  # 随 app 删除。普通 uninstall（不带 --zap）会留下注册项，但 plist 已随 app 消失，
  # 下次开机 launchd 不会拉起任何东西，无害。
  # 需要彻底清理系统级残留时用仓库里的 scripts/uninstall.sh（sudo）。
  # 卸载时 disablesleep 的归零由 quit 时的退出兜底 / helper 看门狗完成（硬性不变量 1）。
end
