import React, { PureComponent } from "react";
import styles from "./styles.module.scss";

class ReportPeriod extends PureComponent {
  constructor(props) {
    super(props);

    this.state = {};
  }

  createStyles = () => {
    let names = [styles.reportPeriod];
    if (this.props.classes) names.push(this.props.classes);

    return names.join(" ");
  };

  render() {
    let { t, startTime, endTime } = this.props;

    startTime = startTime || "-";
    endTime = endTime || "-";

    return (
      <div className={this.createStyles()}>
        <b>{t("Report Period")}:</b>&nbsp;
        <span>{String(startTime)}</span>
        &nbsp;
        <b>{t("To")}</b>&nbsp;
        <span>{String(endTime)}</span>
      </div>
    );
  }
}

export default ReportPeriod;
