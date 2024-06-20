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

function build_linux_amd64() {
  CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags "$ldflags" -o ${appname}
}

function build_linux_arm64() {
  CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -ldflags "$ldflags" -o ${appname}
}

function build_darwin_arm64() {
  CGO_ENABLED=0 GOOS=darwin GOARCH=arm64 go build -ldflags "$ldflags" -o ${appname}
}

function build_images_to_tencent() {
  docker login ccr.ccs.tencentyun.com --username=100016471941 -p het002402
  docker build --build-arg ARG_LDFLAGS="$ldflags" -t ${appname} .
  docker tag ${appname}:${appversion} ccr.ccs.tencentyun.com/100016471941/${appname}:${appversion}
  docker buildx build --build-arg ARG_LDFLAGS="$ldflags" --platform linux/amd64,linux/arm64 -t ccr.ccs.tencentyun.com/100016471941/${appname}:${appversion} --push .
}

function build_images_to_hubdocker() {
  #这个地方登录一次就够了
  docker login -u xxl6097 -p het002402
  #docker login ghcr.io --username xxl6097 --password-stdin
  docker build --build-arg ARG_LDFLAGS="$ldflags" -t ${appname} .
  docker tag ${appname}:${appversion} xxl6097/${appname}:${appversion}
  docker buildx build --build-arg ARG_LDFLAGS="$ldflags" --platform linux/amd64,linux/arm64 -t xxl6097/${appname}:${appversion} --push .

  docker tag ${appname}:${appversion} xxl6097/${appname}:latest
  docker_push_result=$(docker buildx build --build-arg ARG_LDFLAGS="$ldflags" --platform linux/amd64,linux/arm64 -t xxl6097/${appname}:latest --push . 2>&1)
  echo "docker pull xxl6097/${appname}:${appversion}"
}

function build_images_to_conding() {
  docker login -u prdsl-1683373983040 -p ffd28ef40d69e45f4e919e6b109d5a98601e3acd clife-devops-docker.pkg.coding.net
  docker build --build-arg ARG_LDFLAGS="$ldflags" -t ${appname} .
  docker tag ${appname}:${appversion} clife-devops-docker.pkg.coding.net/public-repository/prdsl/${appname}:${appversion}
  docker_push_result=$(docker buildx build --build-arg ARG_LDFLAGS="$ldflags" --platform linux/amd64,linux/arm64 -t clife-devops-docker.pkg.coding.net/public-repository/prdsl/${appname}:${appversion} --push . 2>&1)
  echo "docker pull clife-devops-docker.pkg.coding.net/public-repository/prdsl/${appname}:${appversion}"
}

function gomodtidy() {
  go mod tidy
}

function check_docker_macos() {
  if ! docker info &>/dev/null; then
    echo "Docker 未启动，正在启动 Docker..."
    open --background -a Docker
    echo "Docker 已启动"
    sleep 10
    docker version
  else
    echo "Docker 已经在运行"
  fi
}

function check_docker_linux() {
  if ! docker info &>/dev/null; then
    echo "Docker 未启动，正在启动 Docker..."
    systemctl start docker
    echo "Docker 已启动"
    sleep 5
    docker version
  else
    echo "Docker 已经在运行"
  fi
}

function os_type() {
  os_name=$(uname -s)
  if [ "$os_name" = "Darwin" ]; then
    check_docker_macos
  elif [ "$os_name" = "Linux" ]; then
    check_docker_linux
  else
    echo "未知操作系统"
  fi
}

function menu() {
  echo -e "\r\n0. 编译 Windows amd64"
  echo "1. 编译 Linux amd64"
  echo "2. 编译 Linux arm64"
  echo "3. 编译 MacOS"
  echo "4. 打包多平台镜像->DockerHub"
  echo "5. 打包多平台镜像->Coding"
  echo "6. 打包多平台镜像->Tencent"
  echo "7. go mod tidy"
  echo "请输入编号:"
  read index
  case "$index" in
  [0]) (build_windows_amd64) ;;
  [1]) (build_linux_amd64) ;;
  [2]) (build_linux_arm64) ;;
  [3]) (build_darwin_arm64) ;;
  [4]) (build_images_to_hubdocker) ;;
  [5]) (build_images_to_conding) ;;
  [6]) (build_images_to_tencent) ;;
  [7]) (gomodtidy) ;;
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
    #menu
    build_windows_amd64
  fi
}
main $1
