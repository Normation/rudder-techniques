#!/bin/sh
# vim: syntax=python
''':'
# First try to run this script with python3, else run with python
if command -v python3 >/dev/null 2>/dev/null; then
  exec python3 "$0" "$@"
elif command -v python >/dev/null 2>/dev/null; then
  exec python  "$0" "$@"
else
  exec python2 "$0" "$@"
fi
'''

import getopt
import sys
import os
from subprocess import Popen, PIPE
import re
import json
import pprint
from datetime import datetime, tzinfo, timedelta
import hashlib
import time
import calendar


PY3 = sys.version_info > (3,)


# To store output files
WORKDIR = '/var/rudder/system-update/'
CONTEXT = 'rudder_system_update_module'


# ### CFEngine module protocol ###
# wrapped in module protocol
# https://docs.cfengine.com/docs/master/reference-language-concepts-modules.html

context_sent = False


def cfengine_var(name, value):
    """Outputs a string variable with CFEngine module protocol"""
    global context_sent
    if not context_sent:
        context_sent = True
        # Bundle name for output vars
        print('^context=' + CONTEXT)
    print('=%s=%s' % (name, value))


def cfengine_class(cfe_class):
    """Outputs a class with CFEngine module protocol"""
    print('+' + cfe_class)


def output_result(message, outcome, json_file):
    """Outputs data for Rudder report"""
    cfengine_var('system_update_message', message)
    cfengine_var('system_update_outcome', outcome)
    if json_file:
        cfengine_var('system_update_report', json_file)
        cfengine_class('rudder_system_update_campaign_report')


# ### ###

# ### Time management ###

# https://stackoverflow.com/a/51913324
# we can't use datetime.timezone because of 2.7 compat
ZERO = timedelta(0)
HOUR = timedelta(hours=1)


class UTC(tzinfo):
    """UTC"""

    def utcoffset(self, dt):
        return ZERO

    def tzname(self, dt):
        return 'UTC'

    def dst(self, dt):
        return ZERO


# Python 2 does not have datetime.timestamp()
def timestamp(date):
    # time.mktime does not do what we need
    return calendar.timegm(date.utctimetuple())


def parse_rfc3339(date):
    """Sadly, there is no compatible build-in way to parse RFC3339"""
    formats = [
        '%Y-%m-%dT%H:%M:%S',
        '%Y-%m-%d %H:%M:%S',
    ]
    for format in formats:
        try:
            # python 2 cannot parse timezones with %z either...
            date_p = datetime.strptime(date[:19], format)
            if date[19] == '+':
                date_p -= timedelta(
                    hours=int(date[20:22]), minutes=int(date[23:])
                )
            elif date[19] == '-':
                date_p += timedelta(
                    hours=int(date[20:22]), minutes=int(date[23:])
                )
            elif date[19] == 'Z':
                pass
            else:
                raise Exception('Could not parse timezone in ' + date)
            # make offset-aware
            date_p = date_p.replace(tzinfo=UTC())
            return date_p
        except Exception as e:
            pass
    raise Exception('Could not parse date ' + date)


# start, end: rfc3339 date times
# agent_schedule: number of minutes
# node_id: unique agent info used for predictability
def splayed_start(start, end, agent_schedule, node_id):
    start_t = timestamp(start)
    end_t = timestamp(end)
    hash = hashlib.md5(node_id.encode('ascii'))  # nosec B324
    splay = int(hash.hexdigest(), 16)
    #                    agent period        + 5 min
    real_end_t = end_t - agent_schedule * 60 + 5 * 60
    if real_end_t <= start_t:
        # Splay time is too short
        return None
    real_start_t = start_t + (splay % (real_end_t - start_t))
    res_start = datetime.fromtimestamp(real_start_t, UTC())
    return res_start


def is_past(date):
    now = datetime.now(UTC())
    return now > date


def should_run(start, end):
    now = datetime.now(UTC())
    return now >= start and now < end


# ### ###

# ### Generic command handling ###


def run(command, check=False):
    proc = Popen(command, stdout=PIPE, stderr=PIPE)
    output, error = proc.communicate()
    if PY3:
        output = output.decode('UTF-8')
    if PY3:
        error = error.decode('UTF-8')
    return (proc.returncode, output, error)


def commands_output(commands):
    outputs = []
    errors = []
    for command in commands:
        (code, output, error) = run(command)
        outputs.append(output)
        errors.append(error)
        # stop at first error
        if code != 0:
            break
    return (code, '\n'.join(outputs), '\n'.join(errors))


def do_reboot():
    try:
        Popen(['/usr/bin/systemctl', 'reboot'])
    except Exception as e:
        Popen(['/usr/sbin/shutdown', '--reboot', 'now'])


# ### ###


class UpdateManager(object):
    """A system package manager that handles the update"""

    def __init__(self, campaign_id, workdir):
        self.campaign_id = campaign_id
        self.workdir = workdir
        if not os.path.isdir(self.workdir):
            os.mkdir(self.workdir)
        # For all package manager interactions
        os.environ['LC_ALL'] = 'C'

    def get_file_path(self, f_type):
        file = self.campaign_id + '_' + f_type + '.json'
        return os.path.join(self.workdir, file)

    def store_file(self, f_type, value):
        # ${campaign_id}_before.json
        # ${campaign_id}_lock.json
        # ${campaign_id}_after.json
        # ${campaign_id}_report.json, contains output+updates list
        dest = self.get_file_path(f_type)
        with open(dest, 'w') as file:
            json.dump(value, file)

    def get_file(self, f_type):
        dest = self.get_file_path(f_type)
        with open(dest, 'r') as file:
            return json.load(file)

    def installed(self):
        return self.parse_installed(self.get_installed())

    def get_installed(self):
        """Get list of installed package from package manager"""
        pass

    def parse_installed(self):
        """Parse the list of installed packages"""
        pass

    def set_lock(self):
        """Lock for current campaign id. Locks are never released."""
        now = datetime.now()
        self.store_file('lock', now.isoformat('T'))

    def set_sent(self):
        """Report has been sent"""
        now = datetime.now()
        self.store_file('sent', now.isoformat('T'))

    def get_locked(self):
        """Test if lock is set"""
        try:
            return self.get_file('lock')
        except Exception:
            pass
        return False

    def get_sent(self):
        """Test if send lock is set"""
        try:
            return self.get_file('sent')
        except Exception:
            pass
        return False

    def get_finished(self):
        """Test if update has run"""
        try:
            self.get_file('report')
            return True
        except Exception:
            pass
        return False

    def run_update(self, reboot):
        """Update process"""
        # race condition here but we can live with that
        self.set_lock()

        before = self.installed()
        self.store_file('before', before)

        (code, output, errors) = self.update()

        after = self.installed()
        self.store_file('after', after)

        updates = self.diff(before, after)
        report = {
            'software-updated': updates,
        }

        if code != 0:
            report['status'] = 'error'
        elif updates:
            report['status'] = 'repaired'
        else:
            report['status'] = 'success'

        if output:
            report['output'] = output
        if errors:
            report['errors'] = errors
        self.store_file('report', report)

        if reboot:
            do_reboot()
        else:
            # consider report sent
            self.set_sent()

        return self.get_file_path('report')

    def update(self):
        """Trigger full system update"""
        pass

    def diff(self, before, after):
        """Compare before and after package list and produce updates list"""
        updates = []
        for package, info in before.items():
            version = info['version']
            # split name and arch for output
            parts = package.rsplit('.', 1)
            if package not in after:
                removed = {
                    'name': parts[0],
                    'arch': parts[1],
                    'old-version': version,
                    'action': 'removed',
                }
                updates.append(removed)
        for package, info in after.items():
            version = info['version']
            # split name and arch for output
            parts = package.rsplit('.', 1)
            if package not in before:
                added = {
                    'name': parts[0],
                    'arch': parts[1],
                    'new-version': version,
                    'action': 'added',
                }
                if 'error' in info:
                    added['error'] = info['error']
                updates.append(added)
            elif version == before[package]['version']:
                continue
            else:
                updated = {
                    'name': parts[0],
                    'arch': parts[1],
                    'old-version': before[package]['version'],
                    'new-version': version,
                    'action': 'updated',
                }
                if 'error' in info:
                    updated['error'] = info['error']
                updates.append(updated)
        return updates


class Rpm(UpdateManager):
    def __init__(self, campaign_id, workdir=WORKDIR):
        if os.path.exists("/usr/bin/rpm"):
            self.rpm_path = "/usr/bin/rpm"
        else:
            self.rpm_path = "/bin/rpm"
        super(Rpm, self).__init__(campaign_id, workdir)

    def get_installed(self):
        output_format = '%{name} %{epochnum}:%{version}-%{release} %{arch}\n'
        command = [self.rpm_path, '-qa', '--qf', output_format]
        (code, output, errors) = run(
            command,
            # Fail on errors
            check=True,
        )
        return output

    def parse_installed(self, output):
        packages = {}
        for line in output.splitlines():
            parts = line.split(' ')
            version_parts = parts[1].split(':')
            if version_parts[0] in ['', '0']:
                # Remove default epoch
                version = version_parts[1]
            else:
                version = parts[1]
            # Store name with arch to allow fast indexing when comparing versions
            # we can have several packages with the same name and different arches
            packages[parts[0] + '.' + parts[2]] = {'version': version}
        return packages


class Yum(Rpm):
    def update(self):
        commands = [['/usr/bin/yum', '-y', 'update']]
        return commands_output(commands)


class Zypper(Rpm):
    def update(self):
        commands = [
            ['/usr/bin/zypper', 'refresh'],
            ['/usr/bin/zypper', '--non-interactive', 'update'],
        ]
        return commands_output(commands)


class Dpkg(UpdateManager):
    def __init__(self, campaign_id, workdir=WORKDIR):
        os.environ['DEBIAN_FRONTEND'] = 'noninteractive'
        super(Dpkg, self).__init__(campaign_id, workdir)

    def get_installed(self):
        # unattended-upgrades 1.11.2 all install ok installed
        output_format = '${Package} ${Version} ${Architecture} ${Status}\n'
        command = ['/usr/bin/dpkg-query', '--showformat', output_format, '-W']
        (code, output, errors) = run(
            command,
            # Fail on errors
            check=True,
        )
        return output

    def parse_installed(self, output):
        packages = {}
        for line in output.splitlines():
            parts = line.split(' ')
            state = parts[5]
            if state not in ['installed', 'half-configured', 'half-installed']:
                # consider not installed
                continue
            # Store name with arch to allow fast indexing when comparing versions
            # we can have several packages with the same name and different arches
            index = parts[0] + '.' + parts[2]
            packages[index] = {'version': parts[1]}
            if state != 'installed':
                packages[index]['error'] = state
        return packages


class Apt(Dpkg):
    def update(self):
        commands = [
            ['/usr/bin/apt-get', 'update'],
            ['/usr/bin/apt-get', '-y', 'dist-upgrade'],
        ]
        return commands_output(commands)


def usage():
    sys.stderr.write(
        'Usage: system_update.py --package_manager=[yum|zypper|apt_get] --campaign_id=CAMPAIGNID \
        --start=2022-07-19T14:04:00+02:00 --end=2022-07-19T17:20:00+02:00 --node_id=NODE_ID \
        --agent_schedule=5 [--reboot]\n'
    )
    sys.exit(2)


def run_action(package_manager, reboot, start, end):
    # json output file
    output = ''
    # human readable output
    message = ''
    # outcome in rudder report format
    outcome = 'result_na'

    locked = package_manager.get_locked()
    finished = package_manager.get_finished()
    sent = package_manager.get_sent()
    path = package_manager.get_file_path('report')

    # Common to update and report
    if finished:
        if not sent and os.path.exists(path):
            output = path
            package_manager.set_sent()
            message = 'Sending update report for update started at ' + str(
                locked
            )
        else:
            message = 'Update report already sent at ' + str(sent)
        outcome = 'result_success'
    elif locked:
        message = 'Update is running since ' + str(locked)
    else:
        # not locked = not started
        if should_run(start, end):
            if reboot:
                message = 'Running system update with immediate reboot'
            else:
                message = 'Running system update without reboot'
            output = package_manager.run_update(reboot)
            outcome = 'result_repaired'
        else:
            if is_past(start):
                message = 'Update should have run at ' + str(start)
            else:
                message = 'Update will run at ' + str(start)
    output_result(message, outcome, output)


def parse_package_manager(value, campaign_id, workdir):
    if value in ['yum', 'dnf']:
        pm = Yum(campaign_id, workdir)
    elif value in ['apt', 'apt_get']:
        pm = Apt(campaign_id, workdir)
    elif value == 'zypper':
        pm = Zypper(campaign_id, workdir)
    else:
        usage()
    return pm


def main(args=None):
    # we can't use argparse as we need to support very old python
    try:
        opts, args = getopt.getopt(
            sys.argv[1:],
            'hrp:c:n:a:s:e:w:',
            [
                'help',
                'reboot',
                'package_manager=',
                'campaign_id=',
                'node_id=',
                'agent_schedule=',
                'start=',
                'end=',
                'workdir=',
            ],
        )
    except getopt.GetoptError as err:
        print(err)
        usage()

    reboot = False
    package_manager = ''
    campaign_id = ''
    node_id = ''
    agent_schedule = 5
    start = None
    end = None
    workdir = WORKDIR

    for o, a in opts:
        if o in ('-h', '--help'):
            usage()
        elif o in ('-r', '--reboot'):
            reboot = True
        elif o in ('-p', '--package_manager'):
            package_manager = a
        elif o in ('-c', '--campaign_id'):
            campaign_id = a
        elif o in ('-n', '--node_id'):
            node_id = a
        elif o in ('-a', '--agent_schedule'):
            agent_schedule = int(a)
        elif o in ('-s', '--start'):
            start = parse_rfc3339(a)
        elif o in ('-e', '--end'):
            end = parse_rfc3339(a)
        elif o in ('-w', '--workdir'):
            workdir = a
        else:
            assert False, 'unknown option'

    # Required options
    if (
        not campaign_id
        or not start
        or not end
        or not node_id
        or not package_manager
    ):
        usage()

    try:
        # Compute splay
        real_start = splayed_start(start, end, int(agent_schedule), node_id)

        # Update manager
        package_manager = parse_package_manager(
            package_manager, campaign_id, workdir
        )
        run_action(package_manager, reboot, real_start, end)
    except Exception as e:
        output_result(str(e), 'result_error', '')
        sys.exit()


if __name__ == '__main__':
    sys.exit(main())
