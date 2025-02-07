package main

import (
	"bytes"
	"fmt"
	"io"
	"net/http"
	"path/filepath"
	"strings"
	"text/template"
)

func orgRepo(repo string) string {
	or := strings.TrimPrefix(repo, "https://")
	or = strings.TrimPrefix(or, "http://")
	or = strings.TrimPrefix(or, "git@")
	or = strings.TrimPrefix(or, "github.com/")
	or = strings.TrimSuffix(or, ".git")
	or = strings.TrimSuffix(or, "/")
	return or
}

func rawURL(repo string, paths ...string) string {
	return "https://raw.githubusercontent.com/" + orgRepo(repo) + "/refs/heads/main/" + filepath.Join(paths...)
}

func downloadRaw(repo string, paths ...string) ([]byte, error) {
	resp, err := http.Get(rawURL(repo, paths...))
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("failed to download file: %s", resp.Status)
	}
	bb, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}
	return bb, nil
}

func WelcomeMessage(app Application, launch LaunchSettings) (string, error) {
	t1 := template.New("welcome")
	t1, err := t1.Parse(welcomeMessage)
	if err != nil {
		panic(err)
	}

	bb := bytes.Buffer{}
	err = t1.Execute(&bb, map[string]interface{}{
		"app":    app,
		"launch": launch,
	})
	return bb.String(), err
}

var welcomeMessage = `# Instance Details

- Instance Name: {{ .launch.Name }}
- Application: {{.app.Name}}
- Image: {{.launch.Image}}
- Incus Profiles: {{range .launch.Profiles}}{{.}} {{end}}
{{if .app.DefaultCredentials.Username }}- Default Credentials: User:{{.app.DefaultCredentials.Username}} / Password: {{.app.DefaultCredentials.Password}}{{end}}

## Application Information
{{.app.Description}}

## Resources
Website: [{{.app.Name}}]({{.app.Website}})

Documentation: [{{.app.Name}}]({{.app.Documentation}})

{{if ne .app.InterfacePort 0 }}Application Port : {{.app.InterfacePort}}{{end}}

`
