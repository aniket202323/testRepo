import React from "react";
import ReactDOM from "react-dom";
import App from "./App";
import ErrorBoundary from "./components/ErrorBoundary";
import { I18nextProvider } from "react-i18next";
import { i18nInit } from "./services/locale";
import { Provider } from "react-redux";
import store from "./redux/store";
import "normalize.css";
import "./index.css";
import "devextreme/dist/css/dx.common.css";
import "devextreme/dist/css/dx.light.compact.css";
import "react-multiselect-box/build/css/index.css";
import "./utils/globals.js";
// eslint-disable-next-line no-unused-vars
import { DropDownButton } from "devextreme-react/ui/drop-down-button";

ReactDOM.render(
  <Provider store={store}>
    <I18nextProvider i18n={i18nInit()}>
      <ErrorBoundary>
        <App />
      </ErrorBoundary>
    </I18nextProvider>
  </Provider>,
  document.getElementById("root")
);
