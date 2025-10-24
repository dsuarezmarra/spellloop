echo "Initiating Organic System Test..."
echo "Current directory: $PWD"
echo "Files in current directory:"
Get-ChildItem *.gd | Select-Object Name

echo "Running Godot test..."
Start-Process -FilePath "C:\Users\dsuarez1\Downloads\Godot\Godot_v4.5-stable_win64.exe" -ArgumentList "--path", ".", "--headless", "--quit-after", "3" -Wait -WindowStyle Hidden -RedirectStandardOutput "godot_output_simple.txt" -RedirectStandardError "godot_error_simple.txt"

echo "Test completed. Results:"
if (Test-Path "godot_output_simple.txt") {
    Get-Content "godot_output_simple.txt"
}
if (Test-Path "godot_error_simple.txt") {
    echo "Errors:"
    Get-Content "godot_error_simple.txt"
}