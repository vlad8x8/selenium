load("@rules_dotnet//dotnet:defs.bzl", "csharp_library", "csharp_test")
load("//common:browsers.bzl", "chrome_data")

_BROWSERS = {
    "chrome": {
        "args": [],
        "data": [],
    },
    "firefox": {
        "args": [
            "--params=ActiveDriverConfig=Firefox",
        ] + select({
            "//common:macos": [
                "--params=DriverServiceLocation=$(location @mac_geckodriver//:geckodriver)",
                "--params=BrowserLocation=$(location @mac_firefox//:Firefox.app)/Contents/MacOS/firefox",
            ],
            "//common:linux": [
            ],
            "//conditions:default": [],
        }),
        "data": [
            "@mac_geckodriver//:geckodriver",
            "@mac_firefox//:Firefox.app",
            "//common/src/web",
        ],
    },
}

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
        browsers = None,
        **kwargs):
    test_srcs = [src for src in srcs if _is_test(src, test_suffixes)]
    lib_srcs = [src for src in srcs if not _is_test(src, test_suffixes)]

    extra_deps = [
        "@dotnet_deps//nunitlite",
    ]

    if browsers and len(browsers):
        default_browser = browsers[0]
    else:
        default_browser = None

    tests = []
    for src in test_srcs:
        suffix = src.rfind(".")
        test_name = src[:suffix]

        if not browsers or not len(browsers):
            csharp_test(
                name = test_name,
                srcs = lib_srcs + [src] + ["@rules_dotnet//dotnet/private/rules/common/nunit:shim.cs"],
                deps = deps + extra_deps,
                target_frameworks = target_frameworks,
                data = data,
                tags = tags,
                **kwargs
            )
            tests.append(test_name)
        else:
            for browser in browsers:
                browser_test_name = "%s-%s" % (test_name, browser)

                if browser == default_browser:
                    native.test_suite(
                        name = test_name,
                        tests = [browser_test_name],
                    )

                csharp_test(
                    name = browser_test_name,
                    srcs = lib_srcs + [src] + ["@rules_dotnet//dotnet/private/rules/common/nunit:shim.cs"],
                    deps = deps + extra_deps,
                    target_frameworks = target_frameworks,
                    args = _BROWSERS[browser]["args"],
                    data = data + _BROWSERS[browser]["data"],
                    tags = tags + [
                        "browser-test",
                        "requires-network",
                        "no-sandbox",
                        browser,
                    ],
                    **kwargs
                )
                tests.append(browser_test_name)

    native.test_suite(
        name = name,
        tests = tests,
        tags = ["manual"] + tags,
    )
