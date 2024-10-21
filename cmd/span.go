package cmd

import (
	"flag"
	"fmt"
	"log"

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
	marks, err := s.db.GetAllMarks()
	if err != nil {
		return err
	}

	markMap := newMarkMap(marks)
	fmt.Printf("%v\n", markMap)
	spans := markMap.getSpans()
	for idx, span := range spans {
		fmt.Printf("[%d] %+v\n", idx, span)
	}
	return nil
}

type markMap struct {
	startMarks map[string]*types.Mark
	endMarks   map[string]*types.Mark
}

func newMarkMap(marks []*types.Mark) markMap {
	start := make(map[string]*types.Mark)
	end := make(map[string]*types.Mark)

	for _, mark := range marks {
		if mark.IsStart() {
			start[mark.RemoveSuffix().Name] = mark
		} else if mark.IsEnd() {
			end[mark.RemoveSuffix().Name] = mark
		} else {
			log.Fatalf("Mark with name '%s' is neither start nor end mark\n", mark.Name)
		}
	}

	return markMap{
		startMarks: start,
		endMarks:   end,
	}
}

func (m *markMap) getSpans() []types.Span {
	spans := make([]types.Span, 0, len(m.startMarks))

	for name, startMark := range m.startMarks {
		endMark := m.endMarks[name]
		span := types.NewSpan(nil, startMark, endMark)
		spans = append(spans, span)
	}

	return spans
}