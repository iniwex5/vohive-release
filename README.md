# VoHive Release

公开分发仓库：提供二进制发布资产、安装脚本和运维文档。

## 一键安装

```bash
curl -fsSL https://raw.githubusercontent.com/iniwex5/vohive-release/main/install.sh | bash
```

指定版本：

```bash
curl -fsSL https://raw.githubusercontent.com/iniwex5/vohive-release/main/install.sh | bash -s -- --version v1.0.0
```

仅安装二进制（不安装 systemd）：

```bash
curl -fsSL https://raw.githubusercontent.com/iniwex5/vohive-release/main/install.sh | bash -s -- --no-systemd
```

卸载：

```bash
curl -fsSL https://raw.githubusercontent.com/iniwex5/vohive-release/main/uninstall.sh | bash
```

## 目录

- `install.sh`：安装/升级脚本
- `uninstall.sh`：卸载脚本
- `versions.json`：`stable/latest` 版本索引
- `systemd/vohive.service`：默认服务模板
- `docs/`：快速开始、升级、回滚、安全说明

## 默认安装目录（便携部署）

- 二进制：`/opt/vohive/bin/vohive`
- 配置：`/opt/vohive/config/config.yaml`
- 数据：`/opt/vohive/data`
- 日志目录：`/opt/vohive/logs`

## 资产命名

发布资产统一为：

- `vohive_<version>_linux_amd64.tar.gz`
- `vohive_<version>_linux_arm64.tar.gz`
