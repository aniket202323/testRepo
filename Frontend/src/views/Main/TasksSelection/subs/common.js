import React, { PureComponent } from "react";
import Popup from "../../../../components/Popup";
import { TransformComponent, TransformWrapper } from "react-zoom-pan-pinch";

export class ViewImagePopup extends PureComponent {
  render() {
    const { showImage, tourMapLink, TourDesc, closeImagePopup } = this.props;

    return (
      <Popup
        id="popViewImage"
        visible={showImage}
        onHiding={closeImagePopup}
        dragEnabled={false}
        closeOnOutsideClick={true}
        showTitle={true}
        title={TourDesc}
        showCloseButton={true}
        maxWidth="90%"
        maxHeight="90%"
      >
        <>
          <TransformWrapper initialScale={1}>
            {({ zoomIn, zoomOut, resetTransform, ...rest }) => (
              <React.Fragment>
                <TransformComponent>
                  <img
                    id="tourMapImage"
                    src={`data:image/jpeg;base64,${tourMapLink}`}
                    alt=""
                  />
                </TransformComponent>
              </React.Fragment>
            )}
          </TransformWrapper>
        </>
      </Popup>
    );
  }
}
