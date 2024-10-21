### Config Package

#### Overview

The `config` package manages configurations in Go applications,
ensuring compatibility between `config.yaml` and `setup.env`.
`setup.env` is used to setup environment variables.

Note - When both environment variables and config.yaml settings are present,
the package prioritizes environment variables, overriding equivalent settings in config.yaml.

#### Compatible configurations example

The below configurations are compatible in this project.

- `setup.env` contains:

  ```
  export LOGFILE_PATH=log/terrarium.log
  ```

- `config.yaml` has:
  ```yaml
  logfile:
    path: ./log/mc-terrarium.log
  ```

#### How to use it

- Use a blank import in your package (e.g., main, logger, and so on)
- Get a value using Viper

Note - It's just my preference. `config.Init()` can be used.

```go
import (
    // other packages

    "github.com/cloud-barista/mc-terrarium/pkg/config"
    "github.com/cloud-barista/mc-terrarium/pkg/logger"
)

func init(){
	// Initialize the configuration from "config.yaml" file or environment variables
	config.Init()

	// Initialize the logger
	logger := logger.NewLogger(logger.Config{
		LogLevel:    config.Terrarium.LogLevel,
		LogWriter:   config.Terrarium.LogWriter,
		LogFilePath: config.Terrarium.LogFile.Path,
		MaxSize:     config.Terrarium.LogFile.MaxSize,
		MaxBackups:  config.Terrarium.LogFile.MaxBackups,
		MaxAge:      config.Terrarium.LogFile.MaxAge,
		Compress:    config.Terrarium.LogFile.Compress,
	})

	// Set the global logger
	log.Logger = *logger
}

func main() {
    // Application logic follows
}
```

#### Wrapping Up

This setup illustrates the package's ability to harmonize settings from both `setup.env` and `config.yaml`,
showcasing its versatility and ease of use.
