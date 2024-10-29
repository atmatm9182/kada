package db

import (
	"fmt"
	"os"
	"path"

	"github.com/atmatm9182/kada/types"
)

type Db interface {
	Setup() error

	CreateMark(m *types.Mark) error
	DeleteMark(name string) error
	GetMark(name string) (*types.Mark, error)
	GetAllMarks() ([]*types.Mark, error)

	CreateSpan(span *types.Span) error
	DeleteSpan(name string) error
	UpdateSpan(span *types.Span) error
	GetAllSpans() (map[string]*types.Span, error)
}

type DiskDb struct {
	storageDir   string
	markDir      string
	spanDir      string
	entryFileExt string
	markEncoder  types.Encoder[types.Mark, []byte]
	markDecoder  types.Decoder[types.Mark, []byte]
	spanEncoder  types.Encoder[types.Span, []byte]
	spanDecoder  types.Decoder[types.Span, []byte]
}

func NewDiskDb(dir string, config DiskDbConfig) *DiskDb {
	return &DiskDb{
		storageDir:   dir,
		markDir:      path.Join(dir, "marks"),
		spanDir:      path.Join(dir, "spans"),
		entryFileExt: config.EntryFileExt(),
		markEncoder:  config.MarkEncoder(),
		markDecoder:  config.MarkDecoder(),
		spanEncoder:  config.SpanEncoder(),
		spanDecoder:  config.SpanDecoder(),
	}
}

func (db *DiskDb) Setup() (err error) {
	err = os.MkdirAll(db.markDir, 0777)
	if err != nil {
		return
	}

	return os.MkdirAll(db.spanDir, 0777)
}

func (db *DiskDb) CreateMark(m *types.Mark) (err error) {
	err = db.createMarkEntry(m.Name)
	if err != nil {
		return
	}

	var encoded []byte
	encoded, err = db.markEncoder.Encode(m)
	if err != nil {
		return
	}

	markPath := db.markEntryPath(m.Name)
	return os.WriteFile(markPath, encoded, 0666)
}

func (db *DiskDb) DeleteMark(name string) error {
	entryPath := db.markEntryPath(name)

	if !fileExists(entryPath) {
		return fmt.Errorf("mark '%s' does not exist", name)
	}

	return os.Remove(entryPath)
}

func (db *DiskDb) GetMark(name string) (m *types.Mark, err error) {
	entryPath := db.markEntryPath(name)

	if !fileExists(entryPath) {
		err = fmt.Errorf("mark '%s' does not exist", name)
		return
	}

	var data []byte
	data, err = os.ReadFile(entryPath)
	if err != nil {
		return
	}

	return db.markDecoder.Decode(data)
}

func (db *DiskDb) GetAllMarks() (marks []*types.Mark, err error) {
	return decodeAllInDir(db.markDir, db.markDecoder)
}

func (db *DiskDb) CreateSpan(span *types.Span) error {
	name, err := span.NameWithTimestampHash()
	if err != nil {
		return err
	}

	entryPath := db.spanEntryPath(name)

	if fileExists(entryPath) {
		return fmt.Errorf("span '%s' already exists", span.Name)
	}

	var data []byte
	data, err = db.spanEncoder.Encode(span)
	if err != nil {
		return err
	}

	return os.WriteFile(entryPath, data, 0666)
}

func (db *DiskDb) DeleteSpan(name string) error {
	spans, err := db.GetAllSpans()
	if err != nil {
		return err
	}

	span, ok := spans[name]
	if !ok {
		return fmt.Errorf("span '%s' does not exist", name)
	}

	// span is ongoing!
	if span.End == nil {
		if err = db.DeleteMark(span.Start.Name); err != nil {
			return err
		}
	}

	name, err = span.NameWithTimestampHash()
	if err != nil {
		return err
	}

	fullPath := db.spanEntryPath(name)
	return os.Remove(fullPath)
}

func (db *DiskDb) UpdateSpan(span *types.Span) error {
	name, err := span.NameWithTimestampHash()
	if err != nil {
		return err
	}

	fullPath := db.spanEntryPath(name)
	if !fileExists(fullPath) {
		return fmt.Errorf("span '%s' does not exist", span.Name)
	}

	var encoded []byte
	encoded, err = db.spanEncoder.Encode(span)
	if err != nil {
		return err
	}

	return os.WriteFile(fullPath, encoded, 0666)
}

func (db *DiskDb) GetSpan(name string) (*types.Span, error) {
	fullPath := db.spanEntryPath(name)
	return decodeFromFile(fullPath, db.spanDecoder)
}

func (db *DiskDb) GetAllSpans() (spans map[string]*types.Span, err error) {
	var entries []os.DirEntry
	entries, err = os.ReadDir(db.spanDir)
	if err != nil {
		return
	}

	spans = make(map[string]*types.Span)
	for _, entry := range entries {
		fullPath := path.Join(db.spanDir, entry.Name())

		var span *types.Span
		span, err = decodeFromFile(fullPath, db.spanDecoder)
		if err != nil {
			return
		}

		spans[span.Name] = span
	}

	return
}

func decodeAllInDir[T any](
	dir string,
	decoder types.Decoder[T, []byte],
) (result []*T, err error) {
	var entries []os.DirEntry
	entries, err = os.ReadDir(dir)
	if err != nil {
		return
	}

	result = make([]*T, 0)
	for _, entry := range entries {
		if entry.IsDir() {
			continue
		}

		fullPath := path.Join(dir, entry.Name())
		var t *T
		t, err = decodeFromFile(fullPath, decoder)

		result = append(result, t)
	}

	return
}

func decodeFromFile[T any](filename string, decoder types.Decoder[T, []byte]) (*T, error) {
	data, err := os.ReadFile(filename)
	if err != nil {
		return nil, err
	}

	return decoder.Decode(data)
}

func (db *DiskDb) createMarkEntry(filename string) error {
	fullPath := db.markEntryPath(filename)
	_, err := os.OpenFile(fullPath, os.O_CREATE|os.O_EXCL, 0666)
	return err
}

func (db *DiskDb) markEntryPath(name string) string {
	return fmt.Sprintf("%s.%s", path.Join(db.markDir, name), db.entryFileExt)
}

func (db *DiskDb) spanEntryPath(name string) string {
	return fmt.Sprintf("%s.%s", path.Join(db.spanDir, name), db.entryFileExt)
}

func fileExists(filepath string) bool {
	_, err := os.Stat(filepath)
	return err == nil
}
