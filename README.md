# spipe
We have two version of pipeline, they all transform raw image stack to omni project.
- julia: can only handle limited size image stack. Size constrained by memory.
- python: can handle very large (1TB) dataset. out-of-core computing.
