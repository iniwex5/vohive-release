# Upgrade

指定版本升级：

```bash
curl -fsSL https://raw.githubusercontent.com/iniwex5/vohive-release/master/install.sh | bash -s -- --version v1.2.3
```

默认重复执行安装脚本即为升级语义，脚本会备份旧二进制到 `/opt/vohive/bin/vohive.bak`。
