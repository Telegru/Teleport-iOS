load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "TPNews",
    module_name = "TPNews",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    deps = [
        "//Teleport/TPStrings:TPStrings",
        "//submodules/AsyncDisplayKit:AsyncDisplayKit",
        "//submodules/Display:Display",
        "//submodules/SSignalKit/SwiftSignalKit:SwiftSignalKit",
        "//submodules/TelegramCore:TelegramCore",
        "//submodules/TelegramPresentationData:TelegramPresentationData",
        "//submodules/AccountContext:AccountContext",
        "//Telegram:VKSdkFramework",        
    ],
    copts = [
        "-warnings-as-errors",
    ],
    visibility = [
        "//visibility:public",
    ],
)
