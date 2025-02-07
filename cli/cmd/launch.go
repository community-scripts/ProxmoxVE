/*
Copyright © 2025 Brian Ketelsen <bketelsen@gmail.com>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/
package main

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strconv"
	"time"

	"github.com/charmbracelet/glamour"
	"github.com/charmbracelet/log"
	"github.com/spf13/cobra"

	"github.com/charmbracelet/huh"
	"github.com/charmbracelet/huh/spinner"
)

var rootPasswordTwice string
var doit bool

type cmdLaunch struct {
	global *cmdGlobal
}

func (c *cmdLaunch) Command() *cobra.Command {
	cmd := &cobra.Command{}
	cmd.Use = "launch <application> <instance name>"
	cmd.Short = "launch a container"
	cmd.Args = cobra.ExactArgs(2)

	cmd.Long =
		`A longer description that spans multiple lines and likely contains examples
and usage of using your command. For example:

Cobra is a CLI library for Go that empowers applications.
This application is a tool to generate the needed files
to quickly create a Cobra application.`
	cmd.RunE = c.Run

	return cmd
}

func (c *cmdLaunch) Run(cmd *cobra.Command, args []string) error {
	app := args[0]
	instanceName := args[1]
	log.Debug("Preparing to launch", "application", app, "instance name", instanceName)
	return c.launch(app, instanceName)

}

func (c *cmdLaunch) launch(app string, instanceName string) error {
	// Should we run in accessible mode?
	accessible, _ := strconv.ParseBool(os.Getenv("ACCESSIBLE"))
	// get the application metadata
	application, err := getAppMetadata(app)
	if err != nil {
		return err
	}

	if application.Type != "ct" {
		log.Error("Application type not supported", "type", application.Type)
		return errors.New("application type not supported")
	}

	launchSettings := NewLaunchSettings(*application, instanceName)
	var advanced bool
	var enableSSH bool
	var addGPU bool
	var profiles []string

	form := huh.NewForm(
		huh.NewGroup(huh.NewNote().
			Title("Incus Scripts").
			Description(fmt.Sprintf("Launch a _%s_ container\n\n%s\n\n", app, application.Description)).
			Next(true).
			NextLabel("Get started"),
		),
		huh.NewGroup(
			huh.NewConfirm().
				Title("Use Default Settings?").
				Affirmative("No").
				Negative("Yes").
				Value(&advanced),
		),
	).WithAccessible(accessible)

	err = form.Run()
	if err != nil {
		fmt.Println("form error:", err)
		os.Exit(1)
	}

	if advanced {

		// select install method
		installMethod := 0
		if len(application.InstallMethods) > 1 {
			// select install method
			form := huh.NewForm(

				huh.NewGroup(
					huh.NewSelect[int]().
						Title("Choose Operating System").
						Options(
							huh.NewOption(application.InstallMethods[0].Resources.OS, 0),
							huh.NewOption(application.InstallMethods[1].Resources.OS, 1),
						).
						Value(&installMethod),
				),
			).WithAccessible(accessible)

			err = form.Run()
			if err != nil {
				fmt.Println("form error:", err)
				os.Exit(1)
			}
			launchSettings.Image = "images:" + application.InstallMethods[installMethod].Resources.Image()
			launchSettings.InstallMethod = installMethod

		}

		// select install method
		form := huh.NewForm(

			huh.NewGroup(
				huh.NewConfirm().
					Title("Launch As VM?").
					Value(&launchSettings.VM).
					Affirmative("Yes").
					Negative("No"),
			),
		).WithAccessible(accessible)

		err = form.Run()
		if err != nil {
			fmt.Println("form error:", err)
			os.Exit(1)
		}
		launchSettings.Image = "images:" + application.InstallMethods[installMethod].Resources.Image()
		launchSettings.InstallMethod = installMethod

		// choose ssh options
		form = huh.NewForm(
			huh.NewGroup(
				huh.NewConfirm().
					Title("Pass through GPU?").
					Value(&addGPU).
					Affirmative("Yes").
					Negative("No"),
			),
		).WithAccessible(accessible)

		err = form.Run()
		if err != nil {
			fmt.Println("form error:", err)
			os.Exit(1)
		}

		// choose ssh options
		form = huh.NewForm(
			huh.NewGroup(
				huh.NewConfirm().
					Title("Enable SSH?").
					Value(&enableSSH).
					Affirmative("Yes").
					Negative("No"),
			),
		).WithAccessible(accessible)

		err = form.Run()
		if err != nil {
			fmt.Println("form error:", err)
			os.Exit(1)
		}
		launchSettings.EnableSSH = enableSSH

		if enableSSH {
			home, err := os.UserHomeDir()
			if err != nil {
				return err
			}
			authKeyFile := ""
			form := huh.NewForm(
				huh.NewGroup(
					huh.NewConfirm().
						Title("Allow Root SSH with Password?").
						Value(&launchSettings.SSHRootPassword).
						Affirmative("Yes").
						Negative("No"),
				),
				huh.NewGroup(
					huh.NewInput().
						Value(&launchSettings.RootPassword).
						Title("Enter Root Password").
						Placeholder("correct-horse-battery-staple").
						EchoMode(huh.EchoModePassword).
						Description("Root password for the container."),
					huh.NewInput().
						Value(&rootPasswordTwice).
						Title("Confirm Root Password").
						Placeholder("correct-horse-battery-staple").
						EchoMode(huh.EchoModePassword).
						Description("Root password for the container.").
						Validate(func(s string) error {
							if s != launchSettings.RootPassword {
								return errors.New("passwords do not match")
							}
							return nil
						}),
				),
				huh.NewGroup(
					huh.NewFilePicker().
						Value(&authKeyFile).
						Title("SSH Authorized Key").
						FileAllowed(true).
						DirAllowed(false).
						AllowedTypes([]string{".pub"}).
						ShowHidden(true).
						ShowSize(false).
						ShowPermissions(false).
						CurrentDirectory(filepath.Join(home, ".ssh")).
						Description("Press enter to choose a public key file."),
				),
			).WithAccessible(accessible)

			err = form.Run()
			if err != nil {
				fmt.Println("form error:", err)
				os.Exit(1)
			}
			bb, err := os.ReadFile(authKeyFile)
			if err != nil {
				fmt.Println("error reading pub key:", err)

				return err
			}
			launchSettings.SSHAuthorizedKey = string(bb)
		}

		// select profiles
		profileList, err := c.global.client.ProfileNames(context.Background())
		if err != nil {
			return err
		}
		// remove "default" profile
		for i, p := range profileList {
			if p == "default" {
				profileList = append(profileList[:i], profileList[i+1:]...)
			}
		}

		// add "default" profile back at the beginning
		profileList = append([]string{"default"}, profileList...)

		form = huh.NewForm(
			huh.NewGroup(
				huh.NewMultiSelect[string]().
					Options(huh.NewOptions(profileList...)...).
					Title("Select Additional Incus Profiles").
					Value(&profiles).
					Description("*default* profile should usually be included."),
			),
		).WithAccessible(accessible)

		err = form.Run()
		if err != nil {
			fmt.Println("form error:", err)
			os.Exit(1)
		}
		launchSettings.Profiles = profiles

	}
	form = huh.NewForm(
		huh.NewGroup(
			huh.NewConfirm().
				Title("Create instance?").
				Value(&doit).
				Affirmative("Yes!").
				Negative("No."),
		),
	).WithAccessible(accessible)

	err = form.Run()
	if err != nil {
		fmt.Println("form error:", err)
		os.Exit(1)
	}
	extraConfigs := make(map[string]string)
	// set environment variables
	// SSH Enable
	if launchSettings.EnableSSH {
		extraConfigs["environment.INSTALL_SSH"] = "yes"
	} else {
		extraConfigs["environment.INSTALL_SSH"] = "no"
	}
	if launchSettings.SSHRootPassword {
		extraConfigs["environment.SSH_ROOT"] = "yes"
	} else {
		extraConfigs["environment.SSH_ROOT"] = "no"
	}
	// SSH Authorized Key
	if len(launchSettings.SSHAuthorizedKey) > 0 {
		extraConfigs["environment.SSH_AUTHORIZED_KEY"] = launchSettings.SSHAuthorizedKey
	} else {
		extraConfigs["environment.SSH_AUTHORIZED_KEY"] = "\"\""
	}
	// Root Password
	if len(launchSettings.RootPassword) > 0 {
		extraConfigs["environment.PASSWORD"] = launchSettings.RootPassword
	} else {
		extraConfigs["environment.PASSWORD"] = "\"\""
	}
	// cttype - container type, always 0
	extraConfigs["environment.CTTYPE"] = "0"
	// app - lower caseed application name
	extraConfigs["environment.app"] = application.Slug

	// Application Name
	extraConfigs["environment.APPLICATION"] = application.Name

	// OS Type
	extraConfigs["environment.PCT_OSTYPE"] = application.InstallMethods[launchSettings.InstallMethod].Resources.OS

	// OS Version
	extraConfigs["environment.PCT_OSVERSION"] = application.InstallMethods[launchSettings.InstallMethod].Resources.Version

	// tz
	extraConfigs["environment.tz"] = "Etc/UTC"

	// Cacher
	extraConfigs["environment.CACHER"] = "no"

	// Disable ipv6
	extraConfigs["environment.DISABLEIPV6"] = "yes" // todo: make this a form option

	var funcScript []byte
	if application.InstallMethods[launchSettings.InstallMethod].Resources.OS == "alpine" {
		funcScript, err = downloadRaw(repository, "misc", "alpine-install.func")
		if err != nil {
			fmt.Println("download error:", err)
			os.Exit(1)
		}
	} else {
		funcScript, err = downloadRaw(repository, "misc", "install.func")
		if err != nil {
			fmt.Println("download error:", err)
			os.Exit(1)
		}
	}
	// Function script
	extraConfigs["environment.FUNCTIONS_FILE_PATH"] = string(funcScript)

	createInstance := func() {
		// create the instance
		err := c.global.client.Launch(launchSettings.Image, launchSettings.Name, launchSettings.Profiles, extraConfigs, launchSettings.VM, false)
		if err != nil {
			fmt.Println("Error creating instance:", err)
			os.Exit(1)
		}
		// TODO add bash to alpine before continuing
		//   if [ "$var_os" == "alpine" ]; then
		//     sleep 3
		//     incus exec "$HN" -- /bin/sh -c 'cat <<EOF >/etc/apk/repositories
		// http://dl-cdn.alpinelinux.org/alpine/latest-stable/main
		// http://dl-cdn.alpinelinux.org/alpine/latest-stable/community
		// EOF'
		//     incus exec "$HN"  -- ash -c "apk add bash >/dev/null"
		//   fi
		if addGPU {
			err = c.global.client.AddDeviceToInstance(context.Background(), launchSettings.Name, "gpu", map[string]string{"type": "gpu", "gid": "44", "uid": "0"})
			if err != nil {
				fmt.Println("Error adding GPU to instance:", err)
				os.Exit(1)
			}
		}
		err = c.global.client.StartInstance(context.Background(), launchSettings.Name)
		if err != nil {
			fmt.Println("Error starting instance:", err)
			os.Exit(1)
		}
		if launchSettings.VM {
			log.Info("VM started, waiting for agent...")
			const maxAttempts = 5
			const waitTime = 2
			getState := func() (bool, error) {
				time.Sleep(waitTime * time.Second)
				state, err := c.global.client.InstanceState(context.Background(), launchSettings.Name)
				if err != nil {
					fmt.Println("Error waiting for vm agent:", err)
					return false, err
				}
				if state.State.Processes > 2 {
					return true, nil
				}
				return false, nil
			}
			attempts := 0
			for {
				success, err := getState()
				if err != nil {
					fmt.Println("Error waiting for vm agent:", err)
					os.Exit(1)
				}
				if success {
					break
				}
				attempts++
				if attempts >= maxAttempts {
					fmt.Println("Error waiting for vm agent: max attempts reached")
					os.Exit(1)
				}
			}
		}
	}

	if doit {
		_ = spinner.New().Title("Creating instance...").Accessible(accessible).Action(createInstance).Run()
		installFunc, err := downloadRaw(repository, "install", application.Slug+"-install.sh")
		if err != nil {
			fmt.Println("Error downloading install script:", err)
			os.Exit(1)
		}
		// run installer
		err = c.global.client.ExecInteractive([]string{launchSettings.Name, "bash", "-c", string(installFunc)}, []string{}, 0, 0, "", os.Stdin, os.Stdout, os.Stderr)
		if err != nil {
			fmt.Println("Error executing installer:", err)
			os.Exit(1)
		}

		// print the summary
		out, _ := WelcomeMessage(*application, launchSettings)
		output, _ := glamour.Render(out, "dark")
		fmt.Print(output)
	} else {
		log.Error("Instance creation cancelled")
	}
	return nil
}

func getAppMetadata(app string) (*Application, error) {
	log.Debug("Downloading application metadata", "application", app)
	appJson, err := downloadRaw(repository, "json", app+".json")
	if err != nil {
		log.Error("Failed to download application metadata:", "error", err)
		return nil, err
	}
	var application Application
	err = json.Unmarshal(appJson, &application)
	if err != nil {
		log.Error("Failed to parse application metadata:", "error", err)
		return nil, err
	}
	return &application, nil
}
