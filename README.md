# v-flactag
FLAC tag library written in V.

## Setup
`v install Sorrow446.vflactag`
```v
import sorrow446.vflactag as flactag
```

## Examples
Opening is omitted from the examples.
```v
mut flac := flactag.open('1.flac')!
defer {
    flac.close()
}
```
### Read
#### Read album title
```v
tags := flac.read()!
println(tags.album)
```
#### Extract all covers and save them locally
```v
tags := flac.read()!
if tags.has_covers {
    for idx, cover in tags.covers {
        os.write_file_array("${idx+1}.jpg", cover.picture_data) or {
            panic(err)
        }
    }
}
```
### Write
#### Write album and year
```v
mut to_write := &flactag.FLACMeta{
    album: 'my album'
    year: 2023
}
flac.write(mut to_write, []string{})!
```
#### Write two covers, retaining any already written
```v
cover_data := os.read_bytes('1.jpg')!
cover := flactag.FLACCover {
    height: 600
    mime_type: 'image/jpeg'
    picture_type: 3
    width : 600
    picture_data: cover_data
}

cover_two_data := os.read_bytes('2.jpg')!
cover_two := flactag.FLACCover {
    height: 1000
    mime_type: 'image/jpeg'
    picture_type: 3
    width : 1000
    picture_data: cover_two_data
}

mut covers := []flactag.FLACCover{}
covers << cover
covers << cover_two

mut to_write := &flactag.FLACMeta{
    covers: covers
}

flac.write(mut to_write, []string{})!
```
#### Delete genre, the custom tag named "CUST 1" and the second cover
```v
mut to_write := &flactag.FLACMeta{}
del_strings := ['genre', 'CUST 1', 'cover:2']

flac.write(mut to_write, del_strings)!
```
### Stream Info
#### Read bit-depth and sample rate
```v
si := flac.read_stream_info()!
println('${si.bit_depth}-bit / ${si.sample_rate} Hz')
````

## Deletion strings
Case-insensitive.
```
album string
album_artist
artist
comment
contact
date
encoder
genre
isrc
lyrics
media_type
performer
publisher
title
compilation
covers
cover:(index starting from 1)
disk_number
disk_total
explicit
itunes_advisory
length
track_number
track_total
vendor
year
```
Any others will be assumed to be custom tags.

## Structs
```v
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
```

## Thank you
v-flactag uses a bit reader ported to V from mewkiz's Go flac library.

## Disclaimer
Writing is stable, but I will not be responsible for any corruption to your FLACs.
