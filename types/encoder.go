package types

import "encoding/json"

type Encoder[T any, O any] interface {
	Encode(*T) (O, error)
}

type JsonEncoder[T any, O []byte] struct{}

func (JsonEncoder[T, O]) Encode(input *T) (res O, err error) {
	res, err = json.Marshal(input)
	return
}
