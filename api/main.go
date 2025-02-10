// Copyright (c) 2021-2025 community-scripts ORG
// Author: Michel Roegl-Brunner (michelroegl-brunner)
// License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/gorilla/mux"
	"github.com/joho/godotenv"
	"github.com/rs/cors"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

var client *mongo.Client
var collection *mongo.Collection

func loadEnv() {
	if err := godotenv.Load(); err != nil {
		log.Fatal("Error loading .env file")
	}
}

type DataModel struct {
	ID         primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	CT_TYPE    uint               `json:"ct_type" bson:"ct_type"`
	DISK_SIZE  float32            `json:"disk_size" bson:"disk_size"`
	CORE_COUNT uint               `json:"core_count" bson:"core_count"`
	RAM_SIZE   uint               `json:"ram_size" bson:"ram_size"`
	OS_TYPE    string             `json:"os_type" bson:"os_type"`
	OS_VERSION string             `json:"os_version" bson:"os_version"`
	DISABLEIP6 string             `json:"disableip6" bson:"disableip6"`
	NSAPP      string             `json:"nsapp" bson:"nsapp"`
	METHOD     string             `json:"method" bson:"method"`
	CreatedAt  time.Time          `json:"created_at" bson:"created_at"`
	PVEVERSION string             `json:"pve_version" bson:"pve_version"`
	STATUS     string             `json:"status" bson:"status"`
	RANDOM_ID  string             `json:"random_id" bson:"random_id"`
	TYPE       string             `json:"type" bson:"type"`
	ERROR      string             `json:"error" bson:"error"`
}

type StatusModel struct {
	RANDOM_ID string `json:"random_id" bson:"random_id"`
	ERROR     string `json:"error" bson:"error"`
	STATUS    string `json:"status" bson:"status"`
}

func ConnectDatabase() {
	loadEnv()

	mongoURI := fmt.Sprintf("mongodb://%s:%s@%s:%s",
		os.Getenv("MONGO_USER"),
		os.Getenv("MONGO_PASSWORD"),
		os.Getenv("MONGO_IP"),
		os.Getenv("MONGO_PORT"))

	database := os.Getenv("MONGO_DATABASE")
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	var err error
	client, err = mongo.Connect(ctx, options.Client().ApplyURI(mongoURI))
	if err != nil {
		log.Fatal("Failed to connect to MongoDB!", err)
	}
	collection = client.Database(database).Collection("data_models")
	fmt.Println("Connected to MongoDB on 10.10.10.18")
}

func UploadJSON(w http.ResponseWriter, r *http.Request) {
	var input DataModel

	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}
	input.CreatedAt = time.Now()

	_, err := collection.InsertOne(context.Background(), input)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	log.Println("Received data:", input)
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(map[string]string{"message": "Data saved successfully"})
}

func UpdateStatus(w http.ResponseWriter, r *http.Request) {
	var input StatusModel

	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	filter := bson.M{"random_id": input.RANDOM_ID}
	update := bson.M{"$set": bson.M{"status": input.STATUS, "error": input.ERROR}}

	_, err := collection.UpdateOne(context.Background(), filter, update)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	log.Println("Updated data:", input)
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{"message": "Record updated successfully"})
}

func GetDataJSON(w http.ResponseWriter, r *http.Request) {
	var records []DataModel
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	cursor, err := collection.Find(ctx, bson.M{})
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer cursor.Close(ctx)

	for cursor.Next(ctx) {
		var record DataModel
		if err := cursor.Decode(&record); err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		records = append(records, record)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(records)
}

func main() {
	ConnectDatabase()

	router := mux.NewRouter()
	router.HandleFunc("/upload", UploadJSON).Methods("POST")
	router.HandleFunc("/upload/updatestatus", UpdateStatus).Methods("POST")
	router.HandleFunc("/data/json", GetDataJSON).Methods("GET")

	c := cors.New(cors.Options{
		AllowedOrigins:   []string{"*"},
		AllowedMethods:   []string{"GET", "POST"},
		AllowedHeaders:   []string{"Content-Type", "Authorization"},
		AllowCredentials: true,
	})

	handler := c.Handler(router)

	fmt.Println("Server running on port 8080")
	log.Fatal(http.ListenAndServe(":8080", handler))
}
