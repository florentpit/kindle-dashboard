"""Vérifie les garanties du client sans accéder au Kindle ni au réseau."""
import datetime as dt
import hashlib
import importlib.util
import io
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from zoneinfo import ZoneInfo

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("generate", ROOT / "generator/generate.py")
generate = importlib.util.module_from_spec(spec)
spec.loader.exec_module(generate)


class ScheduleTest(unittest.TestCase):
    def test_paris_dst(self):
        paris = ZoneInfo("Europe/Paris")
        for date, utc_hours in [("2026-03-28", (6, 11, 17, 5, 10, 16)),
                                ("2026-10-24", (5, 10, 16, 6, 11, 17))]:
            now = dt.datetime.fromisoformat(date).replace(tzinfo=paris)
            epochs = generate.refresh_schedule(now, days=2)
            self.assertEqual([dt.datetime.fromtimestamp(t, dt.timezone.utc).hour
                              for t in epochs], list(utc_hours))
            self.assertEqual(epochs, sorted(set(epochs)))


class DownloadTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.path = Path(self.temp.name)
        self.bin = self.path / "bin"
        self.bin.mkdir()
        self.fixture = self.path / "http"
        self.fixture.mkdir()
        self.images = self.path / "images"
        self.images.mkdir()
        self.image = self.images / "bouliac-dashboard.png"
        self.image.write_bytes(b"previous image")
        self.script("curl", '''#!/usr/bin/env python3
import os, pathlib, shutil, sys
args = sys.argv[1:]
url = next(a for a in args if a.startswith("https://"))
name = url.split("?")[0].rsplit("/", 1)[-1]
shutil.copyfile(pathlib.Path(os.environ["FIXTURE"]) / name, args[args.index("-o")+1])
''')
        self.script("sha256sum", '''#!/usr/bin/env python3
import hashlib, pathlib, sys
print(hashlib.sha256(pathlib.Path(sys.argv[1]).read_bytes()).hexdigest(), sys.argv[1])
''')
        self.script("lipc-get-prop", "#!/bin/sh\necho active\n")
        self.env = dict(os.environ, PATH=f"{self.bin}:{os.environ['PATH']}",
                        FIXTURE=str(self.fixture), DASHBOARD_HOME=str(self.path / "client"),
                        DASHBOARD_IMAGES=str(self.images))

    def script(self, name, contents):
        p = self.bin / name
        p.write_text(contents)
        p.chmod(0o755)

    def fixture_image(self, data, digest=None):
        (self.fixture / "dashboard.png").write_bytes(data)
        (self.fixture / "dashboard.sha256").write_text(
            f"{digest or hashlib.sha256(data).hexdigest()}  dashboard.png\n")
        (self.fixture / "schedule.txt").write_text("1793944800\n1793962800\n1793984400\n")

    def run_refresh(self):
        return subprocess.run(["sh", str(ROOT / "kindle/refresh.sh")], env=self.env,
                              capture_output=True)

    def test_valid_png_replaces_cache(self):
        from PIL import Image
        png = io.BytesIO()
        Image.new("L", (1072, 1448), 255).save(png, format="PNG")
        data = png.getvalue()
        self.fixture_image(data)
        result = self.run_refresh()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.image.read_bytes(), data)

    def test_corrupt_download_keeps_previous_image(self):
        self.fixture_image(b"incomplete download", "a" * 64)
        self.assertNotEqual(self.run_refresh().returncode, 0)
        self.assertEqual(self.image.read_bytes(), b"previous image")

    def test_html_with_valid_hash_is_rejected(self):
        self.fixture_image(b"<html>Service unavailable</html>")
        self.assertNotEqual(self.run_refresh().returncode, 0)
        self.assertEqual(self.image.read_bytes(), b"previous image")


if __name__ == "__main__":
    unittest.main()
