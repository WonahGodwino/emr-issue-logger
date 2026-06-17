package models

import "time"

type Facility struct {
    DocType    string    `json:"docType"`
    ID         string    `json:"id"`
    FacilityID string    `json:"facilityId"`
    StateID    string    `json:"stateId"`
    Name       string    `json:"name"`
    Code       string    `json:"code"`
    Type       string    `json:"type"`
    LGA        string    `json:"lga"`
    CreatedAt  time.Time `json:"createdAt"`
    UpdatedAt  time.Time `json:"updatedAt"`
}
