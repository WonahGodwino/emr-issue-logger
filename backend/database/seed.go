package database

import (
    "context"
    "log"
    "time"
    "github.com/WonahGodwino/emr-issue-logger/backend/models"
    "golang.org/x/crypto/bcrypt"
)

func (cb *CouchbaseDB) Seed(ctx context.Context) error {
    col := cb.Bucket.DefaultCollection()

    // Seed SUPER_ADMIN
    superAdminPass, _ := bcrypt.GenerateFromPassword([]byte("SuperAdmin@123"), bcrypt.DefaultCost)
    superAdmin := models.User{
        DocType:   "user",
        ID:        "user::SA-001",
        UserID:    "SA-001",
        Username:  "superadmin",
        Email:     "superadmin@emr.com",
        Password:  string(superAdminPass),
        FullName:  "Super Administrator",
        Role:      models.RoleSuperAdmin,
        CreatedAt: time.Now(),
        UpdatedAt: time.Now(),
        IsActive:  true,
    }
    if _, err := col.Upsert("user::SA-001", superAdmin, nil); err != nil {
        return err
    }
    log.Println("Super Admin user created successfully")

    // Seed default Admin
    adminPass, _ := bcrypt.GenerateFromPassword([]byte("Admin@123"), bcrypt.DefaultCost)
    admin := models.User{
        DocType:   "user",
        ID:        "user::ADMIN-001",
        UserID:    "ADMIN-001",
        Username:  "admin",
        Email:     "admin@emr.com",
        Password:  string(adminPass),
        FullName:  "System Administrator",
        Role:      models.RoleAdmin,
        CreatedAt: time.Now(),
        UpdatedAt: time.Now(),
        IsActive:  true,
    }
    if _, err := col.Upsert("user::ADMIN-001", admin, nil); err != nil {
        return err
    }
    log.Println("Admin user created successfully")
    return nil
}