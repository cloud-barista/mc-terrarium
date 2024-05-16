package model

// type ResponseText struct {
// 	Success bool   `json:"success" example:"true"`
// 	Text    string `json:"text" example:"Any text"`
// }

// type ResponseTextWithDetails struct {
// 	Success bool   `json:"success" example:"true"`
// 	Text    string `json:"text" example:"Any text"`
// 	Details string `json:"details" example:"Any details"`
// }

// type ResponseList struct {
// 	Success bool          `json:"success" example:"true"`
// 	List    []interface{} `json:"list"`
// }

// type ResponseObject struct {
// 	Success bool                   `json:"success" example:"true"`
// 	Object  map[string]interface{} `json:"object"`
// }

type Response struct {
	Success bool                   `json:"success" example:"true"`
	Text    string                 `json:"text" example:"Any text"`
	Detail  string                 `json:"details,omitempty" example:"Any details"`
	Object  map[string]interface{} `json:"object,omitempty"`
	List    []interface{}          `json:"list,omitempty"`
}
