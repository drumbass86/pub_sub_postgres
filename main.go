package main

import (
	"context"
	"fmt"
	"os"
	"time"

	"github.com/jackc/pgx/v4"
	"github.com/lib/pq"
)

func main() {
	// urlExample := ""
	connInfo := "postgres://user:123qwe@172.17.0.2:5432/iot_jobs"
	iotDB, err := pgx.Connect(context.Background(), connInfo)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Unable to connect to database: %v\n", err)
		os.Exit(1)
	}
	defer iotDB.Close(context.Background())

	reportErrInListener := func(event pq.ListenerEventType, err error) {
		if err != nil {
			fmt.Printf("In event:%v error:%v", event, err.Error())
		}
	}
	connPq := "host=172.17.0.2 port=5432 user=user password=123qwe dbname=iot_jobs sslmode=disable"
	listener := pq.NewListener(connPq, 10*time.Second, time.Minute,
		reportErrInListener)
	err = listener.Listen("req_jobs_status_channel")
	if err != nil {
		panic(err)
	}

	fmt.Println("Start monitoring requests from PostgreSQL...")
	tryGetRequest := make(chan interface{})
	go func() {
		for req := range listener.Notify {
			fmt.Println("Received data from channel [", req.Channel, "] :", req.Extra)
			select {
			case tryGetRequest <- req.Extra:
			}
		}
		close(tryGetRequest)
	}()

	for req := range tryGetRequest {
		fmt.Printf("Receive request id:%v", req.(string))
		// query := fmt.Sprintf(`UPDATE req_jobs SET status='processing'
		// 	WHERE id = %s AND status='new' RETURNING *;`, req.(string))
		// var (
		// 	req_id int
		// )
		// errRow := iotDB.QueryRow(context.Background(), query).Scan(&req_id)
		// if errRow != nil {
		// 	fmt.Printf("Error when update status! Err:%v Query: %s", errRow, query)
		// } else {
		// 	fmt.Printf("Update status! Request_id: %v", req_id)
		// }
	}
}
