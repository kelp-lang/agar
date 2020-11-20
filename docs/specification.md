# Agar specification
## instructions
| symbol    | usage                       | description                                                       |
| --------- | --------------------------- | ----------------------------------------------------------------- |
| `add`     | `add %var1 %var2 %result`   | add `%var1` and `%var2` together                                  |
| `sub`     | `sub %var1 %var2 %result`   | subtract `%var2` from `%var1`                                     |
| `eq`      | `eq %var1 %var2 %result`    | set `%result` to `%true` if equal, otherwise `%false`             |
| `neq`     | `eq %var1 %var2 %result`    | set `%result` to `%false` if equal, otherwise `%true`             |
| `ret`     | `ret type`                  | specifies type of the result                                      |
| `app`     | `app %args :blockname %ret` | applies `%args` to a function and sets the value of the `%result` |
| `val`     | `val %var`                  | sets value of parent block to `%var`                              |
| `jmp`     | `jump :name %ret?`          | jumps to a specific block                                         |
| `jmp_eq`  | `jmp_eq %var :name %ret?`   | jumps to block only if `%var` is `%true`                          |
| `jmp_neq` | `jmp_neq %var :name %ret?`  | jumps to block only if `%var` is `%false`                         |

## blocks
blocks start with `blk :blockname` and end with `end :blockname`.
| symbol    | description                                                     |
| --------- | --------------------------------------------------------------- |
| `:arg`    | arguments                                                       |
| `:var`    | all variables that must be taken out of context of the function |
| `:{name}` | named block, can be jumped to, otherwise is skipped             |

## variables
reference a variable with `%varname`.

## comments
comments are lines that begin with `//`
