# ============================================
# 自定义补丁目录
# ============================================
#
# 将你的自定义补丁文件放置在此目录中，
# 然后在 GitHub Actions 中勾选 "应用自定义补丁" 即可自动应用。
#
# ## 补丁命名规则
#
# 根据补丁应用的目标目录，使用不同的前缀：
#
# | 前缀         | 应用目录                        | 说明                 |
# |--------------|--------------------------------|----------------------|
# | `common_`    | `kernel_platform/common/`      | GKI 通用内核补丁      |
# | `msm_`       | `kernel_platform/msm-kernel/`  | 高通 MSM 内核补丁     |
# | `platform_`  | `kernel_platform/`             | 内核平台根目录补丁     |
#
# ## 补丁格式
#
# 补丁文件必须是标准的 unified diff 格式（`git diff` 或 `diff -u` 生成）。
#
# ## 示例
#
# ```
# patches/
# ├── common_001_enable_feature.patch      # 应用到 common 内核
# ├── msm_001_fix_driver.patch             # 应用到 msm-kernel
# └── platform_001_build_fix.patch         # 应用到 kernel_platform 根目录
# ```
#
# ## 生成补丁
#
# 在内核源码中修改代码后，使用以下命令生成补丁：
#
# ```bash
# # 在 kernel_platform/common/ 目录下
# git diff > common_001_my_change.patch
#
# # 或者对暂存区的修改
# git diff --cached > common_001_my_change.patch
# ```
