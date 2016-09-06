Do NOT trust this code!
Read and understand it yourself BEFORE running this!

If you want to run this and dump everything into a file or sendmail run this:
```
bash benchmark.sh | tee -i "$TEMP_DIR/benchmark.sh.log" | cat "$TEMP_DIR/benchmark.sh.log" | sendmail
```

Dependencies:
- bash
- any aes kernel module
- any sha256 kernel module
- xts kernel module
- tempfs (ramdisk support)
- truncate
- cryptsetup
- xfs kernel module
- tee

