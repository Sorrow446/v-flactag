module flactag

import os
import bitreader


fn check_block(mut f os.File) !{
	mut buf := []u8{len: 1}
	f.read(mut buf)!
	t := buf[0] & 0x7F
	if t != 0x0 {
		return error('first block must be stream info')
	}
}

pub fn (mut flac FLAC) read_stream_info() !&FLACStreamInfo{
	flac.f.seek(4, .start)!
	check_block(mut flac.f)!
	flac.f.seek(3, .current)!
	mut br := bitreader.new_reader(flac.f)
	block_size_min := br.read(16)!
	block_size_max := br.read(16)!
	frame_size_min := br.read(24)!
	frame_size_max := br.read(24)!
	sample_rate := br.read(20)!
	channel_count := br.read(3)!
	bit_depth := br.read(5)!
	sample_count := br.read(36)!
	mut buf := []u8{len: 16}
	flac.f.read(mut buf)!
	stream_info := &FLACStreamInfo{
		block_size_min: int(block_size_min)
		block_size_max: int(block_size_max)
		frame_size_min: int(frame_size_min)
		frame_size_max: int(frame_size_max)
		sample_rate: int(sample_rate)
		channel_count: int(channel_count)+1
		bit_depth: int(bit_depth)+1
		sample_count: i64(sample_count)
		audio_md5: buf
	}
	return stream_info
}