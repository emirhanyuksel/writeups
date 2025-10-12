.intel_syntax noprefix
.global _start



.section .data
sockaddr_in:            # struct sockaddr_in {uint16_t  sin_family; uint16_t  sin_port; uint32_t  sin_addr; uint8_t   __pad[8];}
        .family: .short 2
        .port: .short 0x5000
        .addr: .long 0
        .pad: .quad 0

http_ok: .ascii "HTTP/1.0 200 OK\r\n\r\n"

.section .bss

.lcomm req_buf, 4096

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

mov rax, 50             # listen(int sockfd, int backlog)
mov rdi, r8
mov rsi, 0
syscall

mov rax, 43             # accept(?)
mov rdi, r8
mov rsi, 0
mov rdx, 0
syscall

mov r9, rax
mov rax, 0x0            # read()
mov rdi, r9
lea rsi, [req_buf]
mov rdx, 4096
syscall

mov rax, 1              # write(int fd, char *buf, size_t count)
mov rdi, r9
lea rsi, [http_ok]
mov rdx, 19
syscall

mov rax, 3              # close(int fd)
mov rdi, r9
syscall


mov rax, 60             # exit(0)
mov rdi, 0
syscall
