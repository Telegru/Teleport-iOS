load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

load(
    "@build_bazel_rules_apple//apple:resources.bzl",
    "apple_resource_bundle",
    "apple_resource_group",
)
load("//build-system/bazel-utils:plist_fragment.bzl",
    "plist_fragment",
)

filegroup(
    name = "DWallpaperImages",
    srcs = glob([
        "Resources/**/*.png",
        "Resources/**/*.svg",
    ]),
    visibility = ["//visibility:public"],
)

plist_fragment(
    name = "DWallpaperResourcesBundleInfoPlist",
    extension = "plist",
    template =
    """
    <key>CFBundleIdentifier</key>
    <string>org.telegram.DWallpaper</string>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleName</key>
    <string>DWallpaper</string>
    """
)

apple_resource_bundle(
    name = "DWallpaperResourcesBundle",
    infoplists = [
        ":DWallpaperResourcesBundleInfoPlist",
    ],
    resources = [
        ":DWallpaperImages",
    ],
)

swift_library(
    name = "DWallpaper",
    module_name = "DWallpaper",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    deps = [
        "//submodules/AppBundle:AppBundle",
        "//submodules/TelegramCore:TelegramCore",
        "//submodules/Postbox:Postbox",
    ],
    data = [
        ":DWallpaperResourcesBundle",
    ],
    copts = [
        "-warnings-as-errors",
    ],
    visibility = [
        "//visibility:public",
    ],
)
