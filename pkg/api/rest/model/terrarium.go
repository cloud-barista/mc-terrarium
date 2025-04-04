package model

type TerrariumCreationRequest struct {
	Name        string `json:"name" default:"tr01" example:"tr01" validate:"required"`
	Description string `json:"description,omitempty" default:"This terrarium enriches ..." example:"This terrarium enriches ..."`
}

type TerrariumInfo struct {
	Name        string   `json:"name" default:"tr01" example:"tr01" validate:"required"`
	Description string   `json:"description,omitempty" default:"This terrarium enriches ..." example:"This terrarium enriches ..."`
	Id          string   `json:"id" default:"tr01" example:"tr01" validate:"required"`
	Enrichments string   `json:"enrichments,omitempty" default:"" example:"vpn/aws-to-site"`
	Providers   []string `json:"providers,omitempty" default:"" example:"aws,azure,gcp"`
}
