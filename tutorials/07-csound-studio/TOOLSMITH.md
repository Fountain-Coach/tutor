Toolsmith Integration for Csound Studio

Goal: Run LilyPond engraving and Csound synthesis inside a reproducible Linux VM image via Toolsmith’s SandboxRunner (QemuRunner), so the host needs no `lilypond`/`csound` installs.

What’s Included in This Lesson
- App settings to enable a Toolsmith VM and point to an image path.
- QEMU runner hooks for:
  - Engrave `composition.ly` with `/usr/bin/lilypond` in the VM.
  - Synthesize a `.csd` to `output.wav` with `/usr/bin/csound` in the VM, then play it on the host.
- Graceful fallbacks: copy‑ready `.ly` preview and a built‑in Csound simulator if the VM isn’t available.

Prerequisites
- QEMU installed on the host (`qemu-system-x86_64`).
- A Linux image (`.qcow2` or `.img`) that:
  - Has `lilypond` and `csound` installed.
  - Mounts virtio 9p shares with tags `work` and `scratch` at boot (e.g., `/work` and `/scratch`).
  - Executes the command passed via the kernel `-append` string as PID 1 or from an init shim.

Why the 9p requirement?
QemuRunner passes two virtio 9p shares for host↔guest file exchange. The guest must mount them. A minimalist init can:

```
mount -t 9p -o trans=virtio work /work
mount -t 9p -o trans=virtio scratch /scratch
cd /work
exec /bin/sh -c "$KERNEL_CMDLINE"
```

Building a Minimal Image (Outline)
1) Start from an Ubuntu/Debian base or a tiny initrd that supports 9p and a shell.
2) Install tools inside the image:
   - Debian/Ubuntu: `apt-get update && apt-get install -y lilypond csound csound-utils`
3) Ensure 9p modules (`9p`, `9pnet`, `virtio_pci`, `virtio_fs` or `virtio-9p`) are present.
4) Add a small init that mounts `work` and `scratch`, then executes `$KERNEL_CMDLINE`.

Example QEMU Launch (what QemuRunner approximates)
```
qemu-system-x86_64 \
  -accel hvf                 # macOS (or -enable-kvm on Linux) \
  -drive file=toolbox.qcow2,if=virtio,snapshot=on \
  -virtfs local,path=$PWD,security_model=none,mount_tag=work \
  -virtfs local,path=$PWD,security_model=none,mount_tag=scratch \
  -nographic \
  -seccomp restricted.json   # optional seccomp profile \
  -append "/usr/bin/lilypond composition.ly"
```

Using the VM in Csound Studio
1) Build the app as usual (no Toolsmith dependency is required unless you want the VM path):
   - `tutor build` (from this lesson directory)
2) In the app Settings:
   - Toggle “Use Toolsmith VM for Engraving/Synthesis”.
   - Paste the absolute path to your image (`.qcow2`/`.img`).
3) Engrave or Play:
   - If LilyPond is missing locally, “Engrave PDF” will run in the VM.
   - “Play” will synthesize via `csound` in the VM if enabled.

Optional: Add Toolsmith Package to Compile In Runners
If you want the VM path enabled at build time by default, add the Toolsmith package to this lesson’s `Package.swift` and link `SandboxRunner`:

```
// In dependencies:
.package(url: "https://github.com/Fountain-Coach/toolsmith.git", branch: "main"),

// In target dependencies for CsoundStudio:
dependencies: ["SandboxRunner"],
```

Note: This lesson already guards all calls with `#if canImport(SandboxRunner)`; the app will build and run without Toolsmith and simply show fallbacks.

Future Option: Bwrap (Linux Host)
If you have bubblewrap and host tools installed:
- Use Toolsmith’s `BwrapRunner` to execute `/usr/bin/lilypond` and `/usr/bin/csound` safely on Linux.
- This is faster than a VM but still requires host packages.

