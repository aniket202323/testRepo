import React, { Component } from "react";
import DataGrid from "../../../../../components/DataGrid";
import {
  FilterRow,
  FilterPanel,
  Selection,
  Paging,
} from "devextreme-react/ui/data-grid";
import dayjs from "dayjs";
import { isTablet } from "../../../../../utils";
import styles from "../styles.module.scss";

export default class DataGridEmag extends Component {
  constructor(props) {
    super(props);
    this.refGrid = React.createRef();
  }

  shouldComponentUpdate = (nextProps, nextState) => {
    return nextProps.runTime !== this.props.runTime;
  };

  handleOptionChange = (e) => {
    if (isTablet()) {
      let grid = this.refGrid.current?.instance;
      let selectedId = grid.getSelectedRowKeys()[0]?.VarId;
      let currentId = e.data.VarId;
      setTimeout(() => {
        if (selectedId && selectedId === currentId) grid.clearSelection();
      }, 100);
    }
  };

  calculateGridHeight = () => {
    if (isTablet()) {
      return styles.h50;
    } else {
      const { view, emagDataLength } = this.props;
      let cardHeight = document.querySelector("#crdEmag") ? document.querySelector("#crdEmag").offsetHeight - 35 - 50 : 0; // color + report period

      let cellHeight = 35;
      let gridHeader = 45;
      let gridPaging = emagDataLength > 15 ? 40 : 0;
      let h = {
        grd30p: Math.round(cardHeight * 0.3 - 20),
        grd50p: Math.round(cardHeight * 0.5 - 20),
      };
      let gridContent = cellHeight * emagDataLength + gridHeader + gridPaging;
      if (view === "eMag") {
        if (gridContent < h.grd30p) return styles.h30;
        if (gridContent < h.grd50p) return styles.h50;
        else return styles.h70;
      }
      if (view === "downtime") {
        if (gridContent < h.grd30p) return styles.h70;
        if (gridContent < h.grd50p) return styles.h50;
        else return styles.h30;
      }
    }
  };

  render() {
    const {
      t,
      runTime,
      data,
      handlerDowntimeDetails,
      handlerDefectDetails,
      handlerTrendReportPopup,
      view,
    } = this.props;

    if (runTime === null) return null;
    return (
      <React.Fragment>
        <div className={this.calculateGridHeight()}>
          <DataGrid
            identity={"grd" + view}
            key="DataGridEmag"
            reference={this.refGrid}
            dataSource={{
              store: data,
            }}
            allowColumnReordering={false}
            allowColumnResizing={false}
            columnAutoWidth={true}
            searchPanelVisible={false}
            wordWrapEnabled={true}
            scrollingMode="standard"
            columnResizingMode={"nextColumn"}
            height="auto"
            onCellClick={this.handleOptionChange}
            customizeColumns={(columns) => {
              columns.forEach((column) => {
                column.allowFiltering = false;
                column.allowSearch = false;
                column.allowResizing = false;
                if (
                  column.dataField === "TaskId" ||
                  column.dataField === "Fl4" ||
                  column.dataField === "Frequency"
                ) {
                  column.alignment = "center";
                  column.caption =
                    column.dataField === "Fl4"
                      ? t("FL4")
                      : column.dataField === "Frequency"
                        ? t("Freq")
                        : column.dataField;
                }

                if (column.dataField === "Task") {
                  column.caption = t("Task Description");
                  column.cellTemplate = (container, data) => {
                    if (data.value !== null) {
                      let j = document.createElement("span");
                      j.classList.add(styles.dtDetailLink);
                      j.appendChild(document.createTextNode(data.value));
                      j.setAttribute(
                        "id",
                        "btnEmagShowTrendReport-" + data.rowIndex
                      );
                      j.onclick = (e) => handlerTrendReportPopup(data);
                      container.appendChild(j);
                    } else {
                      let j = document.createElement("span");
                      j.appendChild(document.createTextNode(data.value ?? ""));
                      container.appendChild(j);
                    }
                  };
                }

                if (
                  column.dataField === "Dates" ||
                  column.dataField === "VarId" ||
                  column.dataField === "Reason"
                ) {
                  column.visible = false;
                }

                if (column.dataField === "Component") {
                  column.caption = t("Downtime Type");
                  column.minWidth = "300px";
                  if (isTablet()) {
                    var columnWidth = 0;
                    var emagColumns = document.querySelectorAll(
                      "#grdeMag .dx-datagrid-headers table tbody tr td"
                    );
                    emagColumns.forEach((elem, index) => {
                      if (index < 4) {
                        columnWidth += elem.offsetWidth;
                      }
                    });
                    column.width = columnWidth;
                  }
                }

                if (
                  column.dataField !== "TaskId" &&
                  column.dataField !== "Fl4" &&
                  column.dataField !== "Task" &&
                  column.dataField !== "Frequency" &&
                  column.dataField !== "Component" &&
                  column.dataField !== "Reason"
                ) {
                  column.caption = dayjs(column.dataField).format("MM DD");
                  column.alignment = "center";
                  column.allowSorting = false;
                  column.width = "32px";
                  column.cellTemplate = (container, data) => {
                    if (data.value !== "0" && data.value !== null) {
                      if (data.value.toString().includes("-")) {
                        const [cellColor, cellValue] = data.value.split("-");

                        let j = document.createElement("span");
                        j.classList.add(styles[`eMagBg-${cellColor}`]);
                        j.classList.add(styles.eMagCellTemplate);

                        if (view === "eMag") {
                          if (cellValue !== "1")
                            j.appendChild(document.createTextNode(cellValue));
                        } else
                          j.appendChild(document.createTextNode(cellValue));

                        if (view === "eMag")
                          if (cellColor === "6") {
                            j.setAttribute(
                              "id",
                              "btnShowDefectDetail-" + data.rowIndex
                            );
                            j.onclick = (e) => {
                              handlerDefectDetails(data, cellValue);
                            };
                          }

                        if (view === "downtime") {
                          j.setAttribute(
                            "id",
                            "btnShowDowntimeDetails-" + data.rowIndex
                          );
                          j.onclick = (e) => {
                            handlerDowntimeDetails(data, cellValue);
                          };
                        }

                        container.appendChild(j);
                      }
                    }
                  };
                }
              });
            }}
          >
            <Selection
              mode={isTablet() ? "single" : "none"}
              showCheckBoxesMode="none"
            />

            <FilterPanel filterEnabled={false} />
            <FilterRow visible={false} />
            <Paging enabled={true} pageSize={view === "eMag" ? 15 : 10} />
          </DataGrid>
        </div>
      </React.Fragment>
    );
  }
}
