import React, { Component } from "react";
import Icon from "../Icon";
import styles from "./styles.module.scss";

export default class Button extends Component {
  constructor(props) {
    super(props);
    this.state = {
      loading: false,
      text: "",
    };
  }
  createStyles = () => {
    let names = [styles.component];
    if (this.props.disabled) names.push(styles.disabled);
    if (this.props.primary) names.push(styles.primary);
    if (this.props.success) names.push(styles.success);
    if (this.props.classes) names.push(this.props.classes);

    return names.join(" ");
  };

  componentDidMount = () => {
    this.setState({
      loading: this.props["style-type"] === "loading" ? true : false,
      text: this.props.text ? this.props.text : false,
    });
  };

  static getDerivedStateFromProps(props) {
    return {
      text: props.text || "",
    };
  }

  render() {
    const {
      id,
      type,
      disabled,
      hint,
      icon,
      imgsrc,
      visible = true,
      onClick,
      style,
      iconStyle,
    } = this.props;

    if (!visible) return null;

    return (
      <button
        id={id || undefined}
        onClick={onClick}
        className={this.createStyles()}
        type={type || "button"}
        disabled={disabled ? "disabled" : ""}
        title={hint}
        style={style || undefined}
      >
        {this.state.loading ? (
          <Icon name="rotate" />
        ) : icon || imgsrc ? (
          <Icon
            name={icon || imgsrc}
            primary={this.props.primary}
            wasImage={imgsrc}
            style={iconStyle || undefined}
          />
        ) : (
          ""
        )}
        {this.state.text ? (
          <span className={icon || imgsrc ? styles.title : ""}>
            {this.state.text}
          </span>
        ) : (
          ""
        )}
      </button>
    );
  }
}
