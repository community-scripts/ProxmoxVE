package main

import (
	"fmt"
	"os"
	"os/user"
	"path"

	"github.com/bketelsen/inclient"
	"github.com/charmbracelet/log"
	incus "github.com/lxc/incus/v6/client"
	config "github.com/lxc/incus/v6/shared/cliconfig"
	"github.com/lxc/incus/v6/shared/util"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

var repository string
var app *cobra.Command

const version = "0.0.1"

var commit string

// Version returns the current version string
func Version() string {
	clen := 0
	if len(commit) > 7 {
		clen = 8
	}
	return fmt.Sprintf("v%s %s", version, commit[:clen])
}

func main() {
	// Setup the parser
	app = &cobra.Command{}
	app.Use = "scripts-cli"
	app.Short = "Launch incus stuff"
	app.Long =
		`community scripts for incus`
	app.SilenceUsage = true
	app.SilenceErrors = true
	app.CompletionOptions = cobra.CompletionOptions{HiddenDefaultCmd: true}

	app.Version = Version()

	// Global flags
	globalCmd := cmdGlobal{cmd: app}

	// Wrappers
	app.PersistentPreRunE = globalCmd.PreRun

	app.PersistentFlags().StringVar(&repository, "repository", "github.com/bketelsen/IncusScripts", "script source repository")
	viper.BindPFlag("repository", app.PersistentFlags().Lookup("repository"))
	// Version handling
	app.SetVersionTemplate("{{.Version}}\n")

	launchCmd := cmdLaunch{global: &globalCmd}
	app.AddCommand(launchCmd.Command())

	searchCmd := cmdSearch{global: &globalCmd}
	app.AddCommand(searchCmd.Command())

	docsCmd := cmdDocs{global: &globalCmd}
	app.AddCommand(docsCmd.Command())

	// Get help command
	app.InitDefaultHelpCmd()
	var help *cobra.Command
	for _, cmd := range app.Commands() {
		if cmd.Name() == "help" {
			help = cmd
			break
		}
	}
	help.Flags().BoolVar(&globalCmd.flagHelpAll, "all", false, "Show less common commands")

	// Run the main command and handle errors
	err := app.Execute()
	if err != nil {

		// Default error handling
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)

		// If custom exit status not set, use default error status.
		if globalCmd.ret == 0 {
			globalCmd.ret = 1
		}
	}

	if globalCmd.ret != 0 {
		os.Exit(globalCmd.ret)
	}

}

func (c *cmdGlobal) PreRun(cmd *cobra.Command, args []string) error {

	// If calling the help, skip pre-run
	if cmd.Name() == "help" {
		return nil
	}

	// Figure out the config directory and config path
	var configDir string
	if os.Getenv("INCUS_CONF") != "" {
		configDir = os.Getenv("INCUS_CONF")
	} else if os.Getenv("HOME") != "" && util.PathExists(os.Getenv("HOME")) {
		configDir = path.Join(os.Getenv("HOME"), ".config", "incus")
	} else {
		user, err := user.Current()
		if err != nil {
			return err
		}

		if util.PathExists(user.HomeDir) {
			configDir = path.Join(user.HomeDir, ".config", "incus")
		}
	}

	c.confPath = os.ExpandEnv(path.Join(configDir, "config.yml"))
	var err error
	c.conf, err = config.LoadConfig("")
	if err != nil {
		return fmt.Errorf("failed to load incus configuration: %s", err)
	}

	// Load the configuration

	//c.conf = config.NewConfig(configDir, false)
	log.Debug("Incus", "default remote", c.conf.DefaultRemote)
	client, err := inclient.NewClient(c.conf)
	if err != nil {
		return err
	}
	c.client = client
	return nil
}

type remoteResource struct {
	remote string
	server incus.InstanceServer
	name   string
}

func (c *cmdGlobal) ParseServers(remotes ...string) ([]remoteResource, error) {
	servers := map[string]incus.InstanceServer{}
	resources := []remoteResource{}

	for _, remote := range remotes {
		// Parse the remote
		remoteName, name, err := c.conf.ParseRemote(remote)
		if err != nil {
			return nil, err
		}

		// Setup the struct
		resource := remoteResource{
			remote: remoteName,
			name:   name,
		}

		// Look at our cache
		_, ok := servers[remoteName]
		if ok {
			resource.server = servers[remoteName]
			resources = append(resources, resource)
			continue
		}

		// New connection
		d, err := c.conf.GetInstanceServer(remoteName)
		if err != nil {
			return nil, err
		}

		resource.server = d
		servers[remoteName] = d
		resources = append(resources, resource)
	}

	return resources, nil
}
