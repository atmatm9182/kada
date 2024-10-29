package cmd

import (
	"errors"
	"flag"
	"fmt"
	"time"

	"github.com/atmatm9182/kada/db"
	"github.com/atmatm9182/kada/types"
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
	args := s.flagSet.Args()
	if len(args) == 0 {
		return s.listSpans()
	}

	switch args[0] {
	case "list":
		return s.listSpans()
	case "remove":
		args := args[1:]
		if len(args) == 0 {
			return errors.New("not enough arguments for subcommand 'remove' of 'span'")
		}

		if err := s.db.DeleteSpan(args[0]); err != nil {
			return err
		}

		fmt.Printf("Sucessfully deleted span '%s'\n", args[0])
		return nil
	case "add":
		args = args[1:]
		if len(args) < 3 {
			return errors.New("not enough arguments for subcommand 'add' of 'span'")
		}

		start := types.NewMark(args[0], "")
		ts, err := time.ParseInLocation(time.DateTime, args[1], time.Local)
		if err != nil {
			return err
		}
		start.Timestamp = ts

		end := types.NewMark(args[0], "")
		ts, err = time.ParseInLocation(time.DateTime, args[2], time.Local)
		if err != nil {
			return err
		}
		end.Timestamp = ts

		span := types.NewSpan(nil, &start, &end)
		return s.db.CreateSpan(&span)
	default:
		return nil
	}
}

func (s *spanCommand) listSpans() error {
	spans, err := s.db.GetAllSpans()
	if err != nil {
		return err
	}

	for _, span := range spans {
		fmt.Printf("%v\n", span)
	}
	return nil
}
