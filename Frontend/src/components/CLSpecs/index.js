import React, { PureComponent } from "react";
import styles from "./styles.module.scss";

const CLDataSpec = [
  {
    name: "L_Reject",
    bgColor: "#bac3c6",
    labelColor: "#00000",
  },
  {
    name: "Target",
    bgColor: "#adb4b7",
    labelColor: "#00000",
  },
  {
    name: "U_Reject",
    bgColor: "#bac3c6",
    labelColor: "#00000",
  },
];

export default class Index extends PureComponent {
  constructor(props) {
    super(props);
  }

  createStyles = () => {
    let names = [styles.colorBox];
    if (this.props.classes) names.push(this.props.classes);
    return names.join(" ");
  };

  render() {
    return (
      <div className={styles.colorBoxesContainer}>
        <div className={this.createStyles()}>
          <h2 id="VarDesc"></h2>
          <div>
            {CLDataSpec.map((cl_spec) => {
              return (
                <span
                  key={cl_spec.name}
                  style={{
                    backgroundColor: cl_spec.bgColor,
                    color: cl_spec.labelColor,
                  }}
                >
                  <br />
                  {/* <b> {cl_spec.name}</b> {":  "} */}
                  <b>
                    <span id={cl_spec.name}></span>
                  </b>
                </span>
              );
            })}
          </div>
        </div>
      </div>
    );
  }
}
