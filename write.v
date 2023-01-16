module flactag

import os
import time
import encoding.binary

struct Block {
	flag []u8
	data []u8
}

struct Blocks {
	mut:
		stream_blocks []Block
		meta_blocks []Block
		cover_blocks []Block
		other_blocks []Block
}

fn to_24_(in_buf []u8) []u8 {
	mut out_buf := []u8{len: 3}
	out_buf[0] = in_buf[1]
	out_buf[1] = in_buf[2]
	out_buf[2] = in_buf[3]
	return out_buf
}

fn read_block(mut f os.File) ![]u8{
	mut size_buf := []u8{len: 3}
	f.read(mut size_buf)!
	size := to_24(size_buf)
	f.seek(-3, .current)!

	mut buf := []u8{len: int(size)+3}
	f.read(mut buf) or {
		return err
	}
	return buf
}

fn write_end(mut f os.File, mut src_f os.File) !{
	mut buf := []u8{len: 4096}
	for {
		pos := src_f.tell()!
		src_f.read(mut buf) or {
			if err is os.Eof {
                break
            }
            return err
		}
		pos_after_read := src_f.tell()!
		written := pos_after_read-pos
		if written < 4096 {
			f.write(buf[..written])!
		} else {
			f.write(buf)!
		}
	}
}

fn overwrite_tags(mut existing &FLACMeta, mut to_write FLACMeta, del_strings []string) {
	$for field in FLACMeta.fields {
		$if field.typ is string {
			v := to_write.$(field.name)
			if del_strings.contains(field.name) {
				existing.$(field.name) = ''
			} else {
				if v != '' {
					existing.$(field.name) = v
				}
			}
		}
		$if field.typ is int {
			v := to_write.$(field.name).str().int()
			if del_strings.contains(field.name) {
				existing.$(field.name) = 0
			}
			else {
				if v > 0 {
					existing.$(field.name) = v
				}
			}
		}
	}

	for k in existing.custom.keys() {
		if del_strings.contains(k.to_lower()) {
			existing.custom[k] = ''
		}
	}

	for k, v in to_write.custom {
		if v != '' {
			existing.custom[k] = v
		}
	}

	if del_strings.contains('covers') {
		existing.covers = []FLACCover{}
		return
	}

	//mut covers_len := to_write.covers.len
	mut filtered := []FLACCover{}

	for idx, c in existing.covers {
		if !del_strings.contains('cover:${idx+1}') {
			filtered << c
		}
	}

	filtered << to_write.covers
	existing.covers = filtered
}

fn write_com(mut f os.File, field_name string, field_val string) !int {
	mut buf := []u8{len: 4}
	pair := field_name.to_upper() + '=' + field_val
	binary.little_endian_put_u32(mut buf, u32(pair.len))
	f.write(buf)!
	f.write_string(pair)!
	return pair.len + 4
}

fn write_cov(mut f os.File, mut cover FLACCover) !{
	mut written := 0
	mut buf := []u8{len: 4}
	pic_data_len := cover.picture_data.len
	cover_desc_len := cover.description.len
	mime_type_len := cover.mime_type.len

	f.write([u8(0x06)])!
	block_size_p := f.tell()!
	f.write([u8(0x00), 0x00, 0x00])!
	

	binary.big_endian_put_u32(mut buf, u32(cover.picture_type))
	f.write(buf)!
	written += 4

	binary.big_endian_put_u32(mut buf, u32(mime_type_len))
	f.write(buf)!
	f.write_string(cover.mime_type)!
	written += mime_type_len + 4


	binary.big_endian_put_u32(mut buf, u32(cover_desc_len))
	f.write(buf)!
	written += 4


	if cover_desc_len > 0 {
		f.write_string(cover.description)!
		written += cover_desc_len
	}
	binary.big_endian_put_u32(mut buf, u32(cover.width))
	f.write(buf)!
	binary.big_endian_put_u32(mut buf, u32(cover.height))
	f.write(buf)!
	binary.big_endian_put_u32(mut buf, u32(cover.colour_depth))
	f.write(buf)!
	binary.big_endian_put_u32(mut buf, u32(cover.colours_num))
	f.write(buf)!
	binary.big_endian_put_u32(mut buf, u32(pic_data_len))
	f.write(buf)!
	written += 20

	f.write(cover.picture_data)!
	written += pic_data_len

	end_block_p := f.tell()!
	f.seek(block_size_p, .start)!

	binary.big_endian_put_u32(mut buf, u32(written))
	written_u24 := to_24_(buf)
	f.seek(block_size_p, .start)!
	f.write(written_u24)!
	f.seek(end_block_p, .start)!
}

fn create(mut parsed &Blocks, mut fl FLAC, mut to_write &FLACMeta, temp_path string, del_strings []string) !{
	end_data_start := fl.f.tell()!
	fl.f.seek(4, .start)!
	mut tags := fl.read()!
	overwrite_tags(mut tags, mut to_write, del_strings)

	mut f := os.open_file(temp_path, 'wb+', 0o755) or {
		return err
	}
	defer { f.close() }

	mut buf := []u8{len: 4}
	f.write_string('fLaC')!

	//f.write(parsed.stream_blocks[0].flag)!
	f.write([u8(00)])!
	f.write(parsed.stream_blocks[0].data)!

	f.write([u8(0x4)])!
	mut written := 0
	mut com_count := 0

	// block len
	p := f.tell()!

	f.write([u8(0x00), 0x00, 0x00])!

	binary.little_endian_put_u32(mut buf, u32(tags.vendor.len))
	f.write(buf)!
	written += 4
	f.write_string(tags.vendor)!
	written += tags.vendor.len

	com_count_p := f.tell()!

	// com mount
	//binary.little_endian_put_u32(mut buf, 0)
	f.write([u8(0x0), 0x0, 0x0, 0x0])!
	written += 4

	$for field in FLACMeta.fields {
		field_name := field.name
		comment_name := field_name.replace('_', '')
		mut field_val := tags.$(field.name)
		$if field.typ is string {
			if field_val != '' && field_name != 'vendor' {
				written_ := write_com(mut f, comment_name, field_val)!
				written += written_
				com_count ++
			}
		}
		$if field.typ is int {
			if field_val.str().int() > 0 {
				written_ := write_com(mut f, comment_name, field_val.str())!
				written += written_
				com_count ++
			}
		}
	}

	for k, v in tags.custom {
		if v == '' {
			continue
		}
		written_ := write_com(mut f, k.to_upper(), v)!
		written += written_
		com_count ++
	}
	// for da in parsed.cover_blocks {
	// 	//println(da.flag.hex())
	// 	f.write(da.flag)!
	// 	f.write(da.data)!
	// }

	for mut c in tags.covers {
		write_cov(mut f, mut c)!
	}

	for b in parsed.stream_blocks[1..] {
		f.write([u8(0x0)])!
		f.write(b.data)!
	}

	for b in parsed.other_blocks {
		f.write(b.flag)!
		f.write(b.data)!
	}
	fl.f.seek(end_data_start, .start)!
	write_end(mut f, mut fl.f)!
	f.seek(com_count_p, .start)!
	binary.little_endian_put_u32(mut buf, u32(com_count))
	f.write(buf)!
	binary.big_endian_put_u32(mut buf, u32(written))
	written_u24 := to_24_(buf)
	f.seek(p, .start)!
	f.write(written_u24)!
}

fn get_temp_path(flac_path string) string {
	fname := os.file_name(flac_path)
	unix := time.now().unix
	temp_path := os.join_path_single(
		os.temp_dir(), '${fname}_${unix}_tmp.flac')
	return temp_path
}

fn lower_del_strings(del_strings []string) []string {
	mut lowered := []string{}
	for v in del_strings {
		lowered << v.to_lower()
	}
	return lowered
}

pub fn(mut flac FLAC) write(mut to_write &FLACMeta, _del_strings []string)! {
	del_strings := lower_del_strings(_del_strings)
	mut parsed := &Blocks{}
	mut buf := []u8{len: 1}
	for {
		flac.f.read(mut buf)!
		t := buf[0] & 0x7F

		block_data := read_block(mut flac.f)!

		b := Block{data: block_data, flag: buf}

		match t {
			0x0 {
				parsed.stream_blocks << b
			}
			0x4 {
				// skip metadata block
			}
			0x6 {
				parsed.cover_blocks << b
			}
			else {
				parsed.other_blocks << b
			}
		}

		last := 1 & (buf[0] >> 7) == 1
		if last {
			break
		}
	}

	temp_path := get_temp_path(flac.flac_path)
	create(mut parsed, mut flac, mut to_write, temp_path, del_strings)!
	flac.f.close()
	os.rm(flac.flac_path)!
	os.mv(temp_path, flac.flac_path)!
	flac_ := open(flac.flac_path)!
	flac = flac_
	flac.f.seek(4, .start)!
}