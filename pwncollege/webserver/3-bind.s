.intel_syntax noprefix
.global _start

.section .data
sockaddr_in:            # struct sockaddr_in {uint16_t  sin_family; uint16_t  sin_port; uint32_t  sin_addr; uint8_t   __pad[8];}
        .family: .short 2
        .port: .short 0x5000
        .addr: .long 0
        .pad: .quad 0

.section .text
_start:

mov rax, 41             # socket(AF_INET, SOCK_STREAM, 0)
mov rdi, 2              # bits/socket.h:#define PF_INET 2
mov rsi, 1              # bits/socket_type.h:   SOCK_STREAM = 1 
mov rdx, 0
syscall


mov r8, rax             # socket returns sockfd in rax, writing to rdi
mov rax, 49             # bind(int sockfd, const struct sockaddr *addr, socklen_t addrlen);
mov rdi, r8
lea rsi, [sockaddr_in]           
mov rdx, 16
syscall

mov rax, 60             # exit(0)
mov rdi, 0
syscall