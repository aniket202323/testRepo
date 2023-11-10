import React, { PureComponent } from "react";
import Popup from "../../../../components/Popup";
import Button from "../../../../components/Button";
import {
  saveQRCodeInfo,
  updateQRDetailsForTask,
} from "../../../../services/qrcodes";
import Form, {
  SimpleItem,
  Label,
  RequiredRule,
} from "devextreme-react/ui/form";
import { displayPreload } from "../../../../components/Framework/Preload";
import { error } from "../../../../services/notification";

class SaveQr extends PureComponent {
  constructor(props) {
    super(props);

    this.refFormNewQr = React.createRef();

    this.state = {
      QRPath: "",
      showHide: false,
    };
  }

  componentDidMount = () => {
    this.viewSaveQrCode();
    let { dataEdit } = this.props;
    if (dataEdit) {
      let refFormNewQr = this.refFormNewQr.current?.instance;
      setTimeout(() => {
        refFormNewQr.getEditor("qrName")?.option("value", dataEdit.QrName);
        refFormNewQr.getEditor("qrDesc")?.option("value", dataEdit.QrDesc);
      }, 250);
    }
  };

  viewSaveQrCode = () => {
    this.setState({
      showHide: true,
    });
  };

  saveQrDetails = () => {
    let { t, dataEdit } = this.props;
    let isEditing = Object.keys(dataEdit || {}).length > 1;
    let selected = this.props.selected;
    let refFormNewQr = this.refFormNewQr.current?.instance;
    let data = refFormNewQr.option("formData");
    refFormNewQr.validate();
    if (!refFormNewQr.validate().isValid) return;
    let qrDetailsProps = {
      QrId: dataEdit?.QrId,
      QrName: data.qrName,
      VarId: selected?.VarIds?.join(","),
    };

    qrDetailsProps.QrDesc = data.qrDesc ? data.qrDesc : "";

    if (selected?.lines?.length) {
      qrDetailsProps.Lines = selected.lines?.join(",");
      qrDetailsProps.RouteIdstr = "";
    } else if (selected?.myroutes?.length) {
      qrDetailsProps.RouteIdstr = selected.myroutes?.join(",");
      qrDetailsProps.Lines = "";
    } else {
      qrDetailsProps.RouteIdstr = selected.toString();
      qrDetailsProps.Lines = "";
    }

    displayPreload(true);
    if (!isEditing)
      saveQRCodeInfo(qrDetailsProps).then((response) => {
        if (response) {
          error(t("The QR Code name already exists"));
          displayPreload(false);
          return;
        } else {
          this.props.onClickCloseSaveQrcode();
          this.props.handlerData([], true, qrDetailsProps);
          displayPreload(false);
        }
      });
    else
      updateQRDetailsForTask(qrDetailsProps).then(() => {
        this.props.onClickCloseSaveQrcode();
        this.props.handlerData([], true, qrDetailsProps);
        displayPreload(false);
      });
  };

  render() {
    const { t, dataEdit = {} } = this.props;
    const { showHide } = this.state;
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
          width="450px"
        >
          <div id="qrCode" style={{ textAlign: "center", margin: "25px" }}>
            <form>
              <Form
                ref={this.refFormNewQr}
                formData={{ qrName: "", qrDesc: "" }}
                labelLocation="left"
                showColonAfterLabel={true}
                colCount={1}
              >
                <SimpleItem
                  dataField="qrName"
                  editorType="dxTextBox"
                  editorOptions={{ tabIndex: 1, maxLength: 50 }}
                >
                  <Label text={t("QR Code Name")} />
                  <RequiredRule message="QR Code Name is required" />
                </SimpleItem>
                <SimpleItem
                  dataField="qrDesc"
                  editorType="dxTextBox"
                  editorOptions={{ tabIndex: 2, maxLength: 255 }}
                >
                  <Label text={t("QR Code Description")} />
                  {/* <RequiredRule message="QR Code Description is required" /> */}
                </SimpleItem>
                <SimpleItem>
                  <Button
                    text={
                      Object.keys(dataEdit).length !== 0
                        ? t("Update")
                        : t("Generate")
                    }
                    onClick={this.saveQrDetails}
                  />
                  {Object.keys(dataEdit).length !== 0 && (
                    <Button
                      text={t("Cancel")}
                      onClick={this.props.onClickCloseSaveQrcode}
                    />
                  )}
                </SimpleItem>
              </Form>
            </form>
          </div>
          <div></div>
        </Popup>
      </React.Fragment>
    );
  }
}

export default SaveQr;
