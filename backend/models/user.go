package models

import (
    "time"
)

type UserRole string

const (
    RoleSuperAdmin UserRole = "super_admin"
    RoleAdmin      UserRole = "admin"
    RoleUser       UserRole = "user"
)

type User struct {
    DocType   string    `json:"docType"`
    ID        string    `json:"id"`
    UserID    string    `json:"userId"`
    Username  string    `json:"username"`
    Email     string    `json:"email"`
    Password  string    `json:"password"`
    FullName  string    `json:"fullName"`
    Role      UserRole  `json:"role"`
    StateID   string    `json:"stateId,omitempty"`
    FacilityID string   `json:"facilityId,omitempty"`
    CreatedAt time.Time `json:"createdAt"`
    UpdatedAt time.Time `json:"updatedAt"`
    IsActive  bool      `json:"isActive"`
}

type UserResponse struct {
    ID         string    `json:"id"`
    UserID     string    `json:"userId"`
    Username   string    `json:"username"`
    Email      string    `json:"email"`
    FullName   string    `json:"fullName"`
    Role       UserRole  `json:"role"`
    StateID    string    `json:"stateId,omitempty"`
    FacilityID string    `json:"facilityId,omitempty"`
    CreatedAt  time.Time `json:"createdAt"`
}

func (u *User) ToResponse() UserResponse {
    return UserResponse{
        ID:         u.ID,
        UserID:     u.UserID,
        Username:   u.Username,
        Email:      u.Email,
        FullName:   u.FullName,
        Role:       u.Role,
        StateID:    u.StateID,
        FacilityID: u.FacilityID,
        CreatedAt:  u.CreatedAt,
    }
}