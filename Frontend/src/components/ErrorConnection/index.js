import React, { PureComponent, memo } from "react";
import { translate } from "react-i18next";
import styles from "./styles.module.scss";

class ErrorConnection extends PureComponent {
  constructor(props) {
    super(props);

    this.state = {};
  }

  render() {
    const { t } = this.props;
    return (
      <div
        className={[
          styles.container,
          !this.props.display ? styles.hidden : ""
        ].join(" ")}
      >
        <div>
          <h3>{t("Connection Error")}</h3>
          <h4>{t("There is no Internet connection")}</h4>
        </div>
      </div>
    );
  }
}

export default translate()(memo(ErrorConnection));

