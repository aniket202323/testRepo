import i18n from "i18next";
import Backend from "i18next-xhr-backend";
import LanguageDetector from "i18next-browser-languagedetector";
import { reactI18nextModule } from "react-i18next";
import localization from "devextreme/localization";
import dxLocales from "../resources/DX/messages";

const availableLang = [
  "ar",
  "cs",
  "de",
  "en",
  "es",
  "fr",
  "hu",
  "pl",
  "pt",
  "ru",
  "tr",
  "zh",
  "cz",
];

function i18nInit() {
  i18n
    .use(Backend)
    .use(LanguageDetector)
    .use(reactI18nextModule)
    .init({
      fallbackLng: "en",
      load: "all",
      ns: ["translations"],
      defaultNS: "translations",
      debug: false, //process.env.NODE_ENV !== "production",
      interpolation: {
        escapeValue: false, // not needed for react!!
      },
      react: {
        wait: true,
      },
      backend: {
        // loadPath: "./locales/{{lng}}/{{ns}}.json"
        loadPath: (lngs, namespaces) => {
          let lang = availableLang.includes(lngs.toString())
            ? lngs.toString()
            : "en";
          return `./locales/${lang}/${namespaces}.json`;
        },
      },
      nsSeparator: false,
      keySeparator: false,
    });

  i18n.on("languageChanged", (lang) => {
    lang = lang.split("-").length > 1 ? lang.split("-")[0] : lang;
    localStorage.setItem("eCIL-app-language", lang);
    localization.loadMessages(dxLocales);
    localization.locale(lang);
  });

  window.addEventListener(
    "focus",
    function (event) {
      if (i18n.language !== undefined) {
        i18n.language = i18n.language.toString();
        // i18n.language = availableLang.includes(i18n.language.toString())
        //   ? i18n.language.toString()
        //   : "en";

        if (i18n.language !== localStorage.getItem("eCIL-app-language"))
          i18n.changeLanguage(localStorage.getItem("eCIL-app-language"), () => {
            // window.location.reload();
          });
      }
    },
    false
  );
  return i18n;
}

function getAvailableLanguages() {
  let languages = [];
  if (i18n && i18n.options) {
    const keys = i18n.getResource("en", i18n.options.defaultNS, "locales");
    Object.keys(keys).forEach((key) =>
      languages.push({ value: key, text: keys[key] })
    );
  }
  return languages;
}

export { i18nInit, i18n, getAvailableLanguages };
