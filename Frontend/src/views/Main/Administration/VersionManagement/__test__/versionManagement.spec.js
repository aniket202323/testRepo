import React from "react";
import Adapter from "enzyme-adapter-react-16";
import { configure, render, mount } from "enzyme";
import VersionManagement from "../../VersionManagement";

describe("Version Management", () => {
  let wrapper, component;
  const t = (text) => text;
  component = <VersionManagement t={t} />;

  configure({ adapter: new Adapter() });
  beforeEach(() => {
    wrapper = mount(component);
  });

  it("Should render without errors", () => {
    render(component);
  });

  it("Main view should be have an accordion", () => {
    expect(wrapper.find("Accordion").length).toBe(1);
  });

  it("Main view should be have five Items of Accordion", () => {
    expect(wrapper.find("Item").length).toBe(5);
  });

  it("Main view should be have a FileUploader component", () => {
    expect(wrapper.find("FileUploader").length).toBe(1);
  });

  it("Main view should be have a DropDownList component", () => {
    expect(wrapper.find("DropDownList").length).toBe(1);
  });

});
