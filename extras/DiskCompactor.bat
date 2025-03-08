@echo off
for /r %%f in (*.vhdx) do (
    echo Optimizing VHDX file: %%f
    optimize-vhd -Path "%%f" -Mode full
)
echo Optimization complete.
pause