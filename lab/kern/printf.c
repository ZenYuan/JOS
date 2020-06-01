// Simple implementation of cprintf console output for the kernel,
// based on printfmt() and the kernel console's cputchar().

#include <inc/types.h>
#include <inc/stdio.h>
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
	cputchar(ch);
	*cnt++;
}

int
vcprintf(const char *fmt, va_list ap)
{
	//记录写入字符个数
	int cnt = 0;

	vprintfmt((void*)putch, &cnt, fmt, ap);
	return cnt;
}

int
cprintf(const char *fmt, ...)
{
	va_list ap;
	int cnt;

	// 如果参数按顺序入栈导致先出栈ap的值，无法计算
	/*
	//cprintf("x %d, y %x, z %d\n", x, y);
	//stack layout
	 _______
	| 	z	|
	|	y	|
	|	x	|__ap point
	|	fmt	|__fmt point or next stack_base point
	|	ebp	|
	*/
    //va_start用于计算fmt的地址
	va_start(ap, fmt);
	cnt = vcprintf(fmt, ap);
	//va_end用于重置ap
	va_end(ap);

	return cnt;
}

