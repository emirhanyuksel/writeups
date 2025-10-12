.intel_syntax noprefix
.global _start

_start:

mov rax, 41             # socket(AF_INET, SOCK_STREAM, 0)
mov rdi, 2              # bits/socket.h:#define PF_INET 2
mov rsi, 1              # bits/socket_type.h:   SOCK_STREAM = 1 
mov rdx, 0
syscall

mov rax, 60             # exit(0)
mov rdi, 0
syscall