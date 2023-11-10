import React, { PureComponent } from "react";

import styles from "./styles.module.scss";

export default class Input extends PureComponent {
  createStyles = () => {
    let names = [styles.component];
    this.props.border
      ? names.push(styles.border)
      : names.push(styles.withoutBorder);
    if (this.props.disabled) names.push(styles.disabled);
    return names.join(" ");
  };

  hanglerOnChange = () => {};
  render() {
    switch (this.props.type) {
      case "number":
      case "text":
      case "password":
      case "email":
        return (
          <div className={this.props.className}>
            <label htmlFor={this.props.id} className="label">
              {this.props.label}
            </label>
            <input
              id={this.props.id || undefined}
              name={this.props.name}
              className={this.createStyles()}
              disabled={this.props.disabled ? "disabled" : ""}
              type={this.props.type}
              placeholder={this.props.placeholder}
              value={this.props.value === null ? "" : this.props.value}
              defaultValue={this.props.defaultValue || undefined}
              onChange={this.props.onChange}
              onKeyPress={this.props.onKeyPress}
              min={this.props.min || 0}
              max={this.props.max || 0}
              maxLength={this.props.maxLength || undefined}
              step={1}
              pattern={this.props.pattern || "d+"}
            />
          </div>
        );
      default:
        return <div>ERROR! Type not soported!</div>;
    }
  }
}
