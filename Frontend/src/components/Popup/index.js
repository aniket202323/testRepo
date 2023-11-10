import React, { PureComponent } from "react";
import { Popup as DXPopup } from "devextreme-react/ui/popup";

class Popup extends PureComponent {
  constructor(props) {
    super(props);

    this.state = {};
  }

  render() {
    const {
      id,
      reference,
      visible,
      title,
      onHidden,
      onHiding,
      onShowing,
      onShown,
      width,
      height,
      maxWidth,
      maxHeight,
      dragEnabled,
      resizeEnabled,
      closeOnOutsideClick,
      showCloseButton,
    } = this.props;

    return (
      <DXPopup
        id={id || undefined}
        ref={reference || null}
        visible={visible || false}
        onHidden={(e) => (onHidden ? onHidden(e) : null)}
        onShowing={(e) => (onShowing ? onShowing(e) : null)}
        onShown={(e) => (onShown ? onShown(e) : null)}
        onHiding={(e) => onHiding(e.element.id)}
        closeOnOutsideClick={closeOnOutsideClick}
        dragEnabled={dragEnabled || false}
        resizeEnabled={resizeEnabled || false}
        showTitle={true}
        title={title || ""}
        width={width || "auto"}
        height={height || "auto"}
        maxWidth={maxWidth || null}
        maxHeight={maxHeight || null}
        position="center"
        showCloseButton={showCloseButton || true}
        // fullScreen={true}
      >
        {this.props.children}
      </DXPopup>
    );
  }
}

export default Popup;
