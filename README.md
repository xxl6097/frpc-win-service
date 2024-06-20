
go get -u github.com/fatedier/frp@v0.58.1

go get -u github.com/kardianos/service@v1.2.2

goversioninfo -manifest versioninfo.json

rsrc -manifest versioninfo.rc -o resource.syso

