module bitreader

import io

struct Reader {
	mut:
		r io.Reader
		buf []u8
		x u8
		n u8
}

pub fn new_reader(r io.Reader) &Reader {
	return &Reader{
		r: r
		buf: []u8{len: 8}
	}
}

pub fn (mut br Reader) read(n_ u8) !u64 {
	mut x := u64(0)
	mut n := n_
	if n == 0 {
		return 0
	}
	if n > 64 {
		return error('invalid number of bits; n (${n}) exceeds 64')
	}

	if br.n > 0 {
		match true {
			br.n == n {
				br.n = 0
				return u64(br.x)			
			}
			br.n > n {
				br.n -= n
				mask := u8(0xFF) << br.n
				x = u64(br.x&mask) >> br.n
				br.x = br.x ^ br.x & mask
				return x
			}
			else {}
		}
		n -= br.n
		x = u64(br.x)
		br.n = 0
	}

	mut bytes := n / 8
	bits := n % 8
	if bits > 0 {
		bytes++
	}


	br.r.read(mut br.buf[..bytes])!

	for b in  br.buf[..bytes-1] {
		x <<= 8
		x |= u64(b)
	}

	b := br.buf[bytes-1]

	if bits > 0 {
		x <<= bits
		br.n = 8 - bits
		mask := u8(0xFF) << br.n
		x |= u64(b&mask) >> br.n
		br.x = b ^ b & mask

	} else {
		x <<= 8
		x |= u64(b)
	}
	return x
}