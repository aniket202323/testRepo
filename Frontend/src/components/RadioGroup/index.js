import React, { PureComponent } from "react";
import { RadioGroup as DXRadioGroup } from "devextreme-react/ui/radio-group";

class RadioGroup extends PureComponent {
  constructor(props) {
    super(props);

    this.state = {};
  }

  render() {
    const { items, value, valueExpr, displayExpr, onValueChanged } = this.props;

    return (
      <DXRadioGroup
        items={items || []}
        value={value || ""}
        valueExpr={valueExpr || undefined}
        displayExpr={displayExpr || undefined}
        onValueChanged={onValueChanged}
      />
    );
  }
}

export default RadioGroup;
