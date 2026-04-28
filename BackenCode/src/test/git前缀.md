* feat: 新功能（feature）
   1. 用于提交新功能。例如：feat: 增加用户注册功能
   2. fix: 修复 bug
</br>
* docs: 文档变更
  1. 用于提交仅文档相关的修改。例如：docs: 更新README文件
</br>
* style: 代码风格变动（不影响代码逻辑）
  1. 用于提交仅格式化、标点符号、空白等不影响代码运行的变更。例如：style: 删除多余的空行
</br>
* refactor: 代码重构（既不是新增功能也不是修复bug的代码更改）
  1. 用于提交代码重构。例如：refactor: 重构用户验证逻辑
</br>
* perf: 性能优化
  1. 用于提交提升性能的代码修改。例如：perf: 优化图片加载速度
</br>
* test: 添加或修改测试
  1. 用于提交测试相关的内容。例如：test: 增加用户模块的单元测试
</br>
* chore: 杂项（构建过程或辅助工具的变动）
  1. 用于提交构建过程、辅助工具等相关的内容修改。例如：chore: 更新依赖库
  2. 调整xxx函数的日志输出（不影响逻辑）
</br>
* build: 构建系统或外部依赖项的变更
  1. 用于提交影响构建系统的更改。例如：build: 升级webpack到版本5
</br>
* ci: 持续集成配置的变更
  1. 用于提交CI配置文件和脚本的修改。例如：ci: 修改GitHub Actions配置文件
</br>
* revert: 回滚
  1. 用于提交回滚之前的提交。例如：revert: 回滚feat: 增加用户注册功能 

    |类型|用法|
    | -------- | -------- |
    | feat     | 新功能      |
    | fix      | 修 bug    |
    | refactor | 重构（不改功能） |
    | chore    | 杂项       |

# 链接远程git仓库
git init
git remote add origin https://github.com/kciffe/agentTest.git

# 创建并切换分支
git switch -c dev
git push -u origin dev // -u 表示设置默认的远程分支,全称--set-upstream

# 查看远程分支
git branch -r

# 删除远程分支
git push origin --delete dev

# 删除本地分支
git branch -d dev

# merge
git fetch origin
get switch main
git merge origin/dev

# Tag
git switch main 
git push origin main  #注意 很重要
git tag -a v0.3 -m "Release v0.3" 
git push origin v0.3

# 切换对应Tag
git fetch --all --tags
git switch v0.31

# 查看Tags
git fetch --tags
git tag

# SSH
git remote set-url origin git@github.com:kciffe/agentTest.git
ssh -T git@github.com
git push


# 强制合并master到main
git fetch origin
git switch main
git reset --hard origin/main
git push -u origin main --force-with-lease




# Linux
nvidia-smi

lsof /dev/nvidia*
ps -fp 12345
kill -9 12345
