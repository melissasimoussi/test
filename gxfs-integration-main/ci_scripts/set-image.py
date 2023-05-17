import sys
import ruamel.yaml

IMAGE = sys.argv[1]
CONFIG_PATH = sys.argv[2]

IMAGE_REPOSITORY = '/'.join(IMAGE.split(':')[0].split('/')[0:-1]) 
IMAGE_NAME = IMAGE.split('/')[-1].split(':')[0]
IMAGE_TAG = IMAGE.split('/')[-1].split(':')[1]

yaml = ruamel.yaml.YAML()

with open(CONFIG_PATH, "r") as f:
    config = yaml.load(f)

print('Updating image: ' + IMAGE)
print('Config path: ' + CONFIG_PATH)

for app in config['applications']:
    if('values' in app and 'image' in app['values'] and 'repository' in app['values']['image'] and 'tag' in app['values']['image'] and 'name' in app['values']['image']):
        if(app['values']['image']['repository'] == IMAGE_REPOSITORY and app['values']['image']['name'] == IMAGE_NAME):
            if(app['values']['image']['tag'] != IMAGE_TAG):
                print("Updating %s to version %s from version %s" % (app['name'], IMAGE_TAG, app['values']['image']['tag']))
                app['values']['image']['tag'] = IMAGE_TAG
                with open(CONFIG_PATH, "w") as f:
                    yaml.dump(config, f)
                break
