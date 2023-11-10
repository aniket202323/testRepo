import React, { PureComponent } from "react";
import Icon from "../../../Icon";
import styles from "./styles.module.scss";

export default class TopBarButton extends PureComponent {
  createStyles = () => {
    const { className } = this.props;
    const active = !!this.props.active;
    let names = [styles.component];
    if (this.props.disabled) names.push(styles.disabled);
    if (active) names.push(styles.active);
    if (className) names.push(className);
    return names.join(" ");
  };

  render() {
    let disabled = this.props.disabled ? "disabled" : "";
    let show = typeof this.props.show === "undefined" ? true : this.props.show;
    return (
      show && (
        <button
          className={this.createStyles()}
          id={this.props.id}
          disabled={disabled}
          onClick={this.props.onClick}
        >
          {this.props.icon ? (
            <Icon name={this.props.icon} primary style={{ fontSize: "20px" }} />
          ) : (
            ""
          )}
          {this.props.text ? (
            <span className={styles.title}>{this.props.text}</span>
          ) : (
            ""
          )}
        </button>
      )
    );
  }
}
