module flactag

import os

pub struct FLAC {
	mut:
		f os.File
		flac_path string
}

pub struct FLACCover {
	pub mut:
		colours_num int
		colour_depth int
		description string
		height int
		mime_type string
		picture_type_name string
		picture_type int
		width int
		picture_data []u8
}

pub struct FLACMeta {
	pub mut:
		album string
		album_artist string
		artist string
		comment string
		contact string
		date string
		encoder string
		genre string
		isrc string
		lyrics string
		media_type string
		performer string
		publisher string
		title string
		compilation int
		covers []FLACCover
		custom map[string]string
		disk_number int
		disk_total int
		explicit int
		has_covers bool
		itunes_advisory int
		length int
		track_number int
		track_total int
		vendor string
		year int
}

pub struct FLACStreamInfo {
	pub mut:
		block_size_min int
		block_size_max int
		frame_size_min int
		frame_size_max int
		sample_rate int
		channel_count int
		bit_depth int
		sample_count i64
		audio_md5 []u8
}