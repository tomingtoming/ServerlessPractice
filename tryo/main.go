package main

import (
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-lambda-go/events"
	"errors"
	"github.com/nlopes/slack/slackevents"
	"fmt"
	"github.com/nlopes/slack"
	"os"
	"github.com/tomingtoming/ServerlessPractice/common/slackbot"
)

func main() {
	lambda.Start(slackbot.SlackBot(
		os.Getenv("SLACK_CLIENT_SECRET"),
		os.Getenv("SLACK_VERIFICATION_TOKEN"),
		func(api *slack.Client, event slackevents.EventsAPIInnerEvent) (*events.APIGatewayProxyResponse, error) {
			switch ev := event.Data.(type) {
			case *slackevents.AppMentionEvent:
				fmt.Printf("AppMentionEvent: %#v\n", ev)
				if ev.User == "" {
					// Ignore bot
					return slackbot.DefaultAPIGatewayResponse()
				} else if _, _, err := api.PostMessage(ev.Channel, fmt.Sprintf("Hello, <@%s>\n> %s", ev.User, ev.Text), slack.PostMessageParameters{}); err != nil {
					return nil, err
				} else {
					return slackbot.DefaultAPIGatewayResponse()
				}
			case *slackevents.MessageEvent:
				fmt.Printf("MessageEvent: %#v\n", ev)
				if ev.Subtype == "" {
					// Ignore bot
					return slackbot.DefaultAPIGatewayResponse()
				} else {
					return slackbot.DefaultAPIGatewayResponse()
				}
			default:
				return nil, errors.New(fmt.Sprintf("unknown inner event type: %#v", event))
			}
		},
	))
}
