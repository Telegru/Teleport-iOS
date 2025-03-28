import plistlib
from pathlib import Path

def generate_google_services_plist(bundle_id):
    plists_dir = Path().absolute().joinpath("build-system/google-services-ios")

    for f in Path(plists_dir).glob("*.plist"):
        with open(f, 'rb') as file:
            pl = plistlib.load(file)
            p_bundle_id = pl["BUNDLE_ID"]

            if bundle_id == p_bundle_id:
                dst = Path().absolute().joinpath("Telegram/Telegram-iOS/GoogleService-Info.plist")
                with open(dst, "wb") as wf:
                    file = open(f, "rb")
                    wf.write(file.read())
                return

    raise Exception("Не найден подходящий файл GoogleService-Info.plist")

