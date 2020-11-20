# Agar
## Q&A
### What is Agar?
Agar is a layer between Kelp and other backends. Agar can be interpreted or compiled using any toolchains, although none is currently implemented and the specification is lacking right now.
### Why not compile directly to a backend?
Agar insn't really a compiler, Agar is a full programming language. Not intended for programmers, but rather it allows for other programs that provide backend specific code. It is somewhat inspired by assembly, but is actually much more abstract.
### What backends are available?
Currently? None.
### What backends are planned?
There are plans to create an interpreter and binding to either cranelift or LLVM.
### Can I program in Agar?
Yes, you can. It's a simple text file, but it isn't very pleasing language.
### Can I contribute?
Yes you can! Most of my work is currently on the "kelp to agar" side, so you are free to open a PR!
### What does Agar look like?
Check the [docs](docs/) or [examples](examples/) folders!
### Is Agar translatable back to Kelp?
It may be possible, but it really isn't a priority. Kelp to Agar conversion is lossy. All function blocks are removed, functions within functions made into blocks etc.
### Are there any disadvantages?
Yes, many.
- slower compile times
- lot of extra work
- another boiler plate
- point of failure
- another IR
### And advantages?
- simple
- super easy to parse
- really fast to write backends for
- can solve platform specific issues
- easy to manipulate and optimize
- can solve borrowing and reference counting
- can automatically paralellized code