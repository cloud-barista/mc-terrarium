package models

type Response struct {
	Success bool   `json:"success" example:"true"`
	Text    string `json:"text" example:"Any text"`
}
