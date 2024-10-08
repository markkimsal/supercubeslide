const std = @import("std");
const builtin = @import("builtin");
// const sdl = @import("sdl2");
// const mixer = @cImport({
//     @cInclude("SDL2/SDL_mixer.h");
// });

const MainModule = @import("./main.zig");
const mixer = MainModule.sdl;

const Song = struct {
    filename: [*c]const u8,
    title: [*]const u8,
    artist: [*]const u8,
    homepage: [*]const u8,
};

var song_list: [3]Song = [3]Song{ Song{
    .filename = "8bit_party.it",
    .title = "8Bit Party",
    .artist = "Line",
    .homepage = "http://modarchive.org/index.php?request=view_by_moduleid&query=162286",
}, Song{
    .filename = "1_channel_moog.it",
    .title = "Channel Moog",
    .artist = "Manwe",
    .homepage = "http://modarchive.org/index.php?request=view_by_moduleid&query=158975",
}, Song{
    .filename = "a--fchip.it",
    .title = "Friend(Chip)",
    .artist = "AquaLife",
    .homepage = "http://modarchive.org/index.php?request=view_by_moduleid&query=32414",
} };

var curr_song: ?*mixer.Mix_Music = null;
pub var song_index_: usize = 0;

pub fn start_song(song_index: usize) void {
    var s_index = song_index;
    const music = mixer.Mix_Init(mixer.MIX_INIT_MOD | mixer.MIX_INIT_MP3 | mixer.MIX_INIT_OGG);
    const opened = mixer.Mix_OpenAudio(48000, mixer.AUDIO_S16, 2, 4096);
    _ = opened;
    _ = mixer.Mix_Volume(-1, mixer.MIX_MAX_VOLUME/2);
    _ = mixer.Mix_VolumeMusic(mixer.MIX_MAX_VOLUME/2);

    if (s_index >= song_list.len) {
        s_index = s_index % song_list.len;
    }
    std.log.info(" song index {}", .{s_index});
    const filename = song_list[s_index].filename;
    var buffer = [_]u8{undefined} ** 100;
    const printed = std.fmt.bufPrint(&buffer, "media/music/{s}", .{filename}) catch "out-of-memory";
    if (builtin.os.tag == .windows) {
        std.mem.replaceScalar(u8, printed, '/', '\\');
    }
    curr_song = mixer.Mix_LoadMUS(@as([*c]const u8, @ptrCast(printed)));
    if (curr_song) |s| {
        _ = s;
        const yes = mixer.Mix_PlayMusic(curr_song.?, 0);
        std.log.info("yes {}", .{yes});
        _ = music;
    } else {
        std.log.err("cannot load song: {s}", .{mixer.SDL_GetError()});
    }
    song_index_ = s_index;
}

pub fn pause_music() void {
    std.log.info("pause music", .{});
    if (mixer.Mix_PlayingMusic() != 0) {
        _ = mixer.Mix_HaltMusic();
    } else {
        start_song(0);
    }
}

pub fn close() void {
    mixer.Mix_FreeMusic(curr_song);
    mixer.Mix_CloseAudio();
}
