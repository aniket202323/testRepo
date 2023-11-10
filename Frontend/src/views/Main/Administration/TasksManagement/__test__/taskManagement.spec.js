import React from "react";
import Adapter from "enzyme-adapter-react-16";
import { configure, render, mount } from "enzyme";
import TasksManagement from "../../TasksManagement";

describe("Tasks Management", () => {
  let wrapper, component;

  function t(text) {
    return text;
  }

  let settings = {};
  settings.navbar = "Teams";

  component = <TasksManagement t={t} />;

  configure({ adapter: new Adapter() });

  beforeEach(() => {
    wrapper = mount(component);
  });

  it("Should render without errors", () => {
    render(component);
  });

  it("Render DataGrid", () => {
    expect(wrapper.find("DataGrid")).to.have.lengthOf(1);
  });
});
