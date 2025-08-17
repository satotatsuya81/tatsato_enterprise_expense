package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/gin-gonic/gin"
)

func main() {
	// Graceful shutdown with context
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	// Configuration from environment
	port := os.Getenv("PORT")
	if port == "" {
		port = "8001"
	}

	ginMode := os.Getenv("GIN_MODE")
	if ginMode == "" {
		ginMode = "debug"
	}
	gin.SetMode(ginMode)

	// Router setup with basic middleware
	router := gin.New()
	router.Use(gin.Logger())
	router.Use(gin.Recovery())

	// Basic health check endpoint
	router.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status":  "ok",
			"service": "auth-service",
			"version": "1.0.0",
			"time":    time.Now().UTC(),
		})
	})

	// Basic API routes (placeholder)
	v1 := router.Group("/api/v1")
	{
		v1.GET("/", func(c *gin.Context) {
			c.JSON(http.StatusOK, gin.H{
				"message": "Auth Service API v1",
				"status":  "running",
			})
		})
	}

	// HTTP server configuration
	srv := &http.Server{
		Addr:         ":" + port,
		Handler:      router,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	// Start server in a goroutine
	go func() {
		log.Printf("🚀 Auth Service starting on port %s", port)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("❌ Server failed to start: %v", err)
		}
	}()

	// Wait for interrupt signal to gracefully shutdown the server
	<-ctx.Done()
	stop()
	log.Println("🛑 Shutting down server...")

	// Give outstanding requests a 5-second deadline to complete
	shutdownCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := srv.Shutdown(shutdownCtx); err != nil {
		log.Fatalf("❌ Server forced to shutdown: %v", err)
	}

	log.Println("✅ Server exited gracefully")
}