import subprocess
import tempfile
import json
import shutil
import os
import xml.etree.ElementTree as ET

DESTINATION_FOLDER = './initial-promises/node-server'
JAR_FILE = './rudder-templates-cli.jar'

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
    def __init__(self, folder):
        self.root = folder
        self.technique_path_name = os.path.basename(folder)
        print(self.technique_path_name)
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

    def generate_initial_policies(self):
       # create the variables to replace in the templates
       directive_name = system_directives[self.technique_name]
       #rule_name = system_rules[directive_name]
       rule_name = next(x for x in system_rules.keys() if directive_name in system_rules[x])
       data = {
                "trackingkey": "{rule_name}@@{directive_name}@@00".format(
                                  rule_name = rule_name,
                                  directive_name = directive_name
                                )
              }

       # create a temp folder, generate a variables.json file
       with tempfile.TemporaryDirectory() as tmpdirname:
           with open('./variables.json') as json_file:
               src_data = json.load(json_file)
           data = merge_dicts(src_data, data)
           with open(tmpdirname + '/variables.json', 'w') as f:
               json.dump(data, f)
           print('created temporary directory', tmpdirname)

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
               destination = build_path + '/1.0/'
               if 'outpath' in file:
                   destination = os.path.dirname(tmpdirname + '/' + file['outpath'])
               os.makedirs(destination, exist_ok=True)
               subprocess.run([
                  "java", "-jar", JAR_FILE,
                  "--outext", ".cf",
                  "--outdir", destination,
                  "-p", tmpdirname + '/variables.json',
                  source
               ])

           print("Copy to " + DESTINATION_FOLDER + '/' + self.technique_path_name)
           shutil.copytree(tmpdirname + '/' + self.technique_path_name, DESTINATION_FOLDER + '/' + self.technique_path_name)


    def list_files(self):
        print('TECHNIQUE NAME')
        print(self.technique_name)
        print('FILES')
        for i in self.files:
            print(i)
        print('TEMPLATES')
        for i in self.templates:
            print(i)

base = './techniques/system'
with os.scandir(base) as f:
    for entry in f:
        if entry.is_dir():
            t = Technique(os.path.join(base, entry.name))
            t.list_files()
            t.generate_initial_policies()
