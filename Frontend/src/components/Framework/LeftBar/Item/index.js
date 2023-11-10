import React, { Component } from "react";
import { Icon } from "react-fa";
import styles from "./styles.module.scss";

export default class Item extends Component {
  constructor(props) {
    super(props);
    this.state = {
      loading: false,
      text: "",
    };
  }
  createStyles = () => {
    const { disabled, primary, selected } = this.props;

    let names = [styles.component];

    if (disabled) names.push(styles.disabled);
    if (selected) names.push(styles.selected);
    if (primary) names.push(styles.primary);

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

  onClick = (e) => {
    this.props.onClick(e);
  };

  render() {
    const { text, loading } = this.state;
    const { type, disabled, name, icon, imgIcon } = this.props;

    return (
      <button
        // id={"btnNav" + text.replaceAll(" ", "")}
        id={"btnNav" + text.replace(/\s/g, "")}
        onClick={() => this.onClick(name || "")}
        className={this.createStyles()}
        type={type || "button"}
        disabled={disabled ? "disabled" : ""}
        data-name={name || ""}
        title={text}
      >
        {loading ? (
          <Icon spin name="refresh" />
        ) : icon ? (
          <Icon name={icon} />
        ) : imgIcon ? (
          <img alt="" src={imgIcon} className={styles.imgicon} />
        ) : (
          ""
        )}
        {text ? <span className={styles.title}>{text}</span> : ""}
      </button>
    );
  }
}
