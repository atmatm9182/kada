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
	GetMark(name string) (*types.Mark, error)
}

type DiskDb struct {
	storageDir   string
	entryFileExt string
	markEncoder  types.Encoder[types.Mark, []byte]
	markDecoder  types.Decoder[types.Mark, []byte]
}

func NewDiskDb(dir string, config DiskDbConfig) *DiskDb {
	return &DiskDb{
		storageDir:   dir,
		entryFileExt: config.EntryFileExt(),
		markEncoder:  config.MarkEncoder(),
		markDecoder:  config.MarkDecoder(),
	}
}

func (db *DiskDb) Setup() error {
	return os.MkdirAll(db.storageDir, 0777)
}

func (db *DiskDb) CreateMark(m *types.Mark) (err error) {
	err = db.createEntry(m.Name)
	if err != nil {
		return
	}

	var encoded []byte
	encoded, err = db.markEncoder.Encode(m)
	if err != nil {
		return
	}

	err = db.writeToFile(m.Name, encoded)
	return
}

func (db *DiskDb) GetMark(name string) (m *types.Mark, err error) {
	entryPath := db.entryPath(name)

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

func (db *DiskDb) createEntry(filename string) error {
	fullPath := db.entryPath(filename)
	_, err := os.OpenFile(fullPath, os.O_CREATE|os.O_EXCL, 0666)
	return err
}

// This method writes data to the existing file, with it's filepath being relative to the storage
// directory of this db instance.
func (db *DiskDb) writeToFile(filename string, data []byte) error {
	fullPath := db.entryPath(filename)
	if !fileExists(fullPath) {
		return fmt.Errorf("file '%s' does not exist", fullPath)
	}

	return os.WriteFile(fullPath, data, 0666)
}

func (db *DiskDb) fullPath(filename string) string {
	return path.Join(db.storageDir, filename)
}

func (db *DiskDb) entryPath(name string) string {
	return fmt.Sprintf("%s.%s", db.fullPath(name), db.entryFileExt)
}

func fileExists(filepath string) bool {
	_, err := os.Stat(filepath)
	return err == nil
}
