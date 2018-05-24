package main

import (
	"context"
	"encoding/json"
	"io"

	fdk "github.com/fnproject/fdk-go"
)

func main() {
	fdk.Handle(fdk.HandlerFunc(myHandler))
}

func myHandler(ctx context.Context, in io.Reader, out io.Writer) {
	msg := struct {
		Msg string `json:"message"`
	}{
		Msg: "hello v2",
	}
	json.NewEncoder(out).Encode(&msg)
}
