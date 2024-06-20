#!/bin/bash
#修改为自己的应用名称
appname=frpc
version=0.58.1


function build() {
#  echo '设置环境变量...'
#  go env -w GOPROXY=https://goproxy.cn,direct
#  go env -w GOSUMDB=off
#  go env
#  go version
#  go mod tidy
#  echo '开始编译GO程序...'
#  go build -ldflags "$ldflags" *.go
#  echo '工程编译完成'
#  ls -lh
  echo "开始构建镜像docker build...${{ServiceVersion}}"
  docker build --build-arg ARG_LDFLAGS="$ldflags" -t clife-devops-docker.pkg.coding.net/public-repository/{{DEPLOY_ENV}}/{{SERVICE_NAMES}}:{{ServiceVersion}} -f Dockerfile  .
  docker push clife-devops-docker.pkg.coding.net/public-repository/{{DEPLOY_ENV}}/{{SERVICE_NAMES}}:{{ServiceVersion}}
  echo '上传镜像到制品库完成!!!'
  ls -lh

}

function build_windows_amd64() {
  #goversioninfo -manifest versioninfo.json
  go generate
  CGO_ENABLED=0 GOOS=windows GOARCH=amd64 go build -trimpath -ldflags "-linkmode internal $ldflags" -o ${appname}_${version}_windows_amd64.exe
}


function build_windows_arm64() {
  #goversioninfo -manifest versioninfo.json
  #go generate
  CGO_ENABLED=0 GOOS=windows GOARCH=arm64 go build -trimpath -ldflags "-linkmode internal $ldflags" -o ${appname}_${version}_windows_arm64.exe
}


function menu() {
  echo -e "\r\n0. 编译 Windows amd64"
  echo "1. 编译 Windows arm64"
  echo "请输入编号:"
  read index
  case "$index" in
  [0]) (build_windows_amd64) ;;
  [1]) (build_windows_arm64) ;;
  *) echo "exit" ;;
  esac

  if ((index >= 4 && index <= 6)); then
    # 获取命令的退出状态码
    exit_status=$?
    # 检查退出状态码
    if [ $exit_status -eq 0 ]; then
      echo "成功推送Docker"
      echo $appversion >version.txt
    else
      echo "失败"
      echo "【$docker_push_result】"
    fi
  fi
}

function main() {
  if [ "$1" == "build" ]; then
    build
  else
    menu
    #build_windows_amd64
  fi
}
main $1
