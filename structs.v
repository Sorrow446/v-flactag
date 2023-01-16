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