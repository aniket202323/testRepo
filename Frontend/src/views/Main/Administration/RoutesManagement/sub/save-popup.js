import React, { PureComponent } from "react";
import Popup from "../../../../../components/Popup";
import Button from "../../../../../components/Button";
import SelectBox from "../../../../../components/SelectBox";
import Form, { SimpleItem } from "devextreme-react/ui/form";
import { FileUploader } from "devextreme-react/ui/file-uploader";
import {
  uploadTourMap,
  updateTourMapLink,
  unlinkTourStopMapImage,
  deleteTourStopMapImage,
} from "../../../../../services/tourStops";
import { displayPreload } from "../../../../../components/Framework/Preload";
import { confirm } from "devextreme/ui/dialog";
import icons from "../../../../../resources/icons";
import { getAllRoutes } from "../../../../../services/routes";
import {
  getTourStop,
  getTourMapImage,
  getTourMapImageCount,
} from "../../../../../services/tourStops";
import { TransformWrapper, TransformComponent } from "react-zoom-pan-pinch";
import styles from "../styles.module.scss";

class Save extends PureComponent {
  constructor(props) {
    super(props);

    this.refForm = React.createRef();
    this.refFileUploader = React.createRef();

    this.state = {
      showHide: false,
      showHideCopyFromOther: false,
      fileSelected: "",
      routes: [],
      tourStops: [],
      selected: {
        myroutes: [],
        tourStopSelected: [],
      },
      showImage: false,
      tourMapLink: "",
    };
  }

  componentDidMount = () => {
    this.viewSaveCode();
  };

  viewSaveCode = () => {
    this.setState({
      showHide: true,
    });
  };

  getAllRoutes = () => {
    displayPreload(true);
    getAllRoutes().then((response) => {
      this.setState(
        {
          routes: response,
        },
        () => {
          displayPreload(false);
        }
      );
    });
  };

  onSelectedFilesChanged = (e) => {
    const { t } = this.props;
    let refFileUploader = this.refFileUploader?.current.instance;
    let existingTourMap = document.getElementById("tourMap")?.value;
    if (!e.value.length || !refFileUploader._files[0]?.isValid()) return;

    if (existingTourMap) {
      let dialog = confirm(
        `<span>` +
          t(
            "This Tour Stop is already linked to a tour stop map. Uploading this new image will remove and replace the existing image. Are you sure you want to continue?"
          ) +
          `</span>`,
        t("Replace Tour Stop Map")
      );
      dialog.then((dialogResult) => {
        if (dialogResult) {
          this.setState({
            fileSelected: e.value[0],
          });
          return;
        } else {
          this.setState({
            fileSelected: "",
          });
          return;
        }
      });
    } else {
      this.setState({
        fileSelected: e.value[0],
      });
    }
  };

  _uploadTourMap = () => {
    displayPreload(true);
    let file = this.state.fileSelected;
    const TourStop = {
      tourDesc: this.props.tourStopSelected,
      tourId: this.props.tourStopSelected.TourId,
      routeId: this.props.routeIdSelected,
    };
    const formData = new FormData();
    formData.append("file", file);

    formData.append("tourId", TourStop.tourId);
    formData.append("routeId", TourStop.routeId);
    const config = {
      headers: {
        "content-type": "multipart/form-data",
      },
    };
    return uploadTourMap(formData, config).then(() => {
      setTimeout(() => {
        this.props.onClose();
        this.props.handleStep3();
        displayPreload(false);
      }, 500);
    });
  };

  copyFromOtherFunction = () => {
    let tourStop = {};
    let temp = {};

    temp = this.state.tourStops.find(
      (x) => x.TourId === this.state.selected.tourStopSelected[0]
    );

    tourStop.TourId = this.props.tourStopSelected.TourId;
    tourStop.TourMap = temp.TourMap;

    displayPreload(true);
    updateTourMapLink(tourStop).then(() => {
      setTimeout(() => {
        this.props.onClose();
        this.props.handleStep3();
        displayPreload(false);
      }, 500);
    });
  };

  unlink = () => {
    let temp = this.props.tourStopSelected;
    let tourStop = {};
    const { t } = this.props;

    tourStop.TourId = this.props.tourStopSelected.TourId;
    tourStop.TourMap = temp.TourMap;

    // getTourMapImageCount
    displayPreload(true);
    getTourMapImageCount(temp.TourMap).then((response) => {
      let message = "";
      if (response !== 1) {
        message =
          "This action will unlink the tour stop map image. Are you sure you want to continue?";
      } else {
        message =
          "This action will unlink and delete the tour stop map image permanently. Are you sure you want to continue?";
      }

      let dialog = confirm(
        `<span>` + t(message) + `</span>`,
        t("Unlink Tour Stop Map Image")
      );
      dialog.then((dialogResult) => {
        if (dialogResult) {
          displayPreload(true);
          unlinkTourStopMapImage(tourStop).then(() => {
            setTimeout(() => {
              this.props.onClose();
              this.props.handleStep3();
              displayPreload(false);
            }, 500);
          });
        } else {
          return;
        }
      });
      displayPreload(false);
    });
  };

  copyFromOtheTStop = () => {
    !this.state.routes.length && this.getAllRoutes();
    this.setState({
      showHideCopyFromOther: true,
      tourStops: [],
      selected: {
        myroutes: [],
        tourStopSelected: [],
      },
    });
  };

  deleteTourMap = () => {
    const { t } = this.props;
    let filename = document.getElementById("tourMap")?.value;

    let dialog = confirm(
      "<span>" +
        t(
          "Are you sure you want to continue? This action will delete the tour stop map image and cannot be undone."
        ) +
        "</span>",
      t("Remove Tour Stop Map Image")
    );
    dialog.then((dialogResult) => {
      if (dialogResult) {
        displayPreload(true);
        deleteTourStopMapImage(filename).then(() => {
          this.setState(
            {
              showHide: false,
            },
            () => {
              this.props.onClose();
              this.props.handleStep3();
              document.getElementById("tourMap").value = "";
              setTimeout(() => {
                displayPreload(false);
              }, 500);
            }
          );
        });
      } else {
        return;
      }
    });
  };

  handleSelectRoute = (myroutes) => {
    this.setState(
      {
        selected: { ...this.state.selected, myroutes, tourStopSelected: [] },
      },
      () => {
        displayPreload(true);
        getTourStop(myroutes).then((response) => {
          response.forEach((x) => {
            x.IsAdded = x.TourMap !== null;
          });

          this.setState(
            {
              tourStops: response,
            },
            () => {
              displayPreload(false);
            }
          );
        });
      }
    );
  };

  enableAssignButton = (val) => {
    setTimeout(() => {
      let btnQrCode = document.getElementById("btnCopyFromOther");
      if (btnQrCode) {
        btnQrCode.disabled = !val;
      }
    }, 100);
  };

  handleSelectTourStop = (values) => {
    let tourStops = this.state.tourStops;
    let currentVal = values[values.length - 1];
    let IsAdded =
      tourStops.find((y) => y.TourId === currentVal)?.IsAdded || false;
    if (!IsAdded) return;
    this.setState(
      { selected: { ...this.state.selected, tourStopSelected: values } },
      () => this.enableAssignButton(values.length > 0)
    );
  };

  selectTourMap = () => {
    this.setState({
      showHideCopyFromOther: false,
    });
  };

  closing = () => {
    this.setState({
      showHideCopyFromOther: false,
    });
  };

  viewImage = () => {
    let { tourStopSelected } = this.props;
    displayPreload(true);
    getTourMapImage(tourStopSelected.TourId).then((tourMapLink) => {
      if (!tourMapLink) return;
      this.setState(
        {
          showImage: true,
          tourMapLink,
        },
        () => displayPreload(false)
      );
    });
  };

  closeImagePopup = () => {
    this.setState({ showImage: false, tourMapLink: "" });
  };

  render() {
    const { t, tourStopSelected } = this.props;
    const {
      showHide,
      showHideCopyFromOther,
      routes,
      tourStops,
      selected,
      showImage,
      tourMapLink,
    } = this.state;
    let existingTourMapValue = document.getElementById("tourMap")?.value;
    let tMap = selected?.tourStopSelected.length
      ? tourStops.find((t) => t.TourId === selected?.tourStopSelected[0])
          .TourMap
      : "";

    return (
      <React.Fragment>
        <Popup
          id="popGeneratecode"
          visible={showHide}
          onHiding={this.props.onClose}
          dragEnabled={true}
          closeOnOutsideClick={false}
          showTitle={true}
          title={tourStopSelected.TourDesc}
          showCloseButton={false}
          width="450px"
        >
          {existingTourMapValue !== "" && (
            <div style={{ margin: "25px" }}>
              <span style={{ fontWeight: "bold" }}>
                {t("File uploaded") + ":"}
              </span>
              {existingTourMapValue}
              {existingTourMapValue !== "" && (
                <>
                  <Button
                    hint={t("Remove")}
                    icon={icons.remove}
                    onClick={this.deleteTourMap}
                    style={{ marginLeft: "15px" }}
                    classes={styles.btnImg}
                  />
                  <Button
                    hint={t("Unlink")}
                    icon={icons.unlink}
                    onClick={this.unlink}
                    classes={styles.btnImg}
                  />
                  <Button
                    hint={t("View image")}
                    icon={icons.viewImage}
                    onClick={this.viewImage}
                    classes={styles.btnImg}
                  />
                </>
              )}
            </div>
          )}

          <h4 style={{ margin: "10px 20px" }}>
            {tMap !== "" ? t("Tour Map Selected") + ": " + tMap : ""}
          </h4>
          <div id="Code" style={{ display: "flex", margin: "15px" }}>
            <FileUploader
              name="file"
              ref={this.refFileUploader}
              multiple={false}
              uploadMode="useForm"
              accept=".JPG,.JPEG,.PNG"
              allowedFileExtensions={[".JPG", ".JPEG", ".PNG"]}
              invalidFileExtensionMessage={t(
                "Sorry, we cannot upload the file you've selected as it is not a supported image file type. Please select an image file with one of the following formats: JPEG, JPG, and PNG"
              )}
              invalidMaxFileSizeMessage={t(
                "Sorry, we cannot upload the file you've selected as it exceeds the size limit. Please upload an image that is smaller than 5MB."
              )}
              className="flpFileUpload"
              maxFileSize={5000000}
              onValueChanged={this.onSelectedFilesChanged}
              style={{ width: "50%" }}
            />
            <Button
              text={t("Copy from other tour stop")}
              onClick={this.copyFromOtheTStop}
              style={{ height: "30px", fontSize: "11px", whiteSpace: "nowrap" }}
            />
          </div>

          <br />
          <div style={{ textAlign: "center" }}>
            <span className="note">
              {t("Allowed file extensions") + ": "}
              <span style={{ fontWeight: "bold" }}>.JPG, .JPEG, .PNG</span>
            </span>
            <br />
            <span className="note">
              {t("Maximum file size") + ": "}
              <span style={{ fontWeight: "bold" }}>5 MB</span>
            </span>
            <br />
            <br />

            <form>
              <Form
                ref={this.refForm}
                formData={{
                  TourMap: existingTourMapValue,
                }}
                labelLocation="left"
                showColonAfterLabel={true}
                colCount={1}
              >
                <SimpleItem>
                  <Button
                    text={tMap !== "" ? t("Update") : t("Upload")}
                    primary
                    onClick={() =>
                      tMap === ""
                        ? this._uploadTourMap()
                        : this.copyFromOtherFunction()
                    }
                    disabled={this.state.fileSelected === "" && tMap === ""}
                  />
                  <Button
                    text={t("Cancel")}
                    onClick={() => {
                      existingTourMapValue = "";
                      this.props.onClose();
                    }}
                  />
                </SimpleItem>
              </Form>
            </form>
          </div>
        </Popup>

        <Popup
          id="popCopyFromOtherTS"
          visible={showHideCopyFromOther}
          onHiding={this.closing}
          dragEnabled={true}
          closeOnOutsideClick={false}
          showTitle={true}
          title={t("Select Tour Stop")}
          showCloseButton={false}
          maxWidth="600px"
        >
          <>
            <div style={{ display: "flex" }}>
              <SelectBox
                text={t("Routes")}
                enableSelectAll={false}
                enableClear={false}
                store={routes}
                isMultiple={false}
                className={styles.selectBox}
                value={selected.myroutes}
                onChange={this.handleSelectRoute}
                labelKey="RouteDesc"
                valueKey="RouteId"
              />

              <SelectBox
                text={t("Tour Stops")}
                enableSelectAll={false}
                enableClear={false}
                store={tourStops}
                isMultiple={false}
                className={styles.selectBox}
                value={selected.tourStopSelected}
                onChange={this.handleSelectTourStop}
                labelKey="TourDesc"
                valueKey="TourId"
                disabledMessage="Tour Map not assigned"
                disableItems={tourStops.map((x) => {
                  if (!x.IsAdded) return x.TourId;
                  else return -1;
                })}
              />
            </div>
            <br />
            <h4>Tour Map Selected: </h4>
            {tMap !== "" ? tMap : ""}
            <br />
            <br />

            <Button
              id="btnCopyFromOther"
              text={t("Select")}
              primary
              onClick={this.selectTourMap}
              disabled={tMap === ""}
            />
            <Button
              id="btnCancelTM"
              text={t("Cancel")}
              onClick={this.closing}
            />
          </>
        </Popup>

        <Popup
          id="popViewImage"
          visible={showImage}
          onHiding={this.closeImagePopup}
          dragEnabled={false}
          closeOnOutsideClick={true}
          showTitle={true}
          title={t("Tour Stop Image")}
          showCloseButton={true}
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
                      height={
                        document.getElementById("crdTasksSelectionGrid")
                          ?.offsetHeight -
                        100 +
                        "px"
                      }
                      style={{
                        minWidth: "100% !important",
                        padding: "20px",
                      }}
                    />
                  </TransformComponent>
                </React.Fragment>
              )}
            </TransformWrapper>
          </>
        </Popup>
      </React.Fragment>
    );
  }
}

export default Save;
