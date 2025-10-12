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

conn_loop:

mov rax, 43             # accept()
mov rdi, r8
mov rsi, 0
mov rdx, 0
syscall
mov r9, rax

mov rax, 57
syscall

cmp rax, 0

jg reset
jl reset

je child_proc

reset:
mov rax, 3
mov rdi, r9
syscall

jmp conn_loop

child_proc:

mov rax, 3
mov rdi, r8
syscall

mov rax, 0x0            # read()
mov rdi, r9
lea rsi, [req_buf]
mov rdx, 4096
syscall

mov r10, 0              # path start
mov r11, 0              # end pointer
mov r12, rax            # number of bytes read
mov r15, rax
lea rsi, [req_buf]      # cursor to request


loop1:

test r12, r12
jz parse_fail
 
mov al, byte ptr [rsi]
inc rsi
dec r12

cmp al, ' '
jne loop1

mov r10, rsi            # path start


loop2:

test r12, r12
jz parse_fail

mov al, byte ptr [rsi]

cmp al, ' '             # jump to parse_ok if reached ' ' or other characters
je parse_ok
cmp al, 0x0d
je parse_ok
cmp al, 0x0a
je parse_ok

inc rsi
dec r12

jmp loop2

parse_ok:
mov r11, rsi            # r10 has a string of the URL path now
mov byte ptr [r11], 0   # terminating string

mov rax, 2              # open(char *filename, int flags, umode_t mode)
mov rdi, r10
mov rsi, 65
mov rdx, 511
syscall
mov r13, rax            # return value (>=0: file id. <0: open failed)

cmp r13, 0              # r13 = flag file
jl parse_fail


lea rsi, [req_buf]
find_header:
cmp r15, 4
jle parse_fail

mov eax, dword ptr [rsi]
cmp eax, 0x0a0d0a0d

je header_found
inc rsi
dec r15
jmp find_header


header_found:
lea r14, [rsi+4]
sub r15, 4
mov rax, 1
mov rdi, r13
lea rsi, [r14]
mov rdx, r15
syscall

mov rax, 3              # close (int fd)
mov rdi, r13
syscall

mov rax, 1              # write(int fd, char *buf, size_t count)
mov rdi, r9
lea rsi, [http_ok]
mov rdx, 19
syscall


parse_fail:

mov rax, 3              # close(int fd)
mov rdi, r9
syscall

mov rax, 60             # exit(0)
mov rdi, 0
syscall

