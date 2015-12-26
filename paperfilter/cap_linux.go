package main

import (
	"fmt"
	"os"

	"github.com/kardianos/osext"
	"github.com/syndtr/gocapability/capability"
)

func testcap() {
	filename, err := osext.Executable()
	if err != nil {
		panic(err)
	}

	cap, err := capability.NewFile(filename)
	if err != nil {
		panic(err)
	}

	var ok = cap.Get(capability.EFFECTIVE, capability.CAP_NET_ADMIN) &&
		cap.Get(capability.PERMITTED, capability.CAP_NET_ADMIN) &&
		cap.Get(capability.INHERITABLE, capability.CAP_NET_ADMIN) &&
		cap.Get(capability.EFFECTIVE, capability.CAP_NET_RAW) &&
		cap.Get(capability.PERMITTED, capability.CAP_NET_RAW) &&
		cap.Get(capability.INHERITABLE, capability.CAP_NET_RAW)
	fmt.Println(cap)
	if ok {
		fmt.Println("ok")
		os.Exit(0)
	} else {
		fmt.Println("not enough capabilities")
		os.Exit(1)
	}
}

func setcap() {
	filename, err := osext.Executable()
	if err != nil {
		panic(err)
	}

	cap, err := capability.NewFile(filename)
	if err != nil {
		panic(err)
	}

	cap.Set(capability.EFFECTIVE, capability.CAP_NET_ADMIN, capability.CAP_NET_RAW)
	cap.Set(capability.PERMITTED, capability.CAP_NET_ADMIN, capability.CAP_NET_RAW)
	cap.Set(capability.INHERITABLE, capability.CAP_NET_ADMIN, capability.CAP_NET_RAW)
	err = cap.Apply(capability.EFFECTIVE | capability.PERMITTED | capability.INHERITABLE)
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	} else {
		fmt.Println("successfully set capabilities")
		os.Exit(0)
	}
}
