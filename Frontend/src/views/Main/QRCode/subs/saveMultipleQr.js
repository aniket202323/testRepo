import React, { PureComponent } from "react";
import Popup from "../../../../components/Popup";
import Button from "../../../../components/Button";
import { saveQRCodeInfo } from "../../../../services/qrcodes";
import Form, { SimpleItem } from "devextreme-react/ui/form";
import TabPanel, { Item } from "devextreme-react/tab-panel";
import { displayPreload } from "../../../../components/Framework/Preload";
import { warning } from "../../../../services/notification";

class SaveMultipleQr extends PureComponent {
  constructor(props) {
    super(props);
    this.refFormNewQr = React.createRef();

    this.state = {
      QRPath: "",
      showHide: false,
      tourStopsSelected: [],
      selectedIndex: 0,
      data: [],
      enableGenerateButton: false,
    };
  }

  componentDidMount = () => {
    this.viewSaveQrCode();
  };

  viewSaveQrCode = () => {
    this.setState({
      showHide: true,
    });
  };

  saveQRTourStop = (data) => {
    let tourStopData = this.props.tourStopData;
    let selected = this.props.selected;
    let qrCodeProps = {
      RouteIdstr: selected,
      TourStopId: tourStopData.map((x) => x.TourId).join(),
      QRName: data.map((y) => y.qrName).join(),
      QRDesc: data.map((y) => y.qrDesc).join(),
    };

    let hasEmptyField = false;
    data.forEach((x) => {
      if (x.qrName === "") hasEmptyField = true;
    });

    if (hasEmptyField) {
      warning("It is necessary to complete all the required fields.");
      return;
    } else {
      displayPreload(true);
      saveQRCodeInfo(qrCodeProps).then((response) => {
        if (response) {
          warning(response);
          displayPreload(false);
          return;
        }
        this.props.getQRCodeImages(qrCodeProps);
        this.props.onClickCloseSaveQrcode();
      });
    }
  };

  onItemClick = (e, isSaving = false) => {
    let data = this.state.data;
    let index = isSaving ? e : e - 1;
    let name = document.getElementById("qrName" + index)?.value.slice();
    let desc = document.getElementById("qrDesc" + index)?.value.slice();

    data[index] = {
      qrName: name,
      qrDesc: desc,
    };
    this.setState(
      {
        selectedIndex: e?.addedItems ? index : index + 1,
        data,
      },
      () => {
        isSaving && this.saveQRTourStop(data);
      }
    );
  };

  back = (index) => {
    this.setState({
      selectedIndex: index,
    });
  };

  enableGenerateButton = () => {
    let hasEmptyField = this.hasEmptyFields();
    this.setState({
      enableGenerateButton: !hasEmptyField,
    });
  };

  hasEmptyFields = () => {
    let hasEmptyField = false;
    this.props.tourStopData.forEach((ts, index) => {
      let name = document.getElementById("qrName" + index)?.value.slice();
      if (name === "" || name === undefined) hasEmptyField = true;
    });

    return hasEmptyField;
  };

  render() {
    const { t, tourStopData } = this.props;
    const { showHide, selectedIndex, data, enableGenerateButton } = this.state;

    return (
      <React.Fragment>
        <Popup
          id="popGenerateQrcode"
          visible={showHide}
          onHiding={this.props.onClickCloseSaveQrcode}
          dragEnabled={false}
          closeOnOutsideClick={false}
          showTitle={true}
          title={t("QR Code")}
          showCloseButton={false}
          maxWidth="900px"
        >
          <TabPanel
            selectedIndex={selectedIndex}
            swipeEnabled={true}
            onSelectionChanged={(e) => {
              let ts_names = tourStopData.map((x) => x.TourDesc);
              let index = ts_names.indexOf(e?.addedItems[0]?.title);
              this.onItemClick(index);
            }}
          >
            {tourStopData.map((ts, index) => {
              return (
                <Item title={ts.TourDesc}>
                  <div
                    id="qrCode"
                    style={{ textAlign: "center", margin: "25px" }}
                  >
                    <form>
                      <br />
                      <br />
                      <span style={{ marginRight: "25px" }}>
                        {t("QR Code Name")}
                      </span>
                      <span style={{ color: "red", paddingRight: "12px" }}>
                        {"*"}
                      </span>
                      <input
                        type="text"
                        id={"qrName" + index}
                        defaultValue={data[index]?.qrName || ""}
                        maxlength="50"
                        style={{ width: "350px", height: "30px" }}
                        required
                        onChange={() => this.enableGenerateButton(index)}
                      />
                      <br />
                      <br />

                      <span>{t("QR Code Description")}</span>
                      <input
                        type="text"
                        id={"qrDesc" + index}
                        defaultValue={data[index]?.qrDesc || ""}
                        maxlength="255"
                        style={{
                          width: "350px",
                          height: "30px",
                          marginLeft: "15px",
                        }}
                        onChange={(e) => this.enableGenerateButton(e, index)}
                      />

                      <br />
                      <br />
                      <br />
                    </form>
                    <Form
                      id={"FormData-" + index}
                      ref={this.refFormNewQr}
                      formData={
                        data[index] ? data[index] : { qrName: "", qrDesc: "" }
                      }
                      labelLocation="left"
                      showColonAfterLabel={true}
                      colCount={1}
                    >
                      <SimpleItem>
                        {index === tourStopData.length - 1 ? (
                          <>
                            <Button
                              primary
                              text={t("< Back")}
                              onClick={() => this.back(index - 1)}
                              style={{
                                display:
                                  tourStopData.length === 1 ? "none" : "inline",
                              }}
                            />
                            <Button
                              text={t("Cancel")}
                              onClick={this.props.onClickCloseSaveQrcode}
                            />
                          </>
                        ) : index !== 0 ? (
                          <>
                            <Button
                              primary
                              text={t("< Back")}
                              onClick={() => this.back(index - 1)}
                            />
                            <Button
                              primary
                              text={t("Next >")}
                              onClick={() => this.onItemClick(index + 1)}
                            />
                          </>
                        ) : (
                          <>
                            <Button
                              primary
                              text={t("Next >")}
                              onClick={() => this.onItemClick(index + 1)}
                            />
                          </>
                        )}
                        <>
                          <Button
                            primary
                            text={t("Generate")}
                            onClick={() => this.onItemClick(index, true)}
                            disabled={!enableGenerateButton}
                          />
                        </>
                      </SimpleItem>
                    </Form>
                  </div>
                </Item>
              );
            })}
          </TabPanel>
        </Popup>
      </React.Fragment>
    );
  }
}

export default SaveMultipleQr;
