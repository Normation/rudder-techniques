import unittest
import json
import tempfile
from system_update import *
import shutil
import time


class TestGeneric(unittest.TestCase):
    def test_store_get(self):
        tmpdir = tempfile.mkdtemp()
        yum = Yum('id', workdir=tmpdir)
        my_list = ['a', 'b', 'c']
        yum.store_file('test', my_list)
        with open(os.path.join(tmpdir, 'id_test.json'), 'r') as file:
            content = file.read()
            self.assertEqual(content, '["a", "b", "c"]')
        get = yum.get_file('test')
        self.assertEqual(get, my_list)
        shutil.rmtree(tmpdir)

    def test_lock(self):
        tmpdir = tempfile.mkdtemp()
        yum = Yum('id', workdir=tmpdir)
        self.assertEqual(yum.get_locked(), False)
        yum.set_lock()
        reference = datetime.now().isoformat('T')
        with open(os.path.join(tmpdir, 'id_lock.json'), 'r') as file:
            content = file.read().strip('"')
            # compare year
            self.assertEqual(content[:4], reference[:4])
        self.assertEqual(yum.get_locked()[:4], reference[:4])
        shutil.rmtree(tmpdir)

    def test_updated_packages_computation(self):
        self.maxDiff = None
        before = """
{
  "mesa-vulkan-drivers.x86_64": { "version": "22.1.2-1.fc36" },
  "mesa-libxatracker.x86_64": { "version": "22.1.2-1.fc36" },
  "gtksourceview5.x86_64": { "version": "5.4.2-1.fc36" },
  "gnome-software.x86_64": { "version": "42.2-4.fc36" },
  "google-chrome-stable.x86_64": { "version": "103.0.5060.53-1" }
}"""
        after = """
{
  "mesa-libxatracker.x86_64": { "version": "22.1.2-1.fc36" },
  "gtksourceview5.x86_64": { "version": "5.5.2-1.fc36" },
  "gnome-software.x86_64": { "version": "42.2-4.fc36" },
  "libxslt.x86_64": { "version": "1.1.35-2.fc36" },
  "google-chrome-stable.x86_64": { "version": "103.0.5060.53-1" }
}"""
        updates = """
[
  {
    "name": "mesa-vulkan-drivers",
    "arch": "x86_64",
    "old-version": "22.1.2-1.fc36",
    "action": "removed"
  },
  {
    "name": "gtksourceview5",
    "arch": "x86_64",
    "old-version": "5.4.2-1.fc36",
    "new-version": "5.5.2-1.fc36",
    "action": "updated"
  },
  {
    "name": "libxslt",
    "arch": "x86_64",
    "new-version": "1.1.35-2.fc36",
    "action": "added"
  }
]"""
        tmpdir = tempfile.mkdtemp()
        result = Yum('id', workdir=tmpdir).diff(
            json.loads(before), json.loads(after)
        )
        reference = json.loads(updates)
        result.sort(key=lambda d: d['name'])
        reference.sort(key=lambda d: d['name'])
        self.assertEqual(
            result,
            reference,
        )
        shutil.rmtree(tmpdir)


class TestYum(unittest.TestCase):
    def test_parse_installed(self):
        self.maxDiff = None
        output = """sushi 2:41.2-2.fc36 x86_64
mesa-vulkan-drivers 22.1.2-1.fc36 x86_64
mesa-libxatracker 22.1.2-1.fc36 x86_64
gtksourceview5 5.4.2-1.fc36 x86_64
gnome-software 42.2-4.fc36 x86_64
google-chrome-stable 103.0.5060.53-1 x86_64"""
        reference = """
{
  "sushi.x86_64": { "version": "2:41.2-2.fc36" },
  "mesa-vulkan-drivers.x86_64": { "version": "22.1.2-1.fc36" },
  "mesa-libxatracker.x86_64": { "version": "22.1.2-1.fc36" },
  "gtksourceview5.x86_64": { "version": "5.4.2-1.fc36" },
  "gnome-software.x86_64": { "version": "42.2-4.fc36" },
  "google-chrome-stable.x86_64": { "version": "103.0.5060.53-1" }
}"""
        tmpdir = tempfile.mkdtemp()
        result = Yum('id', workdir=tmpdir).parse_installed(output)
        self.assertEqual(
            result,
            json.loads(reference),
        )
        shutil.rmtree(tmpdir)


class TestApt(unittest.TestCase):
    def test_parse_installed(self):
        output = """python3-yaml 3.13-2 amd64 install ok installed
python3.5-minimal 3.5.3-1+deb9u1 amd64 deinstall ok config-files
python3.7 3.7.3-2+deb10u3 amd64 install ok installed
"""
        reference = """
{
  "python3-yaml.amd64": { "version": "3.13-2" },
  "python3.7.amd64": { "version": "3.7.3-2+deb10u3" }
}"""
        tmpdir = tempfile.mkdtemp()
        result = Apt('id', workdir=tmpdir).parse_installed(output)
        self.assertEqual(
            result,
            json.loads(reference),
        )
        shutil.rmtree(tmpdir)


class TestSplay(unittest.TestCase):
    def test_rfc_3339(self):
        date = parse_rfc3339('2022-07-04T20:40:24+02:00')
        self.assertEqual(timestamp(date), 1656960024)
        date = parse_rfc3339('2022-07-04T18:40:24Z')
        self.assertEqual(timestamp(date), 1656960024)

    def test_splay(self):
        start = parse_rfc3339('2022-07-04T20:40:24+02:00')
        end = parse_rfc3339('2022-07-04T22:40:24+02:00')
        start_s = splayed_start(
            start,
            end,
            5,
            'root',
        )
        self.assertEqual(timestamp(start_s), 1656960701)
        # Generate random strings and check all time are between start and end
        for schedule in [5, 10, 15]:
            for i in range(100):
                start_s = splayed_start(start, end, schedule, str(i))
                self.assertTrue(start_s >= start)
                self.assertTrue(start_s < end)
        # Span too short
        for schedule in [180, 360]:
            for i in range(100):
                start_s = splayed_start(start, end, schedule, str(i))
                self.assertEqual(start_s, None)

    def test_should_run(self):
        self.assertTrue(
            should_run(
                parse_rfc3339('2022-07-04T20:40:24+02:00'),
                parse_rfc3339('2122-07-04T22:40:24+02:00'),
            )
        )
        self.assertFalse(
            should_run(
                parse_rfc3339('2002-07-04T20:40:24+02:00'),
                parse_rfc3339('2012-07-04T22:40:24+02:00'),
            )
        )


class TestCli(unittest.TestCase):
    def test_cli_output(self):
        (code, output, error) = run(
            [
                'python',
                'system_update.py',
                '--workdir=test/test_campaign',
                '--package_manager=yum',
                '--campaign_id=plouf',
                '--start=2002-07-04T20:40:24+02:00',
                '--end=2042-07-04T22:40:24+02:00',
                '--node_id=root',
                '--agent_schedule=5',
            ]
        )
        self.assertEqual(code, 0)
        reference = """^context=rudder_system_update_module
=system_update_message=Update report already sent at 2022-07-06T18:11:16.327754
=system_update_outcome=result_success
"""
        self.assertEqual(output, reference)
        self.assertEqual(error, '')

    def test_error_cli_output(self):
        (code, output, error) = run(
            [
                'python',
                'system_update.py',
                '--workdir=/doesnotexist',
                '--package_manager=yum',
                '--campaign_id=failed',
                '--start=2002-07-04T20:40:24+02:00',
                '--end=2042-07-04T22:40:24+02:00',
                '--node_id=root',
                '--agent_schedule=5',
            ]
        )
        self.assertEqual(code, 0)
        reference = """^context=rudder_system_update_module
=system_update_message=[Errno 13] Permission denied: '/doesnotexist'
=system_update_outcome=result_error
"""
        self.assertEqual(output, reference)
        self.assertEqual(error, '')

    def test_error_parms_cli_output(self):
        (code, output, error) = run(
            [
                'python',
                'system_update.py',
                '--workdir=/doesnotexist',
            ]
        )
        self.assertEqual(code, 2)
        self.assertEqual(output, '')
        self.assertTrue(error.startswith('Usage:'))


if __name__ == '__main__':
    unittest.main()
