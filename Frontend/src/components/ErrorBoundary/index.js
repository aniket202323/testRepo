import React, { Component, memo } from "react";
// import { saveAs } from "file-saver";
import { translate } from "react-i18next";
import Button from "../Button";
import errorImg from "../../resources/error.png";
import styles from "./styles.module.scss";

class ErrorBoundary extends Component {
  constructor(props) {
    super(props);
    this.state = { hasError: false };
  }

  static getDerivedStateFromError(error) {
    return { hasError: true };
  }

  componentDidCatch(error, errorInfo) {
    // var blob = new Blob([error + errorInfo.componentStack], {
    //   type: "text/plain;charset=utf-8",
    // });
    // saveAs(blob, "static.txt");
  }

  render() {
    const { t } = this.props;
    if (this.state.hasError) {
      return (
        <div className={styles.errorContainer}>
          <img alt="" src={errorImg} />
          <h3>{t("Sorry, something went wrong")}</h3>
          <label>
            {("Try reloading the page. We're working hard to fix the problem as soon as possible. If the problem persists contact to the support team.")}
          </label>
          <Button
            text="Reload"
            primary
            classes={styles.btnReload}
            onClick={() => window.location.reload()}
          />
        </div>
      );
    }

    return this.props.children;
  }
}

export default translate()(memo(ErrorBoundary));