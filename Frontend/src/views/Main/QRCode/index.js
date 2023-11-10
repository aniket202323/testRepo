import React, { PureComponent } from "react";
import ByTask from "./bytask";
import ByRoute from "./byroute";
import styles from "./styles.module.scss";

class QrCode extends PureComponent {
  render() {
    const { by, t } = this.props;

    return (
      <React.Fragment>
        <div className={styles.container}>
          {by === "byTask" ? <ByTask t={t} /> : <ByRoute t={t} />}
        </div>
      </React.Fragment>
    );
  }
}

export default QrCode;
