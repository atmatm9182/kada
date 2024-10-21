package db

import "github.com/atmatm9182/kada/types"

type DiskDbConfig interface {
	EntryFileExt() string
	MarkEncoder() types.Encoder[types.Mark, []byte]
	MarkDecoder() types.Decoder[types.Mark, []byte]
	SpanEncoder() types.Encoder[types.Span, []byte]
	SpanDecoder() types.Decoder[types.Span, []byte]
}

func NewJsonDiskDbConfig() DiskDbConfig {
	return jsonDiskDbConfig{}
}

type jsonDiskDbConfig struct{}

func (jsonDiskDbConfig) EntryFileExt() string {
	return "json"
}

func (jsonDiskDbConfig) MarkEncoder() types.Encoder[types.Mark, []byte] {
	return types.JsonEncoder[types.Mark, []byte]{}
}

func (jsonDiskDbConfig) MarkDecoder() types.Decoder[types.Mark, []byte] {
	return types.JsonDecoder[types.Mark, []byte]{}
}

func (jsonDiskDbConfig) SpanEncoder() types.Encoder[types.Span, []byte] {
	return types.JsonEncoder[types.Span, []byte]{}
}

func (jsonDiskDbConfig) SpanDecoder() types.Decoder[types.Span, []byte] {
	return types.JsonDecoder[types.Span, []byte]{}
}
