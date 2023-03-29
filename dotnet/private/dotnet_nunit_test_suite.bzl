load("@rules_dotnet//dotnet:defs.bzl", "csharp_library", "csharp_test")
load("//common:browsers.bzl", "chrome_data")

def _is_test(src, test_suffixes):
    for suffix in test_suffixes:
        if src.endswith(suffix):
            return True
    return False

def dotnet_nunit_test_suite(
        name,
        srcs,
        deps = [],
        target_frameworks = None,
        test_suffixes = ["Test.cs"],
        size = None,
        tags = [],
        data = [],
        browsers = ["chrome"],
        **kwargs):
    test_srcs = [src for src in srcs if _is_test(src, test_suffixes)]
    lib_srcs = [src for src in srcs if not _is_test(src, test_suffixes)]

    extra_deps = [
        "@dotnet_deps//nunitlite",
    ]
    # if len(lib_srcs):
    #     csharp_library(
    #         name = "%s-support-lib" % name,
    #         srcs = lib_srcs,
    #         deps = deps,
    #         tags = tags,
    #         target_frameworks = target_frameworks,
    #     )
    #     extra_deps.append(":%s-support-lib" % name)

    tests = []
    for src in test_srcs:
        suffix = src.rfind(".")
        test_name = src[:suffix]

        csharp_test(
            name = test_name,
            srcs = lib_srcs + [src] + ["@rules_dotnet//dotnet/private/rules/common/nunit:shim.cs"],
            deps = deps + extra_deps,
            target_frameworks = target_frameworks,
            args = select({
                "//common:macos": [
                    "--params=ActiveDriverConfig=Firefox",
                    "--params=DriverServiceLocation=$(location @mac_geckodriver//:geckodriver)",
                    "--params=BrowserLocation=$(location @mac_firefox//:Firefox.app)/Contents/MacOS/firefox",
                ],
                "//common:linux": [
                ],
                "//conditions:default": [],
            }),
            data = data + [
                "@mac_geckodriver//:geckodriver",
                "@mac_firefox//:Firefox.app",
                "//common/src/web",
            ],
            tags = tags + [
                "browser-test",
                "no-sandbox",
                "requires-network",
            ],
            **kwargs
        )
        tests.append(test_name)

    native.test_suite(
        name = name,
        tests = tests,
        tags = ["manual"] + tags,
    )
