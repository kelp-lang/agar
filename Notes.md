- point of agar and kelp is always execute code that is closest to math
  - ie. if there is a difference between programming standards and math, use math version if possible
  - agar should allow two ways if possible, math-correct and computationally fast
- assembler files end with ".algae"
- binary files end with ".agar" and are "valid" elf files
- allow for clojure style transients (temporarily mutable data)

# Functions that must be supported in the Assembly
| function name   | description                              |
|-----------------|------------------------------------------|
| define          | define a symbol in assembly symbol table |
| if              | use breq etc.                            |
| eval            | run code from memory                     |
| structs         | create and access struct fields          |
| type-conversion | convert between types                    |
| cons            | create car cdr pair                      |
| car             | get car Field                            |
| cdr             | get cdr field                            |
| length          | get list length                          |
| reverse         |                                          |
| nth             |                                          |
| assoc           |                                          |
| vectors         |                                          |
| append          |                                          |
| value Equality  |                                          |

- all functions operating on list only operate on pointers
- all lists are single linked, so they can share tails with copy-on-write
- lists follow this architecture
```
|cdr|object| -> |cdr|object| -> |self_ptr|nil_object|
```
- list are managed by the memory manager for this vm
- as all data are immutable taking a pointer is a safe operation
- all items are list items (objects are just 1 long lists)
| field                    | type   | memory representation                                               |
|--------------------------|--------|---------------------------------------------------------------------|
| next item in a list      | u64    | 64 bits, if nil, this is nil, if points to itself it's a terminator |
|--------------------------|--------|---------------------------------------------------------------------|
| type                     | symbol | 4 bits or smth                                                      |
| size of content in bytes | number | 60 bits                                                             |
| content                  | bytes  | unknown                                                             |
- when creating a list, the vm calls memory manager with a request for a new list head
  - the MM returns a pointer to the memory
- when defining a symbol, the vm calls the memory manager with a request for symbol creation and content size
  - the MM responds with a pointer to the memory and registers the symbol in the symbol table (this should not be relative to the current namespace, rather absolute)
- when appending to a list, if the vm requests a new memory with a copy of the list, and append command to it
  - the MM responds with new pointer to the head
- the vm can ask the MM to change an object to a list head, or to append a object to a list
- the VM holds a list of all it's handled lists in it's runtime. If it losts a pointer to some list, it is up to the memory manager to clean it up
- exported symbols cannot be cleaned up, they will remain loaded unless they are freed by the programmer, as they may be required later, but local lexical binds are freed automatically
- the memory manager moves variables that aren't referenced to a graveyard, that get's freed the next time it is ran, so the memory doesn't get freed immediately, and the vm can mark data as non-delete, if they happen to appear on the graveyard (maybe, but this may not be possible, just stopping the vm and doing it is probably safer)
# Types
for now 4 bits are enough
- Int
twos complement signed
| field     | size         | notes                                                                        |
|-----------|--------------|------------------------------------------------------------------------------|
| precision | u4           | 0x0 - arbitrary next 60 bits are the precision, otherwise the number of bits |
| data      | by precision |                                                                              |
- Rational
| field | size | notes                                   |
|-------|------|-----------------------------------------|
| Int   |      | simply defines rational as two integers |
| Int   |      |                                         |
- Real
- Complex
- List
- Grapheme
a compacted unicode grapheme maybe it 
| field | size | notes                                                                 |
|-------|------|-----------------------------------------------------------------------|
| size  | u2   | defines grapheme size (1 to 4 bytes)                                  |
| data  |      | 7 bits for 1 byte,  11 for 2 byte,  16 for 3 byte, 21 bits for 4 byte |
- Symbol
- Array
- Lambda
- Atom
- Structure
- Nil
- Quote
is a piece of bytecode saved into memory, can be executed, created and moved around
