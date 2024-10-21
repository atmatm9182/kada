package types

import (
	"fmt"
	"time"
)

type Span struct {
	parent *Span // maybe change this to have a child pointer?
	start  Mark
	end    *Mark
	name   string
}

func NewSpan(parent *Span, start *Mark, end *Mark) Span {
	return Span{
		parent: parent,
		start:  *start,
		end:    end,
		name:   start.RemoveSuffix().Name,
	}
}

func (s *Span) String() string {
	year, month, day := localDate(s.start.Timestamp)
	hour, minute, second := localTime(s.start.Timestamp)

	endedAt := "and still going"

	if s.end != nil {
		year, month, day := localDate(s.end.Timestamp)
		hour, minute, second := localTime(s.end.Timestamp)
		endedAt = fmt.Sprintf(
			"and ended at %02d/%02d/%d %02d:%02d:%02d",
			year,
			month,
			day,
			hour,
			minute,
			second,
		)
	}

	return fmt.Sprintf(
		"%s: started at %02d/%02d/%d %02d:%02d:%02d %s",
		s.name,
		day,
		month,
		year,
		hour,
		minute,
		second,
		endedAt,
	)
}

func localDate(time time.Time) (int, time.Month, int) {
	local := time.Local()
	return local.Date()
}

func localTime(time time.Time) (int, int, int) {
	local := time.Local()
	return local.Hour(), local.Minute(), local.Second()
}
