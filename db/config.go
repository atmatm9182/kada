package db

import "github.com/atmatm9182/kada/types"

type DiskDbConfig interface {
	EntryFileExt() string
	MarkEncoder() types.Encoder[types.Mark, []byte]
	MarkDecoder() types.Decoder[types.Mark, []byte]
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
