import React from "react";
import Adapter from "enzyme-adapter-react-16";
import RoutesManagement from "../../RoutesManagement";
import { configure, render, shallow } from "enzyme";
import { I18nextProvider } from "react-i18next";
import { i18nInit } from "../../../../../services/locale";
import { translate } from "react-i18next";

describe("'Activity Viewer Configuration' Test Cases", () => {
  let wrapper, index, instance, component;
  const t = translate();
  index = (
    <I18nextProvider i18n={i18nInit()}>
      <RoutesManagement t={t} />
    </I18nextProvider>
  );
  component = <RoutesManagement t={t} />;
  configure({ adapter: new Adapter() });

  beforeEach(() => {
    wrapper = shallow(component);
    instance = wrapper.instance();
  });

  it("Should render the By Route Index without errors", () => {
    render(index);
  });

  it("Test handlerRouteScreen method", () => {
    instance = wrapper.instance();
    expect(instance.handlerRouteScreen({ row: { data: "" } })).toBe(undefined);
  });

  it("Test activityCreated: method", () => {
    instance = wrapper.instance();
    expect(instance.activityCreated(1)).toBeDefined();
  });

  it("Test showActivityStored state", () => {
    instance = wrapper.instance();
    expect(instance.state.showActivityStored).toBeDefined();
  });

  it("Test showActivityValue state", () => {
    instance = wrapper.instance();
    expect(instance.state.showActivityValue).toBeDefined();
  });

  it("Test triggersActvity state", () => {
    instance = wrapper.instance();
    expect(instance.state.triggersActvity).toBeDefined();
  });

  it("Test triggersActvityStored state", () => {
    instance = wrapper.instance();
    expect(instance.state.triggersActvityStored).toBeDefined();
  });
});
