import os

print('Importing requests')
import requests

os.environ['PYTHONUNBUFFERED'] = '1'

session = requests.Session()


print('retrieving yuzu releases')
published_req = session.get('https://{}@api.github.com/repos/yuzu-emu/yuzu-mainline/releases'.format(os.getenv('GITHUB_TOKEN')))

if published_req.status_code == 200:
    published_releases = published_req.json()
else:
    print("Could not retrieve 'yuzu-mainline' published releases from GitHub")
    exit(1)

failed_req = session.get('https://raw.githubusercontent.com/linux-gamers/arch-yuzu-mainline/master/builds_failed.txt')
failed_tags = {t.strip() for t in failed_req.text.split('\n') if t} if failed_req.status_code == 200 else set()

if published_releases[0]['tag_name'].split('mainline-')[1] in failed_tags:
    print('The latest published release was not able to be built. Aborting...')
    exit(1)

arch_rel_req = session.get('https://{}@api.github.com/repos/linux-gamers/arch-yuzu-mainline/releases/latest'.format(os.getenv('GITHUB_TOKEN')))

if arch_rel_req.status_code == 200:
    arch_latest_release = 'mainline-{}'.format(arch_rel_req.json()['tag_name'])
else:
    print("Could not retrieve the latest Arch published release from GitHub")
    exit(1)

if published_releases[0]['tag_name'] == arch_latest_release:
    print('All releases were already published')
    exit(1)


all_not_published = []

for r in published_releases:
    if r['tag_name'] > arch_latest_release and r['tag_name'] not in failed_tags:
        all_not_published.append(r['tag_name'])
    else:
        break

print(all_not_published[-1].split('mainline-')[1])
