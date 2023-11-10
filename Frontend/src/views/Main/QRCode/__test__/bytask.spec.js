import React from "react";
import Adapter from "enzyme-adapter-react-16";
import ByTask from "../bytask";
import DataGrid from "../subs/DataGrid";
import { configure, render, shallow } from "enzyme";
import { I18nextProvider } from "react-i18next";
import { i18nInit } from "../../../../services/locale";
import { translate } from "react-i18next";

describe("QR Code 'By Tasks' Test Cases", () => {
  let wrapper, index, instance, bytaskComponent;
  const t = translate();
  index = (
    <I18nextProvider i18n={i18nInit()}>
      <ByTask t={t} />
    </I18nextProvider>
  );
  bytaskComponent = <ByTask t={t} />;
  configure({ adapter: new Adapter() });

  beforeEach(() => {
    wrapper = shallow(bytaskComponent);
    instance = wrapper.instance();
    // console.log(instance);
  });

  it("Should render the By Tasks Index without errors", () => {
    render(index);
  });

  // Accordion
  it("Should have one Accordion component", () => {
    wrapper = shallow(index).childAt(0).dive();
    expect(wrapper.find("Accordion").length).toBe(1);
  });

  // Accordion 2 Items
  it("Should have 2 Items into the Accordion component ('Generate QR Code' & 'QR Code Report')", () => {
    wrapper = shallow(index).childAt(0).dive();
    expect(wrapper.find("Item").length).toBe(2);
  });

  // RadioGroup
  it("Should have one RadioGroup component", () => {
    wrapper = shallow(index).childAt(0).dive();
    expect(wrapper.find("RadioGroup").length).toBe(1);
  });

  // SelectBox
  it("Component should have one SelectBox for Lines", () => {
    wrapper = shallow(bytaskComponent).children();
    expect(wrapper.find("#sboLinesQRCode").length).toBe(1);
  });

  it("Component should have one SelectBox Units", () => {
    wrapper = shallow(bytaskComponent).children();
    expect(wrapper.find("#sboUnitsQRCode").length).toBe(1);
  });

  it("Component should have one SelectBox for Modules", () => {
    wrapper = shallow(bytaskComponent).children();
    expect(wrapper.find("#sboWorkcellsQRCode").length).toBe(1);
  });

  // SelectBox By Line
  it("Should have 3 react-states for the SelectBox components (Line / Master Unit / Module)", () => {
    wrapper = shallow(bytaskComponent);
    instance = wrapper.instance();
    expect(instance.state.lines).toBeDefined();
    expect(instance.state.units).toBeDefined();
    expect(instance.state.workcells).toBeDefined();
  });

  // Tasks DataSource
  it("Should have a data source for loading tasks", () => {
    wrapper = shallow(bytaskComponent);
    instance = wrapper.instance();
    expect(instance.state.tasks).toBeDefined();
  });

  // ViewQr
  it("Should have one ViewQr component for show the QR Code", () => {
    wrapper = shallow(index).childAt(0).dive();
    wrapper.setState({ qrcode: true });
    expect(wrapper.find("ViewQr").length).toBe(1);
  });

  // SaveQr
  it("Should have one SaveQr component for save the QR Code", () => {
    wrapper = shallow(index).childAt(0).dive();
    wrapper.setState({ showsaveQr: true });
    expect(wrapper.find("SaveQr").length).toBe(1);
  });

  it("Test click event: onClickGenerateQR", () => {
    wrapper = shallow(bytaskComponent);
    instance = wrapper.instance();
    expect(instance.onClickGenerateQR()).toBe(undefined);
  });

  // DataGrid
  it("Should have one DataGrid Component for 'Generate QR Code'", () => {
    let dataGrid = <DataGrid t={t} />;
    wrapper = shallow(dataGrid).children();
    expect(wrapper.find("DataGrid").length).toBe(1);
  });

  // QrCodeGrid
  it("Should have one QrCodeGrid component for 'QR Code Report'", () => {
    wrapper = shallow(index).childAt(0).dive();
    expect(wrapper.find("QrCodeGrid").length).toBe(1);
  });
});
