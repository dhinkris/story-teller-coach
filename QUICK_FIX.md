# Quick Fix: "No supported iOS devices are available"

## Immediate Solution

1. **Look at the top toolbar in Xcode** - you'll see a device selector next to the Play button
2. **Click the device selector dropdown** - it might say "Any iOS Device" or show an error
3. **Select a simulator** from the list:
   - iPhone 15
   - iPhone 15 Pro
   - iPhone 14
   - iPad Pro
   - Or any other available simulator

## If No Simulators Appear

### Option 1: Download Simulators
1. Go to **Xcode → Settings** (or **Preferences**)
2. Click the **Platforms** tab (or **Components** in older Xcode)
3. Look for **iOS 16.0** or later
4. Click the **Download** button (cloud icon) if not installed
5. Wait for download to complete
6. Return to Xcode and select the simulator

### Option 2: Create New Simulator
1. Go to **Xcode → Window → Devices and Simulators** (or press `Cmd+Shift+2`)
2. Click the **"+"** button in the bottom left
3. Choose:
   - **Device Type**: iPhone 15 (or any iPhone)
   - **OS Version**: iOS 16.0 or later
4. Click **Create**
5. Select this new simulator from the device selector

### Option 3: Use Physical Device
1. Connect your iPhone/iPad via USB
2. Unlock your device
3. Trust the computer if prompted
4. Select your device from the device selector in Xcode

## After Selecting a Simulator

1. The device selector should now show your chosen simulator
2. Press **Cmd+R** or click the **Play** button
3. The app should build and launch in the simulator

## Still Having Issues?

- Make sure you have Xcode 14.0 or later installed
- Try restarting Xcode
- Check that your Mac meets the system requirements for running simulators
