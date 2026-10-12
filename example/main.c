#include <grpc/grpc.h>
#include <stdio.h>

int main(void) {
    grpc_init();
    printf("gRPC core %s (from C)\n", grpc_version_string());
    grpc_shutdown();
    return 0;
}
