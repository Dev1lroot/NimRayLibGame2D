nim c --verbosity:3 --threads:on --mm:orc -d:useMalloc client.nim
client.exe --addr:127.0.0.1 --port:3000
pause