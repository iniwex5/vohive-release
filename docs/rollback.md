# Rollback

1. 直接安装旧版本：

```bash
curl -fsSL https://raw.githubusercontent.com/iniwex5/vohive-release/master/install.sh | bash -s -- --version v1.2.2
```

2. 若升级失败且 `.bak` 存在，可手动恢复：

```bash
sudo cp /opt/vohive/bin/vohive.bak /opt/vohive/bin/vohive
sudo systemctl restart vohive
```
