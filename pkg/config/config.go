package config

import (
	"errors"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strings"

	"github.com/spf13/viper"
)

var (
	RuntimeConfig Config
	Terrarium     TerrariumConfig
)

type Config struct {
	Terrarium TerrariumConfig `mapstructure:"terrarium"`
}

type TerrariumConfig struct {
	Root        string            `mapstructure:"root"`
	Self        SelfConfig        `mapstructure:"self"`
	API         ApiConfig         `mapstructure:"api"`
	LogFile     LogfileConfig     `mapstructure:"logfile"`
	LogLevel    string            `mapstructure:"loglevel"`
	LogWriter   string            `mapstructure:"logwriter"`
	Node        NodeConfig        `mapstructure:"node"`
	AutoControl AutoControlConfig `mapstructure:"autocontrol"`
	Tumblebug   TumblebugConfig   `mapstructure:"tumblebug"`
	// LKVStore    LkvStoreConfig    `mapstructure:"lkvstore"`
}

type SelfConfig struct {
	Endpoint string `mapstructure:"endpoint"`
}

type ApiConfig struct {
	Allow    AllowConfig `mapstructure:"allow"`
	Auth     AuthConfig  `mapstructure:"auth"`
	Username string      `mapstructure:"username"`
	Password string      `mapstructure:"password"`
}

type AllowConfig struct {
	Origins string `mapstructure:"origins"`
}
type AuthConfig struct {
	Enabled bool `mapstructure:"enabled"`
}

// type LkvStoreConfig struct {
// 	Path string `mapstructure:"path"`
// }

type LogfileConfig struct {
	Path       string `mapstructure:"path"`
	MaxSize    int    `mapstructure:"maxsize"`
	MaxBackups int    `mapstructure:"maxbackups"`
	MaxAge     int    `mapstructure:"maxage"`
	Compress   bool   `mapstructure:"compress"`
}

type NodeConfig struct {
	Env string `mapstructure:"env"`
}

type AutoControlConfig struct {
	DurationMilliSec int `mapstructure:"duration_ms"`
}

type TumblebugConfig struct {
	Endpoint string             `mapstructure:"endpoint"`
	RestUrl  string             `mapstructure:"resturl"`
	API      TumblebugApiConfig `mapstructure:"api"`
}

type TumblebugApiConfig struct {
	Username string `mapstructure:"username"`
	Password string `mapstructure:"password"`
}

func Init() {
	viper.AddConfigPath("../../conf/") // for development
	viper.AddConfigPath(".")           // for production
	viper.AddConfigPath("./conf/")     // for production
	viper.SetConfigType("yaml")
	viper.SetConfigName("config")

	err := viper.ReadInConfig()
	if err != nil {
		log.Printf("No main config file, using default settings: %s", err)
	}

	// Explicitly bind environment variables to configuration keys
	bindEnvironmentVariables()

	replacer := strings.NewReplacer(".", "_")
	viper.SetEnvKeyReplacer(replacer)
	viper.AutomaticEnv()

	if viper.GetString("terrarium.root") == "" {
		log.Println("Finding project root by using project name")

		projectRoot := findProjectRoot("mc-terrarium")
		viper.Set("terrarium.root", projectRoot)
	}

	if err := viper.Unmarshal(&RuntimeConfig); err != nil {
		log.Fatalf("Unable to decode into struct: %v", err)
	}
	Terrarium = RuntimeConfig.Terrarium

	// Print settings if in development mode
	if Terrarium.Node.Env == "development" {
		settings := viper.AllSettings()
		recursivePrintMap(settings, "")
	}
}

// NVL is func for null value logic
func NVL(str string, def string) string {
	if len(str) == 0 {
		return def
	}
	return str
}

func findProjectRoot(projectName string) string {
	execPath, err := os.Executable()
	if err != nil {
		log.Fatalf("Error getting executable path: %v", err)
	}
	execDir := filepath.Dir(execPath)
	projectRoot, err := checkProjectRootInParentDirectory(projectName, execDir)
	if err != nil {
		fmt.Printf("Set current directory as project root directory (%v)\n", err)
		log.Printf("Set current directory as project root directory (%v)", err)
		projectRoot = execDir
	}
	fmt.Printf("Project root directory: %s\n", projectRoot)
	log.Printf("Project root directory: %s\n", projectRoot)
	return projectRoot
}

func checkProjectRootInParentDirectory(projectName string, execDir string) (string, error) {

	// Append a path separator to the project name for accurate matching
	projectNameWithSeparator := projectName + string(filepath.Separator)
	// Find the last index of the project name with the separator
	index := strings.LastIndex(execDir, projectNameWithSeparator)
	if index == -1 {
		return "", errors.New("project name not found in the path")
	}

	// Cut the string up to the index + length of the project name
	result := execDir[:index+len(projectNameWithSeparator)-1]

	return result, nil
}

func recursivePrintMap(m map[string]interface{}, prefix string) {
	for k, v := range m {
		fullKey := prefix + k
		if nestedMap, ok := v.(map[string]interface{}); ok {
			// Recursive call for nested maps
			recursivePrintMap(nestedMap, fullKey+".")
		} else {
			// Print current key-value pair
			log.Printf("Key: %s, Value: %v\n", fullKey, v)
		}
	}
}

func bindEnvironmentVariables() {
	// Explicitly bind environment variables to configuration keys
	viper.BindEnv("terrarium.root", "TERRARIUM_ROOT")
	viper.BindEnv("terrarium.self.endpoint", "TERRARIUM_SELF_ENDPOINT")
	viper.BindEnv("terrarium.api.allow.origins", "TERRARIUM_API_ALLOW_ORIGINS")
	viper.BindEnv("terrarium.api.auth.enabled", "TERRARIUM_API_AUTH_ENABLED")
	viper.BindEnv("terrarium.api.username", "TERRARIUM_API_USERNAME")
	viper.BindEnv("terrarium.api.password", "TERRARIUM_API_PASSWORD")
	viper.BindEnv("terrarium.logfile.path", "TERRARIUM_LOGFILE_PATH")
	viper.BindEnv("terrarium.logfile.maxsize", "TERRARIUM_LOGFILE_MAXSIZE")
	viper.BindEnv("terrarium.logfile.maxbackups", "TERRARIUM_LOGFILE_MAXBACKUPS")
	viper.BindEnv("terrarium.logfile.maxage", "TERRARIUM_LOGFILE_MAXAGE")
	viper.BindEnv("terrarium.logfile.compress", "TERRARIUM_LOGFILE_COMPRESS")
	viper.BindEnv("terrarium.loglevel", "TERRARIUM_LOGLEVEL")
	viper.BindEnv("terrarium.logwriter", "TERRARIUM_LOGWRITER")
	viper.BindEnv("terrarium.node.env", "TERRARIUM_NODE_ENV")
	viper.BindEnv("terrarium.autocontrol.duration_ms", "TERRARIUM_AUTOCONTROL_DURATION_MS")
	viper.BindEnv("terrarium.tumblebug.endpoint", "TERRARIUM_TUMBLEBUG_ENDPOINT")
	viper.BindEnv("terrarium.tumblebug.api.username", "TERRARIUM_TUMBLEBUG_API_USERNAME")
	viper.BindEnv("terrarium.tumblebug.api.password", "TERRARIUM_TUMBLEBUG_API_PASSWORD")
}
