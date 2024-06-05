package model

type TerrariumInfo struct {
	Id          string `json:"id" default:"tr01" example:"tr01" validate:"required"`
	Description string `json:"description,omitempty" default:"This terrarium enriches ..." example:"This terrarium enriches ..."`
	Enrichments string `json:"enrichments,omitempty"`
}
