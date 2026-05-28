from setuptools import setup

APP = ['macro_app.py']
OPTIONS = {
    'argv_emulation': False,
    'iconfile': 'icon.icns',
    'plist': {
        'CFBundleName': 'MACRO',
        'CFBundleDisplayName': 'MACRO',
        'CFBundleIdentifier': 'com.local.macro',
        'CFBundleVersion': '1.0.0',
        'CFBundleShortVersionString': '1.0.0',
        'NSHighResolutionCapable': True,
        'NSAppleEventsUsageDescription': 'MACRO needs accessibility access to send keystrokes.',
    },
    'packages': ['customtkinter', 'pynput'],
    'includes': [
        'pynput.keyboard._darwin',
        'pynput.mouse._darwin',
        'pynput._util.darwin',
        'pynput._util',
    ],
    'excludes': ['tkinter.test'],
}

setup(
    app=APP,
    options={'py2app': OPTIONS},
    setup_requires=['py2app'],
)
