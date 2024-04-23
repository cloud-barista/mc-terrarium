package models

type ResponseText struct {
	Success bool   `json:"success" example:"true"`
	Text    string `json:"text" example:"Any text"`
}

type ResponseList struct {
	Success bool          `json:"success" example:"true"`
	List    []interface{} `json:"list"`
}

type ResponseObject struct {
	Success bool                   `json:"success" example:"true"`
	Object  map[string]interface{} `json:"object"`
}
