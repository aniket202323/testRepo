import React, { PureComponent } from "react";
import Card from "../../../components/Card";
import Button from "../../../components/Button";
import SelectBox from "../../../components/SelectBox";
import { setBreadcrumbEvents } from "../../../components/Framework/Breadcrumb/events";
import { getAllRoutes, IsIntegratedRoute } from "../../../services/routes"; // getAllRoutes
import { filterGrid } from "../TasksSelection/options";
import QrCodeGrid from "./subs/datagrid";
import {
  getAllQRForRoute,
  getAllQRCodeInfoForTourStop,
  getQRCodeForTourStop,
} from "../../../services/qrcodes";
import { getOpsHubServer, getTourStop } from "../../../services/tourStops";
import ViewQr from "./subs/viewQr";
import SaveQr from "./subs/saveQr";
import SaveMultipleQr from "./subs/saveMultipleQr";
import dayjs from "dayjs";
import { Accordion, Item } from "devextreme-react/ui/accordion";
import RadioGroup from "../../../components/RadioGroup";
import icons from "../../../resources/icons";
import { displayPreload } from "../../../components/Framework/Preload";
import styles from "./styles.module.scss";

class ByRoute extends PureComponent {
  constructor(props) {
    super(props);

    this.refGrid = React.createRef();
    this.refAccordion = React.createRef();

    this.state = {
      routes: [],
      selected: {
        myroutes: [],
        tourStopSelected: [],
      },
      qrDataSourceByRoute: [],
      qrDataSourceByTourStop: [],
      showsaveQr: false,
      showsaveMultipleQr: false,
      viewQr: false,
      group: "by-route",
      tourStops: [],
      tourStopSelectedForView: {},
      QRPaths: [],
      originalRoutes: [],
    };
  }

  componentDidMount = () => {
    displayPreload(true);
    this.getAllRoutes();
    getAllQRCodeInfoForTourStop().then((response) => {
      response.forEach(
        (x) =>
          (x.QrDate = x.QrDate.replace("T", " ").slice(0, x.QrDate.length - 4))
      );
      this.setState(
        {
          qrDataSourceByTourStop: response,
        },
        () => displayPreload(false)
      );
    });
    this.setBreadcrumb();
  };

  getAllRoutes = () => {
    getAllRoutes().then((response) => {
      this.setState(
        {
          originalRoutes: [...response],
        },
        () => {
          this.handlerData(response);
          this.refAccordion.current.instance.expandItem(0);
        }
      );
    });
  };

  reloadRoutesAffterDeleteQr = (newRoute) => {
    let routes = [...this.state.routes];
    routes.unshift(newRoute);
    this.handlerData(routes);
  };

  setBreadcrumb = () => {
    setBreadcrumbEvents(
      <nav>
        <Button
          id="btnQrCode"
          icon="qrcode"
          hint="QR Code"
          primary
          disabled={false}
          classes={styles.breadcrumbButton}
          onClick={this.onClickGenerateQR}
        />
      </nav>
    );
    this.enableQRButton(false);
  };

  handlerData = (routes = [], showQrView = false) => {
    let group = this.state.group;
    if (group === "by-route") {
      let newRoutes = routes.length ? routes : [...this.state.routes];
      getAllQRForRoute().then((response) => {
        // If a RouteID is already stored in the DB, do not show it in DropDown
        response?.forEach((route) => {
          route.QrDate = dayjs(route.QrDate).format("YYYY-MM-DD HH:mm");
          let temp = newRoutes.find((x) => x.RouteId === route.RouteId);
          if (temp) {
            let index = newRoutes.indexOf(temp);
            newRoutes.splice(index, 1);
          }
        });
        this.setState(
          {
            qrDataSourceByRoute: response,
            routes: newRoutes,
            viewQr: showQrView,
          },
          () => {
            this.enableQRButton(false);
            showQrView && this.refAccordion.current.instance.expandItem(1);
            displayPreload(false);
          }
        );
      });
    } else if (group === "by-tour-stop") {
      getAllQRCodeInfoForTourStop().then((response) => {
        response?.forEach((ts) => {
          ts.QrDate = dayjs(ts.QrDate).format("YYYY-MM-DD HH:mm");
        });
        this.setState(
          {
            qrDataSourceByTourStop: response,
            viewQr: showQrView,
            tourStopSelectedForView: routes,
          },
          () => {
            this.handleChange({ value: this.state.group });
            this.setState({
              selected: {
                ...this.state.selected,
                tourStopSelected: [],
              },
            });
            this.refAccordion.current.instance.expandItem(1);
            this.refAccordion.current.instance._refresh();
            displayPreload(false);
          }
        );
      });
    }
  };

  getQRCodeImages = async (qrCodeProps) => {
    let QRPaths = [];
    let url = "";
    let selectedRoute = this.state.selected.myroutes[0];

    let TourStopIds = qrCodeProps?.TourStopId.split(",");
    displayPreload(true);
    let _IsIntegratedRoute = await IsIntegratedRoute(selectedRoute);
    if (_IsIntegratedRoute) {
      const opshubServer = await getOpsHubServer();
      url = opshubServer + "&";
    } else {
      url = window.location.href.toString().toLowerCase() + "?";
      url = url.replace("/#", "").replace("#/", "");
    }

    let _qrCodeProps = {
      RouteId: selectedRoute,
      TourStopIds,
      Url: url,
    };

    getQRCodeForTourStop(_qrCodeProps).then((images) => {
      images.forEach((img, index) => {
        let QrName = qrCodeProps.QRName.split(",")[index];
        let QrDesc = qrCodeProps.QRDesc.split(",")[index];
        QRPaths.push({ QrName, QrDesc, img });
      });
      setTimeout(() => {
        this.setState(
          {
            QRPaths,
          },
          () => {
            setTimeout(() => {
              this.handlerData({}, false);
              displayPreload(false);
              this.printQrByTourStop(QRPaths);
            }, qrCodeProps.TourStopId.split(",").length * 1000);
          }
        );
      }, 250);
    });
  };

  printQrByTourStop = (QRPaths) => {
    let qrImg, tempWindow;
    QRPaths.forEach((QR, index) => {
      setTimeout(() => {
        qrImg = document.getElementById("qrCodeId" + index);
        tempWindow = window.open("", "image");
        tempWindow.document.write(
          "<div " +
            "id=" +
            index +
            "' style='page-break-after:always;'><center><h1>" +
            QR.QrName +
            "</h1><h4>" +
            QR.QrDesc +
            "</h4><hr/><br/>" +
            qrImg?.outerHTML +
            "</center></div>"
        );
      }, index * 100);
      if (index === QRPaths.length - 1) {
        setTimeout(() => {
          tempWindow.document.close();
          tempWindow.focus();
          tempWindow.onLoad = tempWindow.print();
          tempWindow.onafterprint = function () {
            tempWindow.close();
          };
        }, index * 250);
      }
    });
  };

  handleSelectRoute = (myroutes) => {
    this.setState(
      {
        selected: { ...this.state.selected, myroutes, tourStopSelected: [] },
      },
      () => {
        if (this.state.group === "by-tour-stop") {
          displayPreload(true);
          let newTourStops = [...this.state.qrDataSourceByTourStop];
          getTourStop(myroutes).then((response) => {
            response.forEach((x) => {
              let temp = newTourStops.find(
                (y) => parseInt(y.TourStopId) === x.TourId
              );
              if (temp) x.IsAdded = true;
            });

            this.setState(
              {
                tourStops: response,
              },
              () => {
                this.enableQRButton(false);
                displayPreload(false);
              }
            );
          });
        } else {
          this.enableQRButton(true);
        }
      }
    );
  };

  enableQRButton = (val) => {
    setTimeout(() => {
      let btnQrCode = document.getElementById("btnQrCode");
      if (btnQrCode) {
        btnQrCode.disabled = !val;
      }
    }, 100);
  };

  setFiltersGrid = () => {
    this.handlerFilterGrid(filterGrid(this.state));
  };

  handlerFilterGrid = (filters) => {
    if (this.refGrid.current !== null)
      this.refGrid.current.instance.filter(filters);
  };

  onClickGenerateQR = (e) => {
    let group = this.state.group;
    if (group.includes("route")) this.setState({ showsaveQr: true });
    else {
      this.setState({ showsaveMultipleQr: true });
    }
  };

  onClickCloseSaveQrcode = () => {
    this.setState({
      showsaveQr: false,
    });
  };

  handleChange = (e) => {
    this.setState(
      {
        group: e.value,
        selected: {
          myroutes: [],
          tourStopSelected: [],
        },
        tasks: [],
        tourStops: [],
      },
      () => {
        this.enableQRButton(false);
      }
    );
  };

  onClickCloseQrcodeView = () => {
    this.setState({ viewQr: false });
  };

  handleSelectTourStop = (values) => {
    let tourStops = this.state.tourStops;
    let currentVal = values[values.length - 1];
    let IsAdded =
      tourStops.find((y) => y.TourId === currentVal)?.IsAdded || false;
    if (IsAdded) return;
    this.setState(
      { selected: { ...this.state.selected, tourStopSelected: values } },
      () => this.enableQRButton(values.length > 0)
    );
  };

  render() {
    const { t } = this.props;
    const {
      selected,
      routes,
      qrDataSourceByRoute,
      qrDataSourceByTourStop,
      showsaveQr,
      showsaveMultipleQr,
      viewQr,
      group,
      tourStops,
      tourStopSelectedForView,
      QRPaths,
      originalRoutes,
    } = this.state;

    return (
      <React.Fragment>
        <div className={styles.container}>
          <Card autoHeight id="crdQrCode">
            <div className={styles.byRouteConteiner}>
              <Accordion
                id="acdQrByTask"
                ref={this.refAccordion}
                collapsible={true}
                multiple={false}
                animationDuration={300}
              >
                <Item title={t("Generate QR Code")}>
                  <div className={styles.rboQrCode}>
                    <div className={styles.headerLeft}>
                      <RadioGroup
                        items={[
                          { text: t("By Route"), value: "by-route" },
                          { text: t("By Tour Stops"), value: "by-tour-stop" },
                        ]}
                        valueExpr="value"
                        displayExpr="text"
                        value={group}
                        onValueChanged={this.handleChange}
                      />
                    </div>
                  </div>
                  <div style={{ display: "flex" }}>
                    <SelectBox
                      text={t("Routes")}
                      enableSelectAll={false}
                      enableClear={false}
                      store={group === "by-route" ? routes : originalRoutes}
                      isMultiple={false}
                      className={styles.selectBox}
                      value={selected.myroutes}
                      onChange={this.handleSelectRoute}
                      labelKey="RouteDesc"
                      valueKey="RouteId"
                    />
                    {group.includes("tour") && (
                      <>
                        <SelectBox
                          text={t("Tour Stops")}
                          enableSelectAll={false}
                          enableClear={false}
                          store={tourStops}
                          isMultiple={true}
                          className={styles.selectBox}
                          value={selected.tourStopSelected}
                          onChange={this.handleSelectTourStop}
                          labelKey="TourDesc"
                          valueKey="TourId"
                          disabledMessage="QR Code already generated"
                          disableItems={tourStops.map((x) => {
                            if (x.IsAdded) return x.TourId;
                            else return -1;
                          })}
                        />
                      </>
                    )}
                  </div>
                  {group.includes("tour") &&
                    tourStops.length === 0 &&
                    selected.myroutes?.length !== 0 && (
                      <div>
                        <div className={styles.noTaskMessage}>
                          <img alt="" src={icons.info} />
                          <label>
                            {t(
                              "The current route does not contain any assigned tour stop."
                            )}
                          </label>
                        </div>
                      </div>
                    )}
                  <br />
                  <br />
                </Item>
                {group.includes("route") && (
                  <Item title={t("QR Code Report")}>
                    <QrCodeGrid
                      t={t}
                      by="routes"
                      qrDataSource={qrDataSourceByRoute}
                      handlerData={this.handlerData}
                      reloadRoutesAffterDeleteQr={
                        this.reloadRoutesAffterDeleteQr
                      }
                      printQr={this.props.printQr}
                      selected={selected.myroutes}
                    />
                  </Item>
                )}
                {group.includes("tour") && (
                  <Item title={t("QR Code Report by Tour Stop")}>
                    <QrCodeGrid
                      t={t}
                      by="tour-stop"
                      qrDataSource={qrDataSourceByTourStop}
                      handlerData={this.handlerData}
                      reloadRoutesAffterDeleteQr={
                        this.reloadRoutesAffterDeleteQr
                      }
                      printQr={this.props.printQr}
                      selected={selected.myroutes}
                    />
                  </Item>
                )}
              </Accordion>
            </div>

            {showsaveQr && (
              <SaveQr
                t={t}
                by={group} //"routes"
                handlerData={this.handlerData}
                selected={selected.myroutes[0]}
                tourStopData={selected?.tourStopSelected}
                tourStops={tourStops}
                onClickCloseSaveQrcode={this.onClickCloseSaveQrcode}
                qrDataSource={
                  group === "by-route"
                    ? qrDataSourceByRoute
                    : qrDataSourceByTourStop
                }
              />
            )}

            {showsaveMultipleQr && (
              <SaveMultipleQr
                t={t}
                by={group} //"routes"
                handlerData={this.handlerData}
                selected={selected.myroutes[0]}
                tourStopData={selected?.tourStopSelected.map((x) =>
                  tourStops.find((y) => y.TourId === x)
                )}
                tourStops={tourStops}
                onClickCloseSaveQrcode={() => {
                  this.setState({ showsaveMultipleQr: false });
                }}
                getQRCodeImages={this.getQRCodeImages}
                qrDataSource={
                  group === "by-route"
                    ? qrDataSourceByRoute
                    : qrDataSourceByTourStop
                }
              />
            )}

            {viewQr && (
              <ViewQr
                t={t}
                by={group}
                selected={selected.myroutes[0]}
                showHide={viewQr}
                tourStopData={tourStopSelectedForView}
                onClickCloseQrcodeView={this.onClickCloseQrcodeView}
              />
            )}
            {QRPaths.map((QRPath, index) => {
              return (
                <div
                  id={"qrCode" + index}
                  key={"qrCode" + index}
                  style={{
                    textAlign: "center",
                    margin: "25px",
                    display: "none",
                    pageBreakAfter: "always",
                  }}
                >
                  <img
                    id={"qrCodeId" + index}
                    key={"qrCodeId" + index}
                    src={`data:image/jpeg;base64,${QRPath.img}`}
                    alt={""}
                    width={256}
                  />
                </div>
              );
            })}
          </Card>
        </div>
      </React.Fragment>
    );
  }
}

export default ByRoute;
