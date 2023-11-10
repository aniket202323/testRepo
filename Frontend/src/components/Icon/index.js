import React, { PureComponent } from "react";
import styles from "./styles.module.scss";

export const ICONS_LIBRARY = "fa-solid fa-";

class Icon extends PureComponent {
  createStyles = () => {
    let names = [styles.iconComponent];
    if (this.props.primary) names.push(styles.primary);
    if (this.props.wasImage) names.push(styles.wasImage);
    return names.join(" ");
  };

  render() {
    const { name, onClick, style } = this.props;

    return (
      <div className={this.createStyles()}>
        <i
          class={ICONS_LIBRARY + `${name}`}
          onClick={onClick}
          style={style}
        ></i>
      </div>
    );
  }
}

export default Icon;
