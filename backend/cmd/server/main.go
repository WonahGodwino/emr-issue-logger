package main

import (
    "context"
    "log"
    "net/http"
    "os"
    "os/signal"
    "syscall"
    "time"

    "github.com/WonahGodwino/emr-issue-logger/backend/config"
    "github.com/WonahGodwino/emr-issue-logger/backend/database"
    "github.com/WonahGodwino/emr-issue-logger/backend/routes"
)

func main() {
    cfg := config.LoadConfig()
    db := database.NewCouchbaseDB(cfg)
    defer db.Close()

    if err := db.EnsurePrimaryIndexes(context.Background()); err != nil {
        log.Printf("Warning: Failed to ensure primary indexes: %v", err)
    }

    if err := db.CreateIndexes(context.Background()); err != nil {
        log.Printf("Warning: Failed to create secondary indexes: %v", err)
    }

    if err := db.Seed(context.Background()); err != nil {
        log.Printf("Warning: Failed to seed data: %v", err)
    }

    router := routes.SetupRouter(cfg, db)

    srv := &http.Server{
        Addr:           ":" + cfg.Port,
        Handler:        router,
        ReadTimeout:    10 * time.Second,
        WriteTimeout:   10 * time.Second,
        MaxHeaderBytes: 1 << 20,
    }

    go func() {
        log.Printf("Server starting on port %s", cfg.Port)
        if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
            log.Fatalf("Failed to start server: %v", err)
        }
    }()

    quit := make(chan os.Signal, 1)
    signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
    <-quit

    log.Println("Shutting down server...")
    ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
    defer cancel()

    if err := srv.Shutdown(ctx); err != nil {
        log.Fatalf("Server forced to shutdown: %v", err)
    }
    log.Println("Server exited properly")
}