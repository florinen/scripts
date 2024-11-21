# Set the screenshot directory
$screenshotDir = "C:\Screenshots"

# Create the directory if it doesn't exist
if (-not (Test-Path -Path $screenshotDir)) {
    New-Item -ItemType Directory -Path $screenshotDir | Out-Null
}

# Function to capture the screenshot
function Take-Screenshot {
    try {
        # Get the primary screen's dimensions
        $screen = [System.Windows.Forms.Screen]::PrimaryScreen
        $width = $screen.Bounds.Width
        $height = $screen.Bounds.Height

        # Create the bitmap and graphics objects
        $bitmap = New-Object System.Drawing.Bitmap $width, $height
        $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
        
        # Capture the screen
        $graphics.CopyFromScreen($screen.Bounds.X, $screen.Bounds.Y, 0, 0, $bitmap.Size)

        # Save the screenshot
        $timestamp = (Get-Date -Format "yyyyMMdd-HHmmss")
        $screenshotPath = Join-Path -Path $screenshotDir -ChildPath "screenshot_$timestamp.png"
        $bitmap.Save($screenshotPath, [System.Drawing.Imaging.ImageFormat]::Png)

        # Cleanup
        $graphics.Dispose()
        $bitmap.Dispose()

        Write-Host "Screenshot saved: $screenshotPath"
    } catch {
        Write-Error "Failed to take screenshot: $_"
    }
}

# Add necessary assemblies
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms

# Infinite loop to take screenshots every 15 seconds
Write-Host "Starting screenshot capture. Press Ctrl+C to stop."
while ($true) {
    Take-Screenshot
    Start-Sleep -Seconds 15
}
