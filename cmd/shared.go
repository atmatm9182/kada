package cmd

import "flag"

type command interface {
	FlagSet() *flag.FlagSet
	Exec() error
}
