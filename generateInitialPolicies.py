import subprocess
import tempfile
import json
import shutil
import os
import xml.etree.ElementTree as ET

DESTINATION_FOLDER = './initial-promises/node-server'
JAR_FILE = './rudder-templates-cli.jar'
SYSTEM_FOLDER = './techniques/system'

system_rules = { # rule : [directives]
                 "hasPolicyServer-root": ["common-root"],
                 "inventory-all": ["inventory-all"],
                 "root-DP": [
                   "root-rudderApache",
                   "root-rudderPostgresql",
                   "root-rudderRelay",
                   "root-rudderSlapd",
                   "root-rudderWebapp",
                   "root-serverCommon"
                 ],
               }

system_directives = { # technique : directive
                      "Make an inventory of the node" : "inventory-all",
                      "Common policies" : "common-root",
                      "Rudder apache" : "root-rudderApache",
                      "Rudder Postgresql" : "root-rudderPostgresql",
                      "Rudder relay" : "root-rudderRelay",
                      "Rudder slapd" : "root-rudderSlapd",
                      "Rudder Webapp" : "root-rudderWebapp",
                      "Server Common" : "root-serverCommon"
                    }

def merge_dicts(x, y):
    z = x.copy()
    z.update(y)
    return z

class Technique:
    """
    Describe a rudder technique as described by its source.
    It assumes that the only version available is 1.0 atm, the folder
    input must not include the version folder but its parent.
    """
    def __init__(self, folder):
        self.root = folder
        self.technique_path_name = os.path.basename(folder)
        self._parse_metadata()

    def _parse_metadata(self):
        metadata_path = self.root + '/1.0/metadata.xml'
        tree = ET.parse(metadata_path)
        root = tree.getroot()

        # find technique name
        self.technique_name = root.attrib['name']

        # find string templates
        # add .st extension to the file name
        templates = []
        for template in root.findall('.//TMLS/TML'):
            template_data = template.attrib
            template_data['name'] = template_data['name'] + '.st'
            for out in template.iter():
                if out.tag == 'OUTPATH':
                    template_data['outpath'] = out.text
                if out.tag == 'INCLUDED':
                    template_data['included'] = out.text
            templates.append(template_data)

        # find included files
        files = []
        for file in root.findall('.//FILES/FILE'):
            file_data = file.attrib
            for out in file.iter():
                if out.tag == 'OUTPATH':
                    file_data['outpath'] = out.text
                if out.tag == 'INCLUDED':
                    file_data['included'] = out.text
            files.append(file_data)

        self.templates = templates
        self.files = files

    def compute_bundle_files(self):
        """
        Compute the bundle files of the technique from its metadata
        """
        bundle_files = []
        for file in self.files + self.templates:
            bundle_file = self.technique_path_name + '/1.0/' + os.path.splitext(file['name'])[0]+'.cf'
            if 'outpath' in file:
                bundle_file = file['outpath']
            if ('included' in file and file['included'] == 'true') or 'included' not in file:
                bundle_files.append(bundle_file)
        return { self.technique_path_name.upper() + "_SEQUENCE" : bundle_files }

    def generate_initial_policies(self, extra_data={}):
        """
        create the variables to replace in the templates
        """
        print("Generate initial policies for technique " + self.technique_name)
        directive_name = system_directives[self.technique_name]
        rule_name = next(x for x in system_rules.keys() if directive_name in system_rules[x])
        data = {
                 "trackingkey": "{rule_name}@@{directive_name}@@00".format(
                                   rule_name = rule_name,
                                   directive_name = directive_name
                                 )
               }
        data = merge_dicts(data, extra_data)

        # create a temp folder, generate a temporary variables.json file
        with tempfile.TemporaryDirectory() as tmpdirname:
            with open('./variables.json') as json_file:
                src_data = json.load(json_file)
            data = merge_dicts(src_data, data)
            with open(tmpdirname + '/variables.json', 'w') as f:
                json.dump(data, f)

            # generate the things
            build_path = tmpdirname + '/' + self.technique_path_name
            os.mkdir(build_path)

            # copy files as needed
            for file in self.files:
                source = self.root + '/1.0/' + file['name']
                destination = build_path + '/1.0/' + file['name']
                if 'outpath' in file:
                    destination = tmpdirname + '/' + file['outpath']
                os.makedirs(os.path.dirname(destination), exist_ok=True)
                shutil.copy(source, destination)

            # render templates as needed
            for file in self.templates:
                source = self.root + '/1.0/' + file['name']
                destination_folder = os.path.dirname(build_path + '/1.0/' + file['name'])
                if 'outpath' in file:
                    destination = tmpdirname + '/' + file['outpath']
                    destination_folder = os.path.dirname(destination)
                os.makedirs(destination_folder, exist_ok=True)
                subprocess.run([
                   "java", "-jar", JAR_FILE,
                   "--outext", ".cf",
                   "--outdir", destination_folder,
                   "-p", tmpdirname + '/variables.json',
                   source
                ])
                # Rename the file afterward since the jar can not modify the file name...
                # the extension is automatically changed to .cf by the jar, we need to modify it in
                # the source path.
                if 'outpath' in file:
                    shutil.move(destination_folder + '/' + os.path.splitext(os.path.basename(file['name']))[0]+'.cf', destination)

            # Remove the variable.json as it is not needed
            ignore = shutil.ignore_patterns('.*/variables.json')
            shutil.copytree(tmpdirname, DESTINATION_FOLDER, dirs_exist_ok=True, ignore=ignore)


techniques = []
compute_bundle_files = {}
# Compute techniques and their bundle sequence
with os.scandir(SYSTEM_FOLDER) as f:
    for entry in f:
        if entry.is_dir():
            t = Technique(os.path.join(SYSTEM_FOLDER, entry.name))
            techniques.append(t)
            compute_bundle_files = merge_dicts(compute_bundle_files, t.compute_bundle_files())
# Generate the promises
for t in techniques:
    t.generate_initial_policies(extra_data = compute_bundle_files)
