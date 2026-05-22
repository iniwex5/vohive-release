# VoHive Release

公开分发仓库：提供二进制发布资产、安装脚本和运维文档。

## 功能介绍

VoHive 是面向移远EC20 4G 模组场景的一体化管理与代理平台，核心能力包括：

- 网页/Bot收发短信
- 多卡统一管理
- 实体 ESIM/eUICC 管理（加卡，切卡，删卡）
- 轻量代理能力：支持 `SOCKS5/HTTP` 实例，按设备网卡强绑定出站。
- TelegramBot / 飞书Bot / QQBot  远程控制
- 在条件满足时启用 VoWiFi
- 通过 `/vocall` 发起 VoWiFi 模拟外呼

## 一、适用环境

### 硬件

推荐：

- EC20CEFAG
- EC20CEFHLG
- 可以小黄鱼几十块买到

要求：

- 设备具备 SIM 卡槽
- 或搭配带SIM卡槽的USB底板

### 系统

建议使用 Linux：

- Debian / Ubuntu
- 树莓派
- NAS

## 二、ModemManager 共存说明

VoHive 在 QMI 模式下会优先通过 `qmi-proxy` 打开控制口，可与系统 `ModemManager` 共用 QMI 通道。

注意：  
同时运行两个管理方时，不建议让两边同时管理拨号、APN 或数据连接。

## 三、可选：把模组切到更合适的 USBNET 模式

如果你确认模组当前模式不对，可以执行：

```bash
sudo apt update
sudo apt install -y socat

echo 'AT+QCFG="usbnet",0;+CFUN=1,1' | sudo socat - /dev/ttyUSB2,crnl
```

说明：

- `AT+QCFG="usbnet",0`：切到常见的 QMI 模式
- `AT+CFUN=1,1`：重启模组
- `/dev/ttyUSB2` 只是示例，实际 AT 口请按你的设备调整

## 四、部署方式一：一键安装

```bash
curl -fsSL https://raw.githubusercontent.com/iniwex5/vohive-release/master/install.sh | bash
```

指定版本：

```bash
curl -fsSL https://raw.githubusercontent.com/iniwex5/vohive-release/master/install.sh | bash -s -- --version v1.0.0
```

仅安装二进制（不安装 systemd）：

```bash
curl -fsSL https://raw.githubusercontent.com/iniwex5/vohive-release/master/install.sh | bash -s -- --no-systemd
```

卸载：

```bash
curl -fsSL https://raw.githubusercontent.com/iniwex5/vohive-release/master/uninstall.sh | bash
```


## 默认安装目录（便携部署）

- 二进制：`/opt/vohive/bin/vohive`
- 配置：`/opt/vohive/config/config.yaml`
- 数据：`/opt/vohive/data`
- 日志目录：`/opt/vohive/logs`


## 五、部署方式二：Docker / Docker Compose

### 1. 创建目录

```bash
mkdir -p vohive/{config,data,logs}
cd vohive
```

### 2. 创建配置文件

新建 `config/config.yaml`：

```yaml
server:
  port: 7575
  debug: false

web:
  username: admin
  password: admin123
```

### 3. 创建 `docker-compose.yml`

```yaml
services:
  vohive:
    image: iniwex/vohive:latest
    container_name: vohive
    restart: unless-stopped
    network_mode: host
    privileged: true
    volumes:
      - ./config:/app/config
      - ./data:/app/data
      - ./logs:/app/logs
    environment:
      - TZ=Asia/Shanghai
      - CONFIG_PATH=/app/config/config.yaml
    devices:
      - /dev:/dev
```

### 4. 启动

```bash
docker compose up -d
```


### 5. 访问后台

```text
http://你的服务器IP:7575
```
注意：

- Docker 部署下AT模式也要关闭宿主机 `ModemManager`
- 这里用了 `privileged`、`/dev` 透传和 `host network`，这是因为程序需要直接接管模组设备

## 六、机器人常用命令

- `/list`：查看设备列表
- `/sms 设备ID`：查看最近短信
- `/send 设备ID 号码 内容`：发送短信
- `/rotate 设备ID`：切换 IP
- `/esim 设备ID`：查看 eSIM profile
- `/switch 设备ID 序号或 ICCID`：切换 eSIM profile
- `/vocall 设备ID 号码`：发起 VoWiFi 模拟呼叫

## 七、补充说明

- VoWiFi 不是只要有网就一定能用，还取决于运营商、号码状态和网络环境要求
- 如果你的需求只是短信、代理池、多模组管理，不折腾 VoWiFi 也可以先用起来
- 本程序已禁止国内运营商卡发起VoWifi，请遵纪守法。
## 八、已知Vohive支持VoWifi的运营商

- CTE UK
- CMLINK UK
- giffgaff UK
- VOXI UK
- Vodafone UK
- 3UK

- Vodafone DE
- Telekom DE
- O2 DE

- T-Mobile US
- 未标出的不代表不兼容，只是我没有
### 程序截图

![image](https://cdn.nodeimage.com/i/rnGhjMfPlMatrdxQMPogawI3d5OGc1Fu.png)

![image](https://cdn.nodeimage.com/i/GGAj5ua1dK4vZihroXV0pUmT7COonPnQ.png)

![image](https://cdn.nodeimage.com/i/hX90MLQqjmgkaPkZt4Pz4uCM1lHmDBx4.png)

![image](https://cdn.nodeimage.com/i/jbbwBuP1Zu9iPpfZrSsXzftGo0et5i4F.png)

![image](https://cdn.nodeimage.com/i/P7BpZu8fF98622Q3VCZlafg4aBHVM8Qu.png)

![image](https://cdn.nodeimage.com/i/dZp8KPWC8VlQrD8RakdYJLL09IaXQAqQ.png)

![image](https://cdn.nodeimage.com/i/X5Ps5w9AHo1Qas6DDsnxYnbrfYcVhAfV.png)

### 发布频道：

https://t.me/vohive_channel

### 交流群：

https://t.me/vohive
