# IDEA 内置 Maven 位置

JetBrains IDE 捆绑的 Maven 安装路径。

## Windows

```
%LOCALAPPDATA%\Programs\IntelliJ IDEA\plugins\maven\lib\maven3\bin\mvn.cmd
%PROGRAMFILES%\JetBrains\IntelliJ IDEA*\plugins\maven\lib\maven3\bin\mvn.cmd
%LOCALAPPDATA%\JetBrains\Toolbox\apps\IDEA*\plugins\maven\lib\maven3\bin\mvn.cmd
%LOCALAPPDATA%\JetBrains\IntelliJIdea*\plugins\maven\lib\maven3\bin\mvn.cmd
%LOCALAPPDATA%\JetBrains\IntelliJIdea*\tmp\JetBrainsGateway\config\plugins\maven\lib\maven3\bin\mvn.cmd
D:\servers\IntelliJ IDEA*\plugins\maven\lib\maven3\bin\mvn.cmd
```

## macOS

```
/Applications/IntelliJ IDEA.app/Contents/plugins/maven/lib/maven3/bin/mvn
/Applications/IntelliJ IDEA CE.app/Contents/plugins/maven/lib/maven3/bin/mvn
~/Library/Caches/JetBrains/Toolbox/apps/IDEA*/plugins/maven/lib/maven3/bin/mvn
~/Library/Caches/JetBrains/IntelliJIdea*/plugins/maven/lib/maven3/bin/mvn
~/Library/Caches/JetBrains/IntelliJIdea*/tmp/JetBrainsGateway/config/plugins/maven/lib/maven3/bin/mvn
```

## Linux

```
/opt/idea/plugins/maven/lib/maven3/bin/mvn
~/.local/share/JetBrains/Toolbox/apps/IDEA*/plugins/maven/lib/maven3/bin/mvn
~/.cache/JetBrains/IntelliJIdea*/plugins/maven/lib/maven3/bin/mvn
~/.local/share/JetBrains/IntelliJIdea*/plugins/maven/lib/maven3/bin/mvn
```

---

**注意**：IDEA 版本号会影响路径，如 `IntelliJIdea2025.2`、`idea2024.3` 等。脚本使用通配符自动匹配各版本。