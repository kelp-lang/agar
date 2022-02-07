// Copyright (C) 2022 by Jáchym Tomášek

// The length of the journey has to be borne with, for every moment
// is necessary.

const std = @import("std");

const Self = @This();

const Page = [4096]u8;
const PageId = u64;
const FreePages = std.SinglyLinkedList(PageId);

pages: std.ArrayList(Page) = undefined,
/// Holds ids of the free pages in the manager
/// Ids of pages are immutable and are never invalidated
/// unless the id is freed, then there is no guarantee that
/// the page access won't produce Use After Free
free_pages: FreePages = undefined,
allocator: std.mem.Allocator,

pub fn init(allocator: std.mem.Allocator) Self {
    return Self{
        .pages = std.ArrayList(Page).init(allocator),
        .free_pages = FreePages{},
        .allocator = allocator,
    };
}

pub fn deinit(self: *Self) void {
    // Destroy all free pages id's
    while (self.free_pages.popFirst()) |id_ptr| {
        self.allocator.destroy(id_ptr);
    }
    self.pages.deinit();
}

/// Returns an id of a new page. There is no guarantee that
/// the page will be zeroes.
pub fn new_page(self: *Self) u64 {
    if (self.free_pages.popFirst()) |id| {
        // Create a stack copy of the integer
        const id_copy = id.data;
        // Destroy the heap integer
        defer self.allocator.destroy(id);
        return id_copy;
    } else {
        self.pages.append([_]u8{0} ** 4096) catch {
          std.log.err("Out of memory!", .{});
        };
        return self.pages.items.len - 1;
    }
    return null;
}

/// Release a page. There is no guarantee that using the id after the release
/// will return a value. And can produce use after free.
pub fn release_page(self: *Self, id: u64) void {
    // If page is at the end, delete it
    if (id == self.pages.items.len - 1) {
        _ = self.pages.pop();
    }
    // If page is somewhere in the middle, reuse it
    else {
        // The free ids linked list only stores pointers
        // So to keep the ids I need to alloc memory for them
        // in the heap and then manually free them
        const id_node = self.allocator.create(FreePages.Node) catch {
          std.log.err("Out of memory! Leaking a page.", .{});
          return;
        };
        id_node.*.data = id;
        self.free_pages.prepend(id_node);
    }
}
