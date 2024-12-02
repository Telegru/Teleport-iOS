load("@build_bazel_rules_apple//apple:apple.bzl", "local_provisioning_profile", "apple_dynamic_xcframework_import")

apple_dynamic_xcframework_import(
    name = "VKSdkFrameworXC",
    xcframework_imports = glob(["VKSdkFramework.xcframework/**"]),
)

objc_library(
    name = "VKSdkFramework",
    deps = [
        ":VKSdkFrameworXC",
    ],
    visibility = ["//visibility:public"],
)
