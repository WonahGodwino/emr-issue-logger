package helpers

import (
    "errors"
    "time"
    "github.com/golang-jwt/jwt/v5"
)

type JWTClaims struct {
    UserID   string `json:"userId"`
    Email    string `json:"email"`
    Role     string `json:"role"`
    Username string `json:"username"`
    jwt.RegisteredClaims
}

func GenerateAccessToken(userID, email, role, username, secret string, expiry time.Duration) (string, error) {
    claims := JWTClaims{
        UserID:   userID,
        Email:    email,
        Role:     role,
        Username: username,
        RegisteredClaims: jwt.RegisteredClaims{
            ExpiresAt: jwt.NewNumericDate(time.Now().Add(expiry)),
            IssuedAt:  jwt.NewNumericDate(time.Now()),
        },
    }

    token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
    return token.SignedString([]byte(secret))
}

func ValidateToken(tokenString, secret string) (*JWTClaims, error) {
    token, err := jwt.ParseWithClaims(tokenString, &JWTClaims{}, func(token *jwt.Token) (interface{}, error) {
        if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
            return nil, errors.New("invalid signing method")
        }
        return []byte(secret), nil
    })

    if err != nil {
        return nil, err
    }

    if claims, ok := token.Claims.(*JWTClaims); ok && token.Valid {
        return claims, nil
    }

    return nil, errors.New("invalid token")
}
