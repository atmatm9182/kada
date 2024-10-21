package cmd

import (
	"flag"
	"fmt"

	"github.com/atmatm9182/kada/db"
)

type spanCommand struct {
	flagSet *flag.FlagSet
	db      db.Db
}

func newSpanCmd(db db.Db) command {
	return &spanCommand{
		flagSet: flag.NewFlagSet("span", flag.ExitOnError),
		db:      db,
	}
}

func (s *spanCommand) FlagSet() *flag.FlagSet {
	return s.flagSet
}

func (s *spanCommand) Exec() error {
	spans, err := s.db.GetAllSpans()
	if err != nil {
		return err
	}

	for _, span := range spans {
		fmt.Printf("%v\n", span)
	}
	return nil
}
