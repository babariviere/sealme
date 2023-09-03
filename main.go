package main

import (
	"fmt"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

func main() {
	entries, err := os.ReadDir("./")
	if err != nil {
		log.Fatal("unable to read current directory:", err)
	}

	for _, e := range entries {
		name := e.Name()
		ext := filepath.Ext(name)
		nameNoExt := name[0 : len(name)-len(ext)]
		if !strings.HasSuffix(nameNoExt, ".sealme") {
			continue
		}
		naked := nameNoExt[0 : len(nameNoExt)-len(".sealme")]

		out := naked + ext
		fmt.Println("sealing", name, "to", out)
		cmd := exec.Command("kubeseal", "-o", "yaml", "--controller-namespace=flux-system")

		inf, err := os.Open(name)
		if err != nil {
			log.Println("failed to open", name+":", err)
			continue
		}
		defer inf.Close()
		cmd.Stdin = inf

		outf, err := os.Create(out)
		if err != nil {
			log.Println("failed to create", name+":", err)
			continue
		}
		defer outf.Close()
		cmd.Stdout = outf

		if err = cmd.Run(); err != nil {
			log.Fatal(err)
		}
	}
}
