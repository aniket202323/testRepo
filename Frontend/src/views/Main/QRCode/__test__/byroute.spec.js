import React from "react";
import Adapter from "enzyme-adapter-react-16";
import ByRoute from "../byroute";
import { configure, render, shallow } from "enzyme";
import { I18nextProvider } from "react-i18next";
import { i18nInit } from "../../../../services/locale";
import { translate } from "react-i18next";

describe("QR Code 'By Route' Test Cases", () => {
  let wrapper, index, instance, byrouteComponent;
  const t = translate();
  index = (
    <I18nextProvider i18n={i18nInit()}>
      <ByRoute t={t} />
    </I18nextProvider>
  );
  byrouteComponent = <ByRoute t={t} />;
  configure({ adapter: new Adapter() });

  beforeEach(() => {
    wrapper = shallow(index);
    instance = wrapper.instance();
  });

  it("Should render the By Route Index without errors", () => {
    render(index);
  });

  // DropDown
  it("Should have one DropDownList component", () => {
    wrapper = shallow(byrouteComponent).children();
    expect(wrapper.find("DropDownList").length).toBe(1);
  });

  // QrCodeGrid
  it("Should have one QrCodeGrid component", () => {
    wrapper = shallow(byrouteComponent).children();
    expect(wrapper.find("QrCodeGrid").length).toBe(1);
  });

  // ViewQr
  it("Should have one ViewQr component for show the QR Code", () => {
    wrapper = shallow(index).childAt(0).dive();
    wrapper.setState({ viewQr: true });
    expect(wrapper.find("ViewQr").length).toBe(1);
  });

  // SaveQr
  it("Should have one SaveQr component for save the QR Code", () => {
    wrapper = shallow(index).childAt(0).dive();
    wrapper.setState({ showsaveQr: true });
    expect(wrapper.find("SaveQr").length).toBe(1);
  });

  it("Test click event: onClickGenerateQR", () => {
    wrapper = shallow(byrouteComponent);
    instance = wrapper.instance();
    console.log(instance);
    expect(instance.onClickGenerateQR()).toBe(undefined);
  });

  it("Test click event: handlerData", () => {
    wrapper = shallow(byrouteComponent);
    instance = wrapper.instance();
    expect(instance.handlerData([], true)).toBe(undefined);
  });
});
