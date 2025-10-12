.intel_syntax noprefix
.global _start

.section .data
sockaddr_in:
        .family: .short 2
        .port: .short 0x5000
        .addr: .long 0
        .pad: .quad 0

http_ok: .ascii "HTTP/1.0 200 OK\r\n\r\n"
req: .short 0
# 0 = GET 1 = POST

.section .bss

.lcomm req_buf, 4096
.lcomm flag_buf, 256

.section .text
_start:

mov rax, 41             # socket(AF_INET, SOCK_STREAM, 0)
mov rdi, 2
mov rsi, 1
mov rdx, 0
syscall
mov r8, rax             # r8 => sockfd

mov rax, 49             # bind(sockfd, *addr, addrlen)
mov rdi, r8
lea rsi, [sockaddr_in]
mov rdx, 16
syscall

mov rax, 50             # listen(sockfd, backlog)
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

mov rax, 57             # fork()
syscall

cmp rax, 0

jg reset
jl reset

je child_proc

reset:
mov rax, 3              # close()
mov rdi, r9
syscall

jmp conn_loop

child_proc:

mov rax, 3              # close()
mov rdi, r8
syscall

mov rax, 0              # read()
mov rdi, r9
lea rsi, [req_buf]
mov rdx, 4096
syscall

mov r10, 0              # path start
mov r11, 0              # end pointer
mov r12, rax            # number of read bytes
mov r15, rax            # same

mov eax, dword ptr [req_buf]    # cursor to request
cmp eax, 0x20544547     # 'GET '
je set_get
jne set_post

set_get:
mov byte ptr [req], 0
jmp loop1

set_post:
mov byte ptr [req], 1
jmp loop1


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

cmp al, ' '
je parse_ok
cmp al, 0x0d
je parse_ok
cmp al, 0x0a
je parse_ok

inc rsi
dec r12

jmp loop2

parse_ok:
mov r11, rsi
mov byte ptr [r11], 0

#DIFFER HERE ACCORDING TO GET AND POST
cmp byte ptr [req], 0
je get
jne post

get:
mov rax, 2              # open(*filename, flags, mode)
mov rdi, r10
mov rsi, 0
mov rdx, 0
syscall
mov r13, rax            # file id

cmp r13, 0
jl parse_fail

mov rax, 0              # read()
mov rdi, r13
lea rsi, [flag_buf]
mov rdx, 256
syscall
mov r14, rax            # length

mov rax, 3              # close(fd)
mov rdi, r13
syscall

mov rax, 1              # write(fd, *buf, count)
mov rdi, r9
lea rsi, [http_ok]
mov rdx, 19
syscall

mov rax, 1              # write(fd, *buf, count)
mov rdi, r9
lea rsi, [flag_buf]
mov rdx, r14
syscall

jmp parse_fail          # not actually fail, we're just done here

post:
mov rax, 2              # open(*filename, flags, mode)
mov rdi, r10
mov rsi, 65
mov rdx, 511
syscall
mov r13, rax            # file id

cmp r13, 0
jl parse_fail

lea rsi, [req_buf]
find_header:

cmp r15, 4
jle parse_fail

mov eax, dword ptr [rsi]
cmp eax, 0x0a0d0a0d     # find '\r\n\r\n'

je header_found
inc rsi
dec r15
jmp find_header

header_found:
lea r14, [rsi+4]
sub r15, 4
mov rax, 1              # write(fd, *buf, count)
mov rdi, r13
lea rsi, [r14]
mov rdx, r15
syscall

mov rax, 3              # close(fd)
mov rdi, r13
syscall

mov rax, 1              # write(fd, *buf, count)
mov rdi, r9
lea rsi, [http_ok]
mov rdx, 19
syscall


parse_fail:

mov rax, 3              # close(fd)
mov rdi, r9
syscall

mov rax, 60             # exit(0)
mov rdi, 0
syscall
