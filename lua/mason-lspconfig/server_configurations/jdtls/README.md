# jdtls

## Customizing JVM arguments

It's possible to customize some of the JVM arguments used to launch the server by setting the `vmargs` configuration.
This can for example be used to change the memory configuration.

Example::

```lua
lspconfig.jdtls.setup {
    vmargs = {
        "-XX:+UseParallelGC",
        "-XX:GCTimeRatio=4",
        "-XX:AdaptiveSizePolicyWeight=90",
        "-Dsun.zip.disableMemoryMapping=true",
        "-Djava.import.generatesMetadataFilesAtProjectRoot=false",
        "-Xmx1G",
        "-Xms100m",
    }
}
```

## Enable Lombok support

Lombok support is disabled by default. To enable Lombok support, set the `use_lombok_agent` configuration to `true`
during setup, like so:

```lua
lspconfig.jdtls.setup {
    use_lombok_agent = true
}
```
