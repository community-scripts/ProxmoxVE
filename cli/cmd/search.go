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
	"encoding/json"
	"fmt"
	"strings"

	"github.com/charmbracelet/log"
	"github.com/spf13/cobra"
)

type cmdSearch struct {
	global *cmdGlobal
}

func (c *cmdSearch) Command() *cobra.Command {
	cmd := &cobra.Command{}
	cmd.Use = "search"
	cmd.Short = "search catalog"
	cmd.Args = cobra.MinimumNArgs(1)
	cmd.Long =
		`search application catalog`
	cmd.RunE = c.Run

	return cmd
}

func (c *cmdSearch) Run(cmd *cobra.Command, args []string) error {
	log.Info("searching catalog")
	catalog, err := getContainerCatalog()
	if err != nil {
		return err
	}
	needle := args[0]

	for _, v := range catalog {
		if strings.Contains(strings.ToLower(v.Name), strings.ToLower(needle)) {
			fmt.Printf("%s | %s | \n\t%s\n", v.Slug, v.Name, v.Description)
		}
	}

	return nil
}

func getContainerCatalog() (map[string]Application, error) {
	log.Debug("Downloading container catalog")
	appJson, err := downloadRaw(repository, "json", "ct-index.json")
	if err != nil {
		log.Error("Failed to download container catalog:", "error", err)
		return nil, err
	}
	var catalog map[string]Application
	err = json.Unmarshal(appJson, &catalog)
	if err != nil {
		log.Error("Failed to unmarshal container catalog:", "error", err)
		return nil, err
	}
	return catalog, nil
}
