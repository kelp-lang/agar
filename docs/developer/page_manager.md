# Page Manager (page_manager.zig)

Memory is in Agar managed in pages. Each page is addressed by the 12 bit immediate. The only difference is that address inside a page is always between 0 and 4095, so there is no reason to use signed immediates and thus the immediate is casted to unsigned integer and used that way.

Page manager uses the zig feature of file structs. In reality it just means that the file itself is treated as a struct. If it hard to comprehend than imagine that you just wrap everything in the file inside `struct {}`.

## Initialization

The struct uses the usual zig `.init()` & `.deinit()` pattern.

## Runtime

There are only two functions in this struct. The one is for initializing new pages and the other is for releasing them. The pages are stored in a ArrayList and the id in which the struct identifies pages is the index in this array. There is no guarantee that the id is unique, usually pages are reused.

The handling of freed pages is that if they appear on the end of the array, they are released if they are in the middle of the array, they are marked as free but not released from the memory. This is done simply because this can assure that the access and all functions will be O(1) as rearranging arrays is O(n).

The free pages are stored into a singly linked list as it doesn't matter in which order they are reused and linked list allows for an easy O(1) LIFO queue.