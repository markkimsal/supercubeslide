pub const AnimationType = enum {
    RemoveCol,
    RemoveRow,
};

pub const TaggedAnimation = union(enum) {
    RemoveCol: Animation,
    RemoveRow: Animation,
};

pub const Animation = struct {
    duration: u32,
    t0: u64,
    anim_type: AnimationType,
};
