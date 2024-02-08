package models

type Response struct {
	Success bool   `json:"success" example:"true"`
	Message string `json:"message" example:"Any message"`
}
