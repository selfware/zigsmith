const App = @import("App.zig");
const Database = @import("Database.zig");
const embed = @import("embed.zig");
const httpz = @import("httpz");
const std = @import("std");

pub fn main() !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer if (gpa.deinit() == .leak) @panic("memory leaked");
    const alloc = gpa.allocator();

    const cdn_url = try get_env(alloc, "CDN_URL") orelse
        return error.MissingCdnUrl;
    const path = try get_env(alloc, "DB_PATH") orelse "data.db";
    defer alloc.free(cdn_url);
    defer alloc.free(path);

    const db = try Database.open(alloc, path);

    var pkgs_count: usize = 0;
    const app = App{
        .db = db,
        .pkgs_count = &pkgs_count,
        .cdn_url = cdn_url,
    };

    var server =
        try httpz.Server(*const App).init(alloc, .{ .port = 8080 }, &app);
    var router = try server.router(.{});

    router.get("/", index, .{});
    router.get("/style.css", style, .{});
    router.get("/index.js", script, .{});

    router.get("/search", search, .{});

    try server.listen();
}

fn search(_: *const App, _: *httpz.Request, res: *httpz.Response) !void {
    // try res.buffer.writer.writeAll("<p>Hello, world!</p>");
    res.content_type = .HTML;
}

fn index(app: *const App, _: *httpz.Request, res: *httpz.Response) !void {
    try res.buffer.writer.print(embed.index, .{app.pkgs_count.*});
    res.content_type = .HTML;
}
fn style(_: *const App, _: *httpz.Request, res: *httpz.Response) !void {
    res.body = embed.style;
    res.content_type = .CSS;
}
fn script(_: *const App, _: *httpz.Request, res: *httpz.Response) !void {
    res.body = embed.script;
    res.content_type = .JS;
}

// fn result(writer: std.Io.Writer, pkg: Package) []const u8 {
//     writer.print(
//         \\<div id="result">
//         \\    <code>{s}</code>
//         \\</div>
//     , .{pkg});
// }

fn get_env(alloc: std.mem.Allocator, key: []const u8) !?[]const u8 {
    return std.process.getEnvVarOwned(alloc, key) catch |err| switch (err) {
        error.EnvironmentVariableNotFound => null,
        else => err,
    };
}

const Envrionment = struct {
    CDN_URL: []const u8,
    DB_PATH: []const u8,
};
