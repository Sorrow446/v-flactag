module flactag

import os


fn check_magic(mut f os.File) !{
	magic := read_str(mut f, 4)!
	if magic != 'fLaC' {
		return error('bad magic')
	}
}

pub fn (mut flac FLAC) close() {
	flac.f.close()
}

pub fn open(flac_path string) !&FLAC {
	mut f := os.open_file(flac_path, 'rb', 0o755)!
	check_magic(mut f)!
	return &FLAC{
		f: f
		flac_path: flac_path
	}
}