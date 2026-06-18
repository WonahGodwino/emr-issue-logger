package models

import (
    "time"
)

type TicketStatus string

const (
    StatusPending     TicketStatus = "pending"
    StatusUnderReview TicketStatus = "under-review"
    StatusInProgress  TicketStatus = "in-progress"
    StatusResolved    TicketStatus = "resolved"
    StatusEscalated   TicketStatus = "escalated"
)

type TicketCategory string

const (
    CategorySystemIssue   TicketCategory = "system-issue"
    CategoryDataIntegrity TicketCategory = "data-integrity"
    CategoryPerformance   TicketCategory = "performance"
    CategoryUIUX          TicketCategory = "ui-ux"
    CategoryIntegration   TicketCategory = "integration"
    CategoryOther         TicketCategory = "other"
)

type TicketModule string

const (
    ModuleEMR          TicketModule = "emr"
    ModulePharmacy      TicketModule = "pharmacy"
    ModuleLab           TicketModule = "lab"
    ModuleBilling       TicketModule = "billing"
    ModuleRegistration  TicketModule = "registration"
    ModuleReports       TicketModule = "reports"
    ModuleInventory     TicketModule = "inventory"
    ModuleOther         TicketModule = "other"
)

type StatusHistory struct {
    Status    TicketStatus `json:"status"`
    Timestamp time.Time    `json:"timestamp"`
    UpdatedBy string       `json:"updatedBy"`
    Note      string       `json:"note,omitempty"`
}

type Ticket struct {
    DocType           string          `json:"docType"`
    ID                string          `json:"id"`
    TicketID          string          `json:"ticketId"`
    Title             string          `json:"title"`
    Description       string          `json:"description"`
    Issue             string          `json:"issue"`
    Module            TicketModule    `json:"module"`
    ReporterUserID    string          `json:"reporterUserId"`
    FacilityID        string          `json:"facilityId"`
    StateID           string          `json:"stateId"`
    Category          TicketCategory  `json:"category"`
    OrderOfImpact     int             `json:"orderOfImpact"`
    IsNewRequirement  bool            `json:"isNewRequirement"`
    Status            TicketStatus    `json:"status"`
    StatusHistory     []StatusHistory `json:"statusHistory"`
    AssignedTo        string          `json:"assignedTo,omitempty"`
    ResolutionNotes   string          `json:"resolutionNotes,omitempty"`
    EscalationComment string          `json:"escalationComment,omitempty"`
    Screenshots       []string        `json:"screenshots,omitempty"`
    CreatedAt         time.Time       `json:"createdAt"`
    CreatedBy         string          `json:"createdBy"`
    UpdatedAt         time.Time       `json:"updatedAt"`
    UpdatedBy         string          `json:"updatedBy"`
    AdminUpdatedAt    *time.Time      `json:"adminUpdatedAt,omitempty"`
    UpdatedByAdmin    string          `json:"updatedByAdmin,omitempty"`
    ResolvedAt        *time.Time      `json:"resolvedAt,omitempty"`
    IsRecalled        bool            `json:"isRecalled"`
    RecalledAt        *time.Time      `json:"recalledAt,omitempty"`
    RecallReason      string          `json:"recallReason,omitempty"`
    StateName         string          `json:"stateName,omitempty"`
    FacilityName      string          `json:"facilityName,omitempty"`
    FacilityLGA       string          `json:"facilityLGA,omitempty"`
}

type TicketResponse struct {
    ID                string          `json:"id"`
    TicketID          string          `json:"ticketId"`
    Title             string          `json:"title"`
    Description       string          `json:"description"`
    Issue             string          `json:"issue"`
    Module            TicketModule    `json:"module"`
    ReporterUserID    string          `json:"reporterUserId"`
    FacilityID        string          `json:"facilityId"`
    StateID           string          `json:"stateId"`
    Category          TicketCategory  `json:"category"`
    OrderOfImpact     int             `json:"orderOfImpact"`
    IsNewRequirement  bool            `json:"isNewRequirement"`
    Status            TicketStatus    `json:"status"`
    StatusHistory     []StatusHistory `json:"statusHistory"`
    AssignedTo        string          `json:"assignedTo,omitempty"`
    ResolutionNotes   string          `json:"resolutionNotes,omitempty"`
    EscalationComment string          `json:"escalationComment,omitempty"`
    Screenshots       []string        `json:"screenshots,omitempty"`
    CreatedAt         time.Time       `json:"createdAt"`
    CreatedBy         string          `json:"createdBy"`
    UpdatedAt         time.Time       `json:"updatedAt"`
    UpdatedBy         string          `json:"updatedBy"`
    AdminUpdatedAt    *time.Time      `json:"adminUpdatedAt,omitempty"`
    UpdatedByAdmin    string          `json:"updatedByAdmin,omitempty"`
    ResolvedAt        *time.Time      `json:"resolvedAt,omitempty"`
    IsRecalled        bool            `json:"isRecalled"`
    RecalledAt        *time.Time      `json:"recalledAt,omitempty"`
    RecallReason      string          `json:"recallReason,omitempty"`
    StateName         string          `json:"stateName,omitempty"`
    FacilityName      string          `json:"facilityName,omitempty"`
    FacilityLGA       string          `json:"facilityLGA,omitempty"`
}

func (t *Ticket) ToResponse() TicketResponse {
    return TicketResponse{
        ID:                t.ID,
        TicketID:          t.TicketID,
        Title:             t.Title,
        Description:       t.Description,
        Issue:             t.Issue,
        Module:            t.Module,
        ReporterUserID:    t.ReporterUserID,
        FacilityID:        t.FacilityID,
        StateID:           t.StateID,
        Category:          t.Category,
        OrderOfImpact:     t.OrderOfImpact,
        IsNewRequirement:  t.IsNewRequirement,
        Status:            t.Status,
        StatusHistory:     t.StatusHistory,
        AssignedTo:        t.AssignedTo,
        ResolutionNotes:   t.ResolutionNotes,
        EscalationComment: t.EscalationComment,
        Screenshots:       t.Screenshots,
        CreatedAt:         t.CreatedAt,
        CreatedBy:         t.CreatedBy,
        UpdatedAt:         t.UpdatedAt,
        UpdatedBy:         t.UpdatedBy,
        AdminUpdatedAt:    t.AdminUpdatedAt,
        UpdatedByAdmin:    t.UpdatedByAdmin,
        ResolvedAt:        t.ResolvedAt,
        IsRecalled:        t.IsRecalled,
        RecalledAt:        t.RecalledAt,
        RecallReason:      t.RecallReason,
        StateName:         t.StateName,
        FacilityName:      t.FacilityName,
        FacilityLGA:       t.FacilityLGA,
    }
}