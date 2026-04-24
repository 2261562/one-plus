# OnePlus ACE 3V 自编译内核

使用 GitHub Actions 自动编译 OnePlus ACE 3V (SM7675 / Snapdragon 7+ Gen 3) 内核。

## 📱 设备信息

| 参数 | 值 |
|------|------|
| 设备 | OnePlus ACE 3V |
| SoC | Qualcomm Snapdragon 7+ Gen 3 (SM7675) |
| 处理器代号 | pineapple |
| 内核源码 | [OnePlusOSS/android_kernel_oneplus_sm7675](https://github.com/OnePlusOSS/android_kernel_oneplus_sm7675) |
| Manifest | [OnePlusOSS/kernel_manifest](https://github.com/OnePlusOSS/kernel_manifest/tree/oneplus/sm7675) |

## 🚀 使用方法

### 1. 创建仓库

使用本仓库作为模板创建你自己的 GitHub 仓库，或者 Fork 本仓库。

### 2. 运行 Action

1. 进入仓库的 **Actions** 页面
2. 左侧选择 **Build OnePlus ACE 3V Kernel**
3. 点击 **Run workflow**
4. 根据需要配置选项（见下方参数说明），然后运行

### 3. 下载产物

编译完成（约 1.5~2.5 小时）后，在 Actions 运行记录的 **Artifacts** 中下载 `AnyKernel3_ACE3V_KSU-*` 压缩包。

### 4. 刷入内核

- **方法一（推荐）**: 使用 [Kernel Flasher](https://github.com/capntrips/KernelFlasher) App 直接刷入 AnyKernel3 ZIP
- **方法二**: 通过 TWRP Recovery 刷入 AnyKernel3 ZIP
- **方法三**: 解压 ZIP，使用 `fastboot flash boot Image` 手动刷入

> ⚠️ **刷入前请务必备份原始 boot 分区！**

## ⚙️ 构建参数说明

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `MANIFEST_BRANCH` | `sm7675` | SoC 平台分支 |
| `MANIFEST_XML` | `oneplus_ace_3v_b` | 设备 Manifest（`_b` = ColorOS 16, `_v` = ColorOS 15） |
| `CPUD` | `pineapple` | 处理器代号（通常无需修改） |
| `ANDROID_VERSION` | `android14` | Android 版本标识（用于补丁匹配） |
| `KERNEL_VERSION` | `6.1` | 内核版本号 |
| `KERNELSU_ENABLED` | `true` | 是否集成 KernelSU Next |
| `KERNELSU_BRANCH` | `next` | KernelSU Next 分支 |
| `APPLY_CUSTOM_PATCHES` | `false` | 是否应用 `patches/` 目录中的自定义补丁 |
| `APPLY_CUSTOM_DEFCONFIG` | `false` | 是否应用 `config/custom_defconfig.fragment` |
| `ENABLE_DOCKER` | `true` | 是否开启 Docker/容器 内核支持 |

## 📂 项目结构

```
.
├── .github/
│   └── workflows/
│       └── build-kernel.yml       # GitHub Actions 主工作流
├── config/
│   ├── docker_defconfig.fragment  # 旧版 Docker fragment（已弃用）
│   └── custom_defconfig.fragment  # 自定义内核配置（模板）
├── scripts/
│   └── enable_docker.sh           # Docker 配置注入脚本
├── patches/
│   └── README.md                  # 自定义补丁说明
└── README.md                      # 本文件
```

## 🐳 Docker 支持

本项目的 Docker 开关现在会执行 `scripts/enable_docker.sh`，直接修改源码树里的 `gki_defconfig`，而不是再走 `docker_defconfig.fragment`。

- **参考来源**: 方案吸收了你提供的“小米直注入 defconfig”思路
- **当前构建基线**: 实际使用的是源码树内的 `gki_defconfig`，不是仓库里的 `config/current_defconfig`
- **OnePlus 特化**: 保留 namespaces / cgroups / seccomp 等 Docker 核心能力，同时把最容易导致 GKI/KMI 问题的网络/存储驱动保持为 `=m`
- **风险规避**: 默认禁用 PPTP/H323/FTP/TFTP 等旧式 NAT helper，避免触发 KMI symbol protection
- **扩展方式**: 更激进的容器能力请放到 `config/custom_defconfig.fragment` 中逐项验证

使用步骤：
1. Action 构建时勾选 `开启 Docker/容器 支持`
2. 刷入编译好的内核
3. 参考相关教程在手机上安装 Docker 运行环境

> ⚠️ 这不是直接照搬其他机型的完整 Docker 配置。当前脚本是“参考后按 OnePlus 树收敛”的版本：会显式打开 Docker 需要的核心配置，但不会默认把 `BLK_CGROUP`、额外 cgroup 控制器、`AppArmor`、`Btrfs` 这类高风险项一起硬开，以降低再次 bootloop 的概率。

## 🔧 自定义补丁

将补丁文件放入 `patches/` 目录，按命名规则添加前缀：

| 前缀 | 应用目录 | 说明 |
|------|---------|------|
| `common_` | `kernel_platform/common/` | GKI 通用内核补丁 |
| `msm_` | `kernel_platform/msm-kernel/` | 高通 MSM 内核补丁 |
| `platform_` | `kernel_platform/` | 内核平台根目录补丁 |

详见 [patches/README.md](patches/README.md)。

## 📋 注意事项

1. **磁盘空间**: 编译过程需要大量磁盘空间，工作流已配置自动清理以最大化可用空间
2. **编译时间**: 完整编译通常需要 1.5~2.5 小时（GitHub Actions 免费额度）
3. **分支选择**: 请确保 `MANIFEST_XML` 与你手机的系统版本匹配
   - `oneplus_ace_3v_b` → ColorOS 16 (Android 16)
   - `oneplus_ace_3v_v` → ColorOS 15 (Android 15)
4. **KernelSU**: 集成 KernelSU 后需配合 [KernelSU Manager](https://github.com/rifsxd/KernelSU-Next) App 使用

## 🔗 参考资源

- [OnePlusOSS 内核源码](https://github.com/OnePlusOSS/android_kernel_oneplus_sm7675)
- [OnePlusOSS Kernel Manifest](https://github.com/OnePlusOSS/kernel_manifest/tree/oneplus/sm7675)
- [KernelSU Next](https://github.com/rifsxd/KernelSU-Next)
- [AnyKernel3](https://github.com/Kernel-SU/AnyKernel3)
- [Kernel Flasher](https://github.com/capntrips/KernelFlasher)

## 📜 License

本项目中的工作流脚本遵循 MIT 协议。内核源码遵循 GPLv2 协议。
