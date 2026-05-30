import os
from PIL import Image

def make_transparent(source_path, target_path):
    print(f"Converting {source_path} to transparent...")
    img = Image.open(source_path).convert("RGBA")
    datas = img.getdata()

    newData = []
    # Any brightness (max of RGB) at or below this value will be 100% transparent.
    # The maximum background noise brightness in the outer border is 37.
    # Setting min_val = 40 completely eliminates the background box.
    min_val = 40
    max_val = 140

    for item in datas:
        r, g, b, a = item
        brightness = max(r, g, b)
        
        if brightness <= min_val:
            new_a = 0
            # Set the color to black for fully transparent pixels to prevent color bleeding
            newData.append((0, 0, 0, 0))
        elif brightness >= max_val:
            newData.append((r, g, b, 255))
        else:
            new_a = int((brightness - min_val) / (max_val - min_val) * 255)
            newData.append((r, g, b, new_a))

    img.putdata(newData)
    img.save(target_path, "PNG")
    print(f"Saved transparent image to {target_path}")

if __name__ == "__main__":
    source = "/home/sanjay/.gemini/antigravity-ide/brain/c3cf81e2-4ae2-44b7-a30e-cc8755f60ab2/streak_tracker_logo_1780129568028.png"
    
    # Generate transparent icons & splashes
    make_transparent(source, "/home/sanjay/projects/streak-tracker-flutter/assets/icon/icon.png")
    make_transparent(source, "/home/sanjay/projects/streak-tracker-flutter/assets/splash/splash.png")
    make_transparent(source, "/home/sanjay/projects/streak-tracker-flutter/assets/splash/splash_dark.png")
