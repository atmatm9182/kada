package types

import "encoding/json"

type Decoder[T any, I any] interface {
	Decode(I) (*T, error)
}

type JsonDecoder[T any, I []byte] struct{}

func (JsonDecoder[T, I]) Decode(input I) (res *T, err error) {
	err = json.Unmarshal(input, &res)
	return
}
