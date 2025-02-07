package main

import (
	"testing"
)

func Test_orgRepo(t *testing.T) {
	type args struct {
		repo string
	}
	tests := []struct {
		name string
		args args
		want string
	}{
		// TODO: Add test cases.
		{"happyPath", args{repo: "https://github.com/bketelsen/IncusScripts"}, "bketelsen/IncusScripts"},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := orgRepo(tt.args.repo); got != tt.want {
				t.Errorf("orgRepo() = %v, want %v", got, tt.want)
			}
		})
	}
}

func Test_rawURL(t *testing.T) {
	type args struct {
		repo  string
		paths []string
	}
	tests := []struct {
		name string
		args args
		want string
	}{
		{"happyPath", args{repo: "github.com/bketelsen/IncusScripts", paths: []string{"test", "test"}}, "https://raw.githubusercontent.com/bketelsen/IncusScripts/refs/heads/main/test/test"},
		{"json", args{repo: "github.com/bketelsen/IncusScripts", paths: []string{"json", "debian.json"}}, "https://raw.githubusercontent.com/bketelsen/IncusScripts/refs/heads/main/json/debian.json"},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := rawURL(tt.args.repo, tt.args.paths...); got != tt.want {
				t.Errorf("rawURL() = %v, want %v", got, tt.want)
			}
		})
	}
}
