package models

import "time"

type State struct {
    DocType   string    `json:"docType"`
    ID        string    `json:"id"`
    StateID   string    `json:"stateId"`
    Name      string    `json:"name"`
    Code      string    `json:"code"`
    CreatedAt time.Time `json:"createdAt"`
    UpdatedAt time.Time `json:"updatedAt"`
}