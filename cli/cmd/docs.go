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
	"os"

	"github.com/charmbracelet/log"
	"github.com/spf13/cobra"
	"github.com/spf13/cobra/doc"
)

type cmdDocs struct {
	global *cmdGlobal
}

func (c *cmdDocs) Command() *cobra.Command {
	cmd := &cobra.Command{}
	cmd.Use = "docs"
	cmd.Short = "generate documentation"
	cmd.Hidden = true

	cmd.RunE = c.Run

	return cmd
}

func (c *cmdDocs) Run(cmd *cobra.Command, args []string) error {
	log.Info("generating documentation")

	// check if the docs directory exists
	// if not, create it
	_, err := os.Stat("./site/src/content/docs/cli")
	if os.IsNotExist(err) {
		err = os.Mkdir("./site/src/content/docs/cli", 0755)
		if err != nil {
			return err
		}
	}

	app.DisableAutoGenTag = true

	err = doc.GenMarkdownTree(app, "./site/src/content/docs/cli")
	if err != nil {
		log.Fatal(err)
	}

	return nil
}
