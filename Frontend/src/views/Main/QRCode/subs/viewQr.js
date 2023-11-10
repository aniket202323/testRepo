import React, { PureComponent } from "react";
import Popup from "../../../../components/Popup";
import Button from "../../../../components/Button";
import {
  getQRCodeForTaskById,
  getQRPathForAssignByRoute,
  getQRCodeForTourStop,
  getInfoForQRId,
} from "../../../../services/qrcodes";
import { displayPreload } from "../../../../components/Framework/Preload";
import { getOpsHubServer } from "../../../../services/tourStops";
import { IsIntegratedRoute } from "../../../../services/routes";

class ViewQr extends PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      QRPath: "",
      showHide: false,
    };
  }

  componentDidMount = () => {
    this.viewQrCode();
  };

  viewQrCode = async () => {
    let { by, selected, showHide, tourStopData } = this.props;
    let url = "";
    let IsByLine = selected?.RouteIdstr === null || selected?.RouteIdstr === "";
    let _IsIntegratedRoute = false;

    displayPreload(true);

    if (!IsByLine) {
      if (by === "tasks") {
        let response = await getInfoForQRId(selected.QrId, !IsByLine);
        _IsIntegratedRoute = this.hasCLTasks(response);
      } else if (["byRoute", "routes", "tour-stop"].includes(by)) {
        _IsIntegratedRoute = await IsIntegratedRoute(
          selected.RouteId || selected?.RouteIdstr
        );
      }
    }

    if (_IsIntegratedRoute) {
      const opshubServer = await getOpsHubServer();
      url = opshubServer + "&";
    } else {
      url = window.location.href.toString().toLowerCase() + "?";
      url = url.replace("/#", "").replace("#/", "");
    }

    if (by.includes("route")) {
      // Menu By Routes
      getQRPathForAssignByRoute(selected.RouteId || selected, url).then(
        (response) => {
          this.setState(
            {
              showHide,
              QRPath: response,
            },
            () => {
              setTimeout(() => {
                displayPreload(false);
              }, 250);
            }
          );
        }
      );
    } else if (by.includes("tour-stop")) {
      let qrCodeProps = {
        RouteId: tourStopData?.RouteId,
        TourStopIds: [tourStopData?.TourStopId],
        Url: url,
      };
      displayPreload(true);
      getQRCodeForTourStop(qrCodeProps).then((response) => {
        this.setState(
          {
            showHide,
            QRPath: response,
          },
          () => {
            setTimeout(() => {
              displayPreload(false);
            }, 250);
          }
        );
        displayPreload(false);
      });
    } else {
      // Menu By Task
      let qrCodeProps = {
        QrId: selected.QrId,
        Url: url,
        isRoute: !IsByLine,
      };
      displayPreload(true);
      getQRCodeForTaskById(qrCodeProps).then((response) => {
        this.setState(
          {
            showHide,
            QRPath: response,
          },
          () => {
            setTimeout(() => {
              displayPreload(false);
            }, 250);
          }
        );
      });
    }
  };

  hasCLTasks = (tasks) => {
    if (!tasks) return;
    return tasks.some((x) => x?.EventSubtypeDesc !== "eCIL");
  };

  printQr = () => {
    let qrImg, tempWindow;
    let qrName = this.props.selected?.QrName || "QR Code";
    qrImg = document.getElementById("qrCodeId");
    tempWindow = window.open("", "image");
    tempWindow.document.write(
      "<center><h2>" +
        qrName +
        "</h2><hr/><br/>" +
        qrImg.outerHTML +
        "</center>"
    );

    setTimeout(() => {
      tempWindow.document.close();
      tempWindow.focus();
      tempWindow.onLoad = tempWindow.print();
    }, 500);
    tempWindow.onafterprint = function () {
      tempWindow.close();
    };
  };

  render() {
    const { t, selected } = this.props;
    const { QRPath, showHide } = this.state;

    return (
      <React.Fragment>
        <Popup
          id="popViewQRCode"
          visible={showHide}
          onHiding={this.props.onClickCloseQrcodeView}
          dragEnabled={false}
          closeOnOutsideClick={true}
          showTitle={true}
          title={selected?.QrName || "QR Code"}
          showCloseButton={false}
          onClick={this.viewQrCode}
          width="450px"
        >
          <div id="qrCode" style={{ textAlign: "center", margin: "25px" }}>
            <img
              id="qrCodeId"
              src={`data:image/jpeg;base64,${QRPath}`}
              alt={""}
              width={256}
            />
          </div>
          <div style={{ textAlign: "center" }}>
            <Button text={t("Print")} onClick={this.printQr} />
          </div>
        </Popup>
      </React.Fragment>
    );
  }
}

export default ViewQr;
