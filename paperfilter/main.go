package main

import (
	"flag"
	"fmt"
	"io/ioutil"
	"net"
	"os"
	"os/signal"
	"path"
	"strings"
	"syscall"
	"time"

	"gopkg.in/vmihailenco/msgpack.v2"

	"github.com/google/gopacket"
	"github.com/google/gopacket/pcap"
	"github.com/k0kubun/pp"
)

type InterfaceAddress struct {
	IP      net.IP     `msgpack:"ip"`
	Netmask net.IPMask `msgpack:"netmask"`
}

type Interface struct {
	Name        string             `msgpack:"name"`
	Description string             `msgpack:"description"`
	Addresses   []InterfaceAddress `msgpack:"addresses"`
	Link        uint16             `msgpack:"link"`
}

type Packet struct {
	Payload       []byte    `msgpack:"payload"`
	Timestamp     time.Time `msgpack:"timestamp"`
	CaptureLength int       `msgpack:"capture_length"`
	Length        int       `msgpack:"length"`
	Truncated     bool      `msgpack:"truncated"`
}

func main() {
	var snaplen = flag.Int("l", 1600, "snaplen")
	var promisc = flag.Bool("p", false, "promiscuous")
	var timeout = flag.Duration("t", -100*time.Millisecond, "timeout")
	var readable = flag.Bool("h", false, "human-readable")
	var testdir = flag.String("s", "", "test-mode")
	flag.Parse()

	enc := msgpack.NewEncoder(os.Stdout)

	if flag.NArg() > 0 {
		args := flag.Args()
		command := args[0]
		switch command {
		case "testcap":
			testcap()
		case "setcap":
			setcap()
		case "list":
			if len(*testdir) > 0 {
				b, err := ioutil.ReadFile(path.Join(*testdir, "list.msgpack"))
				if err != nil {
					fmt.Println(err)
					os.Exit(1)
				}
				list := []Interface{}
				err = msgpack.Unmarshal(b, &list)
				if err != nil {
					fmt.Println(err)
					os.Exit(1)
				}
				if *readable {
					pp.Println(list)
				} else {
					enc.Encode(list)
				}
				os.Exit(0)
			}
			ifs, err := pcap.FindAllDevs()
			if err != nil {
				fmt.Println(err)
				os.Exit(1)
			} else {
				list := []Interface{}
				for _, i := range ifs {
					handle, err := pcap.OpenLive(i.Name, int32(*snaplen), *promisc, *timeout)
					if err != nil {
						continue
					}
					defer handle.Close()
					c := Interface{
						Name:        i.Name,
						Description: i.Description,
						Link:        uint16(handle.LinkType()),
					}
					for _, addr := range i.Addresses {
						c.Addresses = append(c.Addresses, InterfaceAddress{
							IP:      addr.IP,
							Netmask: addr.Netmask,
						})
					}
					list = append(list, c)
				}
				if *readable {
					pp.Println(list)
				} else {
					enc.Encode(list)
				}
				os.Exit(0)
			}
		case "capture":
			if len(args) < 2 {
				fmt.Println("interface required")
				os.Exit(1)
			}

			if len(*testdir) > 0 {
				for i := 0; ; i++ {
					b, err := ioutil.ReadFile(path.Join(*testdir, fmt.Sprintf("packet%03d.msgpack", i)))
					if err != nil {
						break
					}
					p := Packet{}
					err = msgpack.Unmarshal(b, &p)
					if err != nil {
						fmt.Println(err)
						os.Exit(1)
					}
					if *readable {
						pp.Println(p)
					} else {
						enc.Encode(p)
					}
				}
				os.Exit(0)
			}

			handle, err := pcap.OpenLive(args[1], int32(*snaplen), *promisc, *timeout)

			if err != nil {
				fmt.Println(err)
				os.Exit(1)
			}
			defer handle.Close()

			if err := handle.SetBPFFilter(strings.Join(args[2:], " ")); err != nil {
				fmt.Println(err)
				os.Exit(1)
			}

			packetSource := gopacket.NewPacketSource(handle, handle.LinkType())
			sigchan := make(chan os.Signal, 1)
			signal.Notify(sigchan, syscall.SIGHUP, syscall.SIGINT, syscall.SIGTERM, syscall.SIGQUIT)
			for {
				select {
				case packet := <-packetSource.Packets():
					p := Packet{Payload: packet.Data()}
					if meta := packet.Metadata(); meta != nil {
						p.Timestamp = meta.Timestamp
						p.CaptureLength = meta.CaptureLength
						p.Length = meta.Length
						p.Truncated = meta.Truncated
					}
					if *readable {
						pp.Println(p)
					} else {
						enc.Encode(p)
					}
				case <-sigchan:
					os.Exit(0)
				}
			}
		}
	}
}
