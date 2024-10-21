package cmd

import (
	"errors"
	"flag"

	"github.com/atmatm9182/kada/db"
	"github.com/atmatm9182/kada/types"
)

type startCmd struct {
	flagSet *flag.FlagSet
	db      db.Db
}

func newStartCmd(db db.Db) command {
	flagSet := flag.NewFlagSet("start", flag.ExitOnError)

	return &startCmd{flagSet: flagSet, db: db}
}

func (s *startCmd) FlagSet() *flag.FlagSet {
	return s.flagSet
}

func (s *startCmd) Exec() error {
	args := s.flagSet.Args()
	if len(args) == 0 {
		s.flagSet.Usage()
		return errors.New("not enough arguments")
	}

	description := ""
	if len(args) > 1 {
		description = args[1]
	}

	mark := types.NewMark(args[0], description)
	mark = mark.AsStart()
	err := s.db.CreateMark(&mark)
	if err != nil {
		return err
	}

	span := types.NewSpan(nil, &mark, nil)
	return s.db.CreateSpan(&span)
}
