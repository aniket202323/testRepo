import React from "react";
import Adapter from "enzyme-adapter-react-16";
import { configure, render, mount } from "enzyme";
import TeamsManagement from "../../TeamsManagement";

describe("Teams Management", () => {
  let wrapper, component;
  const t = (text) => text;
  component = <TeamsManagement t={t} />;

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

  it("#Tasks view should be have a TreeList", () => {
    wrapper.setState({ displayTasks: true });
    expect(wrapper.find(".taskContainer").find("TreeList").length).toBe(1);
  });

  it("#Tasks view should be have a DataGrid", () => {
    wrapper.setState({ displayTasks: true });
    expect(wrapper.find(".taskContainer").find("DataGrid").length).toBe(1);
  });

  it("#Users view should be have a DataGrid", () => {
    wrapper.setState({ displayUsers: true });
    expect(wrapper.find(".usersContainer").find("DataGrid").length).toBe(1);
  });

  it("#Routes view should be have a DataGrid", () => {
    wrapper.setState({ displayRoutes: true });
    expect(wrapper.find(".routesContainer").find("DataGrid").length).toBe(1);
  });
});
