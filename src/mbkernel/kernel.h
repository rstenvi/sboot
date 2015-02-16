/**
* kernel.h
* Some definitions and include everyone should know about.
*/

#ifndef __KERNEL_H
#define __KERNEL_H

#include <stdint.h>	// uint32_t etc
#include <stddef.h>	// size_t
#include <stdbool.h>


// Defined in ports.s
void outb(uint16_t, uint8_t);
uint8_t inb(uint16_t port);
void outw(uint16_t, uint16_t);
uint16_t inw(uint16_t);



size_t strlen(const char* str);
void vga_write(char* str);
void vga_putc(char ch);
int printf(const char *fmt, ...);

/** Different colors for foreground and background color. */
typedef enum	{
	Black = 0,
	Blue = 1,
	Green = 2,
	Cyan = 3,
	Red = 4,
	Pink = 5,
	Brown = 6,
	LightGray = 7,
	DarkGray = 8,
	LightBlue = 9,
	LightGreen = 10, 
	LightCyan = 11, 
	LightRed = 12, 
	LightPink = 13, 
	Yellow = 14, 
	White = 15
} vga_color;


/** Structure defining the entire screen for the VGA driver. */
typedef struct {
	/** Byte for combined foreground and background color. */
	uint8_t color;
	uint8_t x,	/**< Current horizontal index. */
			y;	/**< Current vertical index. */
	uint8_t tab_sz;	/**< Number of spaces in a tab. */
	uint16_t* mem;	/**< Address to the VGA memory. */
} vga_screen;




/**
* Initializes the screen. This includes setting all the variables in the structure
* vga_screen and painting the entire screen with the color of bg.
*/
void vga_init(vga_color fg, vga_color bg);

/**
* Clear the entire screen with the bacground color that has been set.
*/
void vga_clear();


#endif
