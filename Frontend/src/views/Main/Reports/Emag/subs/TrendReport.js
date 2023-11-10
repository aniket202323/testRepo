import React, { Component } from "react";
import DataGrid from "../../../../../components/DataGrid";
import ColorCoding from "../../../../../components/ColorCoding";
import dayjs from "dayjs";
import {
  FilterRow,
  FilterPanel,
  Scrolling,
} from "devextreme-react/ui/data-grid";
import { EMAG_COLOR } from "../../../../../utils/constants";
import styles from "../styles.module.scss";

export default class TrendReport extends Component {
  constructor(props) {
    super(props);
    this.refGrid = React.createRef();
  }

  shouldComponentUpdate = (nextProps, nextState) => {
    return nextProps.visible !== this.props.visible;
  };

  render() {
    var { t, data } = this.props;
    data = data ?? [];

    return (
      <React.Fragment>
        <div className={styles.trendReportContainer}>
          {data.length !== 0 ? (
            <React.Fragment>
              <div className={styles.trendBoxInformation}>
                <p>
                  <b>{t("Task Description")}:</b>
                  {this.props.taskDescription}
                </p>
                <p>
                  <b>{t("Ending Date")}:</b>
                  {this.props.endDate}
                </p>
              </div>

              <DataGrid
                identity="grdEmagTrendReport"
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
                columnResizingMode={"nextColumn"}
                height="120px"
                onCellPrepared={(e) => {
                  if (e.rowType === "data" && e.rowIndex % 2 === 1) {
                    if (e.columnIndex === 0) e.cellElement.colSpan = 4;
                    if (
                      e.columnIndex === 1 ||
                      e.columnIndex === 2 ||
                      e.columnIndex === 3
                    ) {
                      e.cellElement.style.display = "none";
                    }
                  }
                }}
                customizeColumns={(columns) => {
                  columns.forEach((column) => {
                    column.allowFiltering = false;
                    column.allowSearch = false;

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
                      column.minWidth = "200px";
                    }

                    if (
                      column.dataField === "Dates" ||
                      column.dataField === "VarId"
                    ) {
                      column.visible = false;
                    }

                    if (
                      column.dataField !== "TaskId" &&
                      column.dataField !== "Fl4" &&
                      column.dataField !== "Task" &&
                      column.dataField !== "Frequency" &&
                      column.dataField !== "Dates" &&
                      column.dataField !== "VarId"
                    ) {
                      // column.caption = dayjs(column.dataField).format("MM DD");
                      // let date = Date(column.dataField);

                      let date;

                      if (
                        column.dataField !== null &&
                        column.dataField !== undefined
                      ) {
                        let [month, day] = column.dataField.split("-");
                        date = dayjs()
                          .year(dayjs().year())
                          .month(month - 1)
                          .date(day);
                      }

                      column.caption = dayjs(date).format("MM DD");
                      column.alignment = "center";
                      column.width = "32px";
                      column.cellTemplate = (container, data) => {
                        if (data.value !== null && data.value !== "") {
                          data.value = data.value ?? "";
                          var value = data.value.match(".*[a-z].*")
                            ? data.value
                            : "";

                          let j = document.createElement("span");
                          j.appendChild(document.createTextNode(value));
                          j.setAttribute(
                            "style",
                            `background-color: ${EMAG_COLOR[data.value]};`
                          );
                          if (!data.value.match(".*[a-z].*"))
                            j.classList.add(styles.eMagCellTemplate);

                          container.appendChild(j);
                        }
                      };
                    }
                  });
                }}
              >
                <FilterPanel filterEnabled={false} />
                <FilterRow visible={false} />
                <Scrolling showScrollbar="always" />
              </DataGrid>

              <ColorCoding
                t={t}
                report="eMag"
                visible={this.props.visible}
                classes={styles.colorCoding}
              />
            </React.Fragment>
          ) : (
            <div>No data</div>
          )}
        </div>
      </React.Fragment>
    );
  }
}
