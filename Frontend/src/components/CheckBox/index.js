import React, { PureComponent, memo } from "react";
import { translate } from "react-i18next";
import { CheckBox as DXCheckBox } from "devextreme-react/ui/check-box";
import styles from "./styles.module.scss";

class CheckBox extends PureComponent {
  constructor(props) {
    super(props);

    this.state = {};
  }

  createStyles = () => {
    let names = [styles.container];
    if (this.props.classes) names.push(this.props.classes);

    return names.join(" ");
  };

  render() {
    return (
      <DXCheckBox
        id={this.props.id || undefined}
        className={this.createStyles()}
        defaultValue={this.props.defaultValue || false}
        text={this.props.t(this.props.text)}
        disabled={this.props.disabled || false}
        value={this.props.value || false}
        onValueChanged={(e) =>
          this.props.onValueChanged
            ? this.props.onValueChanged(
              Object.assign({}, e, { tag: this.props.tag })
            )
            : null
        }
      />
    );
  }
}

export default translate()(memo(CheckBox));
