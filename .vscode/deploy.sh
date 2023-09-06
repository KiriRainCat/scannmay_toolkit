#* ----------------------------------- 变量定义 ----------------------------------- *#

# 定义颜色
ICE_BLUE="\e[96m"
RESET="\e[0m"

# Flutter 项目的构建命令
build_command="flutter build windows"

# 新的 Release 版本号
new_version=$(grep "version:" pubspec.yaml | awk '{print $2}')

# ISS 构建文件 文件路径
iss_file="./.vscode/raincat-toolkit.iss"

# ISS 工具工具 文件路径
compiler="D:/Code/Softwares/Inno Setup 6/ISCC.exe"

# 同步批量处理文件 文件路径
batch_run_file="./.vscode/BatchRun.ffs_batch"

# FreeFileSync.exe 文件路径
free_file_sync="D:/Program Files/FreeFileSync/FreeFileSync.exe"

#* --------------------------------- 检查同步处理文件 --------------------------------- *#

# 如果 同步批量处理文件 不存在，打开 FreeFileSync.exe
if [ ! -e "$batch_run_file" ]; then
    "$free_file_sync" &
    sleep 1
fi

# 等待创建 同步批量处理文件
while tasklist | grep -i "FreeFileSync.exe" > /dev/null || [ ! -e "$batch_run_file" ]; do
    echo -e "${ICE_BLUE}Waiting for file-syncing batch file to be created...${RESET}"
    sleep 5
done

# 如果说 FreeFileSync.exe 被关了，批量处理文件 还没被创建，直接终止脚本
if [ ! -e "$batch_run_file" ]; then
  exit
fi

#* ----------------------------------- 构建项目 ----------------------------------- *#

# 执行 Flutter 项目构建
$build_command

#* --------------------------------- 打包应用为安装包 --------------------------------- *#

# 修改安装包构建的版本号
sed -i "s/#define MyAppVersion .*/#define MyAppVersion \"$new_version\"/" $iss_file

# 构建安装包
"$compiler" $iss_file

#* ------------------------------ 修改 release.json ----------------------------- *#

# 修改 version.json 信息，将输入的文本保存到 log 变量中
echo -e "${ICE_BLUE}Enter the release log (press ENTER when done):${RESET}"

IFS= read -r -e log

json_content=$(cat <<EOF
[
  {
    "version": "$new_version",
    "log": "$log"
  }
]
EOF
)

# 将 JSON 对象插入到文件中的数组
release_file="./.vscode/out/release.json"
echo "$json_content" > temp.json

D:/Code/Softwares/CommandLine/jq.exe -s ".[0] += .[1] | .[0]" $release_file temp.json > release_temp.json

rm temp.json
mv release_temp.json $release_file

#* ----------------------------------- 执行同步 ----------------------------------- *#

# 运行 BatchRun.ffs_batch 文件
start "$batch_run_file" &
sleep 1

# 等待同步结束
while tasklist | grep -i "FreeFileSync.exe" > /dev/null; do
    echo -e "${ICE_BLUE}Waiting for file to sync...${RESET}"
    sleep 5
done

echo -e "${ICE_BLUE}Press enter to quit${RESET}"
read -p ""
