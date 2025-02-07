load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")


filegroup(
    name = "TPUIAssets",
    srcs = glob(["Resources/Images.xcassets/**"]),
    visibility = ["//visibility:public"],
)

filegroup(
    name = "TPUIRaw",
    srcs = [
        "ChatWallpaperBuiltin0.jpg",
    ],
    visibility = ["//visibility:public"],
)

swift_library(
    name = "TPUI",
    module_name = "TPUI",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    deps = [
        "//submodules/AppBundle:AppBundle",
    ],
    copts = [
        "-warnings-as-errors",
    ],
    visibility = [
        "//visibility:public",
    ],
)
