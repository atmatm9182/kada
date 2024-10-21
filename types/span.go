package types

type Span struct {
	parent *Span
	start  Mark
	end    *Mark
	name   string
}

func NewSpan(parent *Span, start Mark, end *Mark) Span {
	return Span{
		parent: parent,
		start:  start,
		end:    end,
		name:   start.RemoveSuffix().Name,
	}
}