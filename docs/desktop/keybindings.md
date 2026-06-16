# Niri + DMS Keybindings

Niri compositor 和 DankMaterialShell 综合后的完整快捷键表。
Nix 模块系统通过 attrset merge 自动合并，无 key 冲突。

## Niri 基础 (shell-agnostic)

### 窗口控制

| 快捷键 | 动作 |
|---|---|
| `Mod+Q` | 关闭窗口 |
| `Mod+T` | 切换浮动 |
| `Mod+G` | 切换浮动/平铺焦点 |

### 列宽 / 全屏

| 快捷键 | 动作 |
|---|---|
| `Mod+F` | 最大化列 |
| `Mod+Shift+F` | 全屏窗口 |
| `Mod+C` | 居中列 |
| `Mod+R` | 切换预设列宽 |
| `Mod+E` | 反向切换预设列宽 |
| `Mod+Shift+T` | 切换 Tabbed 显示 |

### 焦点移动 (Vim 风格)

| 快捷键 | 动作 |
|---|---|
| `Mod+H` | 左 / 跨显示器 |
| `Mod+J` | 下 / 跨工作区 |
| `Mod+K` | 上 / 跨工作区 |
| `Mod+L` | 右 / 跨显示器 |

### 移动窗口 / 列

| 快捷键 | 动作 |
|---|---|
| `Mod+Shift+H` | 左移 / 跨显示器 |
| `Mod+Shift+J` | 下移 |
| `Mod+Shift+K` | 上移 |
| `Mod+Shift+L` | 右移 / 跨显示器 |

### 鼠标滚轮

| 快捷键 | 动作 |
|---|---|
| `Mod+滚轮↓` | 右移焦点列 |
| `Mod+滚轮↑` | 左移焦点列 |

### 工作区

| 快捷键 | 动作 |
|---|---|
| `Mod+1` ~ `Mod+9` | 切换工作区 1-9 |
| `Mod+Shift+1` ~ `Mod+Shift+9` | 移动列到工作区 1-9 |

### 概览 / 应用启动

| 快捷键 | 动作 |
|---|---|
| `Mod+W` | 切换概览 |
| `Mod+O` | 显示快捷键覆盖层 |
| `Mod+Return` | 启动终端 (`$TERMINAL`) |
| `Mod+B` | 启动浏览器 (`$BROWSER`) |

### 截图

| 快捷键 | 动作 |
|---|---|
| `Print` | 截图 |
| `Mod+Print` | 截全屏 |
| `Shift+Print` | 截窗口 |

### 退出

| 快捷键 | 动作 |
|---|---|
| `Ctrl+Alt+Delete` | 退出 niri |

---

## DMS 新增

| 快捷键 | 动作 |
|---|---|
| `Mod+Space` | 启动器 (Spotlight) |
| `Mod+N` | 通知面板 |
| `Mod+Comma` | 设置面板 |
| `Mod+P` | 记事本 |
| `Mod+V` | 剪贴板管理器 |
| `Mod+X` | 电源菜单 |
| `Mod+M` | 进程列表 |
| `Super+Alt+L` | 锁屏 |
| `Mod+Alt+N` | 夜间模式 |

### 硬件键

| 快捷键 | 动作 |
|---|---|
| `XF86AudioRaiseVolume` | 音量增 |
| `XF86AudioLowerVolume` | 音量减 |
| `XF86AudioMute` | 静音 |
| `XF86AudioMicMute` | 麦克风静音 |
| `XF86MonBrightnessUp` | 亮度增 |
| `XF86MonBrightnessDown` | 亮度减 |

---

## 源文件

- Niri 基础 binds: `modules/desktop/compositor/niri.nix`
- DMS binds: `modules/desktop/shell/dms.nix` (由上游 `enableKeybinds = true` 注入)
