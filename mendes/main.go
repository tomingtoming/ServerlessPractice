package main

import (
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/nlopes/slack"
	"os"
)

func main() {
	lambda.Start(func() error {
		api := slack.New(os.Getenv("SLACK_CLIENT_SECRET"))
		if _, _, err := api.PostMessage("#zzz_botops_hashigo", "はしご", slack.PostMessageParameters{}); err != nil {
			return err
		} else {
			return nil
		}
	})
}
