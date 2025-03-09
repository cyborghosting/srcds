package main

import (
	"bytes"
	"log"
	"os"
	"path/filepath"
	"strconv"

	"github.com/rumblefrog/go-a2s"
	"golang.org/x/sys/unix"
)

func main() {
	port, ok := os.LookupEnv("SRCDS_PORT")
	if !ok {
		log.Print("environment variable 'SRCDS_PORT' not specified")
		os.Exit(0)
	}

	path, ok := os.LookupEnv("SRCDS_PID_FILE")
	if !ok {
		log.Print("environment variable 'SRCDS_PID_FILE' not specified")
		os.Exit(0)
	}

	pid, _ := readPIDFile(path)
	if pid == 0 {
		log.Print("srcds not running")
		os.Exit(0)
	}

	hostname, err := os.Hostname()
	if err != nil {
		log.Print("failed to resolve hostname:", err.Error())
		os.Exit(0)
	}

	client, err := a2s.NewClient(hostname + ":" + port)
	if err != nil {
		log.Print("failed to create udp connection:", err.Error())
		os.Exit(0)
	}

	info, err := client.QueryInfo()
	if err != nil {
		log.Print("failed to query:", err.Error())
		os.Exit(1)
	}

	log.Printf("GAME: %s, HOSTNAME: %s, MAP: %s, PLAYERS: %d/%d", info.Game, info.Name, info.Map, info.Players, info.MaxPlayers)
	os.Exit(0)
}

func readPIDFile(path string) (pid int, err error) {
	pidByte, err := os.ReadFile(path)
	if err != nil {
		return 0, err
	}
	pid, err = strconv.Atoi(string(bytes.TrimSpace(pidByte)))
	if err != nil {
		return 0, nil
	}
	if pid != 0 && alivePID(pid) {
		return pid, nil
	}
	return 0, nil
}

func alivePID(pid int) bool {
	if pid < 1 {
		return false
	}
	err := unix.Kill(pid, 0)
	if err == nil || err == unix.EPERM {
		return true
	}
	_, err = os.Stat(filepath.Join("/proc", strconv.Itoa(pid)))
	return err == nil
}
