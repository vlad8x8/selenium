load("@rules_dotnet//dotnet/private:providers.bzl", "DotnetAssemblyInfo")
load("@rules_dotnet//dotnet/private/transitions:tfm_transition.bzl", "tfm_transition")

def _nuget_library_export_impl(ctx):
    output = ctx.actions.declare_file("%s.dll" % ctx.label.name)
    ctx.actions.symlink(output = output, target_file = ctx.file.library)

    return [
        DefaultInfo(
            files = depset([output]),
        ),
    ]

_nuget_library_export = rule(
    _nuget_library_export_impl,
    attrs = {
        "library": attr.label(
            doc = "The .Net library that is being published",
            providers = [DotnetAssemblyInfo],
            cfg = tfm_transition,
            mandatory = True,
            allow_single_file = True,
        ),
        "target_framework": attr.string(
            doc = "The target framework that should be published",
            mandatory = True,
        ),
        "_allowlist_function_transition": attr.label(
            default = "@bazel_tools//tools/allowlists/function_transition_allowlist",
        ),
    },
    cfg = tfm_transition,
)

def nuget_library_export(name, library, target_frameworks, **kwargs):
    for framework in target_frameworks:
        _nuget_library_export(
            name = "%s-%s" % (name, framework),
            library = library,
            target_framework = framework,
            **kwargs
        )
