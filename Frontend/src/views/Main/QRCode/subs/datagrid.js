import React, { PureComponent } from "react";
import { isTablet } from "../../../../utils";
import DataGrid from "../../../../components/DataGrid";
import { Column, Editing } from "devextreme-react/ui/data-grid";
import { confirm } from "devextreme/ui/dialog";
import { displayPreload } from "../../../../components/Framework/Preload";
import styles from "../styles.module.scss";
import { deleteQRCode, updateQRCodeName } from "../../../../services/qrcodes";
import ViewQr from "./viewQr";
import Detail from "./details";

class QrCodeGrid extends PureComponent {
  constructor(props) {
    super(props);

    this.refGrid = React.createRef();

    this.state = {
      qrcode: false,
      qrDataSouce: [],
      selectedRow: {},
      viewDetail: false,
    };
  }

  onClickViewQrCode = (e) => {
    this.setState({ selectedRow: e.row.data, qrcode: true });
  };

  onClickUpdateGridQRDetails = (e) => {
    let qrDetailsProps = {
      qrId: e.row.data.QrId,
      qrName: e.row.data.QrName,
      qrDesc: e.row.data.QrDesc || "",
    };
    let grid = this.refGrid.current?.instance;
    let { handlerData } = this.props;
    displayPreload(true);
    updateQRCodeName(qrDetailsProps).then(() => {
      handlerData();
      grid.refresh();
      displayPreload(false);
    });
  };

  onClickDelete = (e) => {
    const { t } = this.props;

    let { QrId, QrName } = e.row.data;
    let grid = this.refGrid.current?.instance;
    let { handlerData } = this.props;

    let dialog = confirm(
      `<span>You are about to delete the QR Code: ${QrName}. Are you sure?</span>`,
      t("Delete")
    );
    dialog.then((dialogResult) => {
      if (dialogResult) {
        displayPreload(true);

        deleteQRCode(QrId).then(() => {
          handlerData();
          grid.refresh();
          this.props.reloadRoutesAffterDeleteQr(e.row.data);
          setTimeout(() => {
            displayPreload(false);
          }, 500);
        });
      }
    });
  };

  onEditingStart = (e) => {
    setTimeout(() => {
      let GREY_COLOR = "#EAEAEA";
      let elem = document
        .getElementsByClassName("dx-edit-row")[0]
        .getElementsByTagName("td");
      elem[2].style.background = GREY_COLOR;
      elem[3].style.background = GREY_COLOR;
      elem[4].style.background = GREY_COLOR;
    }, 100);
  };

  onClickCloseQrcodeView = () => {
    this.setState({ qrcode: false });
  };

  onClickViewDetails = (e) => {
    let selectedRow = e.row.data;
    this.setState({ viewDetail: true, selectedRow });
  };

  onClickCloseDetail = () => {
    this.setState({ viewDetail: false });
  };

  onEditorPreparing = (e) => {
    if (e.parentType === "dataRow" && e.dataField === "QrName") {
      e.editorOptions.maxLength = 50;
    } else if (e.parentType === "dataRow" && e.dataField === "QrDesc") {
      e.editorOptions.maxLength = 255;
    }
  };

  render() {
    const { t, qrDataSource, by = "routes" } = this.props;
    const { qrcode, selectedRow, viewDetail } = this.state;
    return (
      <React.Fragment>
        <div className={styles.container}>
          <DataGrid
            keyExpr="QrId"
            identity="grdQRCode"
            // ref={this.refGrid}
            reference={this.refGrid}
            height={by === "tasks" ? "calc(100% - 35px)" : "450px"}
            dataSource={qrDataSource}
            showBorders={false}
            onEditingStart={this.onEditingStart}
            scrollingMode={isTablet() ? "virtual" : "standard"}
            filterRow={true}
            onEditorPreparing={this.onEditorPreparing}
          >
            <Editing
              mode="row"
              useIcons={true}
              allowAdding={false}
              allowDeleting={true}
              allowUpdating={true}
            />
            <Column
              key="QrName"
              dataField="QrName"
              caption={t("QR Code Name")}
              allowSearch={false}
              allowEditing={true}
            />
            <Column
              key="QrDesc"
              dataField="QrDesc"
              caption={t("QR Description")}
              allowSearch={false}
              allowEditing={true}
            />
            {["routes", "tour-stop"].includes(by) && (
              <Column
                key="RouteDesc"
                dataField="RouteDesc"
                caption={t("Route Desccription")}
                allowSearch={false}
                allowEditing={false}
                disable={true}
              />
            )}
            {by.includes("tour-stop") && (
              <Column
                key="TourDesc"
                dataField="TourDesc"
                caption={t("Tour Stop")}
                allowSearch={false}
                allowEditing={false}
                disable={true}
              />
            )}
            <Column
              key="QrDate"
              dataField="QrDate"
              caption={t("Date")}
              allowSearch={false}
              allowEditing={false}
              disable={true}
              sortOrder="desc"
            />
            <Column
              type="buttons"
              buttons={[
                {
                  hint: t("View"),
                  icon: "print",
                  onClick: this.onClickViewQrCode,
                },
                by === "tasks" && {
                  name: "detail",
                  icon: "info",
                  hint: t("Detail"),
                  onClick: this.onClickViewDetails,
                },
                {
                  name: "edit",
                  hint: t("Edit"),
                },
                {
                  name: "save",
                  hint: t("Save"),
                  onClick: this.onClickUpdateGridQRDetails,
                },
                {
                  name: "cancel",
                  hint: t("Cancel"),
                },
                {
                  name: "delete",
                  hint: t("Delete"),
                  onClick: this.onClickDelete,
                },
              ]}
            />
          </DataGrid>

          {qrcode && (
            <ViewQr
              t={t}
              by={by}
              selected={selectedRow}
              showHide={qrcode}
              onClickCloseQrcodeView={this.onClickCloseQrcodeView}
              tourStopData={selectedRow}
            />
          )}

          {viewDetail && (
            <Detail
              t={t}
              showHide={viewDetail}
              selected={selectedRow}
              onClickDetailEdit={(e) => {
                this.props.onClickDetailEdit(e);
                this.onClickCloseDetail();
              }}
              onClickCloseDetail={this.onClickCloseDetail}
            />
          )}
        </div>
      </React.Fragment>
    );
  }
}

export default QrCodeGrid;
