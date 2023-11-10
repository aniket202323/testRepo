import React from "react";
import Adapter from "enzyme-adapter-react-16";
import { configure, render, mount, shallow } from "enzyme";
import TasksSelection from "../../TasksSelection";
import Grid from "../subs/DataGrid";
import Filters from "../subs/Filters";
import Defects from "../subs/Defects";
import { I18nextProvider } from "react-i18next";
import { i18nInit } from "../../../../services/locale";
import { translate } from "react-i18next";

describe("Tasks Selection test cases", () => {
  let wrapper, index, dataGrid, filters, defects, instance;
  const t = translate();
  index = (
    <I18nextProvider i18n={i18nInit()}>
      <TasksSelection t={t} viewActive={"Plant Model"} />
    </I18nextProvider>
  );
  dataGrid = <Grid t={t} />;
  filters = <Filters t={t} viewActive={"Plant Model"} />;
  defects = <Defects t={t} />;

  configure({ adapter: new Adapter() });

  beforeEach(() => {
    wrapper = shallow(filters);
    instance = wrapper.instance();
    // console.log(instance);
  });

  it("Should render the index without errors", () => {
    render(index);
  });

  it("Should render the Filters without errors", () => {
    render(filters);
  });

  it("Should render the DataGrid without errors", () => {
    render(dataGrid);
  });

  // Cards
  it("Should have 3 Cards Components [Filters / DataGrid / Defects]", () => {
    wrapper = shallow(index).childAt(0).dive();
    expect(wrapper.find("Card").length).toBe(3);
  });

  // Filters
  it("Filters should have 3 SelectBox for Plant Model", () => {
    wrapper = shallow(filters).children();
    expect(wrapper.find(".selectBox").length).toBe(3);
  });

  it("Filters should have one SelectBox for My Teams", () => {
    filters = <Filters t={t} viewActive={"My Teams"} />;
    wrapper = shallow(filters).children();
    expect(wrapper.find("#myteams").length).toBe(1);
  });

  it("Filters should have one SelectBox for Teams", () => {
    filters = <Filters t={t} viewActive={"Teams"} />;
    wrapper = shallow(filters).children();
    expect(wrapper.find("#teams").length).toBe(1);
  });

  it("Filters should have one SelectBox for My Routes", () => {
    filters = <Filters t={t} viewActive={"My Routes"} />;
    wrapper = shallow(filters).children();
    expect(wrapper.find("#myroutes").length).toBe(1);
  });

  it("Filters should have one SelectBox for Routes", () => {
    filters = <Filters t={t} viewActive={"Routes"} />;
    wrapper = shallow(filters).children();
    expect(wrapper.find("#routes").length).toBe(1);
  });

  // Datagrid
  it("Should have one Data Grid", () => {
    wrapper = shallow(index).childAt(0).dive();
    expect(wrapper.find("Grid").length).toBe(1);
  });

  it("DataGrid should have a Popup for 'Customize View' and one for 'Postpone Task'", () => {
    wrapper = shallow(dataGrid).children();
    expect(wrapper.find("Popup").length).toBe(2);
  });

  it("DataGrid should have a Button for Save the changes for selected tasks", () => {
    wrapper = shallow(dataGrid).children();
    expect(wrapper.find("#btnSaveTasksSelection").length).toBe(1);
  });

  it("Test click event for Save selected tasks", () => {
    wrapper = shallow(dataGrid).children();
    wrapper.find("#btnSaveTasksSelection").simulate("click");
  });

  it("DataGrid should have a Grid for loading the Information of each task", () => {
    wrapper = shallow(dataGrid).children();
    expect(wrapper.find(".infoDetailGrid").length).toBe(1);
  });

  // Defects
  it("Should have a defect screen", () => {
    wrapper = shallow(index).childAt(0).dive();
    expect(wrapper.find("Defects").length).toBe(1);
  });

  it("Defects screen should have an instance for defectComponent", () => {
    wrapper = shallow(defects);
    instance = wrapper.instance();
    expect(instance.state.defectComponent).toBeDefined();
  });

  it("Defects screen should have an instance for defectHowFound", () => {
    wrapper = shallow(defects);
    instance = wrapper.instance();
    expect(instance.state.defectHowFound).toBeDefined();
  });

  it("Defects screen should have an instance for defectPriorities", () => {
    wrapper = shallow(defects);
    instance = wrapper.instance();
    expect(instance.state.defectPriorities).toBeDefined();
  });

  it("Tasks Selection has a logic for redirection to the corresponding page: Plant Model or My routes from QR Code", () => {
    filters = (
      <Filters t={t} viewActive={"MyRoutes"} urlParams={{ myroute: 56 }} />
    );
    wrapper = shallow(filters);
    instance = wrapper.instance();
    expect(instance.setFiltersByURL()).toBe(undefined); // execute method without error
    expect(instance.setFiltersByURL).toBeDefined();
  });

  it("Plant Model / My routes have a logic for reading the variables from QR Code", () => {
    let fn = jest.fn();
    filters = <Filters t={t} viewActive={"MyRoutes"} handlerData={fn} />;
    wrapper = shallow(filters);
    instance = wrapper.instance();
    expect(instance.handlerDataByQr()).toBe(undefined); // execute method without error
    expect(instance.handlerDataByQr).toBeDefined();
  });
});
