#+build darwin
package main

import "core:dynlib"

// macOS windows have no icon: GLFW ignores SetWindowIcon. Set the Dock icon on
// the application instead, while the game runs (a bare binary has no bundle to
// hold one).
//
// Raw objc_msgSend calls: core:sys/darwin/Foundation crashes the compiler in
// dev-2026-10 (missing objc_lookUpClass), and the runtime already declares
// objc_msgSend with a variadic signature that arm64 can't call correctly.

@(private = "file")
Send :: proc "c" (self, op: rawptr) -> rawptr
@(private = "file")
Send_Ptr :: proc "c" (self, op, arg: rawptr) -> rawptr
@(private = "file")
Send_Bytes :: proc "c" (self, op, bytes: rawptr, length: uint) -> rawptr

set_window_icon :: proc() {
	lib, ok := dynlib.load_library("/usr/lib/libobjc.A.dylib")
	if !ok do return
	defer dynlib.unload_library(lib)

	get_class := cast(proc "c" (name: cstring) -> rawptr)dynlib.symbol_address(lib, "objc_getClass")
	sel := cast(proc "c" (name: cstring) -> rawptr)dynlib.symbol_address(lib, "sel_registerName")
	msg_send := dynlib.symbol_address(lib, "objc_msgSend")
	send := cast(Send)msg_send
	send_ptr := cast(Send_Ptr)msg_send
	send_bytes := cast(Send_Bytes)msg_send

	data := send_bytes(
		get_class("NSData"),
		sel("dataWithBytes:length:"),
		raw_data(ICON_DATA),
		len(ICON_DATA),
	)
	image := send_ptr(send(get_class("NSImage"), sel("alloc")), sel("initWithData:"), data)
	app := send(get_class("NSApplication"), sel("sharedApplication"))
	send_ptr(app, sel("setApplicationIconImage:"), image)
	send(image, sel("release"))
}
