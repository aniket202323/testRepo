import React, { PureComponent } from "react";
import { getColorCoding } from "./options";
import styles from "./styles.module.scss";

export default class Index extends PureComponent {
  constructor(props) {
    super(props);

    this.state = {};
  }

  createStyles = () => {
    let names = [styles.colorBox];
    if (this.props.classes) names.push(this.props.classes);

    return names.join(" ");
  };

  render() {
    const { t, report, visible } = this.props;

    if (!visible) return null;
    return (
      <div className={styles.colorBoxesContainer}>
        <div className={this.createStyles()}>
          <h2>{t("Cells Color and Priority")}</h2>
          <div>
            {getColorCoding(report).map((color) => (
              <span
                key={color.name}
                style={{
                  backgroundColor: color.bgColor,
                  color: color.labelColor,
                }}
              >
                {t(color.name)}
              </span>
            ))}
          </div>
        </div>
      </div>
    );
  }
}
