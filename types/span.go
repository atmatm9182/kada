package types

import (
	"crypto/sha256"
	"encoding/base64"
	"fmt"
	"time"
)

type Span struct {
	parent *Span // maybe change this to have a child pointer?
	Start  Mark
	End    *Mark
	Name   string
}

func NewSpan(parent *Span, start *Mark, end *Mark) Span {
	return Span{
		parent: parent,
		Start:  *start,
		End:    end,
		Name:   start.RemoveSuffix().Name,
	}
}

// does this need to return an error?...
func (s *Span) NameWithTimestampHash() (string, error) {
	data, err := s.Start.Timestamp.MarshalBinary()
	if err != nil {
		return "", err
	}

	hash := sha256.Sum256(data)
	hashString := base64.StdEncoding.EncodeToString(hash[:])
	return s.Name + hashString, nil
}

func (s *Span) String() string {
	year, month, day := localDate(s.Start.Timestamp)
	hour, minute, second := localTime(s.Start.Timestamp)

	endedAt := "and still going"

	if s.End != nil {
		year, month, day := localDate(s.End.Timestamp)
		hour, minute, second := localTime(s.End.Timestamp)
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
		s.Name,
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
