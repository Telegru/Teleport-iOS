load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

filegroup(
    name = "DOnboardingAssets",
    srcs = glob(["Resources/Images.xcassets/**"]),
    visibility = ["//visibility:public"],
)

swift_library(
    name = "DOnboarding",
    module_name = "DOnboarding",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    deps = [
        "//Teleport/TPStrings:TPStrings",
        "//submodules/AppBundle:AppBundle",
        "//submodules/SSignalKit/SSignalKit:SSignalKit",
        "//submodules/LegacyComponents:LegacyComponents",
        "//submodules/RMIntro:RMIntro",
    ],
    copts = [
        "-warnings-as-errors",
    ],
    visibility = [
        "//visibility:public",
    ],
)
