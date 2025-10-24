@echo off
echo Running Organic System Compilation Test...
"C:\Users\dsuarez1\Downloads\Godot\Godot_v4.5-stable_win64.exe" -s test_compilation.gd > compilation_test_output.txt 2>&1
echo Test completed. Check compilation_test_output.txt for results.
type compilation_test_output.txt