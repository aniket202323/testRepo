import React, { PureComponent } from "react";
import styles from "./styles.module.scss";

class Card extends PureComponent {
  constructor(props) {
    super(props);

    this.state = {};
  }

  createStyles = () => {
    let names = [styles.card];

    if (this.props.autoHeight) names.push(styles.autoHeight);
    if (this.props.classes) names.push(this.props.classes);
    if (this.props.hidden) names.push(styles.hidden);
    if (this.props.float) names.push(styles.float);
    if (this.props.flat) names.push(styles.flat);

    return names.join(" ");
  };

  render() {
    return (
      <div id={this.props.id || ""} className={this.createStyles()}>
        {this.props.children}
      </div>
    );
  }
}

export default Card;
