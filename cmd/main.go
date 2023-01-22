package main

import (
	"context"
	"net"
	"net/http"

	protoUserService "coursework-grpc-golang/gen/go/api/users"
	"coursework-grpc-golang/internal/controller"
	"github.com/grpc-ecosystem/grpc-gateway/v2/runtime"
	"golang.org/x/sync/errgroup"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
)

const grpcHostPort = "0.0.0.0:8082"

func main() {
	grpcServer := grpc.NewServer()

	listen, err := net.Listen("tcp", grpcHostPort)
	if err != nil {
		panic(err)
	}

	protoUserService.RegisterUserServiceServer(
		grpcServer,
		controller.NewUserServer(protoUserService.UnimplementedUserServiceServer{}),
	)

	mux := runtime.NewServeMux()

	opts := []grpc.DialOption{grpc.WithTransportCredentials(insecure.NewCredentials())}

	err = protoUserService.RegisterUserServiceHandlerFromEndpoint(context.Background(), mux, grpcHostPort, opts)
	if err != nil {
		panic(err)
	}

	g, _ := errgroup.WithContext(context.Background())
	g.Go(func() (err error) {
		return grpcServer.Serve(listen)
	})
	g.Go(func() (err error) {
		return http.ListenAndServe(":8081", mux)
	})

	err = g.Wait()
	if err != nil {
		panic(err)
	}
}
