import React, { PureComponent } from "react";
import "./bs-stepper.min.css";
import Stepper from "bs-stepper";
import Button from "../../../../../components/Button";

const steps = ["Routes", "Route | Tasks", "Tour Stops", "Route | Teams"];

class MyStepper extends PureComponent {
  constructor(props) {
    super(props);
    this.state = {
      stepWasUpdated: this.props.stepWasUpdated,
      disableNextButton: this.props.disableNextButton,
    };
  }
  componentDidMount() {
    this.stepper = new Stepper(document.querySelector("#stepper"), {
      linear: false,
      animation: true,
    });
  }

  componentDidUpdate() {
    this.setState({
      stepWasUpdated: this.props.stepWasUpdated,
      disableNextButton: this.props.disableNextButton,
    });
  }

  nextEvent = async (step) => {
    let _step = step + 2;
    let isRouteSelected = await this.props.events(step);
    if (!isRouteSelected) return;
    this.stepper.to(_step);
  };

  render() {
    const { t } = this.props;
    let { stepWasUpdated, disableNextButton } = this.state;
    return (
      <>
        <div id="stepper" class="bs-stepper">
          <div class="bs-stepper-header">
            {steps.map((title, index) => {
              let _i = index - 1;
              return (
                <>
                  <div class="step" data-target={"#test-l-" + index}>
                    {/* eslint-disable-next-line */}
                    <a
                      onClick={() => this.nextEvent(_i)}
                      style={{ cursor: "pointer" }}
                    >
                      <button
                        class="step-trigger"
                        disabled={true}
                        style={{ opacity: "1" }}
                      >
                        <span class="bs-stepper-circle">{index + 1}</span>
                        <span class="bs-stepper-label">{t(title)}</span>
                      </button>
                    </a>
                  </div>
                  <div class="line"></div>
                </>
              );
            })}
          </div>

          <div class="bs-stepper-content">
            {this.props.children.map((stepComponent, i) => {
              return (
                <div id={"test-l-" + i} class="content">
                  {stepComponent}
                  <div style={{ display: "inline-flex", width: "100%" }}>
                    {i !== 0 && (
                      <Button
                        text={t("Back")}
                        primary
                        style={{
                          marginLeft: "45%",
                          marginTop: "15px",
                          marginRight: "10px",
                          scale: "1.2",
                        }}
                        onClick={() => {
                          this.nextEvent(i - 2);
                        }}
                      />
                    )}
                    {i !== 3 && (
                      <Button
                        text={t("Next")}
                        primary
                        disabled={disableNextButton}
                        style={{
                          marginTop: "15px",
                          marginLeft: i === 0 ? "50%" : "0",
                          scale: "1.2",
                        }}
                        onClick={() => {
                          this.nextEvent(i);
                        }}
                      />
                    )}
                    {i !== 0 && (
                      <Button
                        text={t("Save")}
                        primary
                        disabled={
                          !stepWasUpdated &&
                          localStorage.getItem("hasUpdates") !== "true"
                        }
                        style={{
                          marginTop: "15px",
                          marginLeft: "5px",
                          backgroundColor: "#284e93",
                          width: "60px",
                          scale: "1.2",
                        }}
                        onClick={() => {
                          this.props.saveFunction(i);
                        }}
                      />
                    )}
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      </>
    );
  }
}

export default MyStepper;
