package slackbot

import (
	"github.com/aws/aws-lambda-go/events"
	"github.com/nlopes/slack/slackevents"
	"fmt"
	"context"
	"github.com/nlopes/slack"
	"github.com/aws/aws-lambda-go/lambdacontext"
	"encoding/json"
	"errors"
)

/**
 * Create response to slack api for url verification
 */
func URLVerificationEvent(ev *slackevents.EventsAPIURLVerificationEvent) (*events.APIGatewayProxyResponse, error) {
	fmt.Printf("EventsAPIURLVerificationEvent: %#v\n", ev.Challenge)
	return &events.APIGatewayProxyResponse{
		StatusCode: 200,
		Headers: map[string]string{
			"Content-Type": "text",
		},
		Body: ev.Challenge,
	}, nil
}

/**
 * Create normal response to slack api hook
 */
func DefaultAPIGatewayResponse() (*events.APIGatewayProxyResponse, error) {
	return &events.APIGatewayProxyResponse{
		StatusCode: 200,
		Body:       "OK",
	}, nil
}

/**
 * Create slack bot
 */
func SlackBot(token string, secret string, fn func(*slack.Client, slackevents.EventsAPIInnerEvent) (*events.APIGatewayProxyResponse, error)) func(context.Context, events.APIGatewayProxyRequest) (*events.APIGatewayProxyResponse, error) {
	return func(ctx context.Context, request events.APIGatewayProxyRequest) (*events.APIGatewayProxyResponse, error) {
		api := slack.New(token)
		verificationToken := slackevents.OptionVerifyToken(&slackevents.TokenComparator{VerificationToken: secret})
		if _, ok := lambdacontext.FromContext(ctx); !ok {
			return nil, errors.New("failed to get LambdaContext from context.Context")
		} else if _, err := api.AuthTest(); err != nil {
			return nil, err
		} else if eventsAPIEvent, err := slackevents.ParseEvent(json.RawMessage(request.Body), verificationToken); err != nil {
			return nil, err
		} else {
			switch ev := eventsAPIEvent.Data.(type) {
			case *slackevents.EventsAPIURLVerificationEvent:
				return URLVerificationEvent(ev)
			case *slackevents.EventsAPICallbackEvent:
				return fn(api, eventsAPIEvent.InnerEvent)
			default:
				return nil, errors.New(fmt.Sprintf("unknown event type %#v", eventsAPIEvent))
			}
		}
	}
}
