package tfcli

import (
	"errors"
	"fmt"

	tfutil "github.com/cloud-barista/mc-terrarium/pkg/tofu/util"
)

// GlobalOptions defines global options for tofu commands.
type GlobalOptions struct {
	// Chdir changes the working directory before executing the command.
	Chdir string
	// Help displays help information.
	Help bool
	// Version displays version information.
	Version bool
}

// Client is the main struct for executing OpenTofu commands.
type Client struct {
	trId       string
	reqId      string
	cmd        string
	args       []string
	globalOpts *GlobalOptions
	async      bool
}

// String converts GlobalOptions to command line arguments format.
func (opts *GlobalOptions) String() []string {
	var options []string
	
	if opts.Chdir != "" {
		options = append(options, fmt.Sprintf("-chdir=%s", opts.Chdir))
	}
	
	if opts.Help {
		options = append(options, "-help")
	}
	
	if opts.Version {
		options = append(options, "-version")
	}
	
	return options
}

// NewClient creates a new OpenTofu client.
func NewClient(trId, reqId string) *Client {
	return &Client{
		trId:  trId,
		reqId: reqId,
		args:  []string{},
	}
}

// WithGlobalOptions sets global options for the command.
func (c *Client) WithGlobalOptions(opts *GlobalOptions) *Client {
	c.globalOpts = opts
	return c
}

// SetChdir sets the working directory for the command.
func (c *Client) SetChdir(dir string) *Client {
	if c.globalOpts == nil {
		c.globalOpts = &GlobalOptions{}
	}
	c.globalOpts.Chdir = dir
	return c
}

// Help sets the help flag to display help information.
func (c *Client) Help() *Client {
	if c.globalOpts == nil {
		c.globalOpts = &GlobalOptions{}
	}
	c.globalOpts.Help = true
	return c
}

// GlobalVersionFlag sets the global version flag (different from version command).
func (c *Client) GlobalVersionFlag() *Client {
	if c.globalOpts == nil {
		c.globalOpts = &GlobalOptions{}
	}
	c.globalOpts.Version = true
	return c
}

// Async sets whether the command should be executed asynchronously.
func (c *Client) Async(async bool) *Client {
	c.async = async
	return c
}

// buildArgs builds the command and arguments.
func (c *Client) buildArgs() []string {
	args := []string{}
	
	// Add global options
	if c.globalOpts != nil {
		args = append(args, c.globalOpts.String()...)
	}
	
	// Add command
	if c.cmd != "" {
		args = append(args, c.cmd)
	}
	
	// Add arguments
	args = append(args, c.args...)
	
	return args
}

// Exec executes the configured command.
func (c *Client) Exec() (string, error) {
	args := c.buildArgs()
	
	if len(args) == 0 {
		return "", errors.New("no command specified")
	}
	
	if c.async {
		return tfutil.ExecuteTofuCommandAsync(c.trId, c.reqId, args...)
	}
	
	return tfutil.ExecuteTofuCommand(c.trId, c.reqId, args...)
}

// --- Main Commands ---

// Init sets the init command.
func (c *Client) Init() *Client {
	c.cmd = "init"
	return c
}

// Validate sets the validate command.
func (c *Client) Validate() *Client {
	c.cmd = "validate"
	return c
}

// Plan sets the plan command.
func (c *Client) Plan() *Client {
	c.cmd = "plan"
	return c
}

// Apply sets the apply command.
func (c *Client) Apply() *Client {
	c.cmd = "apply"
	return c
}

// Destroy sets the destroy command.
func (c *Client) Destroy() *Client {
	c.cmd = "destroy"
	return c
}

// Output sets the output command.
func (c *Client) Output() *Client {
	c.cmd = "output"
	return c
}

// Import sets the import command.
func (c *Client) Import() *Client {
	c.cmd = "import"
	return c
}

// Fmt sets the fmt command.
func (c *Client) Fmt() *Client {
	c.cmd = "fmt"
	return c
}

// Refresh sets the refresh command.
func (c *Client) Refresh() *Client {
	c.cmd = "refresh"
	return c
}

// Show sets the show command.
func (c *Client) Show() *Client {
	c.cmd = "show"
	return c
}

// Providers sets the providers command.
func (c *Client) Providers() *Client {
	c.cmd = "providers"
	return c
}

// Version sets the version command.
func (c *Client) Version() *Client {
	c.cmd = "version"
	return c
}

// Console sets the console command.
func (c *Client) Console() *Client {
	c.cmd = "console"
	return c
}

// Get sets the get command.
func (c *Client) Get() *Client {
	c.cmd = "get"
	return c
}

// Graph sets the graph command.
func (c *Client) Graph() *Client {
	c.cmd = "graph"
	return c
}

// Login sets the login command.
func (c *Client) Login() *Client {
	c.cmd = "login"
	return c
}

// Logout sets the logout command.
func (c *Client) Logout() *Client {
	c.cmd = "logout"
	return c
}

// Metadata sets the metadata command.
func (c *Client) Metadata() *Client {
	c.cmd = "metadata"
	return c
}

// State sets the state command.
func (c *Client) State() *Client {
	c.cmd = "state"
	return c
}

// Taint sets the taint command.
func (c *Client) Taint() *Client {
	c.cmd = "taint"
	return c
}

// Test sets the test command.
func (c *Client) Test() *Client {
	c.cmd = "test"
	return c
}

// Untaint sets the untaint command.
func (c *Client) Untaint() *Client {
	c.cmd = "untaint"
	return c
}

// Workspace sets the workspace command.
func (c *Client) Workspace() *Client {
	c.cmd = "workspace"
	return c
}

// ForceUnlock sets the force-unlock command.
func (c *Client) ForceUnlock() *Client {
	c.cmd = "force-unlock"
	return c
}

// --- Option Setting Methods ---

// SetArg adds a command line argument.
func (c *Client) SetArg(arg string) *Client {
	c.args = append(c.args, arg)
	return c
}

// SetArgs adds multiple command line arguments.
func (c *Client) SetArgs(args ...string) *Client {
	c.args = append(c.args, args...)
	return c
}

// Auto sets the -auto-approve flag.
func (c *Client) Auto() *Client {
	c.args = append(c.args, "-auto-approve")
	return c
}

// SetVarFile sets a variable file.
func (c *Client) SetVarFile(file string) *Client {
	c.args = append(c.args, fmt.Sprintf("-var-file=%s", file))
	return c
}

// SetVar sets an individual variable.
func (c *Client) SetVar(name, value string) *Client {
	c.args = append(c.args, fmt.Sprintf("-var=%s=%s", name, value))
	return c
}

// SetVars sets multiple variables.
func (c *Client) SetVars(vars map[string]string) *Client {
	for name, value := range vars {
		c.SetVar(name, value)
	}
	return c
}

// SetOut sets the output file (used with plan command).
func (c *Client) SetOut(file string) *Client {
	c.args = append(c.args, fmt.Sprintf("-out=%s", file))
	return c
}

// NoColor disables color output.
func (c *Client) NoColor() *Client {
	c.args = append(c.args, "-no-color")
	return c
}

// Json sets JSON output format.
func (c *Client) Json() *Client {
	c.args = append(c.args, "-json")
	return c
}

// Upgrade sets the -upgrade flag (used with init command).
func (c *Client) Upgrade() *Client {
	c.args = append(c.args, "-upgrade")
	return c
}

// Reconfigure sets the -reconfigure flag (used with init command).
func (c *Client) Reconfigure() *Client {
	c.args = append(c.args, "-reconfigure")
	return c
}

// Backup sets the state backup file path.
func (c *Client) Backup(path string) *Client {
	c.args = append(c.args, fmt.Sprintf("-backup=%s", path))
	return c
}

// SetRefresh sets the refresh flag.
func (c *Client) SetRefresh(refresh bool) *Client {
	c.args = append(c.args, fmt.Sprintf("-refresh=%t", refresh))
	return c
}

// Compact sets the compressed warning output format.
func (c *Client) Compact() *Client {
	c.args = append(c.args, "-compact-warnings")
	return c
}

// Parallelism sets the number of parallel operations.
func (c *Client) Parallelism(count int) *Client {
	c.args = append(c.args, fmt.Sprintf("-parallelism=%d", count))
	return c
}

// Check sets the -check flag (used with fmt command).
func (c *Client) Check() *Client {
	c.args = append(c.args, "-check")
	return c
}

// Recursive sets the -recursive flag (used with fmt command).
func (c *Client) Recursive() *Client {
	c.args = append(c.args, "-recursive")
	return c
}

// Diff sets the -diff flag (used with fmt command).
func (c *Client) Diff() *Client {
	c.args = append(c.args, "-diff")
	return c
}

// Lock sets the -lock flag.
func (c *Client) Lock(lock bool) *Client {
	c.args = append(c.args, fmt.Sprintf("-lock=%t", lock))
	return c
}

// LockTimeout sets the lock-timeout option.
func (c *Client) LockTimeout(duration string) *Client {
	c.args = append(c.args, fmt.Sprintf("-lock-timeout=%s", duration))
	return c
}
