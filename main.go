// Copyright 2015 Daniel Theophanes.
// Use of this source code is governed by a zlib-style
// license that can be found in the LICENSE file.

// simple does nothing except block while running the service.
//
//go:generate goversioninfo -icon=resource/icon.ico -manifest=resource/goversioninfo.exe.manifest
package main

import (
	"fmt"
	_ "github.com/fatedier/frp/assets/frpc"
	"github.com/fatedier/frp/cmd/frpc/sub"
	"github.com/fatedier/frp/pkg/util/system"
	"github.com/kardianos/service"
	"log"
	"os"
	"time"
)

var logger service.Logger

type program struct{}

func (p *program) Start(s service.Service) error {
	// Start should not block. Do the actual work async.
	go p.run()
	return nil
}
func (p *program) run() {
	// Do work here
	fmt.Println("run", time.Now().String())
	system.EnableCompatibilityMode()
	sub.Execute()
}
func (p *program) Stop(s service.Service) error {
	// Stop should not block. Return with a few seconds.
	fmt.Println("Stop", time.Now().String())
	os.Exit(1)
	return nil
}

func main() {
	svcConfig := &service.Config{
		Name:        "AAAFrpService",
		DisplayName: "AAAFrpService",
		Description: "一个专注于内网穿透的高性能的反向代理应用",
	}

	prg := &program{}
	s, err := service.New(prg, svcConfig)
	if err != nil {
		log.Fatal(err)
	}
	logger, err = s.Logger(nil)
	if err != nil {
		log.Fatal(err)
	}
	err = s.Run()
	if err != nil {
		logger.Error(err)
	}
}
