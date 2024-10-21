package main

import (
	"fmt"
	"os"

	"github.com/atmatm9182/kada/cmd"
)

func main() {
	if err := cmd.Exec(); err != nil {
		fmt.Fprintf(os.Stderr, "ERROR: %s\n", err)
	}
}
