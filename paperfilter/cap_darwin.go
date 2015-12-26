package main

import (
	"io/ioutil"
	"os"
	"strings"

	"github.com/kardianos/osext"
)

func testcap() {
	dir, err := ioutil.ReadDir("/dev")
	if err != nil {
		os.Exit(1)
	}
	for _, info := range dir {
		if strings.HasPrefix(info.Name(), "bpf") {
			_, err := os.Open("/dev/" + info.Name())
			if err != nil && os.IsPermission(err) {
				os.Exit(1)
			}
		}
	}
	os.Exit(0)
}

func setcap() {
	filename, err := osext.Executable()
	if err != nil {
		panic(err)
	}
	err = os.Chown(filename, os.Geteuid(), os.Getgid())
	if err != nil {
		panic(err)
	}
	info, err := os.Stat(filename)
	if err != nil {
		panic(err)
	}
	err = os.Chmod(filename, info.Mode()|os.ModeSetuid|os.ModeSetgid)
	if err != nil {
		panic(err)
	}
	os.Exit(0)
}
