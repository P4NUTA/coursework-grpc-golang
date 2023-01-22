package controller

import (
	"context"

	proto_user_service "coursework-grpc-golang/gen/go/api/users"
)

type UserServer struct {
	proto_user_service.UnimplementedUserServiceServer
}

func NewUserServer(unimplementedUserServiceServer proto_user_service.UnimplementedUserServiceServer) *UserServer {
	return &UserServer{UnimplementedUserServiceServer: unimplementedUserServiceServer}
}

func (s *UserServer) GetUser(
	ctx context.Context,
	req *proto_user_service.GetUserRequest,
) (*proto_user_service.GetUserResponse, error) {
	u := &proto_user_service.GetUserResponse_User{
		Id:    1,
		Login: "login",
		Email: "user@user.com",
	}

	return &proto_user_service.GetUserResponse{
		User: u,
	}, nil
}
