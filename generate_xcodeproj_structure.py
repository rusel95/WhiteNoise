#!/usr/bin/env python3
"""
Generate proper Xcode project structure for WhiteNoise
This creates a mapping of all files that should be in the project
"""

import os
import json
from pathlib import Path

def scan_directory(base_path):
    """Scan directory and create file structure"""
    structure = {
        "WhiteNoise": {
            "type": "group",
            "path": "WhiteNoise",
            "children": {
                "App": {
                    "type": "group",
                    "children": {
                        "WhiteNoiseApp.swift": {"type": "file", "path": "WhiteNoise/WhiteNoiseApp.swift"},
                        "Info.plist": {"type": "file", "path": "WhiteNoise/Info.plist"},
                        "WhiteNoise.entitlements": {"type": "file", "path": "WhiteNoise/WhiteNoise.entitlements"},
                        "LaunchScreen.storyboard": {"type": "file", "path": "WhiteNoise/LaunchScreen.storyboard"}
                    }
                },
                "Models": {
                    "type": "group",
                    "path": "WhiteNoise/Models",
                    "children": {}
                },
                "Views": {
                    "type": "group", 
                    "path": "WhiteNoise/Views",
                    "children": {}
                },
                "ViewModels": {
                    "type": "group",
                    "path": "WhiteNoise/ViewModels", 
                    "children": {}
                },
                "Services": {
                    "type": "group",
                    "path": "WhiteNoise/Services",
                    "children": {}
                },
                "Constants": {
                    "type": "group",
                    "path": "WhiteNoise/Constants",
                    "children": {}
                },
                "Extensions": {
                    "type": "group",
                    "path": "WhiteNoise/Extensions",
                    "children": {}
                },
                "Resources": {
                    "type": "group",
                    "path": "WhiteNoise/Resources",
                    "children": {}
                },
                "Sounds": {
                    "type": "group",
                    "path": "WhiteNoise/Sounds",
                    "children": {}
                },
                "Assets.xcassets": {
                    "type": "folder",
                    "path": "WhiteNoise/Assets.xcassets"
                },
                "Preview Content": {
                    "type": "group",
                    "path": "WhiteNoise/Preview Content",
                    "children": {
                        "Preview Assets.xcassets": {
                            "type": "folder",
                            "path": "WhiteNoise/Preview Content/Preview Assets.xcassets"
                        }
                    }
                }
            }
        }
    }
    
    # Scan each directory for files
    groups_to_scan = [
        ("Models", "*.swift"),
        ("Views", "*.swift"),
        ("ViewModels", "*.swift"),
        ("Services", "*.swift"),
        ("Constants", "*.swift"),
        ("Extensions", "*.swift"),
        ("Resources", "*.json"),
    ]
    
    for group_name, pattern in groups_to_scan:
        group_path = os.path.join(base_path, "WhiteNoise", group_name)
        if os.path.exists(group_path):
            for file in Path(group_path).glob(pattern):
                if file.is_file():
                    structure["WhiteNoise"]["children"][group_name]["children"][file.name] = {
                        "type": "file",
                        "path": f"WhiteNoise/{group_name}/{file.name}"
                    }
    
    # Scan Sounds directory recursively
    sounds_path = os.path.join(base_path, "WhiteNoise", "Sounds")
    if os.path.exists(sounds_path):
        for subdir in os.listdir(sounds_path):
            subdir_path = os.path.join(sounds_path, subdir)
            if os.path.isdir(subdir_path):
                structure["WhiteNoise"]["children"]["Sounds"]["children"][subdir] = {
                    "type": "group",
                    "path": f"WhiteNoise/Sounds/{subdir}",
                    "children": {}
                }
                for file in Path(subdir_path).glob("*"):
                    if file.is_file() and not file.name.startswith('.'):
                        structure["WhiteNoise"]["children"]["Sounds"]["children"][subdir]["children"][file.name] = {
                            "type": "file",
                            "path": f"WhiteNoise/Sounds/{subdir}/{file.name}"
                        }
    
    return structure

def print_structure(structure, indent=0):
    """Print the structure in a readable format"""
    for key, value in structure.items():
        if isinstance(value, dict):
            if value.get("type") == "group":
                print("  " * indent + f"📁 {key}/")
                if "children" in value:
                    print_structure(value["children"], indent + 1)
            elif value.get("type") == "file":
                print("  " * indent + f"📄 {key}")
            elif value.get("type") == "folder":
                print("  " * indent + f"📦 {key}")
            else:
                print("  " * indent + f"{key}")
                print_structure(value, indent + 1)

def generate_file_list(structure, group_name=""):
    """Generate a flat list of all files that need to be added"""
    files = []
    
    def traverse(node, current_group=""):
        for key, value in node.items():
            if isinstance(value, dict):
                if value.get("type") == "file":
                    files.append({
                        "name": key,
                        "path": value["path"],
                        "group": current_group
                    })
                elif value.get("type") == "group" and "children" in value:
                    new_group = f"{current_group}/{key}" if current_group else key
                    traverse(value["children"], new_group)
                elif "children" in value:
                    traverse(value["children"], current_group)
    
    traverse(structure)
    return files

if __name__ == "__main__":
    base_path = "/Users/Ruslan_Popesku/Desktop/WhiteNoise"
    
    print("🔍 Scanning WhiteNoise project structure...\n")
    
    structure = scan_directory(base_path)
    
    print("📂 Recommended Xcode Project Structure:")
    print("=" * 50)
    print_structure(structure)
    
    print("\n📋 All files to be included in project:")
    print("=" * 50)
    
    files = generate_file_list(structure)
    
    # Group files by their group
    grouped_files = {}
    for file in files:
        group = file["group"]
        if group not in grouped_files:
            grouped_files[group] = []
        grouped_files[group].append(file)
    
    # Print grouped files
    for group, files in sorted(grouped_files.items()):
        print(f"\n{group}:")
        for file in sorted(files, key=lambda x: x["name"]):
            print(f"  - {file['name']} ({file['path']})")
    
    # Save structure to JSON for reference
    with open(os.path.join(base_path, "project_structure.json"), "w") as f:
        json.dump(structure, f, indent=2)
    
    print(f"\n✅ Project structure saved to project_structure.json")
    print("\n📝 To reorganize your project:")
    print("1. Run ./REORGANIZE_PROJECT.sh to move files")
    print("2. Open Xcode and remove all red (missing) references")
    print("3. Add files according to the structure above")
    print("4. Make sure Resources/SoundConfiguration.json is in 'Copy Bundle Resources'")