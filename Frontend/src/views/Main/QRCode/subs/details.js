import React, { createRef, PureComponent } from "react";
import Popup from "../../../../components/Popup";
import Button from "../../../../components/Button";
import DataGrid from "devextreme-react/ui/data-grid";
import { isTablet } from "../../../../utils";
import { getInfoForQRId } from "../../../../services/qrcodes";
import { displayPreload } from "../../../../components/Framework/Preload";
import { Paging } from "devextreme-react/tree-list";

class Detail extends PureComponent {
  constructor(props) {
    super(props);

    this.refGrid = createRef();

    this.state = {
      data: [],
      selectionDs: [],
      varDs: [],
      showHide: false,
      columns: [],
    };
  }

  componentDidMount = () => {
    this.buildView();
  };

  buildView = () => {
    let { t, selected, showHide } = this.props;
    let columns = [];

    if (selected.Line) columns = this.byLineColumns(columns, t);
    else if (selected.RouteIdstr) columns = this.byRoutesColumns(columns, t);

    let IsRouteId = Boolean(selected.RouteIdstr !== null);

    displayPreload(true);
    getInfoForQRId(selected.QrId, IsRouteId).then((response) => {
      let Unit = response?.map((item) => item.Unit);
      selected.Unit = [...new Set(Unit)] || [];
      selected.Unit = selected.Unit.join(",");
      let Workcell = response?.map((item) => item.Workcell);
      selected.Workcell = [...new Set(Workcell)] || [];
      selected.Workcell = selected.Workcell.join(",");
      this.setState(
        {
          data: [selected],
          selectionDs: response,
          columns,
          showHide,
        },
        () => displayPreload(false)
      );
    });
  };

  byLineColumns = (cols, t) => {
    cols.push(
      {
        dataField: "LineDesc",
        caption: t("Line"),
      },
      {
        dataField: "UnitIdDesc",
        caption: t("Primary Unit"),
      },
      {
        dataField: "WorkcellDesc",
        caption: t("Module"),
      },
      {
        dataField: "VarDesc",
        caption: t("Task Description"),
      }
    );
    return cols;
  };

  byRoutesColumns = (cols, t) => {
    cols.push(
      {
        dataField: "RouteDesc",
        caption: t("Route Description"),
      },
      {
        dataField: "VarDesc",
        caption: t("Task Description"),
      }
    );
    return cols;
  };

  printQr = (by) => {
    let qrImg, tempWindow;
    qrImg = document.getElementById("qrCodeId");
    tempWindow = window.open("", "image");
    tempWindow.document.write(
      "<center><h2>QR Code</h2><hr/><br/>" + qrImg.outerHTML + "</center>"
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

  onClickDetailEdit = () => {
    this.setState(
      {
        showHide: false,
      },
      () => {
        this.props.onClickDetailEdit(this.state.data[0]);
      }
    );
  };

  render() {
    const { t } = this.props;
    const { data, selectionDs, showHide, columns } = this.state;

    return (
      <React.Fragment>
        <Popup
          id="popDetails"
          visible={showHide}
          onHiding={this.props.onClickCloseDetail}
          dragEnabled={false}
          closeOnOutsideClick={true}
          showTitle={true}
          title={t("Details")}
          showCloseButton={false}
          width="80%"
          maxHeight="80%"
        >
          <DataGrid
            identity="grdQrDetails"
            style={{ margin: "15px" }}
            reference={this.refGrid}
            dataSource={data}
            columns={[
              {
                dataField: "QrName",
                caption: t("QR Code Name"),
              },
              {
                dataField: "QrDesc",
                caption: t("QR Description"),
              },
            ]}
            showBorders={true}
            scrollingMode={isTablet() ? "virtual" : "standard"}
          ></DataGrid>

          <h4 style={{ marginLeft: "15px" }}>{t("Associated variables")}</h4>
          <DataGrid
            identity="grdQrVarsDetails"
            style={{ margin: "15px" }}
            reference={this.refGrid}
            dataSource={selectionDs}
            columns={columns}
            showBorders={true}
            scrollingMode={isTablet() ? "virtual" : "standard"}
          >
            <Paging enabled={true} pageSize={10} />
          </DataGrid>
          <div style={{ textAlign: "center" }}>
            <Button
              id="btnQrCodeDetailEdit"
              icon="edit"
              text={t("Edit")}
              primary
              onClick={this.onClickDetailEdit}
            />
          </div>
        </Popup>
      </React.Fragment>
    );
  }
}

export default Detail;
