#!/usr/bin/env python3
"""Frame feeder of the large-array cases: makes the pinned fixture frames and publishes them as waveform PVs of a soft IOC.

Usage:
  feed-frames.py frame --name laser|airy|bound [--images DIR] --output FILE
  feed-frames.py serve --names LIST --period SECONDS --log FILE [--images DIR] [--prefix TEXT] [--count N] [--duration SECONDS]
  feed-frames.py --help

frame  writes the elements of one fixture frame as unsigned 16-bit little-endian values and prints one JSON line with the name, the
       element count and the SHA-256 of the written bytes (the pin of the frame).
serve  hosts one waveform PV per name (PREFIX plus the upper-case name, FTVL USHORT) in a soft IOC and publishes that frame at once and
       then every PERIOD seconds, so that every publication carries a newly observed IOC timestamp. Every publication appends one row
       to the log (time_utc, name, pv, elements, sha256, sequence) and the start appends one JSON record next to it (FILE.json).

Fixtures (D79): laser and airy are the single-channel 8-bit PNG files laser.png and airy.png of the folder given by --images, decoded
here (gray, 8 bits, not interlaced); bound is a Gaussian blob with noise made by the port of the imageFrame generator and of
java.util.Random of the epicsarchiverap-maven checkout (2560 by 2160, seed 20261113, first frame).

The serve command needs softioc and numpy, and EPICS_CA_MAX_ARRAY_BYTES of at least four bytes per element of the largest frame in
its environment. Exit statuses: 0 done, 1 a write failed, 2 invalid usage, 77 a missing or unusable input.
"""

import argparse
import array
import csv
import datetime
import hashlib
import json
import math
import os
import signal
import struct
import sys
import time
import zlib

GEOMETRIES = {"laser": (1307, 1075), "airy": (2560, 1920), "bound": (2560, 2160)}
PNG_FILES = {"laser": "laser.png", "airy": "airy.png"}
BOUND = {"amplitude": 40000.0, "background": 500.0, "sigma_x": 160.0, "sigma_y": 90.0, "noise_sd": 10.0, "seed": 20261113}
PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"
BYTES_PER_ELEMENT_ON_THE_WIRE = 4
DEFAULT_PREFIX = "AASOAK:ARR:"
LOG_COLUMNS = ["time_utc", "name", "pv", "elements", "sha256", "sequence"]
EXIT_OK, EXIT_WRITE, EXIT_USAGE, EXIT_INPUT = 0, 1, 2, 77


class InputError(Exception):
    """A missing or unusable input file."""


class JavaRandom:
    """The linear congruential generator and the polar normal method of java.util.Random."""

    MULTIPLIER = 0x5DEECE66D
    ADDEND = 0xB
    MASK = (1 << 48) - 1

    def __init__(self, seed):
        self.seed = (seed ^ self.MULTIPLIER) & self.MASK
        self.next_gaussian_value = None

    def _next(self, bits):
        self.seed = (self.seed * self.MULTIPLIER + self.ADDEND) & self.MASK
        return self.seed >> (48 - bits)

    def next_double(self):
        return ((self._next(26) << 27) + self._next(27)) * (1.0 / (1 << 53))

    def next_gaussian(self):
        if self.next_gaussian_value is not None:
            value, self.next_gaussian_value = self.next_gaussian_value, None
            return value
        while True:
            v1 = 2 * self.next_double() - 1
            v2 = 2 * self.next_double() - 1
            s = v1 * v1 + v2 * v2
            if 0 < s < 1:
                break
        multiplier = math.sqrt(-2 * math.log(s) / s)
        self.next_gaussian_value = v2 * multiplier
        return v1 * multiplier


def image_frame(width, height, amplitude, background, centre_x, centre_y, sigma_x, sigma_y, noise_sd, rng):
    """The pixels of a frame, row-major from the top left: a Gaussian blob, a background and noise, rounded and clamped to 16 bits."""
    pixels = array.array("H", bytes(2 * width * height))
    index = 0
    for y in range(height):
        dy = (y - centre_y) / sigma_y
        for x in range(width):
            dx = (x - centre_x) / sigma_x
            value = background + amplitude * math.exp(-0.5 * (dx * dx + dy * dy)) + noise_sd * rng.next_gaussian()
            pixels[index] = max(0, min(65535, math.floor(value + 0.5)))
            index += 1
    return pixels


def paeth(a, b, c):
    p = a + b - c
    pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
    if pa <= pb and pa <= pc:
        return a
    return b if pb <= pc else c


def decode_png(path):
    """The pixels of a gray 8-bit PNG that is not interlaced, row-major, as an array of unsigned 16-bit values."""
    try:
        with open(path, "rb") as handle:
            data = handle.read()
    except OSError as error:
        raise InputError(f"{path}: {error.strerror}") from error
    if not data.startswith(PNG_SIGNATURE):
        raise InputError(f"{path}: not a PNG file")
    position, header, idat = len(PNG_SIGNATURE), None, []
    while position + 8 <= len(data):
        length, kind = struct.unpack(">I4s", data[position:position + 8])
        body = data[position + 8:position + 8 + length]
        position += 12 + length
        if kind == b"IHDR":
            header = struct.unpack(">IIBBBBB", body)
        elif kind == b"IDAT":
            idat.append(body)
        elif kind == b"IEND":
            break
    if header is None or not idat:
        raise InputError(f"{path}: no header or no image data")
    width, height, depth, color, _compression, _filter, interlace = header
    if (depth, color, interlace) != (8, 0, 0):
        raise InputError(f"{path}: only gray 8-bit PNG files that are not interlaced are supported")
    try:
        raw = zlib.decompress(b"".join(idat))
    except zlib.error as error:
        raise InputError(f"{path}: {error}") from error
    if len(raw) != height * (width + 1):
        raise InputError(f"{path}: the image data has {len(raw)} bytes, expected {height * (width + 1)}")
    pixels = bytearray(width * height)
    previous = bytearray(width)
    for y in range(height):
        offset = y * (width + 1)
        filter_type = raw[offset]
        line = bytearray(raw[offset + 1:offset + 1 + width])
        if filter_type == 1:
            for x in range(1, width):
                line[x] = (line[x] + line[x - 1]) & 255
        elif filter_type == 2:
            for x in range(width):
                line[x] = (line[x] + previous[x]) & 255
        elif filter_type == 3:
            for x in range(width):
                left = line[x - 1] if x else 0
                line[x] = (line[x] + ((left + previous[x]) >> 1)) & 255
        elif filter_type == 4:
            for x in range(width):
                left = line[x - 1] if x else 0
                upper_left = previous[x - 1] if x else 0
                line[x] = (line[x] + paeth(left, previous[x], upper_left)) & 255
        elif filter_type != 0:
            raise InputError(f"{path}: unknown filter type {filter_type} in row {y}")
        pixels[y * width:(y + 1) * width] = line
        previous = line
    return array.array("H", iter(pixels))


def make_frame(name, images):
    """The elements of the fixture frame of a name, as an array of unsigned 16-bit values."""
    width, height = GEOMETRIES[name]
    if name == "bound":
        return image_frame(width, height, BOUND["amplitude"], BOUND["background"], width / 2.0, height / 2.0,
                           BOUND["sigma_x"], BOUND["sigma_y"], BOUND["noise_sd"], JavaRandom(BOUND["seed"]))
    if images is None:
        raise InputError(f"--images is required for {name}")
    pixels = decode_png(os.path.join(images, PNG_FILES[name]))
    if len(pixels) != width * height:
        raise InputError(f"{PNG_FILES[name]} holds {len(pixels)} pixels, expected {width * height}")
    return pixels


def frame_bytes(pixels):
    """The little-endian bytes of the elements, the form whose SHA-256 pins a frame."""
    copy = array.array("H", pixels)
    if sys.byteorder == "big":
        copy.byteswap()
    return copy.tobytes()


def utc_now():
    return datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.%f")[:-3] + "Z"


def command_frame(arguments):
    pixels = make_frame(arguments.name, arguments.images)
    payload = frame_bytes(pixels)
    try:
        with open(arguments.output, "wb") as handle:
            handle.write(payload)
    except OSError as error:
        print(f"feed-frames: {arguments.output}: {error.strerror}", file=sys.stderr)
        return EXIT_WRITE
    print(json.dumps({"name": arguments.name, "elements": len(pixels), "sha256": hashlib.sha256(payload).hexdigest()}))
    return EXIT_OK


def command_serve(arguments):
    names = [name for name in arguments.names.split(",") if name]
    for name in names:
        if name not in GEOMETRIES:
            print(f"feed-frames: unknown frame name {name}", file=sys.stderr)
            return EXIT_USAGE
    if not names:
        print("feed-frames: --names needs at least one name", file=sys.stderr)
        return EXIT_USAGE
    if not (arguments.prefix.endswith(":") and len(arguments.prefix) > 1):
        print("feed-frames: --prefix must be a device name followed by a colon", file=sys.stderr)
        return EXIT_USAGE
    largest = max(GEOMETRIES[name][0] * GEOMETRIES[name][1] for name in names)
    limit = os.environ.get("EPICS_CA_MAX_ARRAY_BYTES", "")
    if not limit.isdigit() or int(limit) < BYTES_PER_ELEMENT_ON_THE_WIRE * largest:
        print(f"feed-frames: EPICS_CA_MAX_ARRAY_BYTES must be at least {BYTES_PER_ELEMENT_ON_THE_WIRE * largest}, it is '{limit}'", file=sys.stderr)
        return EXIT_USAGE
    try:
        import numpy
        from softioc import asyncio_dispatcher, builder, softioc
    except ImportError as error:
        print(f"feed-frames: serve needs the Python modules softioc and numpy: {error}", file=sys.stderr)
        return EXIT_INPUT
    frames = {}
    for name in names:
        pixels = make_frame(name, arguments.images)
        frames[name] = (pixels, hashlib.sha256(frame_bytes(pixels)).hexdigest())
    dispatcher = asyncio_dispatcher.AsyncioDispatcher()
    records = {}
    builder.SetDeviceName(arguments.prefix[:-1])
    for name in names:
        records[name] = builder.WaveformIn(name.upper(), initial_value=numpy.zeros(len(frames[name][0]), dtype=numpy.uint16))
    builder.LoadDatabase()
    try:
        record_path = arguments.log + ".json"
        with open(record_path, "w") as handle:
            json.dump({"command": sys.argv, "pid": os.getpid(), "start_utc": utc_now(), "period_s": arguments.period,
                       "frames": {name: {"pv": arguments.prefix + name.upper(), "elements": len(frames[name][0]), "sha256": frames[name][1]}
                                  for name in names}}, handle, indent=2, sort_keys=True)
        log = open(arguments.log, "a", newline="")
    except OSError as error:
        print(f"feed-frames: {error.filename}: {error.strerror}", file=sys.stderr)
        return EXIT_WRITE
    writer = csv.writer(log)
    if os.path.getsize(arguments.log) == 0:
        writer.writerow(LOG_COLUMNS)
    stop = []
    signal.signal(signal.SIGTERM, lambda *_: stop.append(1))
    signal.signal(signal.SIGINT, lambda *_: stop.append(1))
    softioc.iocInit(dispatcher)
    arrays = {name: numpy.frombuffer(frame_bytes(frames[name][0]), dtype="<u2") for name in names}
    deadline = time.monotonic() + arguments.duration if arguments.duration else None
    sequence = 0
    status = EXIT_OK
    while not stop:
        sequence += 1
        for name in names:
            records[name].set(arrays[name])
            writer.writerow([utc_now(), name, arguments.prefix + name.upper(), len(arrays[name]), frames[name][1], sequence])
        try:
            log.flush()
        except OSError as error:
            print(f"feed-frames: {arguments.log}: {error.strerror}", file=sys.stderr)
            status = EXIT_WRITE
            break
        if (arguments.count and sequence >= arguments.count) or (deadline and time.monotonic() + arguments.period > deadline):
            break
        end = time.monotonic() + arguments.period
        while not stop and time.monotonic() < end:
            time.sleep(min(0.2, max(0.0, end - time.monotonic())))
    log.close()
    sys.stdout.flush()
    os._exit(status)  # the IOC threads of softioc do not end by themselves


def parse(argv):
    parser = argparse.ArgumentParser(prog="feed-frames.py", description=__doc__.split("\n\n")[0])
    parser.exit_status = EXIT_USAGE
    commands = parser.add_subparsers(dest="command", required=True)
    frame = commands.add_parser("frame", help="write one fixture frame and print its pin")
    frame.add_argument("--name", required=True, choices=sorted(GEOMETRIES))
    frame.add_argument("--images")
    frame.add_argument("--output", required=True)
    serve = commands.add_parser("serve", help="publish the frames as waveform PVs of a soft IOC")
    serve.add_argument("--names", required=True)
    serve.add_argument("--period", required=True, type=float)
    serve.add_argument("--log", required=True)
    serve.add_argument("--images")
    serve.add_argument("--prefix", default=DEFAULT_PREFIX)
    serve.add_argument("--count", type=int, default=0)
    serve.add_argument("--duration", type=float, default=0.0)
    return parser.parse_args(argv)


def main(argv):
    try:
        arguments = parse(argv)
    except SystemExit as error:
        return EXIT_OK if error.code == 0 else EXIT_USAGE
    if arguments.command == "serve" and (arguments.period <= 0 or arguments.count < 0 or arguments.duration < 0):
        print("feed-frames: --period must be positive, --count and --duration not negative", file=sys.stderr)
        return EXIT_USAGE
    try:
        return command_frame(arguments) if arguments.command == "frame" else command_serve(arguments)
    except InputError as error:
        print(f"feed-frames: {error}", file=sys.stderr)
        return EXIT_INPUT


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
