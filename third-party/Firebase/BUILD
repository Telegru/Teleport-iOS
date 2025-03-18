load(
    "@build_bazel_rules_apple//apple:apple.bzl",
    "apple_static_xcframework_import"
)

apple_static_xcframework_import(
    name = "FirebaseAnalytics",
    xcframework_imports = glob([
        "Firebase/FirebaseAnalytics/FirebaseAnalytics.xcframework/**"
    ]),
    deps = [
        ":FirebaseCore",
        ":FirebaseInstallations",
        ":GoogleAppMeasurement",
        ":GoogleAppMeasurementIdentitySupport",
        ":GoogleUtilities",
        ":nanopb"
    ],
    visibility = ["//visibility:public"]
)

apple_static_xcframework_import(
    name = "FirebaseCore",
    xcframework_imports = glob([
        "Firebase/FirebaseAnalytics/FirebaseCore.xcframework/**"
    ]),
    deps = [
        ":FirebaseCoreInternal",
        ":GoogleUtilities"
    ],
    visibility = ["//visibility:public"]
)

apple_static_xcframework_import(
    name = "FBLPromises",
    xcframework_imports = glob([
        "Firebase/FirebaseAnalytics/FBLPromises.xcframework/**"
    ]),
    visibility = ["//visibility:public"]
)

apple_static_xcframework_import(
    name = "FirebaseCoreInternal",
    xcframework_imports = glob([
        "Firebase/FirebaseAnalytics/FirebaseCoreInternal.xcframework/**"
    ]),
    deps = [
        ":GoogleUtilities"
    ],
    visibility = ["//visibility:public"]
)

# apple_static_xcframework_import(
#     name = "FirebaseCoreDiagnostics",
#     xcframework_imports = glob([
#         "Firebase/FirebaseAnalytics/FirebaseCoreDiagnostics.xcframework/**"
#     ]),
#     deps = [
#         ":FirebaseAnalytics"
#     ],
#     visibility = ["//visibility:public"]
# )

apple_static_xcframework_import(
    name = "FirebaseInstallations",
    xcframework_imports = glob([
        "Firebase/FirebaseAnalytics/FirebaseInstallations.xcframework/**"
    ]),
    deps = [
        ":FirebaseCore",
        ":GoogleUtilities",
        ":Promises",
        ":GoogleAppMeasurement",
        ":GoogleAppMeasurementIdentitySupport",
    ],
    visibility = ["//visibility:public"]
)

apple_static_xcframework_import(
    name = "GoogleAppMeasurement",
    xcframework_imports = glob([
        "Firebase/FirebaseAnalytics/GoogleAppMeasurement.xcframework/**"
    ]),
    deps = [
        ":GoogleUtilities",
        ":nanopb"
    ],
    visibility = ["//visibility:public"]
)

apple_static_xcframework_import(
    name = "GoogleAppMeasurementIdentitySupport",
    xcframework_imports = glob([
        "Firebase/FirebaseAnalytics/GoogleAppMeasurementIdentitySupport.xcframework/**"
    ]),
    visibility = ["//visibility:public"]
)

apple_static_xcframework_import(
    name = "GoogleUtilities",
    xcframework_imports = glob([
        "Firebase/FirebaseAnalytics/GoogleUtilities.xcframework/**"
    ]),
    visibility = ["//visibility:public"]
)

apple_static_xcframework_import(
    name = "nanopb",
    xcframework_imports = glob([
        "Firebase/FirebaseAnalytics/nanopb.xcframework/**"
    ]),
    visibility = ["//visibility:public"]
)

apple_static_xcframework_import(
    name = "Promises",
    xcframework_imports = glob([
        "Firebase/FirebaseCrashlytics/Promises.xcframework/**"
    ]),
    deps = [
        ":FBLPromises"
    ],
    visibility = ["//visibility:public"]
)

apple_static_xcframework_import(
    name = "FirebaseCrashlytics",
    xcframework_imports = glob([
        "Firebase/FirebaseCrashlytics/FirebaseCrashlytics.xcframework/**"
    ]),
    deps = [
        ":FirebaseCore",
        ":FirebaseInstallations",
        ":FirebaseSessions",
        ":GoogleDataTransport",
        ":FirebaseRemoteConfigInterop",
        ":GoogleUtilities",
        ":Promises",
        ":nanopb"
    ],
    visibility = ["//visibility:public"]
)

apple_static_xcframework_import(
    name = "FirebaseSessions",
    xcframework_imports = glob([
        "Firebase/FirebaseCrashlytics/FirebaseSessions.xcframework/**"
    ]),
    deps = [
        ":FirebaseCore",
        ":FirebaseInstallations",
        ":GoogleDataTransport",
        ":GoogleUtilities",
        ":Promises",
        ":nanopb"
    ],
    visibility = ["//visibility:public"]
)

apple_static_xcframework_import(
    name = "GoogleDataTransport",
    xcframework_imports = glob([
        "Firebase/FirebaseCrashlytics/GoogleDataTransport.xcframework/**"
    ]),
    visibility = ["//visibility:public"]
)

apple_static_xcframework_import(
    name = "FirebaseRemoteConfigInterop",
    xcframework_imports = glob([
        "Firebase/FirebaseCrashlytics/FirebaseRemoteConfigInterop.xcframework/**"
    ]),
    visibility = ["//visibility:public"]
)