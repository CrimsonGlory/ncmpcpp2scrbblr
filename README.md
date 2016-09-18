ncmpcpp2scrobblr is a last.fm/audioscrobbler song submission script for ncmpcpp.
by CrimsonGlory <https://github.com/CrimsonGlory>

It is based on mp3blstr2dscrbblr.sh 0.4 by Alexander Heinlein <alexander.heinlein@web.de>

License: GPL v3

# Install
```apt-get install libaudio-scrobbler-perl```
```git clone https://github.com/CrimsonGlory/ncmpcpp2scrbblr```

Edit ~/.scrobbler-helper.conf  with
```
[global]
username=your_username
password=your_pass
# Optional (the default is UTF-8)
default_encoding=windows-1251
# Optional (the default is "no")
fix_track_name=yes
```

# Usage
Just execute it and leave it in the background.
```./ncmpcpp2scrbblr.sh & ```
