"""
This script is used to generate the initial policies for the agent
and server. It parses the techniques/system folder and read the metadata
to render all templates, techniques and bundlesequences.
"""
import subprocess
import tempfile
import json
import shutil
import os
import xml.etree.ElementTree as ET
from distutils.dir_util import copy_tree

DESTINATION_FOLDER = './initial-promises/node-server'
JAR_FILE = './rudder-templates-cli.jar'
SYSTEM_FOLDER = './techniques/system'

system_rules = { # rule : [directives]
                 "hasPolicyServer-root": ["common-hasPolicyServer-root"],
                 "inventory-all": ["inventory-all"],
                 "policy-server-root": [
                   "rudder-service-apache-root",
                   "rudder-service-postgresql-root",
                   "rudder-service-relayd-root",
                   "rudder-service-slapd-root",
                   "rudder-service-webapp-root",
                   "server-common-root"
                 ],
               }

system_directives = { # technique : directive
                      "Make an inventory of the node" : "inventory-all",
                      "Common policies" : "common-hasPolicyServer-root",
                      "Rudder apache" : "rudder-service-apache-root",
                      "Rudder Postgresql" : "rudder-service-postgresql-root",
                      "Rudder relay" : "rudder-service-relayd-root",
                      "Rudder slapd" : "rudder-service-slapd-root",
                      "Rudder Webapp" : "rudder-service-webapp-root",
                      "Server Common" : "server-common-root"
                    }

def merge_dicts(src_data, override_data):
    """
    Merge src_data and override_data in a new dict
    """
    result = src_data.copy()
    result.update(override_data)
    return result

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
        Some files must be excluded from the initial policies since they can not
        properly be applied.
        """
        blacklist = ["common/1.0/reporting-http.cf", "rudder-system-directives.cf", "common/1.0/rudder-parameters.cf"]
        bundle_files = []
        for file in self.files + self.templates:
            bundle_file = "{technique_name}/1.0/{file_path}".format(
                             technique_name = self.technique_path_name,
                             file_path = os.path.splitext(file['name'])[0]+'.cf'
                          )
            if 'outpath' in file:
                bundle_file = file['outpath']
            if ('included' in file and file['included'] == 'true') or 'included' not in file:
                if bundle_file not in blacklist:
                    bundle_files.append(bundle_file)
        return { self.technique_path_name.upper() + "_SEQUENCE" : bundle_files }

    def generate_initial_policies(self, extra_data={}):
        """
        create the variables to replace in the templates
        """
        print("Generate initial policies for technique " + self.technique_name)
        directive_name = system_directives[self.technique_name]
        rule_name = next(k for k,v in system_rules.items() if directive_name in v)
        data = {
                 "TRACKINGKEY": "{rule_name}@@{directive_name}@@00".format(
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
            with open(tmpdirname + '/variables.json', 'w') as variables_file:
                json.dump(data, variables_file)

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
                ], check=True)
                # Rename the file afterward since the jar can not modify the file name...
                # the extension is automatically changed to .cf by the jar, we need to modify it in
                # the source path.
                if 'outpath' in file:
                    src = "{build_path}/{template}".format(
                        build_path = destination_folder,
                        template = os.path.splitext(os.path.basename(file['name']))[0]+'.cf'
                    )
                    shutil.move(src, destination)

            # Remove the variable.json as it is not needed
            os.remove(tmpdirname + '/variables.json')
            copy_tree(tmpdirname, DESTINATION_FOLDER)


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
