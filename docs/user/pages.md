# What are pages?
Pages are a system to manage memory. Since computers have a lot more memory than they ever had, it has become quite a task to manage it. Most programming languages abstract the act of getting pages by using an allocator. But that isn't a trivial task to implement and isn't the scope of an virtual machine of this type. Instead Agar exposes the memory in pages of size 4KiB (4096 bytes).

## How to work with pages
Before writing to a page, you must first request it.

```assembly
; get page and save it's id into t0
gp t0 0
```

Then you can store and load from it. Beware that page may already be filled with random data!
```assembly
; store 10000 into t1
li t1 10000

; save t1 into the page that was previously requested
psd t1 t0 0

; ... some other code ...

; load into t1 from the page at offset 0
pld t1 t0 0

; finally free the page from memory
fp t0 0
```