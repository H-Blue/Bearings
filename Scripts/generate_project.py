#!/usr/bin/env python3
"""Generate the dependency-free ReCollect Xcode project and shared scheme.

Run from any directory. Source membership is explicit and refreshed on each run;
stable SHA-256 object identifiers keep project diffs focused and reproducible.
"""

from __future__ import annotations

import hashlib
import json
from pathlib import Path
import re
import xml.etree.ElementTree as ET


ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "ReCollect.xcodeproj"
OBJECTS: dict[str, dict] = {}


def identifier(key: str) -> str:
    return hashlib.sha256(("ReCollect:" + key).encode()).hexdigest()[:24].upper()


def add(key: str, isa: str, **attributes) -> str:
    object_id = identifier(key)
    value = {"isa": isa, **attributes}
    if object_id in OBJECTS and OBJECTS[object_id] != value:
        raise ValueError(f"Conflicting object identifier for {key}")
    OBJECTS[object_id] = value
    return object_id


def serialize(value, depth: int = 0) -> str:
    indent = "\t" * depth
    child_indent = "\t" * (depth + 1)
    if isinstance(value, dict):
        items = []
        for key, item in value.items():
            escaped_key = key if re.fullmatch(r"[A-Za-z0-9_]+", key) else json.dumps(key)
            items.append(f"{child_indent}{escaped_key} = {serialize(item, depth + 1)};")
        return "{\n" + "\n".join(items) + "\n" + indent + "}"
    if isinstance(value, list):
        return "(\n" + "\n".join(f"{child_indent}{serialize(item, depth + 1)}," for item in value) + "\n" + indent + ")"
    if isinstance(value, int):
        return str(value)
    return json.dumps(str(value), ensure_ascii=False)


def source_group(directory: Path) -> tuple[str, list[str], list[str]]:
    """Return a native group and build-phase membership beneath a directory."""
    relative = directory.relative_to(ROOT).as_posix()
    children: list[str] = []
    sources: list[str] = []
    resources: list[str] = []
    if directory.exists():
        for child in sorted(directory.iterdir(), key=lambda path: path.name):
            child_relative = child.relative_to(ROOT).as_posix()
            if child.is_dir() and child.suffix != ".xcassets":
                group, nested_sources, nested_resources = source_group(child)
                children.append(group)
                sources.extend(nested_sources)
                resources.extend(nested_resources)
            elif child.suffix in {".swift", ".xcassets", ".xcprivacy"}:
                file_type = {".swift": "sourcecode.swift", ".xcassets": "folder.assetcatalog", ".xcprivacy": "text.xml"}[child.suffix]
                file_id = add(f"file:{child_relative}", "PBXFileReference", lastKnownFileType=file_type,
                              path=child.name, sourceTree="<group>")
                children.append(file_id)
                build_id = add(f"build:{child_relative}", "PBXBuildFile", fileRef=file_id)
                (sources if child.suffix == ".swift" else resources).append(build_id)
    group_id = add(f"group:{relative}", "PBXGroup", children=children, path=directory.name, sourceTree="<group>")
    return group_id, sources, resources


def configuration_list(key: str, configurations: dict[str, dict]) -> str:
    ids = [add(f"configuration:{key}:{name}", "XCBuildConfiguration", buildSettings=settings, name=name)
           for name, settings in configurations.items()]
    return add(f"configuration-list:{key}", "XCConfigurationList", buildConfigurations=ids,
               defaultConfigurationIsVisible=0, defaultConfigurationName="Release")


def phase(target: str, kind: str, files: list[str]) -> str:
    return add(f"phase:{target}:{kind}", f"PBX{kind}BuildPhase", buildActionMask=2147483647,
               files=files, runOnlyForDeploymentPostprocessing=0)


def target_settings(name: str) -> dict:
    settings = {
        "CODE_SIGN_STYLE": "Automatic",
        "CURRENT_PROJECT_VERSION": "1",
        "GENERATE_INFOPLIST_FILE": "YES",
        "IPHONEOS_DEPLOYMENT_TARGET": "17.0",
        "MARKETING_VERSION": "0.1.0",
        "PRODUCT_BUNDLE_IDENTIFIER": f"com.recollect.{name}",
        "PRODUCT_NAME": "$(TARGET_NAME)",
        "SUPPORTED_PLATFORMS": "iphoneos iphonesimulator",
        "SUPPORTS_MACCATALYST": "NO",
        "SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD": "NO",
        "SWIFT_VERSION": "5.0",
        "TARGETED_DEVICE_FAMILY": "1",
    }
    if name == "ReCollect":
        settings.update({
            "ENABLE_PREVIEWS": "YES",
            "INFOPLIST_KEY_CFBundleDisplayName": "ReCollect",
            "INFOPLIST_KEY_UIApplicationSceneManifest_Generation": "YES",
            "INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents": "YES",
            "INFOPLIST_KEY_UILaunchScreen_Generation": "YES",
            "INFOPLIST_KEY_UISupportedInterfaceOrientations": "UIInterfaceOrientationPortrait",
            "LD_RUNPATH_SEARCH_PATHS": ["$(inherited)", "@executable_path/Frameworks"],
            "SWIFT_EMIT_LOC_STRINGS": "YES",
        })
        if (ROOT / "ReCollect/Resources/Assets.xcassets/AppIcon.appiconset").exists():
            settings["ASSETCATALOG_COMPILER_APPICON_NAME"] = "AppIcon"
    else:
        settings["LD_RUNPATH_SEARCH_PATHS"] = ["$(inherited)", "@executable_path/Frameworks", "@loader_path/Frameworks"]
        if name == "ReCollectTests":
            settings["BUNDLE_LOADER"] = "$(TEST_HOST)"
            settings["TEST_HOST"] = "$(BUILT_PRODUCTS_DIR)/ReCollect.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/ReCollect"
        else:
            settings["TEST_TARGET_NAME"] = "ReCollect"
    return settings


def build_project() -> dict[str, str]:
    project_id = identifier("project")
    names = ["ReCollect", "ReCollectTests", "ReCollectUITests"]
    target_ids = {name: identifier(f"target:{name}") for name in names}
    groups = []
    products = []
    for name in names:
        group, sources, resources = source_group(ROOT / name)
        groups.append(group)
        is_app = name == "ReCollect"
        product = add(f"product:{name}", "PBXFileReference", explicitFileType="wrapper.application" if is_app else "wrapper.cfbundle",
                      includeInIndex=0, path=f"{name}.{'app' if is_app else 'xctest'}", sourceTree="BUILT_PRODUCTS_DIR")
        products.append(product)
        settings = target_settings(name)
        configs = configuration_list(name, {"Debug": dict(settings), "Release": dict(settings)})
        dependencies = []
        if not is_app:
            proxy = add(f"proxy:{name}:ReCollect", "PBXContainerItemProxy", containerPortal=project_id,
                        proxyType=1, remoteGlobalIDString=target_ids["ReCollect"], remoteInfo="ReCollect")
            dependencies.append(add(f"dependency:{name}:ReCollect", "PBXTargetDependency", target=target_ids["ReCollect"], targetProxy=proxy))
        add(f"target:{name}", "PBXNativeTarget", buildConfigurationList=configs,
            buildPhases=[phase(name, "Sources", sources), phase(name, "Frameworks", []), phase(name, "Resources", resources)],
            buildRules=[], dependencies=dependencies, name=name, productName=name, productReference=product,
            productType="com.apple.product-type.application" if is_app else
                        ("com.apple.product-type.bundle.unit-test" if name == "ReCollectTests" else "com.apple.product-type.bundle.ui-testing"))

    products_group = add("group:Products", "PBXGroup", children=products, name="Products", sourceTree="<group>")
    main_group = add("group:main", "PBXGroup", children=[*groups, products_group], sourceTree="<group>")
    common = {
        "ALWAYS_SEARCH_USER_PATHS": "NO",
        "CLANG_ENABLE_MODULES": "YES",
        "CLANG_ENABLE_OBJC_ARC": "YES",
        "CLANG_WARN_DOCUMENTATION_COMMENTS": "YES",
        "CLANG_WARN_OBJC_ROOT_CLASS": "YES_ERROR",
        "ENABLE_STRICT_OBJC_MSGSEND": "YES",
        "GCC_C_LANGUAGE_STANDARD": "gnu17",
        "GCC_NO_COMMON_BLOCKS": "YES",
        "GCC_WARN_64_TO_32_BIT_CONVERSION": "YES",
        "GCC_WARN_ABOUT_RETURN_TYPE": "YES_ERROR",
        "GCC_WARN_UNDECLARED_SELECTOR": "YES",
        "GCC_WARN_UNINITIALIZED_AUTOS": "YES_AGGRESSIVE",
        "GCC_WARN_UNUSED_FUNCTION": "YES",
        "GCC_WARN_UNUSED_VARIABLE": "YES",
        "IPHONEOS_DEPLOYMENT_TARGET": "17.0",
        "SDKROOT": "iphoneos",
        "SWIFT_VERSION": "5.0",
    }
    debug = {**common, "DEBUG_INFORMATION_FORMAT": "dwarf", "ENABLE_TESTABILITY": "YES",
             "GCC_OPTIMIZATION_LEVEL": "0", "GCC_PREPROCESSOR_DEFINITIONS": ["DEBUG=1", "$(inherited)"],
             "ONLY_ACTIVE_ARCH": "YES", "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "DEBUG $(inherited)",
             "SWIFT_OPTIMIZATION_LEVEL": "-Onone"}
    release = {**common, "DEBUG_INFORMATION_FORMAT": "dwarf-with-dsym", "SWIFT_COMPILATION_MODE": "wholemodule",
               "SWIFT_OPTIMIZATION_LEVEL": "-O", "VALIDATE_PRODUCT": "YES"}
    project_configs = configuration_list("project", {"Debug": debug, "Release": release})
    attributes = {target_ids[name]: {"CreatedOnToolsVersion": "16.0", **({"TestTargetID": target_ids["ReCollect"]} if name != "ReCollect" else {})}
                  for name in names}
    add("project", "PBXProject", attributes={"BuildIndependentTargetsInParallel": "YES", "LastUpgradeCheck": "1600", "TargetAttributes": attributes},
        buildConfigurationList=project_configs, compatibilityVersion="Xcode 14.0", developmentRegion="en",
        hasScannedForEncodings=0, knownRegions=["en", "Base"], mainGroup=main_group, productRefGroup=products_group,
        projectDirPath="", projectRoot="", targets=[target_ids[name] for name in names])
    payload = {"archiveVersion": 1, "classes": {}, "objectVersion": 56,
               "objects": dict(sorted(OBJECTS.items())), "rootObject": project_id}
    PROJECT.mkdir(parents=True, exist_ok=True)
    (PROJECT / "project.pbxproj").write_text("// !$*UTF8*$!\n" + serialize(payload) + "\n")
    return target_ids


def buildable(parent, name: str, target_ids: dict[str, str]) -> None:
    ET.SubElement(parent, "BuildableReference", BuildableIdentifier="primary", BlueprintIdentifier=target_ids[name],
                  BuildableName=f"{name}.{'app' if name == 'ReCollect' else 'xctest'}", BlueprintName=name,
                  ReferencedContainer="container:ReCollect.xcodeproj")


def write_scheme(target_ids: dict[str, str]) -> None:
    scheme = ET.Element("Scheme", LastUpgradeVersion="1600", version="1.7")
    action = ET.SubElement(scheme, "BuildAction", parallelizeBuildables="YES", buildImplicitDependencies="YES")
    entries = ET.SubElement(action, "BuildActionEntries")
    for name in target_ids:
        is_app = name == "ReCollect"
        entry = ET.SubElement(entries, "BuildActionEntry", buildForTesting="YES", buildForRunning="YES" if is_app else "NO",
                              buildForProfiling="YES" if is_app else "NO", buildForArchiving="YES" if is_app else "NO",
                              buildForAnalyzing="YES")
        buildable(entry, name, target_ids)
    action = ET.SubElement(scheme, "TestAction", buildConfiguration="Debug", selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB",
                           selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB", shouldUseLaunchSchemeArgsEnv="YES")
    testables = ET.SubElement(action, "Testables")
    for name in ["ReCollectTests", "ReCollectUITests"]:
        testable = ET.SubElement(testables, "TestableReference", skipped="NO", parallelizable="NO")
        buildable(testable, name, target_ids)
    buildable(ET.SubElement(action, "MacroExpansion"), "ReCollect", target_ids)
    action = ET.SubElement(scheme, "LaunchAction", buildConfiguration="Debug", selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB",
                           selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB", launchStyle="0", useCustomWorkingDirectory="NO",
                           ignoresPersistentStateOnLaunch="NO", debugDocumentVersioning="YES", debugServiceExtension="internal", allowLocationSimulation="YES")
    buildable(ET.SubElement(action, "BuildableProductRunnable", runnableDebuggingMode="0"), "ReCollect", target_ids)
    action = ET.SubElement(scheme, "ProfileAction", buildConfiguration="Release", shouldUseLaunchSchemeArgsEnv="YES",
                           savedToolIdentifier="", useCustomWorkingDirectory="NO", debugDocumentVersioning="YES")
    buildable(ET.SubElement(action, "BuildableProductRunnable", runnableDebuggingMode="0"), "ReCollect", target_ids)
    ET.SubElement(scheme, "AnalyzeAction", buildConfiguration="Debug")
    ET.SubElement(scheme, "ArchiveAction", buildConfiguration="Release", revealArchiveInOrganizer="YES")
    ET.indent(scheme, space="   ")
    scheme_directory = PROJECT / "xcshareddata/xcschemes"
    scheme_directory.mkdir(parents=True, exist_ok=True)
    ET.ElementTree(scheme).write(scheme_directory / "ReCollect.xcscheme", encoding="UTF-8", xml_declaration=True)
    workspace = PROJECT / "project.xcworkspace"
    workspace.mkdir(parents=True, exist_ok=True)
    (workspace / "contents.xcworkspacedata").write_text('<?xml version="1.0" encoding="UTF-8"?>\n<Workspace version="1.0">\n   <FileRef location="self:"></FileRef>\n</Workspace>\n')


if __name__ == "__main__":
    write_scheme(build_project())
    print("Generated ReCollect.xcodeproj with shared ReCollect scheme (app, unit tests, UI tests).")
