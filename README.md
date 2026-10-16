# iMusic

一个本地优先的 macOS 音乐播放器 MVP，支持导入 MP3、M4A、MP4 音频并显示同名歌词。

## 当前功能

- 拖拽或选择导入音乐文件、文件夹
- 支持 MP3、M4A、MP4
- 读取歌曲标题、歌手、专辑和时长
- 播放、暂停和进度拖动
- 循环列表自动播放下一首
- 单曲循环
- 搜索歌曲、收藏歌曲、最近播放
- 自动读取同目录同名的 `.lrc` 或 `.txt` 歌词
- LRC 当前行高亮和自动滚动
- 支持 macOS 深色模式

## 使用示例文件

可以导入：

```text
/Users/zsh/Music/下载/愛錯.mp4
```

如果存在同目录歌词，将其命名为：

```text
/Users/zsh/Music/下载/愛錯.lrc
```

应用不会复制、移动或删除原始音乐文件。

## 构建

需要 macOS 13 或更高版本，以及 Swift 6 工具链：

```bash
swift test
./scripts/build-app.sh
open build/iMusic.app
```

这是未签名的本地开发版本，首次打开时如果被 macOS 拦截，可以在“系统设置 → 隐私与安全性”中允许打开。
