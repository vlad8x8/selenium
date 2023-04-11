load("@bazel_skylib//lib:dicts.bzl", "dicts")
load("@bazel_skylib//lib:paths.bzl", "paths")
load(
    "@rules_dotnet//dotnet/private:common.bzl",
    "FRAMEWORK_COMPATIBILITY",
    "is_core_framework",
)
load(
    "@rules_dotnet//dotnet/private/transitions:common.bzl",
    "FRAMEWORK_COMPATABILITY_TRANSITION_OUTPUTS",
    "RID_COMPATABILITY_TRANSITION_OUTPUTS",
)
load("@rules_dotnet//dotnet/private:rids.bzl", "RUNTIME_GRAPH")

def _target_framework_transition_impl(settings, attr):
    if not is_core_framework(attr.target_framework):
        msg = "Transitions must be to a .Net Core framework: " + attr.target_framework
        fail(msg)

    incoming_tfm = settings["@rules_dotnet//dotnet:target_framework"]

    if incoming_tfm not in FRAMEWORK_COMPATABILITY_TRANSITION_OUTPUTS:
        fail("Error setting @rules_dotnet//dotnet:target_framework: invalid value '" + incoming_tfm + "'. Allowed values are " + str(FRAMEWORK_COMPATIBILITY.keys()))

    transitioned_tfm = attr.target_framework

    runtime_identifier = settings["@rules_dotnet//dotnet:rid"]

    return dicts.add({"@rules_dotnet//dotnet:target_framework": transitioned_tfm}, {"@rules_dotnet//dotnet:rid": runtime_identifier}, FRAMEWORK_COMPATABILITY_TRANSITION_OUTPUTS[transitioned_tfm], RID_COMPATABILITY_TRANSITION_OUTPUTS[runtime_identifier])

_target_framework_transition = transition(
    implementation = _target_framework_transition_impl,
    inputs = ["@rules_dotnet//dotnet:target_framework", "@rules_dotnet//dotnet:rid", "//command_line_option:cpu", "//command_line_option:platforms"],
    outputs = ["@rules_dotnet//dotnet:target_framework", "@rules_dotnet//dotnet:rid"] +
              ["@rules_dotnet//dotnet:framework_compatible_%s" % framework for framework in FRAMEWORK_COMPATIBILITY.keys()] +
              ["@rules_dotnet//dotnet:rid_compatible_%s" % rid for rid in RUNTIME_GRAPH.keys()],
)

def _dotnet_tool_impl(ctx):
    binary = ctx.attr.binary[0]
    default_info = binary[DefaultInfo]

    exe = default_info.files_to_run.executable
    exe_name = exe.basename

    copied_exe = ctx.actions.declare_file(paths.join(ctx.label.name, exe_name))
    ctx.actions.symlink(
        output = copied_exe,
        target_file = exe,
        is_executable = True,
    )

    return [
        DefaultInfo(
            files = depset([copied_exe], transitive = [default_info.files]),
            runfiles = default_info.default_runfiles,
            executable = copied_exe,
        ),
    ]

dotnet_tool = rule(
    _dotnet_tool_impl,
    attrs = {
        "binary": attr.label(
            cfg = _target_framework_transition,
        ),
        "target_framework": attr.string(
            mandatory = True,
        ),
        "_allowlist_function_transition": attr.label(
            default = "@bazel_tools//tools/allowlists/function_transition_allowlist",
        ),
    },
    executable = True,
)
