package codex

import (
	"encoding/json"
	"testing"

	"github.com/QuantumNous/new-api/constant"
	relaycommon "github.com/QuantumNous/new-api/relay/common"
	relayconstant "github.com/QuantumNous/new-api/relay/constant"
	"github.com/QuantumNous/new-api/relaykit/dto"
	"github.com/samber/lo"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestGetRequestURLAlphaSearch(t *testing.T) {
	adaptor := &Adaptor{}
	info := &relaycommon.RelayInfo{
		ChannelMeta: &relaycommon.ChannelMeta{
			ChannelType:    constant.ChannelTypeCodex,
			ChannelBaseUrl: "https://chatgpt.com",
		},
		RelayMode: relayconstant.RelayModeAlphaSearch,
	}

	url, err := adaptor.GetRequestURL(info)
	require.NoError(t, err)
	assert.Equal(t, "https://chatgpt.com/backend-api/codex/alpha/search", url)
}

// The Codex backend rejects these fields, so the adaptor clears them rather
// than forwarding what the client sent.
func TestConvertOpenAIResponsesRequestDropsPenalties(t *testing.T) {
	adaptor := &Adaptor{}
	info := &relaycommon.RelayInfo{
		ChannelMeta: &relaycommon.ChannelMeta{ChannelType: constant.ChannelTypeCodex},
		RelayMode:   relayconstant.RelayModeResponses,
	}

	converted, err := adaptor.ConvertOpenAIResponsesRequest(nil, info, dto.OpenAIResponsesRequest{
		Model:            "gpt-5-codex",
		Input:            json.RawMessage(`"hello"`),
		MaxOutputTokens:  lo.ToPtr(uint(128)),
		Temperature:      lo.ToPtr(1.0),
		FrequencyPenalty: json.RawMessage(`1.5`),
		PresencePenalty:  json.RawMessage(`1.5`),
	})
	require.NoError(t, err)

	request, ok := converted.(dto.OpenAIResponsesRequest)
	require.True(t, ok)
	assert.Nil(t, request.MaxOutputTokens)
	assert.Nil(t, request.Temperature)
	assert.Nil(t, request.FrequencyPenalty)
	assert.Nil(t, request.PresencePenalty)
}

func TestConvertOpenAIResponsesRequestHistoricalWebSearch(t *testing.T) {
	const history = `[{"type":"web_search_call","id":"ws_history","status":"completed","action":{"type":"search","query":"synthetic"}},{"role":"user","content":"Summarize without tools."}]`
	for _, tc := range []struct {
		name       string
		tools      json.RawMessage
		choice     json.RawMessage
		input      json.RawMessage
		compact    bool
		wantRepair bool
	}{
		{name: "omitted tools", input: json.RawMessage(history), wantRepair: true},
		{name: "empty tools auto", tools: json.RawMessage(`[]`), choice: json.RawMessage(`"auto"`), input: json.RawMessage(history), wantRepair: true},
		{name: "null tools none", tools: json.RawMessage(`null`), choice: json.RawMessage(`"none"`), input: json.RawMessage(history), wantRepair: true},
		{name: "null choice", choice: json.RawMessage(`null`), input: json.RawMessage(history), wantRepair: true},
		{name: "existing functions unchanged", tools: json.RawMessage(`[{"type":"function","name":"work"}]`), input: json.RawMessage(history)},
		{name: "existing web search unchanged", tools: json.RawMessage(`[{"type":"web_search"}]`), input: json.RawMessage(history)},
		{name: "required choice unchanged", choice: json.RawMessage(`"required"`), input: json.RawMessage(history)},
		{name: "specific choice unchanged", choice: json.RawMessage(`{"type":"function","name":"work"}`), input: json.RawMessage(history)},
		{name: "no historical search", input: json.RawMessage(`[{"role":"user","content":"web_search_call is only text"}]`)},
		{name: "text input", input: json.RawMessage(`"hello"`)},
		{name: "malformed input unchanged", input: json.RawMessage(`[`)},
		{name: "malformed tools unchanged", tools: json.RawMessage(`{}`), input: json.RawMessage(history)},
		{name: "native compact unchanged", input: json.RawMessage(history), compact: true},
	} {
		t.Run(tc.name, func(t *testing.T) {
			mode := relayconstant.RelayModeResponses
			if tc.compact {
				mode = relayconstant.RelayModeResponsesCompact
			}
			info := &relaycommon.RelayInfo{ChannelMeta: &relaycommon.ChannelMeta{ChannelType: constant.ChannelTypeCodex}, RelayMode: mode}
			original := dto.OpenAIResponsesRequest{Model: "gpt-6-astra", Input: tc.input, Tools: tc.tools, ToolChoice: tc.choice}
			converted, err := (&Adaptor{}).ConvertOpenAIResponsesRequest(nil, info, original)
			require.NoError(t, err)
			request := converted.(dto.OpenAIResponsesRequest)
			assert.Equal(t, original.Input, request.Input, "history must never be removed or rewritten")
			if tc.wantRepair {
				assert.JSONEq(t, `[{"type":"web_search","external_web_access":false}]`, string(request.Tools))
				assert.JSONEq(t, `"none"`, string(request.ToolChoice), "compatibility must not enable new tool calls")
			} else {
				assert.Equal(t, original.Tools, request.Tools)
				assert.Equal(t, original.ToolChoice, request.ToolChoice)
			}
		})
	}
}
