/*
Copyright 2019 The Cloud-Barista Authors.
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

// Package main is the starting point of mc-terrarium
package main

import (
	"flag"
	"strconv"
	"sync"

	// Black import (_) is for running a package's init() function without using its other contents.
	"github.com/cloud-barista/mc-terrarium/pkg/config"
	"github.com/cloud-barista/mc-terrarium/pkg/logger"
	"github.com/fsnotify/fsnotify"
	"github.com/rs/zerolog/log"
	"github.com/spf13/viper"

	//_ "github.com/go-sql-driver/mysql"

	// _ "github.com/mattn/go-sqlite3"

	restServer "github.com/cloud-barista/mc-terrarium/pkg/api/rest"

	"github.com/cloud-barista/mc-terrarium/pkg/readyz"
)

// NoOpLogger is an implementation of resty.Logger that discards all logs.
type NoOpLogger struct{}

func (n *NoOpLogger) Errorf(format string, v ...interface{}) {}
func (n *NoOpLogger) Warnf(format string, v ...interface{})  {}
func (n *NoOpLogger) Debugf(format string, v ...interface{}) {}

func init() {
	readyz.SetReady(false)

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

// @title Multi-Cloud Terrarium REST API
// @version latest
// @description Multi-Cloud Terrarium (mc-terrarium) aims to provide an environment to enrich multi-cloud infrastructure.

// @contact.name API Support
// @contact.url https://github.com/cloud-barista/mc-terrarium/issues/new

// @license.name Apache 2.0
// @license.url http://www.apache.org/licenses/LICENSE-2.0.html

// @host localhost:8888
// @BasePath /terrarium

// @securityDefinitions.basic BasicAuth
func main() {

	log.Info().Msg("preparing to run mc-terrarium server...")

	// Set the default port number "8888" for the REST API server to listen on
	port := flag.String("port", "8888", "port number for the restapiserver to listen to")
	flag.Parse()

	// Validate port
	if portInt, err := strconv.Atoi(*port); err != nil || portInt < 1 || portInt > 65535 {
		log.Fatal().Msgf("%s is not a valid port number. Please retry with a valid port number (ex: -port=[1-65535]).", *port)
	}
	log.Debug().Msgf("port number: %s", *port)

	// Watch config file changes
	go func() {
		viper.WatchConfig()
		viper.OnConfigChange(func(e fsnotify.Event) {
			log.Debug().Str("file", e.Name).Msg("config file changed")
			err := viper.ReadInConfig()
			if err != nil { // Handle errors reading the config file
				log.Fatal().Err(err).Msg("fatal error in config file")
			}
			err = viper.Unmarshal(&config.RuntimeConfig)
			if err != nil {
				log.Panic().Err(err).Msg("error unmarshaling runtime configuration")
			}
			config.Terrarium = config.RuntimeConfig.Terrarium
		})
	}()

	// Launch API servers (REST)
	wg := new(sync.WaitGroup)
	wg.Add(1)

	// Start REST Server
	go func() {
		restServer.RunServer(*port)
		wg.Done()
	}()

	wg.Wait()
}
