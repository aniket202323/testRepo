import React from "react";
import Adapter from "enzyme-adapter-react-16";
import QrCode from "../index";
import { configure, render } from "enzyme";
import { I18nextProvider } from "react-i18next";
import { i18nInit } from "../../../../services/locale";
import { translate } from "react-i18next";

describe("QR Code Components Test Cases", () => {
  let index, ByTask, ByRoute;
  const t = translate();
  index = (
    <I18nextProvider i18n={i18nInit()}>
      <QrCode t={t} />
    </I18nextProvider>
  );

  configure({ adapter: new Adapter() });

  it("Should render the index without errors", () => {
    render(index);
  });

  it("Should render the ByTask Component without errors", () => {
    ByTask = <QrCode t={t} by="byTask" />;
    render(ByTask);
  });

  it("Should render the ByRoutes Component without errors", () => {
    ByRoute = <QrCode t={t} by="byRoute" />;
    render(ByRoute);
  });
});
