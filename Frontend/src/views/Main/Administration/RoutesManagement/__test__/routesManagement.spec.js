import React from "react";
import Adapter from "enzyme-adapter-react-16";
import { configure, render, mount } from "enzyme";
import RoutesManagement from "../../RoutesManagement";

describe("Routes Management", () => {
  let wrapper, component;
  const t = (text) => text;
  component = <RoutesManagement t={t} />;

  configure({ adapter: new Adapter() });
  beforeEach(() => {
    wrapper = mount(component);
  });

  it("Should render without errors", () => {
    render(component);
  });

  it("Main view should be have a DataGrid", () => {
    expect(wrapper.find("DataGrid").length).toBe(1);
  });

  it("#Teams view should be have a DataGrid", () => {
    wrapper.setState({ displayTeams: true });
    expect(wrapper.find(".teamsContainer").find("DataGrid").length).toBe(1);
  });

  it("#Tasks view should be have a DataGrid", () => {
    wrapper.setState({ displayTasks: true });
    expect(wrapper.find(".taskContainer").find("DataGrid").length).toBe(1);
  });

  it("#Tasks view should be have a TreeList", () => {
    wrapper.setState({ displayTasks: true });
    expect(wrapper.find(".taskContainer").find("TreeList").length).toBe(1);
  });
});
