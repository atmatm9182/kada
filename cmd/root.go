package cmd

import (
	"errors"
	"fmt"
	"log"
	"os"
	"path"
	"runtime"

	"github.com/atmatm9182/kada/db"
)

var cmds = make(map[string]command)

func init() {
	db := createAndSetupDiskDb()
	cmds["start"] = newStartCmd(db)
	cmds["end"] = newEndCmd(db)
	cmds["span"] = newSpanCmd(db)
}

func createAndSetupDiskDb() db.Db {
	dir, err := dataDir()
	if err != nil {
		log.Fatalln(err)
	}

	db := db.NewDiskDb(dir, db.NewJsonDiskDbConfig())
	if err = db.Setup(); err != nil {
		log.Fatalf("Unable to setup the db: %s\n", err)
	}

	return db
}

const appName = "kada"

func dataDir() (string, error) {
	var (
		dataDirName  string
		userHomeName string
		pathArgs     []string
	)

	if runtime.GOOS == "windows" {
		dataDirName = "APPDATA"
		userHomeName = "HOMEPATH"
		pathArgs = []string{"AppData", "Roaming"}
	} else {
		dataDirName = "XDG_DATA_HOME"
		userHomeName = "HOME"
		pathArgs = []string{".local", "share"}
	}

	// assume unix
	dir, ok := os.LookupEnv(dataDirName)
	if ok {
		return path.Join(dir, appName), nil
	}

	var home string
	home, ok = os.LookupEnv(userHomeName)
	if !ok {
		return home, errors.New("unable to locate user's data dir nor user's home dir")
	}

	pathArgs = append([]string{home}, pathArgs...)
	pathArgs = append(pathArgs, appName)

	return path.Join(pathArgs...), nil
}

func Exec() error {
	args := os.Args[1:]
	if len(args) == 0 {
		return errors.New("not enough arguments")
	}

	cmdName := args[0]
	cmd, ok := cmds[cmdName]

	if !ok {
		return fmt.Errorf("unknown subcommand %s", cmdName)
	}

	if err := cmd.FlagSet().Parse(args[1:]); err != nil {
		return err
	}

	return cmd.Exec()
}
