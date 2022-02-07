# Get started

## Requirements
Agar VM has no runtime dependencies. You can download it from the [releases page](../../releases). If your platform isn't listed, continue to the building from source section.

## Building from source
If you want to build Agar from source you will need the zig compiler version `0.9.*`, nothing else is nescessary.

### From `main` branch
1. clone the repository
```bash
git clone https://github.com/kelp-lang/agar.git
# or
wget https://github.com/kelp-lang/agar
```
2. run the zig compiler
```bash
cd agar
zig build -Drelease-safe
```
3. copy the file to desired location
```bash
cp zig-out/bin/agar the/desired/location
```
### From latest release
Simply download the source code from the releases page. After unziping the archive, continue with the second step from the previous tutorial.

---

If you have the `agar` executable working, let's move to [actually using it](./first_steps.md).