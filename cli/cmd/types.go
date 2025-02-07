package main

import "strings"

type Metadata struct {
	Categories []struct {
		Name        string  `json:"name"`
		ID          int     `json:"id"`
		SortOrder   float64 `json:"sort_order"`
		Description string  `json:"description"`
	} `json:"categories"`
}

type Application struct {
	Name               string             `json:"name,omitempty"`
	Slug               string             `json:"slug,omitempty"`
	Categories         []int              `json:"categories,omitempty"`
	DateCreated        string             `json:"date_created,omitempty"`
	Type               string             `json:"type,omitempty"`
	Updateable         bool               `json:"updateable,omitempty"`
	Privileged         bool               `json:"privileged,omitempty"`
	InterfacePort      int                `json:"interface_port,omitempty"`
	Documentation      string             `json:"documentation,omitempty"`
	Website            string             `json:"website,omitempty"`
	Logo               string             `json:"logo,omitempty"`
	Description        string             `json:"description,omitempty"`
	InstallMethods     []InstallMethods   `json:"install_methods,omitempty"`
	DefaultCredentials DefaultCredentials `json:"default_credentials,omitempty"`
	Notes              []Notes            `json:"notes,omitempty"`
}

func (a Application) GetJSON() string {
	return strings.ToLower(a.Slug) + ".json"
}
func (a Application) GetSlug() string {
	return strings.ToLower(a.Slug)
}

type Resources struct {
	CPU     int    `json:"cpu,omitempty"`
	RAM     int    `json:"ram,omitempty"`
	OS      string `json:"os,omitempty"`
	Version string `json:"version,omitempty"`
}

func (r Resources) GetOS() string {
	return strings.ToLower(r.OS)
}
func (r Resources) GetVersion() string {
	return strings.ToLower(r.Version)
}
func (r Resources) Image() string {
	return strings.ToLower(r.OS) + "/" + strings.ToLower(r.Version)
}

type InstallMethods struct {
	Type      string    `json:"type,omitempty"`
	Script    string    `json:"script,omitempty"`
	Resources Resources `json:"resources,omitempty"`
}
type DefaultCredentials struct {
	Username any `json:"username,omitempty"`
	Password any `json:"password,omitempty"`
}
type Notes struct {
	Text string `json:"text,omitempty"`
	Type string `json:"type,omitempty"`
}

type ExecuteContext struct {
	Application   Application
	InstallMethod InstallMethods
	Resource      Resources
}

type LaunchSettings struct {
	Name             string            `json:"name,omitempty"`
	Image            string            `json:"image,omitempty"`
	Profiles         []string          `json:"profiles,omitempty"`
	CPU              int               `json:"cpu,omitempty"`
	RAM              int               `json:"ram,omitempty"`
	RootPassword     string            `json:"root_password,omitempty"`
	EnableSSH        bool              `json:"enable_ssh,omitempty"`
	SSHRootPassword  bool              `json:"ssh_root_password,omitempty"`
	SSHAuthorizedKey string            `json:"ssh_authorized_key,omitempty"`
	Environment      map[string]string `json:"environment,omitempty"`
	InstallMethod    int               `json:"install_method,omitempty"`
}

func NewLaunchSettings(a Application, name string) LaunchSettings {
	l := LaunchSettings{
		Name:          name,
		Profiles:      []string{"default"},
		InstallMethod: 0,
	}
	l.Image = "images:" + a.InstallMethods[0].Resources.Image()
	return l
}
