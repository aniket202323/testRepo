import React, { PureComponent } from "react";
import DateBox from "devextreme-react/ui/date-box";

class DateTime extends PureComponent {
  constructor(props) {
    super(props);

    this.state = {};
  }

  render() {
    const {
      id,
      reference,
      type,
      min,
      max,
      displayFormat,
      showClearButton,
      disabled,
      placeholder,
      height,
      acceptCustomValue,
      onValueChanged,
      value,
      pickerType,
      applyValueMode,
      defaultValue,
    } = this.props;

    return (
      <DateBox
        id={id || undefined}
        ref={reference || null}
        type={type || "date"}
        displayFormat={displayFormat || "yyyy-MM-dd"}
        min={min || undefined}
        max={max || undefined}
        showClearButton={showClearButton || false}
        disabled={disabled || false}
        placeholder={placeholder || ""}
        applyValueMode={applyValueMode || "useButtons"}
        onValueChanged={onValueChanged || undefined}
        acceptCustomValue={acceptCustomValue || false}
        height={height || "auto"}
        value={value || null}
        pickerType={pickerType || null}
        defaultValue={defaultValue || null}
      />
    );
  }
}

export default DateTime;
