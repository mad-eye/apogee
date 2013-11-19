os = (navigator.platform.match(/mac|win|linux/i) || ["other"])[0].toLowerCase()
isMac = os == 'mac'


@Client = {os, isMac}
