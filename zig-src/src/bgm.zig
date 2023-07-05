const std = @import("std");
const sdl = @import("sdl2");
const mixer = @cImport({
    @cInclude("SDL2/SDL_mixer.h");
});

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

pub fn start_song(song_index: usize) void {
    std.log.info(" song index {}", .{song_index});
    var music = mixer.Mix_Init(mixer.MIX_INIT_MOD | mixer.MIX_INIT_MP3 | mixer.MIX_INIT_OGG);
    var opened = mixer.Mix_OpenAudio(48000, mixer.AUDIO_S16, 2, 4096);
    _ = opened;
    _ = mixer.Mix_Volume(-1, 21);
    _ = mixer.Mix_VolumeMusic(12);

    const filename = song_list[song_index].filename;
    var buffer = [_]u8{undefined} ** 100;
    const printed = std.fmt.bufPrint(&buffer, "../media/music/{s}", .{filename}) catch "out-of-memory";
    curr_song = mixer.Mix_LoadMUS(@as([*c]const u8, @ptrCast(printed)));
    if (curr_song) |s| {
        _ = s;
        var yes = mixer.Mix_PlayMusic(curr_song.?, 0);
        std.log.info("yes {}", .{yes});
        _ = music;
    } else {
        std.log.err("cannot load song: {s}", .{mixer.SDL_GetError()});
    }
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
