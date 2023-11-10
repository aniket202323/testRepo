import React, { PureComponent } from "react";
import { LoadIndicator } from "devextreme-react/ui/load-indicator";
import styles from "./styles.module.scss";

export function displayPreload(state) {
  if (document.getElementById("preload") !== null)
    document.getElementById("preload").style.display = state ? "flex" : "none";
}

class Preload extends PureComponent {
  render() {
    const { t } = this.props;

    return (
      <div id="preload" className={styles.preload}>
        <div className={styles.preloadContent}>
          <LoadIndicator width="50" height="50" visible={true} />
          <span>{t("Loading, please wait")}...</span>
        </div>
      </div>
    );
  }
}

export default Preload;
