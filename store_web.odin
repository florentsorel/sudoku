#+build js
package main

// The browser has no file system we can keep between visits: entries go to
// localStorage instead. The JavaScript side is in web/index_template.html.

foreign import storage "sudoku_storage"

@(default_calling_convention = "contextless")
foreign storage {
	storage_set :: proc(key: string, value: []byte) ---
	// Byte length of the stored value, -1 if there is none
	storage_length :: proc(key: string) -> int ---
	storage_get :: proc(key: string, buf: []byte) ---
	storage_remove :: proc(key: string) ---
}

store_write :: proc(name: string, data: []byte) -> bool {
	storage_set(name, data)
	return true
}

store_read :: proc(name: string, allocator := context.allocator) -> (data: []byte, ok: bool) {
	n := storage_length(name)
	if n < 0 do return
	data = make([]byte, n, allocator)
	storage_get(name, data)
	return data, true
}

store_remove :: proc(name: string) {
	storage_remove(name)
}
