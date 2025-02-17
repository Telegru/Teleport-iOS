load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")


filegroup(
    name = "DWallpaperImages",
    srcs = glob([
        "Resources/**/*.png",
        "Resources/**/*.svg",
    ]),
    visibility = ["//visibility:public"],
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
    copts = [
        "-warnings-as-errors",
    ],
    visibility = [
        "//visibility:public",
    ],
)
