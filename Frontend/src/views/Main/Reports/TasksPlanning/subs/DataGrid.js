import React, { PureComponent } from "react";
import {
  FilterRow,
  Pager,
  Paging,
  Export,
  Grouping,
  GroupPanel,
  SearchPanel,
  ColumnChooser,
  FilterPanel,
  Column,
  StateStoring,
  Scrolling,
} from "devextreme-react/ui/data-grid";
import { custom } from "devextreme/ui/dialog";
import { renderToString } from "react-dom/server";
import {
  generateExportDocument,
  setIdsByClassName,
} from "../../../../../utils/index";
import { warning } from "../../../../../services/notification";
import { getTasksPlanningDetail } from "../../../../../services/reports";
import {
  gridTasksPlanningToolbarPreparing,
  gridTasksPlanningColumns,
} from "../options";
import Button from "../../../../../components/Button";
import DataGrid from "../../../../../components/DataGrid";
import Popup from "../../../../../components/Popup";
import { CustomViewDialog } from "../../../../../components/CustomView";
import { getDefaultViews } from "../../../../../components/CustomView/Dialog/index";
import dayjs from "dayjs";
import icons from "../../../../../resources/icons";
import DataSource from "devextreme/data/data_source";
import { isTablet } from "../../../../../utils";

class Grid extends PureComponent {
  constructor(props) {
    super(props);
    this.refGrid = React.createRef();
    this.refGridInfoDetail = React.createRef();
    this.state = {
      loadStateStoring: false,
      showCustomViewDialog: false,
      taskInfoDS: [],
    };
  }

  // shouldComponentUpdate = (nextProps, nextState) => {
  //   if (
  //     nextProps.runTime !== this.props.runTime ||
  //     nextState.showCustomViewDialog !== this.state.showCustomViewDialog
  //   )
  //     return true;
  //   else return false;
  // };

  componentDidUpdate = () => {
    setIdsByClassName([
      "btnCustomizeGridTasksPlanning",
      {
        idContainer: "grdTasksPlanning",
        class: "dx-datagrid-column-chooser-button",
        ids: ["btnColumnChooserTasksPlanning"],
      },
      "btnExcelExportTasksPlanning",
      "btnPdfExportTasksPlanning",
    ]);
  };

  setIdsGridComponents = () => {
    setIdsByClassName([
      {
        idContainer: "grdTasksPlanning",
        class: "dx-texteditor-input",
        ids: ["txtColumnSearchGrdTasksPlanning"],
        same: true,
      },
      {
        class: "btnColumnInfoTasksPlanningGrid",
        ids: ["btnColumnInfoTasksPlanningGrid"],
        same: true,
      },
      {
        class: "btnDocumentTasksPlanningGrid",
        ids: ["btnDocumentTasksPlanningGrid"],
        same: true,
      },
    ]);
  };

  onClickCustomize = () => {
    this.setState({ showCustomViewDialog: true });
  };

  onHidingToolbar = (toolbar) => {
    this.setState({ [toolbar]: false });
  };

  onClickExportCellInfo = () => {
    let ref = this.refGridInfoDetail.current.instance;
    ref.exportToExcel(false);
  };

  onClickCellInfo = (data) => {
    const { t, refFilters } = this.props;
    let info = [];

    var filters = refFilters;
    const { plantModel } = filters;

    let granularity,
      topLevelId,
      startTime,
      endTime,
      routesIds,
      teamsIds,
      teamsDetails;

    //granularity
    granularity = filters.rdgGranularity;

    //topLevelId
    topLevelId = 0;
    if (granularity === 4) {
      topLevelId = plantModel.departments.join();
    }

    if (granularity === 5) {
      topLevelId = plantModel.lines.join();
    }

    if (granularity === 6) {
      topLevelId = plantModel.units.join();
    }

    //routesIds
    routesIds =
      filters.rdgEntryType === "My Routes"
        ? plantModel.myroutes.join(",")
        : plantModel.routes.join(",");

    //teamsIds
    teamsIds =
      filters.rdgEntryType === "My Teams"
        ? plantModel.myteams.join(",")
        : plantModel.teams.join(",");

    //start and endtime
    startTime = dayjs(filters.dtStartTime).format("YYYY-MM-DD HH:mm:ss");
    endTime = dayjs(filters.dtEndTime).format("YYYY-MM-DD HH:mm:ss");

    //teamsDetails
    teamsDetails = filters.rdgTeamsDetails;

    getTasksPlanningDetail(
      data.VarId,
      granularity,
      topLevelId,
      startTime,
      endTime,
      routesIds,
      teamsIds,
      teamsDetails
    ).then((response) => {
      let resp = response.length > 0 ? response.pop() : {};

      let fields = [
        "VarId",
        "Task",
        "LongTaskName",
        "TaskAction",
        "TaskId",
        "FL1",
        "FL2",
        "FL3",
        "FL4",
        "TaskFrequency",
        "TaskType",
        "EntryOn",
        "Criteria",
        "Hazards",
        "Method",
        "PPE",
        "Tools",
        "Lubricant",
      ];
      if (resp.EntryOn !== "" && resp.EntryOn !== null)
        resp["EntryOn"] = dayjs(resp.EntryOn).format("MM-DD-YYYY HH:mm:ss");

      Object.keys(resp).forEach((key) => {
        if (fields.includes(key)) {
          let column = gridTasksPlanningColumns()
            .filter((column) => column.caption)
            .find((col) => col.dataField === key);
          if (column !== undefined) {
            info.push({
              order: fields.indexOf(key),
              field: column.caption,
              value: resp[key],
            });
          }
        }
      });

      info = info.sort((a, b) => a.order - b.order);

      this.setState({ taskInfoDS: info });

      let dialog = custom({
        title: t("Task Information"),
        messageHtml: renderToString(
          <>
            <table id="informationTable" className="informationTable">
              <tr>
                <th>{t("Item")}</th>
                <th>{t("Description")}</th>
              </tr>
              {info.map((row) => (
                <tr key={row.field}>
                  <td>{row.field}</td>
                  <td>{row.value}</td>
                </tr>
              ))}
            </table>
            <Button
              id="btnTaskInformationExport"
              text="Export to Excel"
              imgsrc={icons.excel}
            />
          </>
        ),
        dragEnabled: false,
      });
      dialog.show();

      setTimeout(() => {
        document
          .getElementById("btnTaskInformationExport")
          .addEventListener("click", this.onClickExportCellInfo);
        setIdsByClassName([
          {
            class:
              "dx-overlay-content dx-popup-normal dx-resizable dx-popup-inherit-height",
            ids: ["popTaskInformationTasksPlanning"],
          },
          {
            idContainer: "popTaskInformationTasksPlanning",
            class: "dx-button dx-button-normal dx-dialog-button",
            ids: ["btnOkTaskInformationTasksPlanning"],
          },
        ]);
      }, 500);
    });
  };

  async generateExportData() {
    let refGrid = this.refGrid.current.instance;

    let columns = Array(
      refGrid.getVisibleColumns().reduce(
        (obj, item) => (
          // eslint-disable-next-line no-sequences
          (obj[item.dataField] = this.props.t(item.caption)), obj
        ),
        {}
      )
    );

    let data = await new DataSource({
      store: [...refGrid.getDataSource().store()._array],
      filter: refGrid.getCombinedFilter(),
      sort: refGrid.getDataSource().sort(),
      paginate: false,
    }).load();

    return { columns, data };
  }

  onClickExportToPDF = async () => {
    var fontReady = document
      .getElementById("root")
      .getAttribute("data-pdf-font-ready");

    if (fontReady === "false" && localStorage.i18nextLng === "zh") {
      warning(
        "The font to export to pdf is not already loaded, please wait a seconds and try again"
      );
    } else {
      const { columns, data } = await this.generateExportData();
      var pdfdoc = generateExportDocument(columns, data);
      pdfdoc.save("gvTasks.pdf");
    }
  };

  onClickExportToExcel = () => {
    let grid = this.refGrid.current.instance;
    grid.exportToExcel(false);
  };

  render() {
    const { t, runTime, data } = this.props;

    return (
      <React.Fragment>
        {runTime !== null && (
          <>
            <DataGrid
              identity="grdTasksPlanning"
              reference={this.refGrid}
              dataSource={{
                store: data,
                // filter: filterGrid(this.props.refFilters),
                // key: "VarId",
                reshapeOnPush: false,
              }}
              scrollingMode="standard"
              columnAutoWidth={true}
              height="calc(100% - 35px)"
              columns={gridTasksPlanningColumns(this.onClickCellInfo)}
              onContentReady={this.setIdsGridComponents}
              onToolbarPreparing={(e) =>
                gridTasksPlanningToolbarPreparing(
                  e,
                  t,
                  this.onClickCustomize,
                  this.onClickExportToExcel,
                  this.onClickExportToPDF
                )
              }
            >
              <SearchPanel visible={false} />
              <ColumnChooser enabled={true} />
              <Export enabled={false} fileName="gvTasks" />
              <GroupPanel visible={true} />
              <Grouping autoExpandAll={true} contextMenuEnabled={false} />
              <FilterRow visible={true} applyFilter="auto" />
              <FilterPanel filterEnabled={true} />
              <Paging enabled={true} pageSize={50} />
              <Pager
                showPageSizeSelector={false}
                showNavigationButtons={false}
                showInfo={true}
                visible={isTablet() ? false : true}
              />
              <StateStoring
                enabled={true}
                type="custom"
                customLoad={() => {
                  if (!this.state.loadStateStoring) {
                    let defaultView = getDefaultViews();
                    if (defaultView !== null) {
                      this.setState({ loadStateStoring: true });
                      return JSON.parse(defaultView.Data);
                    }
                  }
                }}
              />
              <Scrolling mode={isTablet() ? "virtual" : "standard"} />
            </DataGrid>

            {/* Information Detail Grid */}
            <div className={this.props.hideInfoDetail}>
              <DataGrid
                identity="grdTasksPlanningInfoDetail"
                reference={this.refGridInfoDetail}
                dataSource={{
                  store: { type: "array", data: this.state.taskInfoDS },
                }}
                columnAutoWidth={true}
              >
                <Export fileName="gvDetails" />
                <Column caption={t("Item")} dataField="field" />
                <Column caption={t("Description")} dataField="value" />
              </DataGrid>
            </div>
          </>
        )}

        <Popup
          id="showCustomViewDialog"
          visible={this.state.showCustomViewDialog}
          onHiding={this.onHidingToolbar}
          width="750px"
        >
          <CustomViewDialog
            t={t}
            viewName="TasksPlanningReport"
            refGrid={this.refGrid}
            opened={this.state.showCustomViewDialog}
          />
        </Popup>
      </React.Fragment>
    );
  }
}

export default Grid;
