package config

import (
    "log"
    "os"
    "strconv"
    "time"
    "github.com/joho/godotenv"
)

type Config struct {
    Port                  string
    CouchbaseEndpoint     string
    CouchbaseUsername     string
    CouchbasePassword     string
    CouchbaseBucket       string
    JWTSecret             string
    JWTAccessExpiry       time.Duration
    JWTRefreshExpiry      time.Duration
    BcryptCost            int
    CORSAllowedOrigins    []string
    Environment           string
}

func LoadConfig() *Config {
    if err := godotenv.Load(); err != nil {
        log.Println("No .env file found, using environment variables")
    }

    accessExpiry, _ := time.ParseDuration(getEnv("JWT_ACCESS_EXPIRY", "15m"))
    refreshExpiry, _ := time.ParseDuration(getEnv("JWT_REFRESH_EXPIRY", "7d"))
    bcryptCost, _ := strconv.Atoi(getEnv("BCRYPT_COST", "12"))

    return &Config{
        Port:               getEnv("PORT", "8080"),
        CouchbaseEndpoint:  getEnv("COUCHBASE_ENDPOINT", "couchbases://your-cluster.cloud.couchbase.com"),
        CouchbaseUsername:  getEnv("COUCHBASE_USERNAME", "your-username"),
        CouchbasePassword:  getEnv("COUCHBASE_PASSWORD", "your-password"),
        CouchbaseBucket:    getEnv("COUCHBASE_BUCKET", "your-bucket"),
        JWTSecret:          getEnv("JWT_SECRET", "default-secret-change-me"),
        JWTAccessExpiry:    accessExpiry,
        JWTRefreshExpiry:   refreshExpiry,
        BcryptCost:         bcryptCost,
        CORSAllowedOrigins: []string{getEnv("CORS_ALLOWED_ORIGINS", "http://localhost:4200")},
        Environment:        getEnv("ENVIRONMENT", "development"),
    }
}

func getEnv(key, defaultValue string) string {
    if value := os.Getenv(key); value != "" {
        return value
    }
    return defaultValue
}