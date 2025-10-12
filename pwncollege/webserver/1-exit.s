.intel_syntax noprefix
.global _start

_start:

mov rax, 60             #exit syscall
mov rdi, 0
syscall