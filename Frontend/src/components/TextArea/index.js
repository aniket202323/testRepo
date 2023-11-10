import React, { PureComponent } from "react";
import styles from "./styles.module.scss";

class TextArea extends PureComponent {
  constructor(props) {
    super(props);

    this.state = {};
  }

  render() {
    const { cols, rows, maxwidth, disabled, resizable } = this.props;

    return (
      <textarea
        name={this.props.name}
        className={[
          styles.component,
          maxwidth ? styles.maxwidth : "",
          !resizable ? styles.noresizable : ""
        ].join(" ")}
        cols={cols || 50}
        rows={rows || 5}
        disabled={disabled || false}
      ></textarea>
    );
  }
}

export default TextArea;
