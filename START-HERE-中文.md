# Assignment Three：当前项目与提交步骤

项目已整合老师的完整源码、保留全部 `lib/`，并完成练习及书面答案。
最新的真实测试结果见 `docs/submission-checks.txt`，完成情况与限制见
`docs/completion-report.md`。请先阅读根目录 `README.md`。

正式 Tier 2（20%）仍需完成七个真实的 Sepolia 部署及 Etherscan 源码验证。
当前 README 的七行占位符不代表部署成功，Anvil 地址也不能代替 Sepolia 地址。
具体命令见 `docs/deployment-sepolia.md`。脚本使用公开 `DEPLOYER` 地址与
加密 keystore 或硬件钱包签名；不要向聊天、代码或 Git 提供私钥或助记词。
此工作没有广播任何 Sepolia 交易，广播前需要用户明确批准。

本地 Ex1 示例使用 Anvil unlocked accounts，无需读取私钥。
操作与实际输出见 `docs/local-walkthrough.md`。

用户说明 Moodle 延期至 2026 年 10 月 20 日 23:55；请以课程页面显示的时区
及最终提交状态为准。本环境没有正式评分 PDF，评分权重依据用户提供的任务说明。

1. 审阅 Pull Request、答案和架构图，不要未经批准合并。
2. 使用独立且有测试 ETH 的 Sepolia 钱包完成七个部署及验证。
3. 将真实地址、验证链接和真实截图写入 README 与 docs。
4. 重跑 `python3 scripts/capture-checks.py`、`python3 scripts/audit-submission.py`
   和 `python3 scripts/package-submission.py`。
5. 检查 ZIP：保留 lib，排除 Git 历史、缓存和钱包文件；上传 Moodle 并确认已提交。
