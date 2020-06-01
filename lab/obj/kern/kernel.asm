
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4 66                	in     $0x66,%al

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 00 11 00       	mov    $0x110000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 00 11 f0       	mov    $0xf0110000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 56 00 00 00       	call   f0100094 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <test_backtrace>:
#include <kern/console.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 0c             	sub    $0xc,%esp
f0100047:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("entering test_backtrace %d\n", x);
f010004a:	53                   	push   %ebx
f010004b:	68 40 18 10 f0       	push   $0xf0101840
f0100050:	e8 8c 08 00 00       	call   f01008e1 <cprintf>
	if (x > 0)
f0100055:	83 c4 10             	add    $0x10,%esp
f0100058:	85 db                	test   %ebx,%ebx
f010005a:	7e 25                	jle    f0100081 <test_backtrace+0x41>
		test_backtrace(x-1);
f010005c:	83 ec 0c             	sub    $0xc,%esp
f010005f:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0100062:	50                   	push   %eax
f0100063:	e8 d8 ff ff ff       	call   f0100040 <test_backtrace>
f0100068:	83 c4 10             	add    $0x10,%esp
	else
		mon_backtrace(0, 0, 0);
	cprintf("leaving test_backtrace %d\n", x);
f010006b:	83 ec 08             	sub    $0x8,%esp
f010006e:	53                   	push   %ebx
f010006f:	68 5c 18 10 f0       	push   $0xf010185c
f0100074:	e8 68 08 00 00       	call   f01008e1 <cprintf>
}
f0100079:	83 c4 10             	add    $0x10,%esp
f010007c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010007f:	c9                   	leave  
f0100080:	c3                   	ret    
{
	cprintf("entering test_backtrace %d\n", x);
	if (x > 0)
		test_backtrace(x-1);
	else
		mon_backtrace(0, 0, 0);
f0100081:	83 ec 04             	sub    $0x4,%esp
f0100084:	6a 00                	push   $0x0
f0100086:	6a 00                	push   $0x0
f0100088:	6a 00                	push   $0x0
f010008a:	e8 cd 06 00 00       	call   f010075c <mon_backtrace>
f010008f:	83 c4 10             	add    $0x10,%esp
f0100092:	eb d7                	jmp    f010006b <test_backtrace+0x2b>

f0100094 <i386_init>:
	cprintf("leaving test_backtrace %d\n", x);
}

void
i386_init(void)
{
f0100094:	55                   	push   %ebp
f0100095:	89 e5                	mov    %esp,%ebp
f0100097:	83 ec 0c             	sub    $0xc,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f010009a:	b8 40 29 11 f0       	mov    $0xf0112940,%eax
f010009f:	2d 00 23 11 f0       	sub    $0xf0112300,%eax
f01000a4:	50                   	push   %eax
f01000a5:	6a 00                	push   $0x0
f01000a7:	68 00 23 11 f0       	push   $0xf0112300
f01000ac:	e8 3a 13 00 00       	call   f01013eb <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000b1:	e8 98 04 00 00       	call   f010054e <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000b6:	83 c4 08             	add    $0x8,%esp
f01000b9:	68 ac 1a 00 00       	push   $0x1aac
f01000be:	68 77 18 10 f0       	push   $0xf0101877
f01000c3:	e8 19 08 00 00       	call   f01008e1 <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000c8:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000cf:	e8 6c ff ff ff       	call   f0100040 <test_backtrace>
f01000d4:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000d7:	83 ec 0c             	sub    $0xc,%esp
f01000da:	6a 00                	push   $0x0
f01000dc:	e8 81 06 00 00       	call   f0100762 <monitor>
f01000e1:	83 c4 10             	add    $0x10,%esp
f01000e4:	eb f1                	jmp    f01000d7 <i386_init+0x43>

f01000e6 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000e6:	55                   	push   %ebp
f01000e7:	89 e5                	mov    %esp,%ebp
f01000e9:	56                   	push   %esi
f01000ea:	53                   	push   %ebx
f01000eb:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f01000ee:	83 3d 44 29 11 f0 00 	cmpl   $0x0,0xf0112944
f01000f5:	74 0f                	je     f0100106 <_panic+0x20>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000f7:	83 ec 0c             	sub    $0xc,%esp
f01000fa:	6a 00                	push   $0x0
f01000fc:	e8 61 06 00 00       	call   f0100762 <monitor>
f0100101:	83 c4 10             	add    $0x10,%esp
f0100104:	eb f1                	jmp    f01000f7 <_panic+0x11>
{
	va_list ap;

	if (panicstr)
		goto dead;
	panicstr = fmt;
f0100106:	89 35 44 29 11 f0    	mov    %esi,0xf0112944

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f010010c:	fa                   	cli    
f010010d:	fc                   	cld    

	va_start(ap, fmt);
f010010e:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f0100111:	83 ec 04             	sub    $0x4,%esp
f0100114:	ff 75 0c             	pushl  0xc(%ebp)
f0100117:	ff 75 08             	pushl  0x8(%ebp)
f010011a:	68 92 18 10 f0       	push   $0xf0101892
f010011f:	e8 bd 07 00 00       	call   f01008e1 <cprintf>
	vcprintf(fmt, ap);
f0100124:	83 c4 08             	add    $0x8,%esp
f0100127:	53                   	push   %ebx
f0100128:	56                   	push   %esi
f0100129:	e8 8d 07 00 00       	call   f01008bb <vcprintf>
	cprintf("\n");
f010012e:	c7 04 24 ce 18 10 f0 	movl   $0xf01018ce,(%esp)
f0100135:	e8 a7 07 00 00       	call   f01008e1 <cprintf>
f010013a:	83 c4 10             	add    $0x10,%esp
f010013d:	eb b8                	jmp    f01000f7 <_panic+0x11>

f010013f <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f010013f:	55                   	push   %ebp
f0100140:	89 e5                	mov    %esp,%ebp
f0100142:	53                   	push   %ebx
f0100143:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100146:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100149:	ff 75 0c             	pushl  0xc(%ebp)
f010014c:	ff 75 08             	pushl  0x8(%ebp)
f010014f:	68 aa 18 10 f0       	push   $0xf01018aa
f0100154:	e8 88 07 00 00       	call   f01008e1 <cprintf>
	vcprintf(fmt, ap);
f0100159:	83 c4 08             	add    $0x8,%esp
f010015c:	53                   	push   %ebx
f010015d:	ff 75 10             	pushl  0x10(%ebp)
f0100160:	e8 56 07 00 00       	call   f01008bb <vcprintf>
	cprintf("\n");
f0100165:	c7 04 24 ce 18 10 f0 	movl   $0xf01018ce,(%esp)
f010016c:	e8 70 07 00 00       	call   f01008e1 <cprintf>
	va_end(ap);
}
f0100171:	83 c4 10             	add    $0x10,%esp
f0100174:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100177:	c9                   	leave  
f0100178:	c3                   	ret    
f0100179:	00 00                	add    %al,(%eax)
	...

f010017c <serial_proc_data>:
//only use with %edx,%eax register
static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010017c:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100181:	ec                   	in     (%dx),%al
static bool serial_exists;

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100182:	a8 01                	test   $0x1,%al
f0100184:	74 0a                	je     f0100190 <serial_proc_data+0x14>
f0100186:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010018b:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f010018c:	0f b6 c0             	movzbl %al,%eax
f010018f:	c3                   	ret    

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100190:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f0100195:	c3                   	ret    

f0100196 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100196:	55                   	push   %ebp
f0100197:	89 e5                	mov    %esp,%ebp
f0100199:	53                   	push   %ebx
f010019a:	83 ec 04             	sub    $0x4,%esp
f010019d:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f010019f:	ff d3                	call   *%ebx
f01001a1:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001a4:	74 29                	je     f01001cf <cons_intr+0x39>
		if (c == 0)
f01001a6:	85 c0                	test   %eax,%eax
f01001a8:	74 f5                	je     f010019f <cons_intr+0x9>
			continue;
		cons.buf[cons.wpos++] = c;
f01001aa:	8b 0d 24 25 11 f0    	mov    0xf0112524,%ecx
f01001b0:	8d 51 01             	lea    0x1(%ecx),%edx
f01001b3:	88 81 20 23 11 f0    	mov    %al,-0xfeedce0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f01001b9:	81 fa 00 02 00 00    	cmp    $0x200,%edx
			cons.wpos = 0;
f01001bf:	b8 00 00 00 00       	mov    $0x0,%eax
f01001c4:	0f 44 d0             	cmove  %eax,%edx
f01001c7:	89 15 24 25 11 f0    	mov    %edx,0xf0112524
f01001cd:	eb d0                	jmp    f010019f <cons_intr+0x9>
	}
}
f01001cf:	83 c4 04             	add    $0x4,%esp
f01001d2:	5b                   	pop    %ebx
f01001d3:	5d                   	pop    %ebp
f01001d4:	c3                   	ret    

f01001d5 <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01001d5:	55                   	push   %ebp
f01001d6:	89 e5                	mov    %esp,%ebp
f01001d8:	53                   	push   %ebx
f01001d9:	83 ec 04             	sub    $0x4,%esp
f01001dc:	ba 64 00 00 00       	mov    $0x64,%edx
f01001e1:	ec                   	in     (%dx),%al
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
f01001e2:	a8 01                	test   $0x1,%al
f01001e4:	0f 84 f2 00 00 00    	je     f01002dc <kbd_proc_data+0x107>
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
f01001ea:	a8 20                	test   $0x20,%al
f01001ec:	0f 85 f1 00 00 00    	jne    f01002e3 <kbd_proc_data+0x10e>
f01001f2:	ba 60 00 00 00       	mov    $0x60,%edx
f01001f7:	ec                   	in     (%dx),%al
f01001f8:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01001fa:	3c e0                	cmp    $0xe0,%al
f01001fc:	74 61                	je     f010025f <kbd_proc_data+0x8a>
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f01001fe:	84 c0                	test   %al,%al
f0100200:	78 70                	js     f0100272 <kbd_proc_data+0x9d>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
		shift &= ~(shiftcode[data] | E0ESC);
		return 0;
	} else if (shift & E0ESC) {
f0100202:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f0100208:	f6 c1 40             	test   $0x40,%cl
f010020b:	74 0e                	je     f010021b <kbd_proc_data+0x46>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f010020d:	83 c8 80             	or     $0xffffff80,%eax
f0100210:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100212:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100215:	89 0d 00 23 11 f0    	mov    %ecx,0xf0112300
	}

	shift |= shiftcode[data];
f010021b:	0f b6 d2             	movzbl %dl,%edx
f010021e:	0f b6 82 20 1a 10 f0 	movzbl -0xfefe5e0(%edx),%eax
f0100225:	0b 05 00 23 11 f0    	or     0xf0112300,%eax
	shift ^= togglecode[data];
f010022b:	0f b6 8a 20 19 10 f0 	movzbl -0xfefe6e0(%edx),%ecx
f0100232:	31 c8                	xor    %ecx,%eax
f0100234:	a3 00 23 11 f0       	mov    %eax,0xf0112300

	c = charcode[shift & (CTL | SHIFT)][data];
f0100239:	89 c1                	mov    %eax,%ecx
f010023b:	83 e1 03             	and    $0x3,%ecx
f010023e:	8b 0c 8d 00 19 10 f0 	mov    -0xfefe700(,%ecx,4),%ecx
f0100245:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100249:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f010024c:	a8 08                	test   $0x8,%al
f010024e:	74 61                	je     f01002b1 <kbd_proc_data+0xdc>
		if ('a' <= c && c <= 'z')
f0100250:	89 da                	mov    %ebx,%edx
f0100252:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100255:	83 f9 19             	cmp    $0x19,%ecx
f0100258:	77 4b                	ja     f01002a5 <kbd_proc_data+0xd0>
			c += 'A' - 'a';
f010025a:	83 eb 20             	sub    $0x20,%ebx
f010025d:	eb 0c                	jmp    f010026b <kbd_proc_data+0x96>

	data = inb(KBDATAP);

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
f010025f:	83 0d 00 23 11 f0 40 	orl    $0x40,0xf0112300
		return 0;
f0100266:	bb 00 00 00 00       	mov    $0x0,%ebx
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f010026b:	89 d8                	mov    %ebx,%eax
f010026d:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100270:	c9                   	leave  
f0100271:	c3                   	ret    
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f0100272:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f0100278:	89 cb                	mov    %ecx,%ebx
f010027a:	83 e3 40             	and    $0x40,%ebx
f010027d:	83 e0 7f             	and    $0x7f,%eax
f0100280:	85 db                	test   %ebx,%ebx
f0100282:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100285:	0f b6 d2             	movzbl %dl,%edx
f0100288:	0f b6 82 20 1a 10 f0 	movzbl -0xfefe5e0(%edx),%eax
f010028f:	83 c8 40             	or     $0x40,%eax
f0100292:	0f b6 c0             	movzbl %al,%eax
f0100295:	f7 d0                	not    %eax
f0100297:	21 c8                	and    %ecx,%eax
f0100299:	a3 00 23 11 f0       	mov    %eax,0xf0112300
		return 0;
f010029e:	bb 00 00 00 00       	mov    $0x0,%ebx
f01002a3:	eb c6                	jmp    f010026b <kbd_proc_data+0x96>

	c = charcode[shift & (CTL | SHIFT)][data];
	if (shift & CAPSLOCK) {
		if ('a' <= c && c <= 'z')
			c += 'A' - 'a';
		else if ('A' <= c && c <= 'Z')
f01002a5:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01002a8:	8d 4b 20             	lea    0x20(%ebx),%ecx
f01002ab:	83 fa 1a             	cmp    $0x1a,%edx
f01002ae:	0f 42 d9             	cmovb  %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002b1:	f7 d0                	not    %eax
f01002b3:	a8 06                	test   $0x6,%al
f01002b5:	75 b4                	jne    f010026b <kbd_proc_data+0x96>
f01002b7:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01002bd:	75 ac                	jne    f010026b <kbd_proc_data+0x96>
		cprintf("Rebooting!\n");
f01002bf:	83 ec 0c             	sub    $0xc,%esp
f01002c2:	68 c4 18 10 f0       	push   $0xf01018c4
f01002c7:	e8 15 06 00 00       	call   f01008e1 <cprintf>
//to io one char
//only use of %eax %edx
static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002cc:	b8 03 00 00 00       	mov    $0x3,%eax
f01002d1:	ba 92 00 00 00       	mov    $0x92,%edx
f01002d6:	ee                   	out    %al,(%dx)
f01002d7:	83 c4 10             	add    $0x10,%esp
f01002da:	eb 8f                	jmp    f010026b <kbd_proc_data+0x96>
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
f01002dc:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
f01002e1:	eb 88                	jmp    f010026b <kbd_proc_data+0x96>
	// Ignore data from mouse.
	if (stat & KBS_TERR)
		return -1;
f01002e3:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
f01002e8:	eb 81                	jmp    f010026b <kbd_proc_data+0x96>

f01002ea <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01002ea:	55                   	push   %ebp
f01002eb:	89 e5                	mov    %esp,%ebp
f01002ed:	57                   	push   %edi
f01002ee:	56                   	push   %esi
f01002ef:	53                   	push   %ebx
f01002f0:	83 ec 1c             	sub    $0x1c,%esp
f01002f3:	89 c1                	mov    %eax,%ecx

static void
serial_putc(int c)
{
	int i;
	for (i = 0;
f01002f5:	be 00 00 00 00       	mov    $0x0,%esi
//only use with %edx,%eax register
static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002fa:	bf fd 03 00 00       	mov    $0x3fd,%edi
f01002ff:	bb 84 00 00 00       	mov    $0x84,%ebx
f0100304:	89 fa                	mov    %edi,%edx
f0100306:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100307:	a8 20                	test   $0x20,%al
f0100309:	75 13                	jne    f010031e <cons_putc+0x34>
f010030b:	81 fe ff 31 00 00    	cmp    $0x31ff,%esi
f0100311:	7f 0b                	jg     f010031e <cons_putc+0x34>
f0100313:	89 da                	mov    %ebx,%edx
f0100315:	ec                   	in     (%dx),%al
f0100316:	ec                   	in     (%dx),%al
f0100317:	ec                   	in     (%dx),%al
f0100318:	ec                   	in     (%dx),%al
	     i++)
f0100319:	83 c6 01             	add    $0x1,%esi
f010031c:	eb e6                	jmp    f0100304 <cons_putc+0x1a>
		delay();

	outb(COM1 + COM_TX, c);
f010031e:	88 4d e7             	mov    %cl,-0x19(%ebp)
//to io one char
//only use of %eax %edx
static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100321:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100326:	89 c8                	mov    %ecx,%eax
f0100328:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100329:	be 00 00 00 00       	mov    $0x0,%esi
//only use with %edx,%eax register
static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010032e:	bf 79 03 00 00       	mov    $0x379,%edi
f0100333:	bb 84 00 00 00       	mov    $0x84,%ebx
f0100338:	89 fa                	mov    %edi,%edx
f010033a:	ec                   	in     (%dx),%al
f010033b:	81 fe ff 31 00 00    	cmp    $0x31ff,%esi
f0100341:	7f 0f                	jg     f0100352 <cons_putc+0x68>
f0100343:	84 c0                	test   %al,%al
f0100345:	78 0b                	js     f0100352 <cons_putc+0x68>
f0100347:	89 da                	mov    %ebx,%edx
f0100349:	ec                   	in     (%dx),%al
f010034a:	ec                   	in     (%dx),%al
f010034b:	ec                   	in     (%dx),%al
f010034c:	ec                   	in     (%dx),%al
f010034d:	83 c6 01             	add    $0x1,%esi
f0100350:	eb e6                	jmp    f0100338 <cons_putc+0x4e>
//to io one char
//only use of %eax %edx
static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100352:	ba 78 03 00 00       	mov    $0x378,%edx
f0100357:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f010035b:	ee                   	out    %al,(%dx)
f010035c:	ba 7a 03 00 00       	mov    $0x37a,%edx
f0100361:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100366:	ee                   	out    %al,(%dx)
f0100367:	b8 08 00 00 00       	mov    $0x8,%eax
f010036c:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f010036d:	89 ca                	mov    %ecx,%edx
f010036f:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100375:	89 c8                	mov    %ecx,%eax
f0100377:	80 cc 07             	or     $0x7,%ah
f010037a:	85 d2                	test   %edx,%edx
f010037c:	0f 44 c8             	cmove  %eax,%ecx

	switch (c & 0xff) {
f010037f:	0f b6 c1             	movzbl %cl,%eax
f0100382:	83 f8 09             	cmp    $0x9,%eax
f0100385:	0f 84 b0 00 00 00    	je     f010043b <cons_putc+0x151>
f010038b:	7e 73                	jle    f0100400 <cons_putc+0x116>
f010038d:	83 f8 0a             	cmp    $0xa,%eax
f0100390:	0f 84 98 00 00 00    	je     f010042e <cons_putc+0x144>
f0100396:	83 f8 0d             	cmp    $0xd,%eax
f0100399:	0f 85 d3 00 00 00    	jne    f0100472 <cons_putc+0x188>
		break;
	case '\n':
		crt_pos += CRT_COLS;
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f010039f:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f01003a6:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003ac:	c1 e8 16             	shr    $0x16,%eax
f01003af:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003b2:	c1 e0 04             	shl    $0x4,%eax
f01003b5:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
		break;
	}
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f01003bb:	66 81 3d 28 25 11 f0 	cmpw   $0x7cf,0xf0112528
f01003c2:	cf 07 
f01003c4:	0f 87 cb 00 00 00    	ja     f0100495 <cons_putc+0x1ab>
			crt_buf[i] = 0; //0x0700 | ' ';
		crt_pos -= CRT_COLS;
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f01003ca:	8b 0d 30 25 11 f0    	mov    0xf0112530,%ecx
f01003d0:	b8 0e 00 00 00       	mov    $0xe,%eax
f01003d5:	89 ca                	mov    %ecx,%edx
f01003d7:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01003d8:	0f b7 1d 28 25 11 f0 	movzwl 0xf0112528,%ebx
f01003df:	8d 71 01             	lea    0x1(%ecx),%esi
f01003e2:	89 d8                	mov    %ebx,%eax
f01003e4:	66 c1 e8 08          	shr    $0x8,%ax
f01003e8:	89 f2                	mov    %esi,%edx
f01003ea:	ee                   	out    %al,(%dx)
f01003eb:	b8 0f 00 00 00       	mov    $0xf,%eax
f01003f0:	89 ca                	mov    %ecx,%edx
f01003f2:	ee                   	out    %al,(%dx)
f01003f3:	89 d8                	mov    %ebx,%eax
f01003f5:	89 f2                	mov    %esi,%edx
f01003f7:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01003f8:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01003fb:	5b                   	pop    %ebx
f01003fc:	5e                   	pop    %esi
f01003fd:	5f                   	pop    %edi
f01003fe:	5d                   	pop    %ebp
f01003ff:	c3                   	ret    
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
		c |= 0x0700;

	switch (c & 0xff) {
f0100400:	83 f8 08             	cmp    $0x8,%eax
f0100403:	75 6d                	jne    f0100472 <cons_putc+0x188>
	case '\b':
		if (crt_pos > 0) {
f0100405:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f010040c:	66 85 c0             	test   %ax,%ax
f010040f:	74 b9                	je     f01003ca <cons_putc+0xe0>
			crt_pos--;
f0100411:	83 e8 01             	sub    $0x1,%eax
f0100414:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f010041a:	0f b7 c0             	movzwl %ax,%eax
f010041d:	b1 00                	mov    $0x0,%cl
f010041f:	83 c9 20             	or     $0x20,%ecx
f0100422:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f0100428:	66 89 0c 42          	mov    %cx,(%edx,%eax,2)
f010042c:	eb 8d                	jmp    f01003bb <cons_putc+0xd1>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f010042e:	66 83 05 28 25 11 f0 	addw   $0x50,0xf0112528
f0100435:	50 
f0100436:	e9 64 ff ff ff       	jmp    f010039f <cons_putc+0xb5>
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
		break;
	case '\t':
		cons_putc(' ');
f010043b:	b8 20 00 00 00       	mov    $0x20,%eax
f0100440:	e8 a5 fe ff ff       	call   f01002ea <cons_putc>
		cons_putc(' ');
f0100445:	b8 20 00 00 00       	mov    $0x20,%eax
f010044a:	e8 9b fe ff ff       	call   f01002ea <cons_putc>
		cons_putc(' ');
f010044f:	b8 20 00 00 00       	mov    $0x20,%eax
f0100454:	e8 91 fe ff ff       	call   f01002ea <cons_putc>
		cons_putc(' ');
f0100459:	b8 20 00 00 00       	mov    $0x20,%eax
f010045e:	e8 87 fe ff ff       	call   f01002ea <cons_putc>
		cons_putc(' ');
f0100463:	b8 20 00 00 00       	mov    $0x20,%eax
f0100468:	e8 7d fe ff ff       	call   f01002ea <cons_putc>
f010046d:	e9 49 ff ff ff       	jmp    f01003bb <cons_putc+0xd1>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100472:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f0100479:	8d 50 01             	lea    0x1(%eax),%edx
f010047c:	66 89 15 28 25 11 f0 	mov    %dx,0xf0112528
f0100483:	0f b7 c0             	movzwl %ax,%eax
f0100486:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f010048c:	66 89 0c 42          	mov    %cx,(%edx,%eax,2)
f0100490:	e9 26 ff ff ff       	jmp    f01003bb <cons_putc+0xd1>
	}
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100495:	a1 2c 25 11 f0       	mov    0xf011252c,%eax
f010049a:	83 ec 04             	sub    $0x4,%esp
f010049d:	68 00 0f 00 00       	push   $0xf00
f01004a2:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f01004a8:	52                   	push   %edx
f01004a9:	50                   	push   %eax
f01004aa:	e8 84 0f 00 00       	call   f0101433 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0; //0x0700 | ' ';
f01004af:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f01004b5:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f01004bb:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f01004c1:	83 c4 10             	add    $0x10,%esp
f01004c4:	66 c7 00 00 00       	movw   $0x0,(%eax)
f01004c9:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01004cc:	39 d0                	cmp    %edx,%eax
f01004ce:	75 f4                	jne    f01004c4 <cons_putc+0x1da>
			crt_buf[i] = 0; //0x0700 | ' ';
		crt_pos -= CRT_COLS;
f01004d0:	66 83 2d 28 25 11 f0 	subw   $0x50,0xf0112528
f01004d7:	50 
f01004d8:	e9 ed fe ff ff       	jmp    f01003ca <cons_putc+0xe0>

f01004dd <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01004dd:	80 3d 34 25 11 f0 00 	cmpb   $0x0,0xf0112534
f01004e4:	75 01                	jne    f01004e7 <serial_intr+0xa>
f01004e6:	c3                   	ret    
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01004e7:	55                   	push   %ebp
f01004e8:	89 e5                	mov    %esp,%ebp
f01004ea:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01004ed:	b8 7c 01 10 f0       	mov    $0xf010017c,%eax
f01004f2:	e8 9f fc ff ff       	call   f0100196 <cons_intr>
}
f01004f7:	c9                   	leave  
f01004f8:	c3                   	ret    

f01004f9 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01004f9:	55                   	push   %ebp
f01004fa:	89 e5                	mov    %esp,%ebp
f01004fc:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004ff:	b8 d5 01 10 f0       	mov    $0xf01001d5,%eax
f0100504:	e8 8d fc ff ff       	call   f0100196 <cons_intr>
}
f0100509:	c9                   	leave  
f010050a:	c3                   	ret    

f010050b <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f010050b:	55                   	push   %ebp
f010050c:	89 e5                	mov    %esp,%ebp
f010050e:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f0100511:	e8 c7 ff ff ff       	call   f01004dd <serial_intr>
	kbd_intr();
f0100516:	e8 de ff ff ff       	call   f01004f9 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f010051b:	8b 15 20 25 11 f0    	mov    0xf0112520,%edx
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
	}
	return 0;
f0100521:	b8 00 00 00 00       	mov    $0x0,%eax
	// (e.g., when called from the kernel monitor).
	serial_intr();
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100526:	3b 15 24 25 11 f0    	cmp    0xf0112524,%edx
f010052c:	74 1e                	je     f010054c <cons_getc+0x41>
		c = cons.buf[cons.rpos++];
f010052e:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100531:	0f b6 82 20 23 11 f0 	movzbl -0xfeedce0(%edx),%eax
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
f0100538:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f010053e:	ba 00 00 00 00       	mov    $0x0,%edx
f0100543:	0f 44 ca             	cmove  %edx,%ecx
f0100546:	89 0d 20 25 11 f0    	mov    %ecx,0xf0112520
		return c;
	}
	return 0;
}
f010054c:	c9                   	leave  
f010054d:	c3                   	ret    

f010054e <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f010054e:	55                   	push   %ebp
f010054f:	89 e5                	mov    %esp,%ebp
f0100551:	57                   	push   %edi
f0100552:	56                   	push   %esi
f0100553:	53                   	push   %ebx
f0100554:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100557:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010055e:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100565:	5a a5 
	if (*cp != 0xA55A) {
f0100567:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010056e:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100572:	0f 84 b7 00 00 00    	je     f010062f <cons_init+0xe1>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100578:	c7 05 30 25 11 f0 b4 	movl   $0x3b4,0xf0112530
f010057f:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100582:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f0100587:	8b 3d 30 25 11 f0    	mov    0xf0112530,%edi
f010058d:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100592:	89 fa                	mov    %edi,%edx
f0100594:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100595:	8d 4f 01             	lea    0x1(%edi),%ecx
//only use with %edx,%eax register
static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100598:	89 ca                	mov    %ecx,%edx
f010059a:	ec                   	in     (%dx),%al
f010059b:	0f b6 c0             	movzbl %al,%eax
f010059e:	c1 e0 08             	shl    $0x8,%eax
f01005a1:	89 c3                	mov    %eax,%ebx
//to io one char
//only use of %eax %edx
static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005a3:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005a8:	89 fa                	mov    %edi,%edx
f01005aa:	ee                   	out    %al,(%dx)
//only use with %edx,%eax register
static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005ab:	89 ca                	mov    %ecx,%edx
f01005ad:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01005ae:	89 35 2c 25 11 f0    	mov    %esi,0xf011252c

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f01005b4:	0f b6 c0             	movzbl %al,%eax
f01005b7:	09 d8                	or     %ebx,%eax

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f01005b9:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
//to io one char
//only use of %eax %edx
static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005bf:	bb 00 00 00 00       	mov    $0x0,%ebx
f01005c4:	b9 fa 03 00 00       	mov    $0x3fa,%ecx
f01005c9:	89 d8                	mov    %ebx,%eax
f01005cb:	89 ca                	mov    %ecx,%edx
f01005cd:	ee                   	out    %al,(%dx)
f01005ce:	bf fb 03 00 00       	mov    $0x3fb,%edi
f01005d3:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01005d8:	89 fa                	mov    %edi,%edx
f01005da:	ee                   	out    %al,(%dx)
f01005db:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005e0:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01005e5:	ee                   	out    %al,(%dx)
f01005e6:	be f9 03 00 00       	mov    $0x3f9,%esi
f01005eb:	89 d8                	mov    %ebx,%eax
f01005ed:	89 f2                	mov    %esi,%edx
f01005ef:	ee                   	out    %al,(%dx)
f01005f0:	b8 03 00 00 00       	mov    $0x3,%eax
f01005f5:	89 fa                	mov    %edi,%edx
f01005f7:	ee                   	out    %al,(%dx)
f01005f8:	ba fc 03 00 00       	mov    $0x3fc,%edx
f01005fd:	89 d8                	mov    %ebx,%eax
f01005ff:	ee                   	out    %al,(%dx)
f0100600:	b8 01 00 00 00       	mov    $0x1,%eax
f0100605:	89 f2                	mov    %esi,%edx
f0100607:	ee                   	out    %al,(%dx)
//only use with %edx,%eax register
static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100608:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010060d:	ec                   	in     (%dx),%al
f010060e:	89 c3                	mov    %eax,%ebx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100610:	3c ff                	cmp    $0xff,%al
f0100612:	0f 95 05 34 25 11 f0 	setne  0xf0112534
f0100619:	89 ca                	mov    %ecx,%edx
f010061b:	ec                   	in     (%dx),%al
f010061c:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100621:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100622:	80 fb ff             	cmp    $0xff,%bl
f0100625:	74 23                	je     f010064a <cons_init+0xfc>
		cprintf("Serial port does not exist!\n");
}
f0100627:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010062a:	5b                   	pop    %ebx
f010062b:	5e                   	pop    %esi
f010062c:	5f                   	pop    %edi
f010062d:	5d                   	pop    %ebp
f010062e:	c3                   	ret    
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f010062f:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100636:	c7 05 30 25 11 f0 d4 	movl   $0x3d4,0xf0112530
f010063d:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100640:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
f0100645:	e9 3d ff ff ff       	jmp    f0100587 <cons_init+0x39>
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
		cprintf("Serial port does not exist!\n");
f010064a:	83 ec 0c             	sub    $0xc,%esp
f010064d:	68 d0 18 10 f0       	push   $0xf01018d0
f0100652:	e8 8a 02 00 00       	call   f01008e1 <cprintf>
f0100657:	83 c4 10             	add    $0x10,%esp
}
f010065a:	eb cb                	jmp    f0100627 <cons_init+0xd9>

f010065c <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f010065c:	55                   	push   %ebp
f010065d:	89 e5                	mov    %esp,%ebp
f010065f:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100662:	8b 45 08             	mov    0x8(%ebp),%eax
f0100665:	e8 80 fc ff ff       	call   f01002ea <cons_putc>
}
f010066a:	c9                   	leave  
f010066b:	c3                   	ret    

f010066c <getchar>:

int
getchar(void)
{
f010066c:	55                   	push   %ebp
f010066d:	89 e5                	mov    %esp,%ebp
f010066f:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100672:	e8 94 fe ff ff       	call   f010050b <cons_getc>
f0100677:	85 c0                	test   %eax,%eax
f0100679:	74 f7                	je     f0100672 <getchar+0x6>
		/* do nothing */;
	return c;
}
f010067b:	c9                   	leave  
f010067c:	c3                   	ret    

f010067d <iscons>:
int
iscons(int fdnum)
{
	// used by readline
	return 1;
}
f010067d:	b8 01 00 00 00       	mov    $0x1,%eax
f0100682:	c3                   	ret    
	...

f0100684 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100684:	55                   	push   %ebp
f0100685:	89 e5                	mov    %esp,%ebp
f0100687:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f010068a:	68 20 1b 10 f0       	push   $0xf0101b20
f010068f:	68 3e 1b 10 f0       	push   $0xf0101b3e
f0100694:	68 43 1b 10 f0       	push   $0xf0101b43
f0100699:	e8 43 02 00 00       	call   f01008e1 <cprintf>
f010069e:	83 c4 0c             	add    $0xc,%esp
f01006a1:	68 ac 1b 10 f0       	push   $0xf0101bac
f01006a6:	68 4c 1b 10 f0       	push   $0xf0101b4c
f01006ab:	68 43 1b 10 f0       	push   $0xf0101b43
f01006b0:	e8 2c 02 00 00       	call   f01008e1 <cprintf>
	return 0;
}
f01006b5:	b8 00 00 00 00       	mov    $0x0,%eax
f01006ba:	c9                   	leave  
f01006bb:	c3                   	ret    

f01006bc <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01006bc:	55                   	push   %ebp
f01006bd:	89 e5                	mov    %esp,%ebp
f01006bf:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01006c2:	68 55 1b 10 f0       	push   $0xf0101b55
f01006c7:	e8 15 02 00 00       	call   f01008e1 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006cc:	83 c4 08             	add    $0x8,%esp
f01006cf:	68 0c 00 10 00       	push   $0x10000c
f01006d4:	68 d4 1b 10 f0       	push   $0xf0101bd4
f01006d9:	e8 03 02 00 00       	call   f01008e1 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006de:	83 c4 0c             	add    $0xc,%esp
f01006e1:	68 0c 00 10 00       	push   $0x10000c
f01006e6:	68 0c 00 10 f0       	push   $0xf010000c
f01006eb:	68 fc 1b 10 f0       	push   $0xf0101bfc
f01006f0:	e8 ec 01 00 00       	call   f01008e1 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006f5:	83 c4 0c             	add    $0xc,%esp
f01006f8:	68 2f 18 10 00       	push   $0x10182f
f01006fd:	68 2f 18 10 f0       	push   $0xf010182f
f0100702:	68 20 1c 10 f0       	push   $0xf0101c20
f0100707:	e8 d5 01 00 00       	call   f01008e1 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010070c:	83 c4 0c             	add    $0xc,%esp
f010070f:	68 00 23 11 00       	push   $0x112300
f0100714:	68 00 23 11 f0       	push   $0xf0112300
f0100719:	68 44 1c 10 f0       	push   $0xf0101c44
f010071e:	e8 be 01 00 00       	call   f01008e1 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100723:	83 c4 0c             	add    $0xc,%esp
f0100726:	68 40 29 11 00       	push   $0x112940
f010072b:	68 40 29 11 f0       	push   $0xf0112940
f0100730:	68 68 1c 10 f0       	push   $0xf0101c68
f0100735:	e8 a7 01 00 00       	call   f01008e1 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
f010073a:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f010073d:	b8 40 29 11 f0       	mov    $0xf0112940,%eax
f0100742:	2d 0d fc 0f f0       	sub    $0xf00ffc0d,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100747:	c1 f8 0a             	sar    $0xa,%eax
f010074a:	50                   	push   %eax
f010074b:	68 8c 1c 10 f0       	push   $0xf0101c8c
f0100750:	e8 8c 01 00 00       	call   f01008e1 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100755:	b8 00 00 00 00       	mov    $0x0,%eax
f010075a:	c9                   	leave  
f010075b:	c3                   	ret    

f010075c <mon_backtrace>:
int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	// Your code here.
	return 0;
}
f010075c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100761:	c3                   	ret    

f0100762 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100762:	55                   	push   %ebp
f0100763:	89 e5                	mov    %esp,%ebp
f0100765:	57                   	push   %edi
f0100766:	56                   	push   %esi
f0100767:	53                   	push   %ebx
f0100768:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f010076b:	68 b8 1c 10 f0       	push   $0xf0101cb8
f0100770:	e8 6c 01 00 00       	call   f01008e1 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100775:	c7 04 24 dc 1c 10 f0 	movl   $0xf0101cdc,(%esp)
f010077c:	e8 60 01 00 00       	call   f01008e1 <cprintf>
f0100781:	83 c4 10             	add    $0x10,%esp
f0100784:	e9 cf 00 00 00       	jmp    f0100858 <monitor+0xf6>
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100789:	83 ec 08             	sub    $0x8,%esp
f010078c:	0f be c0             	movsbl %al,%eax
f010078f:	50                   	push   %eax
f0100790:	68 72 1b 10 f0       	push   $0xf0101b72
f0100795:	e8 14 0c 00 00       	call   f01013ae <strchr>
f010079a:	83 c4 10             	add    $0x10,%esp
f010079d:	85 c0                	test   %eax,%eax
f010079f:	74 6c                	je     f010080d <monitor+0xab>
			*buf++ = 0;
f01007a1:	c6 03 00             	movb   $0x0,(%ebx)
f01007a4:	89 f7                	mov    %esi,%edi
f01007a6:	8d 5b 01             	lea    0x1(%ebx),%ebx
f01007a9:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f01007ab:	0f b6 03             	movzbl (%ebx),%eax
f01007ae:	84 c0                	test   %al,%al
f01007b0:	75 d7                	jne    f0100789 <monitor+0x27>
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
	}
	argv[argc] = 0;
f01007b2:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01007b9:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01007ba:	85 f6                	test   %esi,%esi
f01007bc:	0f 84 96 00 00 00    	je     f0100858 <monitor+0xf6>
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01007c2:	83 ec 08             	sub    $0x8,%esp
f01007c5:	68 3e 1b 10 f0       	push   $0xf0101b3e
f01007ca:	ff 75 a8             	pushl  -0x58(%ebp)
f01007cd:	e8 7e 0b 00 00       	call   f0101350 <strcmp>
f01007d2:	83 c4 10             	add    $0x10,%esp
f01007d5:	85 c0                	test   %eax,%eax
f01007d7:	0f 84 a7 00 00 00    	je     f0100884 <monitor+0x122>
f01007dd:	83 ec 08             	sub    $0x8,%esp
f01007e0:	68 4c 1b 10 f0       	push   $0xf0101b4c
f01007e5:	ff 75 a8             	pushl  -0x58(%ebp)
f01007e8:	e8 63 0b 00 00       	call   f0101350 <strcmp>
f01007ed:	83 c4 10             	add    $0x10,%esp
f01007f0:	85 c0                	test   %eax,%eax
f01007f2:	0f 84 87 00 00 00    	je     f010087f <monitor+0x11d>
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01007f8:	83 ec 08             	sub    $0x8,%esp
f01007fb:	ff 75 a8             	pushl  -0x58(%ebp)
f01007fe:	68 94 1b 10 f0       	push   $0xf0101b94
f0100803:	e8 d9 00 00 00       	call   f01008e1 <cprintf>
f0100808:	83 c4 10             	add    $0x10,%esp
f010080b:	eb 4b                	jmp    f0100858 <monitor+0xf6>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
		if (*buf == 0)
f010080d:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100810:	74 a0                	je     f01007b2 <monitor+0x50>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100812:	83 fe 0f             	cmp    $0xf,%esi
f0100815:	74 2f                	je     f0100846 <monitor+0xe4>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
f0100817:	8d 7e 01             	lea    0x1(%esi),%edi
f010081a:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
		while (*buf && !strchr(WHITESPACE, *buf))
f010081e:	0f b6 03             	movzbl (%ebx),%eax
f0100821:	84 c0                	test   %al,%al
f0100823:	74 84                	je     f01007a9 <monitor+0x47>
f0100825:	83 ec 08             	sub    $0x8,%esp
f0100828:	0f be c0             	movsbl %al,%eax
f010082b:	50                   	push   %eax
f010082c:	68 72 1b 10 f0       	push   $0xf0101b72
f0100831:	e8 78 0b 00 00       	call   f01013ae <strchr>
f0100836:	83 c4 10             	add    $0x10,%esp
f0100839:	85 c0                	test   %eax,%eax
f010083b:	0f 85 68 ff ff ff    	jne    f01007a9 <monitor+0x47>
			buf++;
f0100841:	83 c3 01             	add    $0x1,%ebx
f0100844:	eb d8                	jmp    f010081e <monitor+0xbc>
		if (*buf == 0)
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100846:	83 ec 08             	sub    $0x8,%esp
f0100849:	6a 10                	push   $0x10
f010084b:	68 77 1b 10 f0       	push   $0xf0101b77
f0100850:	e8 8c 00 00 00       	call   f01008e1 <cprintf>
f0100855:	83 c4 10             	add    $0x10,%esp
	cprintf("Welcome to the JOS kernel monitor!\n");
	cprintf("Type 'help' for a list of commands.\n");


	while (1) {
		buf = readline("K> ");
f0100858:	83 ec 0c             	sub    $0xc,%esp
f010085b:	68 6e 1b 10 f0       	push   $0xf0101b6e
f0100860:	e8 23 09 00 00       	call   f0101188 <readline>
f0100865:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100867:	83 c4 10             	add    $0x10,%esp
f010086a:	85 c0                	test   %eax,%eax
f010086c:	74 ea                	je     f0100858 <monitor+0xf6>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f010086e:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100875:	be 00 00 00 00       	mov    $0x0,%esi
f010087a:	e9 2c ff ff ff       	jmp    f01007ab <monitor+0x49>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f010087f:	b8 01 00 00 00       	mov    $0x1,%eax
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
f0100884:	83 ec 04             	sub    $0x4,%esp
f0100887:	8d 04 40             	lea    (%eax,%eax,2),%eax
f010088a:	ff 75 08             	pushl  0x8(%ebp)
f010088d:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100890:	52                   	push   %edx
f0100891:	56                   	push   %esi
f0100892:	ff 14 85 0c 1d 10 f0 	call   *-0xfefe2f4(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100899:	83 c4 10             	add    $0x10,%esp
f010089c:	85 c0                	test   %eax,%eax
f010089e:	79 b8                	jns    f0100858 <monitor+0xf6>
				break;
	}
}
f01008a0:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01008a3:	5b                   	pop    %ebx
f01008a4:	5e                   	pop    %esi
f01008a5:	5f                   	pop    %edi
f01008a6:	5d                   	pop    %ebp
f01008a7:	c3                   	ret    

f01008a8 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01008a8:	55                   	push   %ebp
f01008a9:	89 e5                	mov    %esp,%ebp
f01008ab:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f01008ae:	ff 75 08             	pushl  0x8(%ebp)
f01008b1:	e8 a6 fd ff ff       	call   f010065c <cputchar>
	*cnt++;
}
f01008b6:	83 c4 10             	add    $0x10,%esp
f01008b9:	c9                   	leave  
f01008ba:	c3                   	ret    

f01008bb <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01008bb:	55                   	push   %ebp
f01008bc:	89 e5                	mov    %esp,%ebp
f01008be:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f01008c1:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01008c8:	ff 75 0c             	pushl  0xc(%ebp)
f01008cb:	ff 75 08             	pushl  0x8(%ebp)
f01008ce:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01008d1:	50                   	push   %eax
f01008d2:	68 a8 08 10 f0       	push   $0xf01008a8
f01008d7:	e8 c4 03 00 00       	call   f0100ca0 <vprintfmt>
	return cnt;
}
f01008dc:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01008df:	c9                   	leave  
f01008e0:	c3                   	ret    

f01008e1 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01008e1:	55                   	push   %ebp
f01008e2:	89 e5                	mov    %esp,%ebp
f01008e4:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01008e7:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01008ea:	50                   	push   %eax
f01008eb:	ff 75 08             	pushl  0x8(%ebp)
f01008ee:	e8 c8 ff ff ff       	call   f01008bb <vcprintf>
	va_end(ap);

	return cnt;
}
f01008f3:	c9                   	leave  
f01008f4:	c3                   	ret    
f01008f5:	00 00                	add    %al,(%eax)
	...

f01008f8 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01008f8:	55                   	push   %ebp
f01008f9:	89 e5                	mov    %esp,%ebp
f01008fb:	57                   	push   %edi
f01008fc:	56                   	push   %esi
f01008fd:	53                   	push   %ebx
f01008fe:	83 ec 14             	sub    $0x14,%esp
f0100901:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0100904:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0100907:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f010090a:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f010090d:	8b 1a                	mov    (%edx),%ebx
f010090f:	8b 01                	mov    (%ecx),%eax
f0100911:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100914:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f010091b:	eb 23                	jmp    f0100940 <stab_binsearch+0x48>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f010091d:	8d 5f 01             	lea    0x1(%edi),%ebx
			continue;
f0100920:	eb 1e                	jmp    f0100940 <stab_binsearch+0x48>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100922:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100925:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100928:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f010092c:	3b 55 0c             	cmp    0xc(%ebp),%edx
f010092f:	73 41                	jae    f0100972 <stab_binsearch+0x7a>
			*region_left = m;
f0100931:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100934:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0100936:	8d 5f 01             	lea    0x1(%edi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100939:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0100940:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0100943:	7f 5a                	jg     f010099f <stab_binsearch+0xa7>
		int true_m = (l + r) / 2, m = true_m;
f0100945:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100948:	01 d8                	add    %ebx,%eax
f010094a:	89 c7                	mov    %eax,%edi
f010094c:	c1 ef 1f             	shr    $0x1f,%edi
f010094f:	01 c7                	add    %eax,%edi
f0100951:	d1 ff                	sar    %edi
f0100953:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f0100956:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100959:	8d 54 81 04          	lea    0x4(%ecx,%eax,4),%edx
f010095d:	89 f8                	mov    %edi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f010095f:	39 c3                	cmp    %eax,%ebx
f0100961:	7f ba                	jg     f010091d <stab_binsearch+0x25>
f0100963:	0f b6 0a             	movzbl (%edx),%ecx
f0100966:	83 ea 0c             	sub    $0xc,%edx
f0100969:	39 f1                	cmp    %esi,%ecx
f010096b:	74 b5                	je     f0100922 <stab_binsearch+0x2a>
			m--;
f010096d:	83 e8 01             	sub    $0x1,%eax
f0100970:	eb ed                	jmp    f010095f <stab_binsearch+0x67>
		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0100972:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100975:	76 14                	jbe    f010098b <stab_binsearch+0x93>
			*region_right = m - 1;
f0100977:	83 e8 01             	sub    $0x1,%eax
f010097a:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010097d:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0100980:	89 07                	mov    %eax,(%edi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100982:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100989:	eb b5                	jmp    f0100940 <stab_binsearch+0x48>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f010098b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010098e:	89 07                	mov    %eax,(%edi)
			l = m;
			addr++;
f0100990:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0100994:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100996:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f010099d:	eb a1                	jmp    f0100940 <stab_binsearch+0x48>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f010099f:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f01009a3:	75 15                	jne    f01009ba <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f01009a5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01009a8:	8b 00                	mov    (%eax),%eax
f01009aa:	83 e8 01             	sub    $0x1,%eax
f01009ad:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01009b0:	89 06                	mov    %eax,(%esi)
		     l > *region_left && stabs[l].n_type != type;
		     l--)
			/* do nothing */;
		*region_left = l;
	}
}
f01009b2:	83 c4 14             	add    $0x14,%esp
f01009b5:	5b                   	pop    %ebx
f01009b6:	5e                   	pop    %esi
f01009b7:	5f                   	pop    %edi
f01009b8:	5d                   	pop    %ebp
f01009b9:	c3                   	ret    

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01009ba:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01009bd:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f01009bf:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01009c2:	8b 0f                	mov    (%edi),%ecx
f01009c4:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01009c7:	8b 7d ec             	mov    -0x14(%ebp),%edi
f01009ca:	8d 54 97 04          	lea    0x4(%edi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01009ce:	eb 03                	jmp    f01009d3 <stab_binsearch+0xdb>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f01009d0:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01009d3:	39 c1                	cmp    %eax,%ecx
f01009d5:	7d 0a                	jge    f01009e1 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f01009d7:	0f b6 1a             	movzbl (%edx),%ebx
f01009da:	83 ea 0c             	sub    $0xc,%edx
f01009dd:	39 f3                	cmp    %esi,%ebx
f01009df:	75 ef                	jne    f01009d0 <stab_binsearch+0xd8>
		     l--)
			/* do nothing */;
		*region_left = l;
f01009e1:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01009e4:	89 06                	mov    %eax,(%esi)
	}
}
f01009e6:	eb ca                	jmp    f01009b2 <stab_binsearch+0xba>

f01009e8 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f01009e8:	55                   	push   %ebp
f01009e9:	89 e5                	mov    %esp,%ebp
f01009eb:	57                   	push   %edi
f01009ec:	56                   	push   %esi
f01009ed:	53                   	push   %ebx
f01009ee:	83 ec 1c             	sub    $0x1c,%esp
f01009f1:	8b 7d 08             	mov    0x8(%ebp),%edi
f01009f4:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f01009f7:	c7 06 1c 1d 10 f0    	movl   $0xf0101d1c,(%esi)
	info->eip_line = 0;
f01009fd:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f0100a04:	c7 46 08 1c 1d 10 f0 	movl   $0xf0101d1c,0x8(%esi)
	info->eip_fn_namelen = 9;
f0100a0b:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f0100a12:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f0100a15:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100a1c:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f0100a22:	0f 86 db 00 00 00    	jbe    f0100b03 <debuginfo_eip+0x11b>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100a28:	b8 69 7b 10 f0       	mov    $0xf0107b69,%eax
f0100a2d:	3d cd 61 10 f0       	cmp    $0xf01061cd,%eax
f0100a32:	0f 86 5e 01 00 00    	jbe    f0100b96 <debuginfo_eip+0x1ae>
f0100a38:	80 3d 68 7b 10 f0 00 	cmpb   $0x0,0xf0107b68
f0100a3f:	0f 85 58 01 00 00    	jne    f0100b9d <debuginfo_eip+0x1b5>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100a45:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100a4c:	b8 cc 61 10 f0       	mov    $0xf01061cc,%eax
f0100a51:	2d 54 1f 10 f0       	sub    $0xf0101f54,%eax
f0100a56:	c1 f8 02             	sar    $0x2,%eax
f0100a59:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100a5f:	83 e8 01             	sub    $0x1,%eax
f0100a62:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100a65:	83 ec 08             	sub    $0x8,%esp
f0100a68:	57                   	push   %edi
f0100a69:	6a 64                	push   $0x64
f0100a6b:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100a6e:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100a71:	b8 54 1f 10 f0       	mov    $0xf0101f54,%eax
f0100a76:	e8 7d fe ff ff       	call   f01008f8 <stab_binsearch>
	if (lfile == 0)
f0100a7b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a7e:	83 c4 10             	add    $0x10,%esp
f0100a81:	85 c0                	test   %eax,%eax
f0100a83:	0f 84 1b 01 00 00    	je     f0100ba4 <debuginfo_eip+0x1bc>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100a89:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100a8c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100a8f:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100a92:	83 ec 08             	sub    $0x8,%esp
f0100a95:	57                   	push   %edi
f0100a96:	6a 24                	push   $0x24
f0100a98:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100a9b:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100a9e:	b8 54 1f 10 f0       	mov    $0xf0101f54,%eax
f0100aa3:	e8 50 fe ff ff       	call   f01008f8 <stab_binsearch>

	if (lfun <= rfun) {
f0100aa8:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100aab:	83 c4 10             	add    $0x10,%esp
f0100aae:	3b 5d d8             	cmp    -0x28(%ebp),%ebx
f0100ab1:	7f 64                	jg     f0100b17 <debuginfo_eip+0x12f>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100ab3:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100ab6:	c1 e0 02             	shl    $0x2,%eax
f0100ab9:	8d 90 54 1f 10 f0    	lea    -0xfefe0ac(%eax),%edx
f0100abf:	8b 88 54 1f 10 f0    	mov    -0xfefe0ac(%eax),%ecx
f0100ac5:	b8 69 7b 10 f0       	mov    $0xf0107b69,%eax
f0100aca:	2d cd 61 10 f0       	sub    $0xf01061cd,%eax
f0100acf:	39 c1                	cmp    %eax,%ecx
f0100ad1:	73 09                	jae    f0100adc <debuginfo_eip+0xf4>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100ad3:	81 c1 cd 61 10 f0    	add    $0xf01061cd,%ecx
f0100ad9:	89 4e 08             	mov    %ecx,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100adc:	8b 42 08             	mov    0x8(%edx),%eax
f0100adf:	89 46 10             	mov    %eax,0x10(%esi)
		info->eip_fn_addr = addr;
		lline = lfile;
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100ae2:	83 ec 08             	sub    $0x8,%esp
f0100ae5:	6a 3a                	push   $0x3a
f0100ae7:	ff 76 08             	pushl  0x8(%esi)
f0100aea:	e8 e0 08 00 00       	call   f01013cf <strfind>
f0100aef:	2b 46 08             	sub    0x8(%esi),%eax
f0100af2:	89 46 0c             	mov    %eax,0xc(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100af5:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100af8:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100afb:	c1 e0 02             	shl    $0x2,%eax
f0100afe:	83 c4 10             	add    $0x10,%esp
f0100b01:	eb 22                	jmp    f0100b25 <debuginfo_eip+0x13d>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100b03:	83 ec 04             	sub    $0x4,%esp
f0100b06:	68 26 1d 10 f0       	push   $0xf0101d26
f0100b0b:	6a 7f                	push   $0x7f
f0100b0d:	68 33 1d 10 f0       	push   $0xf0101d33
f0100b12:	e8 cf f5 ff ff       	call   f01000e6 <_panic>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100b17:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f0100b1a:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100b1d:	eb c3                	jmp    f0100ae2 <debuginfo_eip+0xfa>
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0100b1f:	83 eb 01             	sub    $0x1,%ebx
f0100b22:	83 e8 0c             	sub    $0xc,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100b25:	39 d9                	cmp    %ebx,%ecx
f0100b27:	7f 3a                	jg     f0100b63 <debuginfo_eip+0x17b>
	       && stabs[lline].n_type != N_SOL
f0100b29:	0f b6 90 58 1f 10 f0 	movzbl -0xfefe0a8(%eax),%edx
f0100b30:	80 fa 84             	cmp    $0x84,%dl
f0100b33:	74 0e                	je     f0100b43 <debuginfo_eip+0x15b>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100b35:	80 fa 64             	cmp    $0x64,%dl
f0100b38:	75 e5                	jne    f0100b1f <debuginfo_eip+0x137>
f0100b3a:	83 b8 5c 1f 10 f0 00 	cmpl   $0x0,-0xfefe0a4(%eax)
f0100b41:	74 dc                	je     f0100b1f <debuginfo_eip+0x137>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100b43:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100b46:	8b 14 85 54 1f 10 f0 	mov    -0xfefe0ac(,%eax,4),%edx
f0100b4d:	b8 69 7b 10 f0       	mov    $0xf0107b69,%eax
f0100b52:	2d cd 61 10 f0       	sub    $0xf01061cd,%eax
f0100b57:	39 c2                	cmp    %eax,%edx
f0100b59:	73 08                	jae    f0100b63 <debuginfo_eip+0x17b>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100b5b:	81 c2 cd 61 10 f0    	add    $0xf01061cd,%edx
f0100b61:	89 16                	mov    %edx,(%esi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100b63:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100b66:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100b69:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100b6e:	39 ca                	cmp    %ecx,%edx
f0100b70:	7d 3e                	jge    f0100bb0 <debuginfo_eip+0x1c8>
		for (lline = lfun + 1;
f0100b72:	8d 42 01             	lea    0x1(%edx),%eax
f0100b75:	eb 07                	jmp    f0100b7e <debuginfo_eip+0x196>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0100b77:	83 46 14 01          	addl   $0x1,0x14(%esi)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0100b7b:	83 c0 01             	add    $0x1,%eax


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100b7e:	39 c1                	cmp    %eax,%ecx
f0100b80:	74 29                	je     f0100bab <debuginfo_eip+0x1c3>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100b82:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100b85:	80 3c 95 58 1f 10 f0 	cmpb   $0xa0,-0xfefe0a8(,%edx,4)
f0100b8c:	a0 
f0100b8d:	74 e8                	je     f0100b77 <debuginfo_eip+0x18f>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100b8f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100b94:	eb 1a                	jmp    f0100bb0 <debuginfo_eip+0x1c8>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100b96:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100b9b:	eb 13                	jmp    f0100bb0 <debuginfo_eip+0x1c8>
f0100b9d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100ba2:	eb 0c                	jmp    f0100bb0 <debuginfo_eip+0x1c8>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0100ba4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100ba9:	eb 05                	jmp    f0100bb0 <debuginfo_eip+0x1c8>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100bab:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100bb0:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100bb3:	5b                   	pop    %ebx
f0100bb4:	5e                   	pop    %esi
f0100bb5:	5f                   	pop    %edi
f0100bb6:	5d                   	pop    %ebp
f0100bb7:	c3                   	ret    

f0100bb8 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100bb8:	55                   	push   %ebp
f0100bb9:	89 e5                	mov    %esp,%ebp
f0100bbb:	57                   	push   %edi
f0100bbc:	56                   	push   %esi
f0100bbd:	53                   	push   %ebx
f0100bbe:	83 ec 1c             	sub    $0x1c,%esp
f0100bc1:	89 c7                	mov    %eax,%edi
f0100bc3:	89 d6                	mov    %edx,%esi
f0100bc5:	8b 45 08             	mov    0x8(%ebp),%eax
f0100bc8:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100bcb:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100bce:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100bd1:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0100bd4:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100bd9:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100bdc:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0100bdf:	3b 45 10             	cmp    0x10(%ebp),%eax
f0100be2:	89 d0                	mov    %edx,%eax
f0100be4:	1b 45 e4             	sbb    -0x1c(%ebp),%eax
f0100be7:	8b 5d 14             	mov    0x14(%ebp),%ebx
f0100bea:	73 15                	jae    f0100c01 <printnum+0x49>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100bec:	83 eb 01             	sub    $0x1,%ebx
f0100bef:	85 db                	test   %ebx,%ebx
f0100bf1:	7e 43                	jle    f0100c36 <printnum+0x7e>
			putch(padc, putdat);
f0100bf3:	83 ec 08             	sub    $0x8,%esp
f0100bf6:	56                   	push   %esi
f0100bf7:	ff 75 18             	pushl  0x18(%ebp)
f0100bfa:	ff d7                	call   *%edi
f0100bfc:	83 c4 10             	add    $0x10,%esp
f0100bff:	eb eb                	jmp    f0100bec <printnum+0x34>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100c01:	83 ec 0c             	sub    $0xc,%esp
f0100c04:	ff 75 18             	pushl  0x18(%ebp)
f0100c07:	8b 45 14             	mov    0x14(%ebp),%eax
f0100c0a:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0100c0d:	53                   	push   %ebx
f0100c0e:	ff 75 10             	pushl  0x10(%ebp)
f0100c11:	83 ec 08             	sub    $0x8,%esp
f0100c14:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100c17:	ff 75 e0             	pushl  -0x20(%ebp)
f0100c1a:	ff 75 dc             	pushl  -0x24(%ebp)
f0100c1d:	ff 75 d8             	pushl  -0x28(%ebp)
f0100c20:	e8 bb 09 00 00       	call   f01015e0 <__udivdi3>
f0100c25:	83 c4 18             	add    $0x18,%esp
f0100c28:	52                   	push   %edx
f0100c29:	50                   	push   %eax
f0100c2a:	89 f2                	mov    %esi,%edx
f0100c2c:	89 f8                	mov    %edi,%eax
f0100c2e:	e8 85 ff ff ff       	call   f0100bb8 <printnum>
f0100c33:	83 c4 20             	add    $0x20,%esp
		while (--width > 0)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100c36:	83 ec 08             	sub    $0x8,%esp
f0100c39:	56                   	push   %esi
f0100c3a:	83 ec 04             	sub    $0x4,%esp
f0100c3d:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100c40:	ff 75 e0             	pushl  -0x20(%ebp)
f0100c43:	ff 75 dc             	pushl  -0x24(%ebp)
f0100c46:	ff 75 d8             	pushl  -0x28(%ebp)
f0100c49:	e8 a2 0a 00 00       	call   f01016f0 <__umoddi3>
f0100c4e:	83 c4 14             	add    $0x14,%esp
f0100c51:	0f be 80 41 1d 10 f0 	movsbl -0xfefe2bf(%eax),%eax
f0100c58:	50                   	push   %eax
f0100c59:	ff d7                	call   *%edi
}
f0100c5b:	83 c4 10             	add    $0x10,%esp
f0100c5e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100c61:	5b                   	pop    %ebx
f0100c62:	5e                   	pop    %esi
f0100c63:	5f                   	pop    %edi
f0100c64:	5d                   	pop    %ebp
f0100c65:	c3                   	ret    

f0100c66 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100c66:	55                   	push   %ebp
f0100c67:	89 e5                	mov    %esp,%ebp
f0100c69:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100c6c:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100c70:	8b 10                	mov    (%eax),%edx
f0100c72:	3b 50 04             	cmp    0x4(%eax),%edx
f0100c75:	73 0a                	jae    f0100c81 <sprintputch+0x1b>
		*b->buf++ = ch;
f0100c77:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100c7a:	89 08                	mov    %ecx,(%eax)
f0100c7c:	8b 45 08             	mov    0x8(%ebp),%eax
f0100c7f:	88 02                	mov    %al,(%edx)
}
f0100c81:	5d                   	pop    %ebp
f0100c82:	c3                   	ret    

f0100c83 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100c83:	55                   	push   %ebp
f0100c84:	89 e5                	mov    %esp,%ebp
f0100c86:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100c89:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100c8c:	50                   	push   %eax
f0100c8d:	ff 75 10             	pushl  0x10(%ebp)
f0100c90:	ff 75 0c             	pushl  0xc(%ebp)
f0100c93:	ff 75 08             	pushl  0x8(%ebp)
f0100c96:	e8 05 00 00 00       	call   f0100ca0 <vprintfmt>
	va_end(ap);
}
f0100c9b:	83 c4 10             	add    $0x10,%esp
f0100c9e:	c9                   	leave  
f0100c9f:	c3                   	ret    

f0100ca0 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100ca0:	55                   	push   %ebp
f0100ca1:	89 e5                	mov    %esp,%ebp
f0100ca3:	57                   	push   %edi
f0100ca4:	56                   	push   %esi
f0100ca5:	53                   	push   %ebx
f0100ca6:	83 ec 3c             	sub    $0x3c,%esp
f0100ca9:	8b 75 08             	mov    0x8(%ebp),%esi
f0100cac:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100caf:	8b 7d 10             	mov    0x10(%ebp),%edi
f0100cb2:	eb 0a                	jmp    f0100cbe <vprintfmt+0x1e>

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
				return;
			putch(ch, putdat);
f0100cb4:	83 ec 08             	sub    $0x8,%esp
f0100cb7:	53                   	push   %ebx
f0100cb8:	50                   	push   %eax
f0100cb9:	ff d6                	call   *%esi
f0100cbb:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100cbe:	83 c7 01             	add    $0x1,%edi
f0100cc1:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0100cc5:	83 f8 25             	cmp    $0x25,%eax
f0100cc8:	74 0c                	je     f0100cd6 <vprintfmt+0x36>
			if (ch == '\0')
f0100cca:	85 c0                	test   %eax,%eax
f0100ccc:	75 e6                	jne    f0100cb4 <vprintfmt+0x14>
			for (fmt--; fmt[-1] != '%'; fmt--)
				/* do nothing */;
			break;
		}
	}
}
f0100cce:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100cd1:	5b                   	pop    %ebx
f0100cd2:	5e                   	pop    %esi
f0100cd3:	5f                   	pop    %edi
f0100cd4:	5d                   	pop    %ebp
f0100cd5:	c3                   	ret    
				return;
			putch(ch, putdat);
		}

		// Process a %-escape sequence
		padc = ' ';
f0100cd6:	c6 45 d3 20          	movb   $0x20,-0x2d(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
f0100cda:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
		}

		// Process a %-escape sequence
		padc = ' ';
		width = -1;
		precision = -1;
f0100ce1:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
			putch(ch, putdat);
		}

		// Process a %-escape sequence
		padc = ' ';
		width = -1;
f0100ce8:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		precision = -1;
		lflag = 0;
f0100cef:	b9 00 00 00 00       	mov    $0x0,%ecx
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100cf4:	8d 47 01             	lea    0x1(%edi),%eax
f0100cf7:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100cfa:	0f b6 17             	movzbl (%edi),%edx
f0100cfd:	8d 42 dd             	lea    -0x23(%edx),%eax
f0100d00:	3c 55                	cmp    $0x55,%al
f0100d02:	0f 87 f9 03 00 00    	ja     f0101101 <vprintfmt+0x461>
f0100d08:	0f b6 c0             	movzbl %al,%eax
f0100d0b:	ff 24 85 d0 1d 10 f0 	jmp    *-0xfefe230(,%eax,4)
f0100d12:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100d15:	c6 45 d3 2d          	movb   $0x2d,-0x2d(%ebp)
f0100d19:	eb d9                	jmp    f0100cf4 <vprintfmt+0x54>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100d1b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100d1e:	c6 45 d3 30          	movb   $0x30,-0x2d(%ebp)
f0100d22:	eb d0                	jmp    f0100cf4 <vprintfmt+0x54>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100d24:	0f b6 d2             	movzbl %dl,%edx
f0100d27:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100d2a:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d2f:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
				precision = precision * 10 + ch - '0';
f0100d32:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100d35:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0100d39:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0100d3c:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0100d3f:	83 f9 09             	cmp    $0x9,%ecx
f0100d42:	77 55                	ja     f0100d99 <vprintfmt+0xf9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100d44:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
f0100d47:	eb e9                	jmp    f0100d32 <vprintfmt+0x92>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100d49:	8b 45 14             	mov    0x14(%ebp),%eax
f0100d4c:	8b 00                	mov    (%eax),%eax
f0100d4e:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100d51:	8b 45 14             	mov    0x14(%ebp),%eax
f0100d54:	8d 40 04             	lea    0x4(%eax),%eax
f0100d57:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100d5a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
f0100d5d:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100d61:	79 91                	jns    f0100cf4 <vprintfmt+0x54>
				width = precision, precision = -1;
f0100d63:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100d66:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100d69:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
f0100d70:	eb 82                	jmp    f0100cf4 <vprintfmt+0x54>
f0100d72:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100d75:	85 c0                	test   %eax,%eax
f0100d77:	ba 00 00 00 00       	mov    $0x0,%edx
f0100d7c:	0f 49 d0             	cmovns %eax,%edx
f0100d7f:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100d82:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100d85:	e9 6a ff ff ff       	jmp    f0100cf4 <vprintfmt+0x54>
f0100d8a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100d8d:	c7 45 d4 01 00 00 00 	movl   $0x1,-0x2c(%ebp)
			goto reswitch;
f0100d94:	e9 5b ff ff ff       	jmp    f0100cf4 <vprintfmt+0x54>
f0100d99:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100d9c:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100d9f:	eb bc                	jmp    f0100d5d <vprintfmt+0xbd>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100da1:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100da4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0100da7:	e9 48 ff ff ff       	jmp    f0100cf4 <vprintfmt+0x54>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100dac:	8b 45 14             	mov    0x14(%ebp),%eax
f0100daf:	8d 78 04             	lea    0x4(%eax),%edi
f0100db2:	83 ec 08             	sub    $0x8,%esp
f0100db5:	53                   	push   %ebx
f0100db6:	ff 30                	pushl  (%eax)
f0100db8:	ff d6                	call   *%esi
			break;
f0100dba:	83 c4 10             	add    $0x10,%esp
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100dbd:	89 7d 14             	mov    %edi,0x14(%ebp)
			break;
f0100dc0:	e9 db 02 00 00       	jmp    f01010a0 <vprintfmt+0x400>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100dc5:	8b 45 14             	mov    0x14(%ebp),%eax
f0100dc8:	8d 78 04             	lea    0x4(%eax),%edi
f0100dcb:	8b 00                	mov    (%eax),%eax
f0100dcd:	99                   	cltd   
f0100dce:	31 d0                	xor    %edx,%eax
f0100dd0:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100dd2:	83 f8 06             	cmp    $0x6,%eax
f0100dd5:	7f 23                	jg     f0100dfa <vprintfmt+0x15a>
f0100dd7:	8b 14 85 28 1f 10 f0 	mov    -0xfefe0d8(,%eax,4),%edx
f0100dde:	85 d2                	test   %edx,%edx
f0100de0:	74 18                	je     f0100dfa <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
			else
				printfmt(putch, putdat, "%s", p);
f0100de2:	52                   	push   %edx
f0100de3:	68 62 1d 10 f0       	push   $0xf0101d62
f0100de8:	53                   	push   %ebx
f0100de9:	56                   	push   %esi
f0100dea:	e8 94 fe ff ff       	call   f0100c83 <printfmt>
f0100def:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100df2:	89 7d 14             	mov    %edi,0x14(%ebp)
f0100df5:	e9 a6 02 00 00       	jmp    f01010a0 <vprintfmt+0x400>
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0100dfa:	50                   	push   %eax
f0100dfb:	68 59 1d 10 f0       	push   $0xf0101d59
f0100e00:	53                   	push   %ebx
f0100e01:	56                   	push   %esi
f0100e02:	e8 7c fe ff ff       	call   f0100c83 <printfmt>
f0100e07:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100e0a:	89 7d 14             	mov    %edi,0x14(%ebp)
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0100e0d:	e9 8e 02 00 00       	jmp    f01010a0 <vprintfmt+0x400>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0100e12:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e15:	83 c0 04             	add    $0x4,%eax
f0100e18:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100e1b:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e1e:	8b 10                	mov    (%eax),%edx
				p = "(null)";
f0100e20:	85 d2                	test   %edx,%edx
f0100e22:	b8 52 1d 10 f0       	mov    $0xf0101d52,%eax
f0100e27:	0f 45 c2             	cmovne %edx,%eax
f0100e2a:	89 45 cc             	mov    %eax,-0x34(%ebp)
			if (width > 0 && padc != '-')
f0100e2d:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100e31:	7e 06                	jle    f0100e39 <vprintfmt+0x199>
f0100e33:	80 7d d3 2d          	cmpb   $0x2d,-0x2d(%ebp)
f0100e37:	75 0d                	jne    f0100e46 <vprintfmt+0x1a6>
				for (width -= strnlen(p, precision); width > 0; width--)
f0100e39:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0100e3c:	89 c7                	mov    %eax,%edi
f0100e3e:	03 45 e0             	add    -0x20(%ebp),%eax
f0100e41:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100e44:	eb 3f                	jmp    f0100e85 <vprintfmt+0x1e5>
f0100e46:	83 ec 08             	sub    $0x8,%esp
f0100e49:	ff 75 d8             	pushl  -0x28(%ebp)
f0100e4c:	50                   	push   %eax
f0100e4d:	e8 32 04 00 00       	call   f0101284 <strnlen>
f0100e52:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0100e55:	29 c2                	sub    %eax,%edx
f0100e57:	89 55 c4             	mov    %edx,-0x3c(%ebp)
f0100e5a:	83 c4 10             	add    $0x10,%esp
f0100e5d:	89 d7                	mov    %edx,%edi
					putch(padc, putdat);
f0100e5f:	0f be 45 d3          	movsbl -0x2d(%ebp),%eax
f0100e63:	89 45 e0             	mov    %eax,-0x20(%ebp)
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100e66:	85 ff                	test   %edi,%edi
f0100e68:	7e 58                	jle    f0100ec2 <vprintfmt+0x222>
					putch(padc, putdat);
f0100e6a:	83 ec 08             	sub    $0x8,%esp
f0100e6d:	53                   	push   %ebx
f0100e6e:	ff 75 e0             	pushl  -0x20(%ebp)
f0100e71:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100e73:	83 ef 01             	sub    $0x1,%edi
f0100e76:	83 c4 10             	add    $0x10,%esp
f0100e79:	eb eb                	jmp    f0100e66 <vprintfmt+0x1c6>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
f0100e7b:	83 ec 08             	sub    $0x8,%esp
f0100e7e:	53                   	push   %ebx
f0100e7f:	52                   	push   %edx
f0100e80:	ff d6                	call   *%esi
f0100e82:	83 c4 10             	add    $0x10,%esp
f0100e85:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100e88:	29 f9                	sub    %edi,%ecx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0100e8a:	83 c7 01             	add    $0x1,%edi
f0100e8d:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0100e91:	0f be d0             	movsbl %al,%edx
f0100e94:	85 d2                	test   %edx,%edx
f0100e96:	74 45                	je     f0100edd <vprintfmt+0x23d>
f0100e98:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0100e9c:	78 06                	js     f0100ea4 <vprintfmt+0x204>
f0100e9e:	83 6d d8 01          	subl   $0x1,-0x28(%ebp)
f0100ea2:	78 35                	js     f0100ed9 <vprintfmt+0x239>
				if (altflag && (ch < ' ' || ch > '~'))
f0100ea4:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f0100ea8:	74 d1                	je     f0100e7b <vprintfmt+0x1db>
f0100eaa:	0f be c0             	movsbl %al,%eax
f0100ead:	83 e8 20             	sub    $0x20,%eax
f0100eb0:	83 f8 5e             	cmp    $0x5e,%eax
f0100eb3:	76 c6                	jbe    f0100e7b <vprintfmt+0x1db>
					putch('?', putdat);
f0100eb5:	83 ec 08             	sub    $0x8,%esp
f0100eb8:	53                   	push   %ebx
f0100eb9:	6a 3f                	push   $0x3f
f0100ebb:	ff d6                	call   *%esi
f0100ebd:	83 c4 10             	add    $0x10,%esp
f0100ec0:	eb c3                	jmp    f0100e85 <vprintfmt+0x1e5>
f0100ec2:	8b 55 c4             	mov    -0x3c(%ebp),%edx
f0100ec5:	85 d2                	test   %edx,%edx
f0100ec7:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ecc:	0f 49 c2             	cmovns %edx,%eax
f0100ecf:	29 c2                	sub    %eax,%edx
f0100ed1:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100ed4:	e9 60 ff ff ff       	jmp    f0100e39 <vprintfmt+0x199>
f0100ed9:	89 cf                	mov    %ecx,%edi
f0100edb:	eb 02                	jmp    f0100edf <vprintfmt+0x23f>
f0100edd:	89 cf                	mov    %ecx,%edi
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0100edf:	85 ff                	test   %edi,%edi
f0100ee1:	7e 10                	jle    f0100ef3 <vprintfmt+0x253>
				putch(' ', putdat);
f0100ee3:	83 ec 08             	sub    $0x8,%esp
f0100ee6:	53                   	push   %ebx
f0100ee7:	6a 20                	push   $0x20
f0100ee9:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0100eeb:	83 ef 01             	sub    $0x1,%edi
f0100eee:	83 c4 10             	add    $0x10,%esp
f0100ef1:	eb ec                	jmp    f0100edf <vprintfmt+0x23f>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0100ef3:	8b 45 c8             	mov    -0x38(%ebp),%eax
f0100ef6:	89 45 14             	mov    %eax,0x14(%ebp)
f0100ef9:	e9 a2 01 00 00       	jmp    f01010a0 <vprintfmt+0x400>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0100efe:	83 f9 01             	cmp    $0x1,%ecx
f0100f01:	7f 1f                	jg     f0100f22 <vprintfmt+0x282>
		return va_arg(*ap, long long);
	else if (lflag)
f0100f03:	85 c9                	test   %ecx,%ecx
f0100f05:	74 67                	je     f0100f6e <vprintfmt+0x2ce>
		return va_arg(*ap, long);
f0100f07:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f0a:	8b 00                	mov    (%eax),%eax
f0100f0c:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100f0f:	89 c1                	mov    %eax,%ecx
f0100f11:	c1 f9 1f             	sar    $0x1f,%ecx
f0100f14:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0100f17:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f1a:	8d 40 04             	lea    0x4(%eax),%eax
f0100f1d:	89 45 14             	mov    %eax,0x14(%ebp)
f0100f20:	eb 17                	jmp    f0100f39 <vprintfmt+0x299>
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, long long);
f0100f22:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f25:	8b 50 04             	mov    0x4(%eax),%edx
f0100f28:	8b 00                	mov    (%eax),%eax
f0100f2a:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100f2d:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0100f30:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f33:	8d 40 08             	lea    0x8(%eax),%eax
f0100f36:	89 45 14             	mov    %eax,0x14(%ebp)
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0100f39:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100f3c:	8b 4d dc             	mov    -0x24(%ebp),%ecx
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0100f3f:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0100f44:	85 c9                	test   %ecx,%ecx
f0100f46:	0f 89 3a 01 00 00    	jns    f0101086 <vprintfmt+0x3e6>
				putch('-', putdat);
f0100f4c:	83 ec 08             	sub    $0x8,%esp
f0100f4f:	53                   	push   %ebx
f0100f50:	6a 2d                	push   $0x2d
f0100f52:	ff d6                	call   *%esi
				num = -(long long) num;
f0100f54:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100f57:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0100f5a:	f7 da                	neg    %edx
f0100f5c:	83 d1 00             	adc    $0x0,%ecx
f0100f5f:	f7 d9                	neg    %ecx
f0100f61:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0100f64:	b8 0a 00 00 00       	mov    $0xa,%eax
f0100f69:	e9 18 01 00 00       	jmp    f0101086 <vprintfmt+0x3e6>
	if (lflag >= 2)
		return va_arg(*ap, long long);
	else if (lflag)
		return va_arg(*ap, long);
	else
		return va_arg(*ap, int);
f0100f6e:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f71:	8b 00                	mov    (%eax),%eax
f0100f73:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100f76:	89 c1                	mov    %eax,%ecx
f0100f78:	c1 f9 1f             	sar    $0x1f,%ecx
f0100f7b:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0100f7e:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f81:	8d 40 04             	lea    0x4(%eax),%eax
f0100f84:	89 45 14             	mov    %eax,0x14(%ebp)
f0100f87:	eb b0                	jmp    f0100f39 <vprintfmt+0x299>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0100f89:	83 f9 01             	cmp    $0x1,%ecx
f0100f8c:	7f 1e                	jg     f0100fac <vprintfmt+0x30c>
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f0100f8e:	85 c9                	test   %ecx,%ecx
f0100f90:	74 32                	je     f0100fc4 <vprintfmt+0x324>
		return va_arg(*ap, unsigned long);
f0100f92:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f95:	8b 10                	mov    (%eax),%edx
f0100f97:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100f9c:	8d 40 04             	lea    0x4(%eax),%eax
f0100f9f:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0100fa2:	b8 0a 00 00 00       	mov    $0xa,%eax
f0100fa7:	e9 da 00 00 00       	jmp    f0101086 <vprintfmt+0x3e6>
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
f0100fac:	8b 45 14             	mov    0x14(%ebp),%eax
f0100faf:	8b 10                	mov    (%eax),%edx
f0100fb1:	8b 48 04             	mov    0x4(%eax),%ecx
f0100fb4:	8d 40 08             	lea    0x8(%eax),%eax
f0100fb7:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0100fba:	b8 0a 00 00 00       	mov    $0xa,%eax
f0100fbf:	e9 c2 00 00 00       	jmp    f0101086 <vprintfmt+0x3e6>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f0100fc4:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fc7:	8b 10                	mov    (%eax),%edx
f0100fc9:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100fce:	8d 40 04             	lea    0x4(%eax),%eax
f0100fd1:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0100fd4:	b8 0a 00 00 00       	mov    $0xa,%eax
f0100fd9:	e9 a8 00 00 00       	jmp    f0101086 <vprintfmt+0x3e6>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0100fde:	83 f9 01             	cmp    $0x1,%ecx
f0100fe1:	7f 1b                	jg     f0100ffe <vprintfmt+0x35e>
		return va_arg(*ap, long long);
	else if (lflag)
f0100fe3:	85 c9                	test   %ecx,%ecx
f0100fe5:	74 5c                	je     f0101043 <vprintfmt+0x3a3>
		return va_arg(*ap, long);
f0100fe7:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fea:	8b 00                	mov    (%eax),%eax
f0100fec:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100fef:	99                   	cltd   
f0100ff0:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0100ff3:	8b 45 14             	mov    0x14(%ebp),%eax
f0100ff6:	8d 40 04             	lea    0x4(%eax),%eax
f0100ff9:	89 45 14             	mov    %eax,0x14(%ebp)
f0100ffc:	eb 17                	jmp    f0101015 <vprintfmt+0x375>
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, long long);
f0100ffe:	8b 45 14             	mov    0x14(%ebp),%eax
f0101001:	8b 50 04             	mov    0x4(%eax),%edx
f0101004:	8b 00                	mov    (%eax),%eax
f0101006:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101009:	89 55 dc             	mov    %edx,-0x24(%ebp)
f010100c:	8b 45 14             	mov    0x14(%ebp),%eax
f010100f:	8d 40 08             	lea    0x8(%eax),%eax
f0101012:	89 45 14             	mov    %eax,0x14(%ebp)

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0101015:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0101018:	8b 4d dc             	mov    -0x24(%ebp),%ecx
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 8;
f010101b:	b8 08 00 00 00       	mov    $0x8,%eax

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0101020:	85 c9                	test   %ecx,%ecx
f0101022:	79 62                	jns    f0101086 <vprintfmt+0x3e6>
				putch('-', putdat);
f0101024:	83 ec 08             	sub    $0x8,%esp
f0101027:	53                   	push   %ebx
f0101028:	6a 2d                	push   $0x2d
f010102a:	ff d6                	call   *%esi
				num = -(long long) num;
f010102c:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010102f:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0101032:	f7 da                	neg    %edx
f0101034:	83 d1 00             	adc    $0x0,%ecx
f0101037:	f7 d9                	neg    %ecx
f0101039:	83 c4 10             	add    $0x10,%esp
			}
			base = 8;
f010103c:	b8 08 00 00 00       	mov    $0x8,%eax
f0101041:	eb 43                	jmp    f0101086 <vprintfmt+0x3e6>
	if (lflag >= 2)
		return va_arg(*ap, long long);
	else if (lflag)
		return va_arg(*ap, long);
	else
		return va_arg(*ap, int);
f0101043:	8b 45 14             	mov    0x14(%ebp),%eax
f0101046:	8b 00                	mov    (%eax),%eax
f0101048:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010104b:	89 c1                	mov    %eax,%ecx
f010104d:	c1 f9 1f             	sar    $0x1f,%ecx
f0101050:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0101053:	8b 45 14             	mov    0x14(%ebp),%eax
f0101056:	8d 40 04             	lea    0x4(%eax),%eax
f0101059:	89 45 14             	mov    %eax,0x14(%ebp)
f010105c:	eb b7                	jmp    f0101015 <vprintfmt+0x375>
			}
			base = 8;
			goto number;
		// pointer
		case 'p':
			putch('0', putdat);
f010105e:	83 ec 08             	sub    $0x8,%esp
f0101061:	53                   	push   %ebx
f0101062:	6a 30                	push   $0x30
f0101064:	ff d6                	call   *%esi
			putch('x', putdat);
f0101066:	83 c4 08             	add    $0x8,%esp
f0101069:	53                   	push   %ebx
f010106a:	6a 78                	push   $0x78
f010106c:	ff d6                	call   *%esi
			num = (unsigned long long)
f010106e:	8b 45 14             	mov    0x14(%ebp),%eax
f0101071:	8b 10                	mov    (%eax),%edx
f0101073:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0101078:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f010107b:	8d 40 04             	lea    0x4(%eax),%eax
f010107e:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0101081:	b8 10 00 00 00       	mov    $0x10,%eax
		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
		number:
			printnum(putch, putdat, num, base, width, padc);
f0101086:	83 ec 0c             	sub    $0xc,%esp
f0101089:	0f be 7d d3          	movsbl -0x2d(%ebp),%edi
f010108d:	57                   	push   %edi
f010108e:	ff 75 e0             	pushl  -0x20(%ebp)
f0101091:	50                   	push   %eax
f0101092:	51                   	push   %ecx
f0101093:	52                   	push   %edx
f0101094:	89 da                	mov    %ebx,%edx
f0101096:	89 f0                	mov    %esi,%eax
f0101098:	e8 1b fb ff ff       	call   f0100bb8 <printnum>
			break;
f010109d:	83 c4 20             	add    $0x20,%esp
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f01010a0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f01010a3:	e9 16 fc ff ff       	jmp    f0100cbe <vprintfmt+0x1e>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f01010a8:	83 f9 01             	cmp    $0x1,%ecx
f01010ab:	7f 1b                	jg     f01010c8 <vprintfmt+0x428>
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f01010ad:	85 c9                	test   %ecx,%ecx
f01010af:	74 2c                	je     f01010dd <vprintfmt+0x43d>
		return va_arg(*ap, unsigned long);
f01010b1:	8b 45 14             	mov    0x14(%ebp),%eax
f01010b4:	8b 10                	mov    (%eax),%edx
f01010b6:	b9 00 00 00 00       	mov    $0x0,%ecx
f01010bb:	8d 40 04             	lea    0x4(%eax),%eax
f01010be:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f01010c1:	b8 10 00 00 00       	mov    $0x10,%eax
f01010c6:	eb be                	jmp    f0101086 <vprintfmt+0x3e6>
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
f01010c8:	8b 45 14             	mov    0x14(%ebp),%eax
f01010cb:	8b 10                	mov    (%eax),%edx
f01010cd:	8b 48 04             	mov    0x4(%eax),%ecx
f01010d0:	8d 40 08             	lea    0x8(%eax),%eax
f01010d3:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f01010d6:	b8 10 00 00 00       	mov    $0x10,%eax
f01010db:	eb a9                	jmp    f0101086 <vprintfmt+0x3e6>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f01010dd:	8b 45 14             	mov    0x14(%ebp),%eax
f01010e0:	8b 10                	mov    (%eax),%edx
f01010e2:	b9 00 00 00 00       	mov    $0x0,%ecx
f01010e7:	8d 40 04             	lea    0x4(%eax),%eax
f01010ea:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f01010ed:	b8 10 00 00 00       	mov    $0x10,%eax
f01010f2:	eb 92                	jmp    f0101086 <vprintfmt+0x3e6>
			printnum(putch, putdat, num, base, width, padc);
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f01010f4:	83 ec 08             	sub    $0x8,%esp
f01010f7:	53                   	push   %ebx
f01010f8:	6a 25                	push   $0x25
f01010fa:	ff d6                	call   *%esi
			break;
f01010fc:	83 c4 10             	add    $0x10,%esp
f01010ff:	eb 9f                	jmp    f01010a0 <vprintfmt+0x400>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0101101:	83 ec 08             	sub    $0x8,%esp
f0101104:	53                   	push   %ebx
f0101105:	6a 25                	push   $0x25
f0101107:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101109:	83 c4 10             	add    $0x10,%esp
f010110c:	89 f8                	mov    %edi,%eax
f010110e:	eb 03                	jmp    f0101113 <vprintfmt+0x473>
f0101110:	83 e8 01             	sub    $0x1,%eax
f0101113:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
f0101117:	75 f7                	jne    f0101110 <vprintfmt+0x470>
f0101119:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010111c:	eb 82                	jmp    f01010a0 <vprintfmt+0x400>

f010111e <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f010111e:	55                   	push   %ebp
f010111f:	89 e5                	mov    %esp,%ebp
f0101121:	83 ec 18             	sub    $0x18,%esp
f0101124:	8b 45 08             	mov    0x8(%ebp),%eax
f0101127:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f010112a:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010112d:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0101131:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0101134:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010113b:	85 c0                	test   %eax,%eax
f010113d:	74 26                	je     f0101165 <vsnprintf+0x47>
f010113f:	85 d2                	test   %edx,%edx
f0101141:	7e 22                	jle    f0101165 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0101143:	ff 75 14             	pushl  0x14(%ebp)
f0101146:	ff 75 10             	pushl  0x10(%ebp)
f0101149:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010114c:	50                   	push   %eax
f010114d:	68 66 0c 10 f0       	push   $0xf0100c66
f0101152:	e8 49 fb ff ff       	call   f0100ca0 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0101157:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010115a:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f010115d:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101160:	83 c4 10             	add    $0x10,%esp
}
f0101163:	c9                   	leave  
f0101164:	c3                   	ret    
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0101165:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f010116a:	eb f7                	jmp    f0101163 <vsnprintf+0x45>

f010116c <snprintf>:
	return b.cnt;
}

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010116c:	55                   	push   %ebp
f010116d:	89 e5                	mov    %esp,%ebp
f010116f:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0101172:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0101175:	50                   	push   %eax
f0101176:	ff 75 10             	pushl  0x10(%ebp)
f0101179:	ff 75 0c             	pushl  0xc(%ebp)
f010117c:	ff 75 08             	pushl  0x8(%ebp)
f010117f:	e8 9a ff ff ff       	call   f010111e <vsnprintf>
	va_end(ap);

	return rc;
}
f0101184:	c9                   	leave  
f0101185:	c3                   	ret    
	...

f0101188 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0101188:	55                   	push   %ebp
f0101189:	89 e5                	mov    %esp,%ebp
f010118b:	57                   	push   %edi
f010118c:	56                   	push   %esi
f010118d:	53                   	push   %ebx
f010118e:	83 ec 0c             	sub    $0xc,%esp
f0101191:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0101194:	85 c0                	test   %eax,%eax
f0101196:	74 11                	je     f01011a9 <readline+0x21>
		cprintf("%s", prompt);
f0101198:	83 ec 08             	sub    $0x8,%esp
f010119b:	50                   	push   %eax
f010119c:	68 62 1d 10 f0       	push   $0xf0101d62
f01011a1:	e8 3b f7 ff ff       	call   f01008e1 <cprintf>
f01011a6:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f01011a9:	83 ec 0c             	sub    $0xc,%esp
f01011ac:	6a 00                	push   $0x0
f01011ae:	e8 ca f4 ff ff       	call   f010067d <iscons>
f01011b3:	89 c7                	mov    %eax,%edi
f01011b5:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f01011b8:	be 00 00 00 00       	mov    $0x0,%esi
f01011bd:	eb 4b                	jmp    f010120a <readline+0x82>
	echoing = iscons(0);
	while (1) {
		c = getchar();
		if (c < 0) {
			cprintf("read error: %e\n", c);
f01011bf:	83 ec 08             	sub    $0x8,%esp
f01011c2:	50                   	push   %eax
f01011c3:	68 44 1f 10 f0       	push   $0xf0101f44
f01011c8:	e8 14 f7 ff ff       	call   f01008e1 <cprintf>
			return NULL;
f01011cd:	83 c4 10             	add    $0x10,%esp
f01011d0:	b8 00 00 00 00       	mov    $0x0,%eax
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}
f01011d5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01011d8:	5b                   	pop    %ebx
f01011d9:	5e                   	pop    %esi
f01011da:	5f                   	pop    %edi
f01011db:	5d                   	pop    %ebp
f01011dc:	c3                   	ret    
		c = getchar();
		if (c < 0) {
			cprintf("read error: %e\n", c);
			return NULL;
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
			if (echoing)
f01011dd:	85 ff                	test   %edi,%edi
f01011df:	75 05                	jne    f01011e6 <readline+0x5e>
				cputchar('\b');
			i--;
f01011e1:	83 ee 01             	sub    $0x1,%esi
f01011e4:	eb 24                	jmp    f010120a <readline+0x82>
		if (c < 0) {
			cprintf("read error: %e\n", c);
			return NULL;
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
			if (echoing)
				cputchar('\b');
f01011e6:	83 ec 0c             	sub    $0xc,%esp
f01011e9:	6a 08                	push   $0x8
f01011eb:	e8 6c f4 ff ff       	call   f010065c <cputchar>
f01011f0:	83 c4 10             	add    $0x10,%esp
f01011f3:	eb ec                	jmp    f01011e1 <readline+0x59>
			i--;
		} else if (c >= ' ' && i < BUFLEN-1) {
			if (echoing)
				cputchar(c);
f01011f5:	83 ec 0c             	sub    $0xc,%esp
f01011f8:	53                   	push   %ebx
f01011f9:	e8 5e f4 ff ff       	call   f010065c <cputchar>
f01011fe:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0101201:	88 9e 40 25 11 f0    	mov    %bl,-0xfeedac0(%esi)
f0101207:	8d 76 01             	lea    0x1(%esi),%esi
		cprintf("%s", prompt);

	i = 0;
	echoing = iscons(0);
	while (1) {
		c = getchar();
f010120a:	e8 5d f4 ff ff       	call   f010066c <getchar>
f010120f:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0101211:	85 c0                	test   %eax,%eax
f0101213:	78 aa                	js     f01011bf <readline+0x37>
			cprintf("read error: %e\n", c);
			return NULL;
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101215:	83 f8 08             	cmp    $0x8,%eax
f0101218:	0f 94 c2             	sete   %dl
f010121b:	83 f8 7f             	cmp    $0x7f,%eax
f010121e:	0f 94 c0             	sete   %al
f0101221:	08 c2                	or     %al,%dl
f0101223:	74 04                	je     f0101229 <readline+0xa1>
f0101225:	85 f6                	test   %esi,%esi
f0101227:	7f b4                	jg     f01011dd <readline+0x55>
			if (echoing)
				cputchar('\b');
			i--;
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101229:	83 fb 1f             	cmp    $0x1f,%ebx
f010122c:	7e 0e                	jle    f010123c <readline+0xb4>
f010122e:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0101234:	7f 06                	jg     f010123c <readline+0xb4>
			if (echoing)
f0101236:	85 ff                	test   %edi,%edi
f0101238:	74 c7                	je     f0101201 <readline+0x79>
f010123a:	eb b9                	jmp    f01011f5 <readline+0x6d>
				cputchar(c);
			buf[i++] = c;
		} else if (c == '\n' || c == '\r') {
f010123c:	83 fb 0a             	cmp    $0xa,%ebx
f010123f:	74 05                	je     f0101246 <readline+0xbe>
f0101241:	83 fb 0d             	cmp    $0xd,%ebx
f0101244:	75 c4                	jne    f010120a <readline+0x82>
			if (echoing)
f0101246:	85 ff                	test   %edi,%edi
f0101248:	75 11                	jne    f010125b <readline+0xd3>
				cputchar('\n');
			buf[i] = 0;
f010124a:	c6 86 40 25 11 f0 00 	movb   $0x0,-0xfeedac0(%esi)
			return buf;
f0101251:	b8 40 25 11 f0       	mov    $0xf0112540,%eax
f0101256:	e9 7a ff ff ff       	jmp    f01011d5 <readline+0x4d>
			if (echoing)
				cputchar(c);
			buf[i++] = c;
		} else if (c == '\n' || c == '\r') {
			if (echoing)
				cputchar('\n');
f010125b:	83 ec 0c             	sub    $0xc,%esp
f010125e:	6a 0a                	push   $0xa
f0101260:	e8 f7 f3 ff ff       	call   f010065c <cputchar>
f0101265:	83 c4 10             	add    $0x10,%esp
f0101268:	eb e0                	jmp    f010124a <readline+0xc2>
	...

f010126c <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f010126c:	55                   	push   %ebp
f010126d:	89 e5                	mov    %esp,%ebp
f010126f:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0101272:	b8 00 00 00 00       	mov    $0x0,%eax
f0101277:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f010127b:	74 05                	je     f0101282 <strlen+0x16>
		n++;
f010127d:	83 c0 01             	add    $0x1,%eax
f0101280:	eb f5                	jmp    f0101277 <strlen+0xb>
	return n;
}
f0101282:	5d                   	pop    %ebp
f0101283:	c3                   	ret    

f0101284 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0101284:	55                   	push   %ebp
f0101285:	89 e5                	mov    %esp,%ebp
f0101287:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010128a:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010128d:	ba 00 00 00 00       	mov    $0x0,%edx
f0101292:	39 c2                	cmp    %eax,%edx
f0101294:	74 0d                	je     f01012a3 <strnlen+0x1f>
f0101296:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f010129a:	74 05                	je     f01012a1 <strnlen+0x1d>
		n++;
f010129c:	83 c2 01             	add    $0x1,%edx
f010129f:	eb f1                	jmp    f0101292 <strnlen+0xe>
f01012a1:	89 d0                	mov    %edx,%eax
	return n;
}
f01012a3:	5d                   	pop    %ebp
f01012a4:	c3                   	ret    

f01012a5 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01012a5:	55                   	push   %ebp
f01012a6:	89 e5                	mov    %esp,%ebp
f01012a8:	53                   	push   %ebx
f01012a9:	8b 45 08             	mov    0x8(%ebp),%eax
f01012ac:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01012af:	ba 00 00 00 00       	mov    $0x0,%edx
f01012b4:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f01012b8:	88 0c 10             	mov    %cl,(%eax,%edx,1)
f01012bb:	83 c2 01             	add    $0x1,%edx
f01012be:	84 c9                	test   %cl,%cl
f01012c0:	75 f2                	jne    f01012b4 <strcpy+0xf>
		/* do nothing */;
	return ret;
}
f01012c2:	5b                   	pop    %ebx
f01012c3:	5d                   	pop    %ebp
f01012c4:	c3                   	ret    

f01012c5 <strcat>:

char *
strcat(char *dst, const char *src)
{
f01012c5:	55                   	push   %ebp
f01012c6:	89 e5                	mov    %esp,%ebp
f01012c8:	53                   	push   %ebx
f01012c9:	83 ec 10             	sub    $0x10,%esp
f01012cc:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01012cf:	53                   	push   %ebx
f01012d0:	e8 97 ff ff ff       	call   f010126c <strlen>
f01012d5:	83 c4 08             	add    $0x8,%esp
	strcpy(dst + len, src);
f01012d8:	ff 75 0c             	pushl  0xc(%ebp)
f01012db:	01 d8                	add    %ebx,%eax
f01012dd:	50                   	push   %eax
f01012de:	e8 c2 ff ff ff       	call   f01012a5 <strcpy>
	return dst;
}
f01012e3:	89 d8                	mov    %ebx,%eax
f01012e5:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01012e8:	c9                   	leave  
f01012e9:	c3                   	ret    

f01012ea <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01012ea:	55                   	push   %ebp
f01012eb:	89 e5                	mov    %esp,%ebp
f01012ed:	56                   	push   %esi
f01012ee:	53                   	push   %ebx
f01012ef:	8b 45 08             	mov    0x8(%ebp),%eax
f01012f2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01012f5:	89 c6                	mov    %eax,%esi
f01012f7:	03 75 10             	add    0x10(%ebp),%esi
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01012fa:	89 c2                	mov    %eax,%edx
f01012fc:	39 f2                	cmp    %esi,%edx
f01012fe:	74 11                	je     f0101311 <strncpy+0x27>
		*dst++ = *src;
f0101300:	83 c2 01             	add    $0x1,%edx
f0101303:	0f b6 19             	movzbl (%ecx),%ebx
f0101306:	88 5a ff             	mov    %bl,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0101309:	80 fb 01             	cmp    $0x1,%bl
f010130c:	83 d9 ff             	sbb    $0xffffffff,%ecx
f010130f:	eb eb                	jmp    f01012fc <strncpy+0x12>
	}
	return ret;
}
f0101311:	5b                   	pop    %ebx
f0101312:	5e                   	pop    %esi
f0101313:	5d                   	pop    %ebp
f0101314:	c3                   	ret    

f0101315 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0101315:	55                   	push   %ebp
f0101316:	89 e5                	mov    %esp,%ebp
f0101318:	56                   	push   %esi
f0101319:	53                   	push   %ebx
f010131a:	8b 75 08             	mov    0x8(%ebp),%esi
f010131d:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101320:	8b 55 10             	mov    0x10(%ebp),%edx
f0101323:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101325:	85 d2                	test   %edx,%edx
f0101327:	74 21                	je     f010134a <strlcpy+0x35>
f0101329:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f010132d:	89 f2                	mov    %esi,%edx
		while (--size > 0 && *src != '\0')
f010132f:	39 c2                	cmp    %eax,%edx
f0101331:	74 14                	je     f0101347 <strlcpy+0x32>
f0101333:	0f b6 19             	movzbl (%ecx),%ebx
f0101336:	84 db                	test   %bl,%bl
f0101338:	74 0b                	je     f0101345 <strlcpy+0x30>
			*dst++ = *src++;
f010133a:	83 c1 01             	add    $0x1,%ecx
f010133d:	83 c2 01             	add    $0x1,%edx
f0101340:	88 5a ff             	mov    %bl,-0x1(%edx)
f0101343:	eb ea                	jmp    f010132f <strlcpy+0x1a>
f0101345:	89 d0                	mov    %edx,%eax
		*dst = '\0';
f0101347:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f010134a:	29 f0                	sub    %esi,%eax
}
f010134c:	5b                   	pop    %ebx
f010134d:	5e                   	pop    %esi
f010134e:	5d                   	pop    %ebp
f010134f:	c3                   	ret    

f0101350 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0101350:	55                   	push   %ebp
f0101351:	89 e5                	mov    %esp,%ebp
f0101353:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101356:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0101359:	0f b6 01             	movzbl (%ecx),%eax
f010135c:	84 c0                	test   %al,%al
f010135e:	74 0c                	je     f010136c <strcmp+0x1c>
f0101360:	3a 02                	cmp    (%edx),%al
f0101362:	75 08                	jne    f010136c <strcmp+0x1c>
		p++, q++;
f0101364:	83 c1 01             	add    $0x1,%ecx
f0101367:	83 c2 01             	add    $0x1,%edx
f010136a:	eb ed                	jmp    f0101359 <strcmp+0x9>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f010136c:	0f b6 c0             	movzbl %al,%eax
f010136f:	0f b6 12             	movzbl (%edx),%edx
f0101372:	29 d0                	sub    %edx,%eax
}
f0101374:	5d                   	pop    %ebp
f0101375:	c3                   	ret    

f0101376 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0101376:	55                   	push   %ebp
f0101377:	89 e5                	mov    %esp,%ebp
f0101379:	53                   	push   %ebx
f010137a:	8b 45 08             	mov    0x8(%ebp),%eax
f010137d:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101380:	89 c3                	mov    %eax,%ebx
f0101382:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0101385:	eb 06                	jmp    f010138d <strncmp+0x17>
		n--, p++, q++;
f0101387:	83 c0 01             	add    $0x1,%eax
f010138a:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f010138d:	39 d8                	cmp    %ebx,%eax
f010138f:	74 16                	je     f01013a7 <strncmp+0x31>
f0101391:	0f b6 08             	movzbl (%eax),%ecx
f0101394:	84 c9                	test   %cl,%cl
f0101396:	74 04                	je     f010139c <strncmp+0x26>
f0101398:	3a 0a                	cmp    (%edx),%cl
f010139a:	74 eb                	je     f0101387 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f010139c:	0f b6 00             	movzbl (%eax),%eax
f010139f:	0f b6 12             	movzbl (%edx),%edx
f01013a2:	29 d0                	sub    %edx,%eax
}
f01013a4:	5b                   	pop    %ebx
f01013a5:	5d                   	pop    %ebp
f01013a6:	c3                   	ret    
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f01013a7:	b8 00 00 00 00       	mov    $0x0,%eax
f01013ac:	eb f6                	jmp    f01013a4 <strncmp+0x2e>

f01013ae <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01013ae:	55                   	push   %ebp
f01013af:	89 e5                	mov    %esp,%ebp
f01013b1:	8b 45 08             	mov    0x8(%ebp),%eax
f01013b4:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01013b8:	0f b6 10             	movzbl (%eax),%edx
f01013bb:	84 d2                	test   %dl,%dl
f01013bd:	74 09                	je     f01013c8 <strchr+0x1a>
		if (*s == c)
f01013bf:	38 ca                	cmp    %cl,%dl
f01013c1:	74 0a                	je     f01013cd <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01013c3:	83 c0 01             	add    $0x1,%eax
f01013c6:	eb f0                	jmp    f01013b8 <strchr+0xa>
		if (*s == c)
			return (char *) s;
	return 0;
f01013c8:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01013cd:	5d                   	pop    %ebp
f01013ce:	c3                   	ret    

f01013cf <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01013cf:	55                   	push   %ebp
f01013d0:	89 e5                	mov    %esp,%ebp
f01013d2:	8b 45 08             	mov    0x8(%ebp),%eax
f01013d5:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01013d9:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f01013dc:	38 ca                	cmp    %cl,%dl
f01013de:	74 09                	je     f01013e9 <strfind+0x1a>
f01013e0:	84 d2                	test   %dl,%dl
f01013e2:	74 05                	je     f01013e9 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f01013e4:	83 c0 01             	add    $0x1,%eax
f01013e7:	eb f0                	jmp    f01013d9 <strfind+0xa>
		if (*s == c)
			break;
	return (char *) s;
}
f01013e9:	5d                   	pop    %ebp
f01013ea:	c3                   	ret    

f01013eb <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01013eb:	55                   	push   %ebp
f01013ec:	89 e5                	mov    %esp,%ebp
f01013ee:	57                   	push   %edi
f01013ef:	56                   	push   %esi
f01013f0:	53                   	push   %ebx
f01013f1:	8b 7d 08             	mov    0x8(%ebp),%edi
f01013f4:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01013f7:	85 c9                	test   %ecx,%ecx
f01013f9:	74 31                	je     f010142c <memset+0x41>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01013fb:	89 f8                	mov    %edi,%eax
f01013fd:	09 c8                	or     %ecx,%eax
f01013ff:	a8 03                	test   $0x3,%al
f0101401:	75 23                	jne    f0101426 <memset+0x3b>
		c &= 0xFF;
f0101403:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0101407:	89 d3                	mov    %edx,%ebx
f0101409:	c1 e3 08             	shl    $0x8,%ebx
f010140c:	89 d0                	mov    %edx,%eax
f010140e:	c1 e0 18             	shl    $0x18,%eax
f0101411:	89 d6                	mov    %edx,%esi
f0101413:	c1 e6 10             	shl    $0x10,%esi
f0101416:	09 f0                	or     %esi,%eax
f0101418:	09 c2                	or     %eax,%edx
f010141a:	09 da                	or     %ebx,%edx
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f010141c:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f010141f:	89 d0                	mov    %edx,%eax
f0101421:	fc                   	cld    
f0101422:	f3 ab                	rep stos %eax,%es:(%edi)
f0101424:	eb 06                	jmp    f010142c <memset+0x41>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0101426:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101429:	fc                   	cld    
f010142a:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f010142c:	89 f8                	mov    %edi,%eax
f010142e:	5b                   	pop    %ebx
f010142f:	5e                   	pop    %esi
f0101430:	5f                   	pop    %edi
f0101431:	5d                   	pop    %ebp
f0101432:	c3                   	ret    

f0101433 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0101433:	55                   	push   %ebp
f0101434:	89 e5                	mov    %esp,%ebp
f0101436:	57                   	push   %edi
f0101437:	56                   	push   %esi
f0101438:	8b 45 08             	mov    0x8(%ebp),%eax
f010143b:	8b 75 0c             	mov    0xc(%ebp),%esi
f010143e:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0101441:	39 c6                	cmp    %eax,%esi
f0101443:	73 32                	jae    f0101477 <memmove+0x44>
f0101445:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0101448:	39 c2                	cmp    %eax,%edx
f010144a:	76 2b                	jbe    f0101477 <memmove+0x44>
		s += n;
		d += n;
f010144c:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010144f:	89 fe                	mov    %edi,%esi
f0101451:	09 ce                	or     %ecx,%esi
f0101453:	09 d6                	or     %edx,%esi
f0101455:	f7 c6 03 00 00 00    	test   $0x3,%esi
f010145b:	75 0e                	jne    f010146b <memmove+0x38>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f010145d:	83 ef 04             	sub    $0x4,%edi
f0101460:	8d 72 fc             	lea    -0x4(%edx),%esi
f0101463:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f0101466:	fd                   	std    
f0101467:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101469:	eb 09                	jmp    f0101474 <memmove+0x41>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f010146b:	83 ef 01             	sub    $0x1,%edi
f010146e:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0101471:	fd                   	std    
f0101472:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0101474:	fc                   	cld    
f0101475:	eb 1a                	jmp    f0101491 <memmove+0x5e>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101477:	89 c2                	mov    %eax,%edx
f0101479:	09 ca                	or     %ecx,%edx
f010147b:	09 f2                	or     %esi,%edx
f010147d:	f6 c2 03             	test   $0x3,%dl
f0101480:	75 0a                	jne    f010148c <memmove+0x59>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0101482:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f0101485:	89 c7                	mov    %eax,%edi
f0101487:	fc                   	cld    
f0101488:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010148a:	eb 05                	jmp    f0101491 <memmove+0x5e>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f010148c:	89 c7                	mov    %eax,%edi
f010148e:	fc                   	cld    
f010148f:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0101491:	5e                   	pop    %esi
f0101492:	5f                   	pop    %edi
f0101493:	5d                   	pop    %ebp
f0101494:	c3                   	ret    

f0101495 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0101495:	55                   	push   %ebp
f0101496:	89 e5                	mov    %esp,%ebp
f0101498:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f010149b:	ff 75 10             	pushl  0x10(%ebp)
f010149e:	ff 75 0c             	pushl  0xc(%ebp)
f01014a1:	ff 75 08             	pushl  0x8(%ebp)
f01014a4:	e8 8a ff ff ff       	call   f0101433 <memmove>
}
f01014a9:	c9                   	leave  
f01014aa:	c3                   	ret    

f01014ab <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01014ab:	55                   	push   %ebp
f01014ac:	89 e5                	mov    %esp,%ebp
f01014ae:	56                   	push   %esi
f01014af:	53                   	push   %ebx
f01014b0:	8b 45 08             	mov    0x8(%ebp),%eax
f01014b3:	8b 55 0c             	mov    0xc(%ebp),%edx
f01014b6:	89 c6                	mov    %eax,%esi
f01014b8:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01014bb:	39 f0                	cmp    %esi,%eax
f01014bd:	74 1c                	je     f01014db <memcmp+0x30>
		if (*s1 != *s2)
f01014bf:	0f b6 08             	movzbl (%eax),%ecx
f01014c2:	0f b6 1a             	movzbl (%edx),%ebx
f01014c5:	38 d9                	cmp    %bl,%cl
f01014c7:	75 08                	jne    f01014d1 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
		s1++, s2++;
f01014c9:	83 c0 01             	add    $0x1,%eax
f01014cc:	83 c2 01             	add    $0x1,%edx
f01014cf:	eb ea                	jmp    f01014bb <memcmp+0x10>
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
f01014d1:	0f b6 c1             	movzbl %cl,%eax
f01014d4:	0f b6 db             	movzbl %bl,%ebx
f01014d7:	29 d8                	sub    %ebx,%eax
f01014d9:	eb 05                	jmp    f01014e0 <memcmp+0x35>
		s1++, s2++;
	}

	return 0;
f01014db:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01014e0:	5b                   	pop    %ebx
f01014e1:	5e                   	pop    %esi
f01014e2:	5d                   	pop    %ebp
f01014e3:	c3                   	ret    

f01014e4 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01014e4:	55                   	push   %ebp
f01014e5:	89 e5                	mov    %esp,%ebp
f01014e7:	8b 45 08             	mov    0x8(%ebp),%eax
f01014ea:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f01014ed:	89 c2                	mov    %eax,%edx
f01014ef:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f01014f2:	39 d0                	cmp    %edx,%eax
f01014f4:	73 09                	jae    f01014ff <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
f01014f6:	38 08                	cmp    %cl,(%eax)
f01014f8:	74 05                	je     f01014ff <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01014fa:	83 c0 01             	add    $0x1,%eax
f01014fd:	eb f3                	jmp    f01014f2 <memfind+0xe>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01014ff:	5d                   	pop    %ebp
f0101500:	c3                   	ret    

f0101501 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0101501:	55                   	push   %ebp
f0101502:	89 e5                	mov    %esp,%ebp
f0101504:	57                   	push   %edi
f0101505:	56                   	push   %esi
f0101506:	53                   	push   %ebx
f0101507:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010150a:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010150d:	eb 03                	jmp    f0101512 <strtol+0x11>
		s++;
f010150f:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101512:	0f b6 01             	movzbl (%ecx),%eax
f0101515:	3c 20                	cmp    $0x20,%al
f0101517:	74 f6                	je     f010150f <strtol+0xe>
f0101519:	3c 09                	cmp    $0x9,%al
f010151b:	74 f2                	je     f010150f <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f010151d:	3c 2b                	cmp    $0x2b,%al
f010151f:	74 2a                	je     f010154b <strtol+0x4a>
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0101521:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0101526:	3c 2d                	cmp    $0x2d,%al
f0101528:	74 2b                	je     f0101555 <strtol+0x54>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f010152a:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0101530:	75 0f                	jne    f0101541 <strtol+0x40>
f0101532:	80 39 30             	cmpb   $0x30,(%ecx)
f0101535:	74 28                	je     f010155f <strtol+0x5e>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0101537:	85 db                	test   %ebx,%ebx
f0101539:	b8 0a 00 00 00       	mov    $0xa,%eax
f010153e:	0f 44 d8             	cmove  %eax,%ebx
f0101541:	b8 00 00 00 00       	mov    $0x0,%eax
f0101546:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0101549:	eb 50                	jmp    f010159b <strtol+0x9a>
	while (*s == ' ' || *s == '\t')
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
f010154b:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f010154e:	bf 00 00 00 00       	mov    $0x0,%edi
f0101553:	eb d5                	jmp    f010152a <strtol+0x29>

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
		s++, neg = 1;
f0101555:	83 c1 01             	add    $0x1,%ecx
f0101558:	bf 01 00 00 00       	mov    $0x1,%edi
f010155d:	eb cb                	jmp    f010152a <strtol+0x29>

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f010155f:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0101563:	74 0e                	je     f0101573 <strtol+0x72>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101565:	85 db                	test   %ebx,%ebx
f0101567:	75 d8                	jne    f0101541 <strtol+0x40>
		s++, base = 8;
f0101569:	83 c1 01             	add    $0x1,%ecx
f010156c:	bb 08 00 00 00       	mov    $0x8,%ebx
f0101571:	eb ce                	jmp    f0101541 <strtol+0x40>
	else if (*s == '-')
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
f0101573:	83 c1 02             	add    $0x2,%ecx
f0101576:	bb 10 00 00 00       	mov    $0x10,%ebx
f010157b:	eb c4                	jmp    f0101541 <strtol+0x40>
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
f010157d:	8d 72 9f             	lea    -0x61(%edx),%esi
f0101580:	89 f3                	mov    %esi,%ebx
f0101582:	80 fb 19             	cmp    $0x19,%bl
f0101585:	77 29                	ja     f01015b0 <strtol+0xaf>
			dig = *s - 'a' + 10;
f0101587:	0f be d2             	movsbl %dl,%edx
f010158a:	83 ea 57             	sub    $0x57,%edx
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f010158d:	3b 55 10             	cmp    0x10(%ebp),%edx
f0101590:	7d 30                	jge    f01015c2 <strtol+0xc1>
			break;
		s++, val = (val * base) + dig;
f0101592:	83 c1 01             	add    $0x1,%ecx
f0101595:	0f af 45 10          	imul   0x10(%ebp),%eax
f0101599:	01 d0                	add    %edx,%eax

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f010159b:	0f b6 11             	movzbl (%ecx),%edx
f010159e:	8d 72 d0             	lea    -0x30(%edx),%esi
f01015a1:	89 f3                	mov    %esi,%ebx
f01015a3:	80 fb 09             	cmp    $0x9,%bl
f01015a6:	77 d5                	ja     f010157d <strtol+0x7c>
			dig = *s - '0';
f01015a8:	0f be d2             	movsbl %dl,%edx
f01015ab:	83 ea 30             	sub    $0x30,%edx
f01015ae:	eb dd                	jmp    f010158d <strtol+0x8c>
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
f01015b0:	8d 72 bf             	lea    -0x41(%edx),%esi
f01015b3:	89 f3                	mov    %esi,%ebx
f01015b5:	80 fb 19             	cmp    $0x19,%bl
f01015b8:	77 08                	ja     f01015c2 <strtol+0xc1>
			dig = *s - 'A' + 10;
f01015ba:	0f be d2             	movsbl %dl,%edx
f01015bd:	83 ea 37             	sub    $0x37,%edx
f01015c0:	eb cb                	jmp    f010158d <strtol+0x8c>
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
f01015c2:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01015c6:	74 05                	je     f01015cd <strtol+0xcc>
		*endptr = (char *) s;
f01015c8:	8b 75 0c             	mov    0xc(%ebp),%esi
f01015cb:	89 0e                	mov    %ecx,(%esi)
	return (neg ? -val : val);
f01015cd:	89 c2                	mov    %eax,%edx
f01015cf:	f7 da                	neg    %edx
f01015d1:	85 ff                	test   %edi,%edi
f01015d3:	0f 45 c2             	cmovne %edx,%eax
}
f01015d6:	5b                   	pop    %ebx
f01015d7:	5e                   	pop    %esi
f01015d8:	5f                   	pop    %edi
f01015d9:	5d                   	pop    %ebp
f01015da:	c3                   	ret    
f01015db:	00 00                	add    %al,(%eax)
f01015dd:	00 00                	add    %al,(%eax)
	...

f01015e0 <__udivdi3>:
f01015e0:	55                   	push   %ebp
f01015e1:	57                   	push   %edi
f01015e2:	56                   	push   %esi
f01015e3:	53                   	push   %ebx
f01015e4:	83 ec 1c             	sub    $0x1c,%esp
f01015e7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f01015eb:	8b 6c 24 30          	mov    0x30(%esp),%ebp
f01015ef:	8b 74 24 34          	mov    0x34(%esp),%esi
f01015f3:	8b 5c 24 38          	mov    0x38(%esp),%ebx
f01015f7:	85 d2                	test   %edx,%edx
f01015f9:	75 4d                	jne    f0101648 <__udivdi3+0x68>
f01015fb:	39 f3                	cmp    %esi,%ebx
f01015fd:	76 19                	jbe    f0101618 <__udivdi3+0x38>
f01015ff:	31 ff                	xor    %edi,%edi
f0101601:	89 e8                	mov    %ebp,%eax
f0101603:	89 f2                	mov    %esi,%edx
f0101605:	f7 f3                	div    %ebx
f0101607:	89 fa                	mov    %edi,%edx
f0101609:	83 c4 1c             	add    $0x1c,%esp
f010160c:	5b                   	pop    %ebx
f010160d:	5e                   	pop    %esi
f010160e:	5f                   	pop    %edi
f010160f:	5d                   	pop    %ebp
f0101610:	c3                   	ret    
f0101611:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101618:	89 d9                	mov    %ebx,%ecx
f010161a:	85 db                	test   %ebx,%ebx
f010161c:	75 0b                	jne    f0101629 <__udivdi3+0x49>
f010161e:	b8 01 00 00 00       	mov    $0x1,%eax
f0101623:	31 d2                	xor    %edx,%edx
f0101625:	f7 f3                	div    %ebx
f0101627:	89 c1                	mov    %eax,%ecx
f0101629:	31 d2                	xor    %edx,%edx
f010162b:	89 f0                	mov    %esi,%eax
f010162d:	f7 f1                	div    %ecx
f010162f:	89 c6                	mov    %eax,%esi
f0101631:	89 e8                	mov    %ebp,%eax
f0101633:	89 f7                	mov    %esi,%edi
f0101635:	f7 f1                	div    %ecx
f0101637:	89 fa                	mov    %edi,%edx
f0101639:	83 c4 1c             	add    $0x1c,%esp
f010163c:	5b                   	pop    %ebx
f010163d:	5e                   	pop    %esi
f010163e:	5f                   	pop    %edi
f010163f:	5d                   	pop    %ebp
f0101640:	c3                   	ret    
f0101641:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101648:	39 f2                	cmp    %esi,%edx
f010164a:	77 1c                	ja     f0101668 <__udivdi3+0x88>
f010164c:	0f bd fa             	bsr    %edx,%edi
f010164f:	83 f7 1f             	xor    $0x1f,%edi
f0101652:	75 2c                	jne    f0101680 <__udivdi3+0xa0>
f0101654:	39 f2                	cmp    %esi,%edx
f0101656:	72 06                	jb     f010165e <__udivdi3+0x7e>
f0101658:	31 c0                	xor    %eax,%eax
f010165a:	39 eb                	cmp    %ebp,%ebx
f010165c:	77 a9                	ja     f0101607 <__udivdi3+0x27>
f010165e:	b8 01 00 00 00       	mov    $0x1,%eax
f0101663:	eb a2                	jmp    f0101607 <__udivdi3+0x27>
f0101665:	8d 76 00             	lea    0x0(%esi),%esi
f0101668:	31 ff                	xor    %edi,%edi
f010166a:	31 c0                	xor    %eax,%eax
f010166c:	89 fa                	mov    %edi,%edx
f010166e:	83 c4 1c             	add    $0x1c,%esp
f0101671:	5b                   	pop    %ebx
f0101672:	5e                   	pop    %esi
f0101673:	5f                   	pop    %edi
f0101674:	5d                   	pop    %ebp
f0101675:	c3                   	ret    
f0101676:	8d 76 00             	lea    0x0(%esi),%esi
f0101679:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f0101680:	89 f9                	mov    %edi,%ecx
f0101682:	b8 20 00 00 00       	mov    $0x20,%eax
f0101687:	29 f8                	sub    %edi,%eax
f0101689:	d3 e2                	shl    %cl,%edx
f010168b:	89 54 24 08          	mov    %edx,0x8(%esp)
f010168f:	89 c1                	mov    %eax,%ecx
f0101691:	89 da                	mov    %ebx,%edx
f0101693:	d3 ea                	shr    %cl,%edx
f0101695:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0101699:	09 d1                	or     %edx,%ecx
f010169b:	89 f2                	mov    %esi,%edx
f010169d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01016a1:	89 f9                	mov    %edi,%ecx
f01016a3:	d3 e3                	shl    %cl,%ebx
f01016a5:	89 c1                	mov    %eax,%ecx
f01016a7:	d3 ea                	shr    %cl,%edx
f01016a9:	89 f9                	mov    %edi,%ecx
f01016ab:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f01016af:	89 eb                	mov    %ebp,%ebx
f01016b1:	d3 e6                	shl    %cl,%esi
f01016b3:	89 c1                	mov    %eax,%ecx
f01016b5:	d3 eb                	shr    %cl,%ebx
f01016b7:	09 de                	or     %ebx,%esi
f01016b9:	89 f0                	mov    %esi,%eax
f01016bb:	f7 74 24 08          	divl   0x8(%esp)
f01016bf:	89 d6                	mov    %edx,%esi
f01016c1:	89 c3                	mov    %eax,%ebx
f01016c3:	f7 64 24 0c          	mull   0xc(%esp)
f01016c7:	39 d6                	cmp    %edx,%esi
f01016c9:	72 15                	jb     f01016e0 <__udivdi3+0x100>
f01016cb:	89 f9                	mov    %edi,%ecx
f01016cd:	d3 e5                	shl    %cl,%ebp
f01016cf:	39 c5                	cmp    %eax,%ebp
f01016d1:	73 04                	jae    f01016d7 <__udivdi3+0xf7>
f01016d3:	39 d6                	cmp    %edx,%esi
f01016d5:	74 09                	je     f01016e0 <__udivdi3+0x100>
f01016d7:	89 d8                	mov    %ebx,%eax
f01016d9:	31 ff                	xor    %edi,%edi
f01016db:	e9 27 ff ff ff       	jmp    f0101607 <__udivdi3+0x27>
f01016e0:	8d 43 ff             	lea    -0x1(%ebx),%eax
f01016e3:	31 ff                	xor    %edi,%edi
f01016e5:	e9 1d ff ff ff       	jmp    f0101607 <__udivdi3+0x27>
f01016ea:	00 00                	add    %al,(%eax)
f01016ec:	00 00                	add    %al,(%eax)
	...

f01016f0 <__umoddi3>:
f01016f0:	55                   	push   %ebp
f01016f1:	57                   	push   %edi
f01016f2:	56                   	push   %esi
f01016f3:	53                   	push   %ebx
f01016f4:	83 ec 1c             	sub    $0x1c,%esp
f01016f7:	8b 5c 24 34          	mov    0x34(%esp),%ebx
f01016fb:	8b 44 24 3c          	mov    0x3c(%esp),%eax
f01016ff:	8b 74 24 30          	mov    0x30(%esp),%esi
f0101703:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0101707:	89 da                	mov    %ebx,%edx
f0101709:	85 c0                	test   %eax,%eax
f010170b:	75 43                	jne    f0101750 <__umoddi3+0x60>
f010170d:	39 df                	cmp    %ebx,%edi
f010170f:	76 17                	jbe    f0101728 <__umoddi3+0x38>
f0101711:	89 f0                	mov    %esi,%eax
f0101713:	f7 f7                	div    %edi
f0101715:	89 d0                	mov    %edx,%eax
f0101717:	31 d2                	xor    %edx,%edx
f0101719:	83 c4 1c             	add    $0x1c,%esp
f010171c:	5b                   	pop    %ebx
f010171d:	5e                   	pop    %esi
f010171e:	5f                   	pop    %edi
f010171f:	5d                   	pop    %ebp
f0101720:	c3                   	ret    
f0101721:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101728:	89 fd                	mov    %edi,%ebp
f010172a:	85 ff                	test   %edi,%edi
f010172c:	75 0b                	jne    f0101739 <__umoddi3+0x49>
f010172e:	b8 01 00 00 00       	mov    $0x1,%eax
f0101733:	31 d2                	xor    %edx,%edx
f0101735:	f7 f7                	div    %edi
f0101737:	89 c5                	mov    %eax,%ebp
f0101739:	89 d8                	mov    %ebx,%eax
f010173b:	31 d2                	xor    %edx,%edx
f010173d:	f7 f5                	div    %ebp
f010173f:	89 f0                	mov    %esi,%eax
f0101741:	f7 f5                	div    %ebp
f0101743:	89 d0                	mov    %edx,%eax
f0101745:	eb d0                	jmp    f0101717 <__umoddi3+0x27>
f0101747:	89 f6                	mov    %esi,%esi
f0101749:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f0101750:	89 f1                	mov    %esi,%ecx
f0101752:	39 d8                	cmp    %ebx,%eax
f0101754:	76 0a                	jbe    f0101760 <__umoddi3+0x70>
f0101756:	89 f0                	mov    %esi,%eax
f0101758:	83 c4 1c             	add    $0x1c,%esp
f010175b:	5b                   	pop    %ebx
f010175c:	5e                   	pop    %esi
f010175d:	5f                   	pop    %edi
f010175e:	5d                   	pop    %ebp
f010175f:	c3                   	ret    
f0101760:	0f bd e8             	bsr    %eax,%ebp
f0101763:	83 f5 1f             	xor    $0x1f,%ebp
f0101766:	75 20                	jne    f0101788 <__umoddi3+0x98>
f0101768:	39 d8                	cmp    %ebx,%eax
f010176a:	0f 82 b0 00 00 00    	jb     f0101820 <__umoddi3+0x130>
f0101770:	39 f7                	cmp    %esi,%edi
f0101772:	0f 86 a8 00 00 00    	jbe    f0101820 <__umoddi3+0x130>
f0101778:	89 c8                	mov    %ecx,%eax
f010177a:	83 c4 1c             	add    $0x1c,%esp
f010177d:	5b                   	pop    %ebx
f010177e:	5e                   	pop    %esi
f010177f:	5f                   	pop    %edi
f0101780:	5d                   	pop    %ebp
f0101781:	c3                   	ret    
f0101782:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101788:	89 e9                	mov    %ebp,%ecx
f010178a:	ba 20 00 00 00       	mov    $0x20,%edx
f010178f:	29 ea                	sub    %ebp,%edx
f0101791:	d3 e0                	shl    %cl,%eax
f0101793:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101797:	89 d1                	mov    %edx,%ecx
f0101799:	89 f8                	mov    %edi,%eax
f010179b:	d3 e8                	shr    %cl,%eax
f010179d:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f01017a1:	89 54 24 04          	mov    %edx,0x4(%esp)
f01017a5:	8b 54 24 04          	mov    0x4(%esp),%edx
f01017a9:	09 c1                	or     %eax,%ecx
f01017ab:	89 d8                	mov    %ebx,%eax
f01017ad:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01017b1:	89 e9                	mov    %ebp,%ecx
f01017b3:	d3 e7                	shl    %cl,%edi
f01017b5:	89 d1                	mov    %edx,%ecx
f01017b7:	d3 e8                	shr    %cl,%eax
f01017b9:	89 e9                	mov    %ebp,%ecx
f01017bb:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01017bf:	d3 e3                	shl    %cl,%ebx
f01017c1:	89 c7                	mov    %eax,%edi
f01017c3:	89 d1                	mov    %edx,%ecx
f01017c5:	89 f0                	mov    %esi,%eax
f01017c7:	d3 e8                	shr    %cl,%eax
f01017c9:	89 e9                	mov    %ebp,%ecx
f01017cb:	89 fa                	mov    %edi,%edx
f01017cd:	d3 e6                	shl    %cl,%esi
f01017cf:	09 d8                	or     %ebx,%eax
f01017d1:	f7 74 24 08          	divl   0x8(%esp)
f01017d5:	89 d1                	mov    %edx,%ecx
f01017d7:	89 f3                	mov    %esi,%ebx
f01017d9:	f7 64 24 0c          	mull   0xc(%esp)
f01017dd:	89 c6                	mov    %eax,%esi
f01017df:	89 d7                	mov    %edx,%edi
f01017e1:	39 d1                	cmp    %edx,%ecx
f01017e3:	72 06                	jb     f01017eb <__umoddi3+0xfb>
f01017e5:	75 10                	jne    f01017f7 <__umoddi3+0x107>
f01017e7:	39 c3                	cmp    %eax,%ebx
f01017e9:	73 0c                	jae    f01017f7 <__umoddi3+0x107>
f01017eb:	2b 44 24 0c          	sub    0xc(%esp),%eax
f01017ef:	1b 54 24 08          	sbb    0x8(%esp),%edx
f01017f3:	89 d7                	mov    %edx,%edi
f01017f5:	89 c6                	mov    %eax,%esi
f01017f7:	89 ca                	mov    %ecx,%edx
f01017f9:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01017fe:	29 f3                	sub    %esi,%ebx
f0101800:	19 fa                	sbb    %edi,%edx
f0101802:	89 d0                	mov    %edx,%eax
f0101804:	d3 e0                	shl    %cl,%eax
f0101806:	89 e9                	mov    %ebp,%ecx
f0101808:	d3 eb                	shr    %cl,%ebx
f010180a:	d3 ea                	shr    %cl,%edx
f010180c:	09 d8                	or     %ebx,%eax
f010180e:	83 c4 1c             	add    $0x1c,%esp
f0101811:	5b                   	pop    %ebx
f0101812:	5e                   	pop    %esi
f0101813:	5f                   	pop    %edi
f0101814:	5d                   	pop    %ebp
f0101815:	c3                   	ret    
f0101816:	8d 76 00             	lea    0x0(%esi),%esi
f0101819:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f0101820:	89 da                	mov    %ebx,%edx
f0101822:	29 fe                	sub    %edi,%esi
f0101824:	19 c2                	sbb    %eax,%edx
f0101826:	89 f1                	mov    %esi,%ecx
f0101828:	89 c8                	mov    %ecx,%eax
f010182a:	e9 4b ff ff ff       	jmp    f010177a <__umoddi3+0x8a>
