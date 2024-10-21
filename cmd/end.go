package cmd

import (
	"errors"
	"flag"

	"github.com/atmatm9182/kada/db"
	"github.com/atmatm9182/kada/types"
)

type endCmd struct {
	flagSet *flag.FlagSet
	db      db.Db
}

func newEndCmd(db db.Db) command {
	flagSet := flag.NewFlagSet("start", flag.ExitOnError)

	return &endCmd{flagSet: flagSet, db: db}
}

func (e *endCmd) FlagSet() *flag.FlagSet {
	return e.flagSet
}

func (e *endCmd) Exec() error {
	args := e.flagSet.Args()
	if len(args) == 0 {
		e.flagSet.Usage()
		return errors.New("not enough arguments")
	}

	description := ""
	if len(args) > 1 {
		description = args[1]
	}

	markName := args[0]

	endMark := types.NewMark(markName, description)

	_, err := e.db.GetMark(endMark.AsStart().Name)
	if err != nil {
		return err
	}

	endMark = endMark.AsEnd()
	return e.db.CreateMark(&endMark)
}
