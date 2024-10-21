package types

import (
	"fmt"
	"strings"
	"time"
)

type Mark struct {
	Timestamp   time.Time
	Name        string
	Description string
}

func NewMark(name, description string) Mark {
	return Mark{
		Timestamp:   time.Now(),
		Name:        name,
		Description: description,
	}
}

func (m *Mark) AsStart() Mark {
	return m.withSuffix("start")
}

func (m *Mark) AsEnd() Mark {
	return m.withSuffix("end")
}

func (m *Mark) RemoveSuffix() Mark {
	mark := *m
	before, found := strings.CutSuffix(mark.Name, "-start")
	if found {
		mark.Name = before
		return mark
	}

	before, found = strings.CutSuffix(mark.Name, "-end")
	if found {
		mark.Name = before
	}

	return mark
}

func (m *Mark) withSuffix(suffix string) Mark {
	mark := *m
	mark.Name = fmt.Sprintf("%s-%s", m.Name, suffix)
	return mark
}