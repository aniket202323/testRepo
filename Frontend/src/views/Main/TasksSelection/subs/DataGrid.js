import React, { PureComponent } from "react";
import DataGrid from "../../../../components/DataGrid";
import Button from "../../../../components/Button";
import Popup from "../../../../components/Popup";
import Input from "../../../../components/Input";
import { CustomViewDialog } from "../../../../components/CustomView";
import { displayPreload } from "../../../../components/Framework/Preload";
import {
  Column,
  Pager,
  Paging,
  Export,
  Editing,
  Selection,
  GroupPanel,
  Grouping,
  Sorting,
} from "devextreme-react/ui/data-grid";
import DateBox from "devextreme-react/ui/date-box";
import { custom } from "devextreme/ui/dialog";
import { renderToString } from "react-dom/server";
import { warning } from "../../../../services/notification";
import { gridToolbarPreparing, gridColumns, filterGrid } from "../options";
import {
  generateExportDocument,
  generateQuickPrint,
  setIdsByClassName,
  sortBy,
} from "../../../../utils";
import {
  getPrompts,
  saveTasksSelection,
  getTaskInfo,
  setTasksValues,
  addComments,
  updateComments,
} from "../../../../services/tasks";
import { getProfile } from "../../../../services/auth";
import DataSource from "devextreme/data/data_source";
import dayjs from "dayjs";
import nav from "../tabs.scss";
import styles from "../styles.module.scss";
import { getTourMapImage } from "../../../../services/tourStops";
import Icon from "../../../../components/Icon";
import icons from "../../../../resources/icons";
import { TransformWrapper, TransformComponent } from "react-zoom-pan-pinch";

class Grid extends PureComponent {
  constructor(props) {
    super(props);

    this.refGrid = React.createRef();
    this.refDtpPostponedTask = React.createRef();
    this.refGridInfoDetail = React.createRef();
    this.refGridTourMaps = React.createRef();

    this.state = {
      dataFiltered: this.props.data,
      originalData: [],
      showCustomViewDialog: false,
      showPostponeTaskDialog: false,
      promps: [],
      taskInfoDS: [],
      tourMapLink: "",
      dynamicColumns: [],
      showTourMapLinks: false,
      selectedTourId: {},
      TourDesc: "",
      noTourStopTasksMessage: "",
      isExpanded: false,
      isCompletedAll: false,
      commentWasUpdated: false,
    };
  }

  componentDidMount = () => {
    getPrompts().then((response) => {
      this.setState({
        promps: response,
      });
    });
  };

  componentDidUpdate = (prevProps, prevState) => {
    if (prevProps.data.length !== this.props.data.length)
      this.accordionHandler("", true);

    setIdsByClassName([
      "btnSaveSelectedTasksSelection",
      "btnCompleteAllTasksSelection",
      "btnCustomizeGridTasksSelection",
      "btnRefreshGridTasksSelection",
      {
        idContainer: "grdTasksSelection",
        class: "dx-datagrid-column-chooser-button",
        ids: ["btnColumnChooserTasksSelection"],
      },
      "btnQuickPrintTasksSelection",
      "btnExcelExportTasksSelection",
      "btnPdfExportTasksSelection",
    ]);
  };

  setIdsGridComponents = () => {
    setIdsByClassName([
      {
        idContainer: "grdTasksSelection",
        class: "dx-texteditor-input",
        ids: ["txtColumnSearchGrdTasksSelection"],
        same: true,
      },
      {
        class: "btnColumnInfo",
        ids: ["btnColumnInfo"],
        same: true,
      },
      {
        class: "btnColumnDoc",
        ids: ["btnColumnDoc"],
        same: true,
      },
      {
        class: "taskgrid-ddb",
        ids: ["sboTaskValue"],
        same: true,
      },
      {
        class: "btnMove",
        ids: ["btnMove"],
        same: true,
      },
      {
        class: "bntAddComment",
        ids: ["bntAddComment"],
        same: true,
      },
      {
        class: "bntAddNbrDefects",
        ids: ["bntAddNbrDefects"],
        same: true,
      },
    ]);
  };

  handlerFilterGrid = (filters) => {
    if (this.refGrid.current !== null)
      this.refGrid.current.instance.filter(filters);
  };

  onFilterGrid = () => {
    return filterGrid(this.props.refFilters);
  };

  onHidingToolbar = (toolbar) => {
    this.setState({ [toolbar]: false }, () => {
      this.props.applyFiltersGrid();

      let refGrid = this.refGrid.current.instance;
      let pageIndex = refGrid.pageIndex();

      setTimeout(() => {
        refGrid.pageIndex(pageIndex);
      }, 50);
    });
  };

  onCellPrepared = (e) => {
    if (e.rowType === "data") {
      if (!e.data.IsEdited && e.columnIndex === 0) {
        e.cellElement.classList.add("grid-chk-hidden");
      }
    }
  };

  onRowPrepared = (e) => {
    if (e.rowType === "data") {
      if (e.data.IsEdited) {
        // let value = this.getUserPrompt(e.data.CurrentResult);
        e.rowElement.classList.remove(`dx-selection`);
        e.rowElement.classList.add(`grid-row-selected`);
      }
    }
  };

  getUserPrompt = (value) => {
    return (
      this.state.promps.find((t) => t.ServerPrompt === value)?.UserPrompt ?? ""
    );
  };

  getServerPrompt = (value) => {
    return (
      this.state.promps.find((t) => t.UserPrompt === value)?.ServerPrompt ?? ""
    );
  };

  getTasksStateValues = (value) => {
    value = this.getUserPrompt(value);

    const { promps } = this.state;

    if (value === "Defect") {
      return promps.filter((t) => t.UserPrompt === "Defect");
    }

    if (value === "Ok") {
      return promps.filter(
        (t) => t.UserPrompt === "Defect" || t.UserPrompt === "Ok"
      );
    }

    if (value === "Late") {
      return promps.filter(
        (t) =>
          t.UserPrompt === "Defect" ||
          t.UserPrompt === "Ok" ||
          t.UserPrompt === "Late"
      );
    }

    if (value === "Pending") {
      return promps.filter(
        (t) =>
          t.UserPrompt === "Defect" ||
          t.UserPrompt === "Ok" ||
          t.UserPrompt === "Pending"
      );
    }
  };

  getHeaderFilter = (column) => {
    if (column === "CurrentResult") {
      let data = JSON.parse(JSON.stringify(this.props.data));
      let promps = JSON.parse(JSON.stringify(this.state.promps));

      let filterValues = [...new Set(data.map((j) => j.CurrentResult))];

      // eslint-disable-next-line
      return filterValues.map((filterValue) => {
        let filterText = promps.find(
          (k) => k.ServerPrompt === filterValue
        )?.LangPrompt;

        if (filterText)
          return Object.assign(
            {},
            {
              text: filterText,
              value: filterValue,
            }
          );
      });
    }
  };

  onClickCustomize = () => {
    this.setState({ showCustomViewDialog: true });
  };

  onClickRefreshGrid = () => {
    this.props.handlerData(true);
  };

  onClickExportToPDF = async () => {
    let refGrid = this.refGrid.current.instance;

    let fontReady = document
      .getElementById("root")
      .getAttribute("data-pdf-font-ready");

    if (fontReady === "false" && localStorage.i18nextLng === "zh") {
      warning(
        "The font to export to pdf is not already loaded, please wait a seconds and try again"
      );
    } else {
      let columns = this.generateExportColumns();

      let data = await new DataSource({
        store: [...refGrid.getDataSource().store()._array],
        filter: refGrid.getCombinedFilter(),
        sort: refGrid.getDataSource().sort(),
        paginate: false,
      }).load();

      let pdfdoc = generateExportDocument(columns, data);
      pdfdoc.save("gvTasks.pdf");
    }
  };

  onClickExportToExcel = () => {
    let grid = this.refGrid.current.instance;
    grid.exportToExcel(false);
  };

  onClickQuickPrint = async () => {
    let refGrid = this.refGrid.current.instance;

    let fontReady = document
      .getElementById("root")
      .getAttribute("data-pdf-font-ready");

    if (fontReady === "false" && localStorage.i18nextLng === "zh") {
      warning(
        "The font to export to pdf is not already loaded, please wait a seconds and try again"
      );
    } else {
      let columns = this.generateExportColumns(true);
      let data = await new DataSource({
        store: [...refGrid.getDataSource().store()._array],
        filter: refGrid.getCombinedFilter(),
        sort: refGrid.getDataSource().sort(),
        paginate: false,
      }).load();

      generateQuickPrint("gvTasks", columns, data, true);
    }
  };

  generateExportColumns = (isQuickPrint = false) => {
    const { t } = this.props;
    if (isQuickPrint)
      return [
        {
          FL2: "FL2",
          SlaveUnitDesc: t("Module"),
          TaskId: t("Task Id"),
          LongTaskName: t("Long Task Name"),
          NbrItems: t("# Items"),
          Duration: t("Duration"),
          TaskType: t("Task Type"),
          QFactorType: t("Q-Factor Type"),
          Criteria: t("Criteria"),
          PPE: t("PPE"),
          Hazards: t("Hazards"),
          Lubricant: t("Lubricant"),
          Tools: t("Tools"),
          CurrentResult: t("Value"),
        },
      ];
    else
      return Array(
        this.refGrid.current.instance
          .getVisibleColumns()
          .filter(
            (column) =>
              column.caption !== "" &&
              column.dataField !== "ColInfo" &&
              column.dataField !== ""
          )
          .reduce(
            (obj, item) => (
              // eslint-disable-next-line no-sequences
              (obj[item.dataField] = t(item.caption)), obj
            ),
            {}
          )
      );
  };

  onClickCellInfo = (dataSelected) => {
    const { t } = this.props;
    let _temp = [];
    let TestId = dataSelected.TestId;

    let refGrid = this.refGrid.current.instance;
    let pageIndex = refGrid.pageIndex();

    let fields = [
      "TestId",
      "VarDesc",
      "LongTaskName",
      "TaskAction",
      "TaskId",
      "FL1",
      "FL2",
      "FL3",
      "FL4",
      "TaskFreq",
      "TaskType",
      "EntryOn1",
      "Criteria",
      "Hazards",
      "Method",
      "PPE",
      "Tools",
      "Lubricant",
    ];

    getTaskInfo(TestId).then((data) => {
      data["VarDesc"] = data.TaskName;
      data["TaskFreq"] = data.TaskFrequency;
      data["PPE"] = data.Ppe;
      if (data.EntryOn1 !== "" && data.EntryOn1 !== null)
        data["EntryOn1"] = dayjs(data.EntryOn1).format("MM-DD-YYYY HH:mm:ss");

      Object.keys(data).forEach((key) => {
        if (fields.includes(key)) {
          let column = gridColumns(t)
            .filter((column) => column.caption)
            .find((col) => col.dataField === key);
          if (column !== undefined) {
            _temp.push({
              order: fields.indexOf(key),
              caption: column.caption,
              value: data[key],
            });
          }
        }
      });

      _temp = _temp.sort((a, b) => a.order - b.order);
      this.setState({ taskInfoDS: _temp }, () => {
        setTimeout(() => {
          refGrid.pageIndex(pageIndex);
        }, 50);
      });

      let dialog = custom({
        title: t("Task Information"),
        messageHtml: renderToString(
          <>
            <table className="informationTable">
              <tr>
                <th>{t("Item")}</th>
                <th>{t("Description")}</th>
              </tr>
              {_temp.map((row) => (
                <tr key={row.caption}>
                  <td>{row.caption}</td>
                  <td>{row.value}</td>
                </tr>
              ))}
            </table>
            <Button
              id="btnTaskInformationExport"
              text={t("Export to Excel")}
              // imgsrc={icons.excel}
              icon="file-excel"
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
            ids: ["popTaskInformationTasksSelection"],
          },
          {
            idContainer: "popTaskInformationTasksSelection",
            class: "dx-button dx-button-normal dx-dialog-button",
            ids: ["btnOkTaskInformationTasksSelection"],
          },
        ]);
      }, 500);
    });
  };

  onClickExportCellInfo = () => {
    let ref = this.refGridInfoDetail.current.instance;
    ref.exportToExcel(false);
  };

  onClickCellComment = (data) => {
    const { t } = this.props;

    let dialog = custom({
      title: t("Task Comment"),
      messageHtml: renderToString(
        <form className={styles.commentDialog}>
          <Input
            id="txtTaskComment"
            name="txtTaskComment"
            type="text"
            border
            defaultValue={data.CommentInfo}
          />
        </form>
      ),
      buttons: [
        {
          text: t("Save"),
          type: "default",
          onClick: () => Object({ save: true }),
        },
        { text: t("Cancel") },
      ],
      dragEnabled: false,
    });
    dialog.show().then((dialogResult) => {
      let value = document.getElementById("txtTaskComment").value;
      if (dialogResult?.save && value !== data.CommentInfo) {
        let refGrid = this.refGrid.current.instance;
        data.IsEdited = true;
        data.IsSelected = true;
        data.CommentInfo = value;
        this.setState({ commentWasUpdated: true }, () =>
          refGrid.saveEditData()
        );
      }
    });
    setTimeout(() => {
      setIdsByClassName([
        {
          class: "dx-overlay-content dx-popup-normal dx-resizable",
          ids: ["popTaskCommentTasksSelection"],
        },
        {
          idContainer: "popTaskCommentTasksSelection",
          class: "dx-button dx-dialog-button",
          ids: [
            "btnSaveTaskCommentTasksSelection",
            "btnCancelTaskCommentTasksSelection",
          ],
        },
      ]);
    }, 500);
  };

  onClickCellMove = (data) => {
    this.setState({ showPostponeTaskDialog: true }, () => {
      this.props.applyFiltersGrid();

      let refGrid = this.refGrid.current.instance;
      let pageIndex = refGrid.pageIndex();

      setTimeout(() => {
        refGrid.pageIndex(pageIndex);
      }, 50);

      setTimeout(() => {
        var date = data.key.ScheduleTime;
        var rowIndex = data.rowIndex;

        var refdtp = this.refDtpPostponedTask.current.instance;

        document.querySelector("[name=txtCurrentTime]").textContent = date;
        document.querySelector("[name=txtCSTRowIndex]").textContent = rowIndex;

        refdtp.option("min", new Date(date));
        refdtp.option("value", new Date(date));
      }, 500);
    });
  };

  onSaveSelectedTasks = () => {
    let { commentWasUpdated, originalData } = this.state;
    let editedData = this.refGrid.current?.instance
      .getDataSource()
      .store()
      ._array.filter((row) => row.IsEdited && row.IsSelected);

    let id_token = sessionStorage.getItem("OpsHubToken");
    if (editedData?.length) {
      displayPreload(true);
      saveTasksSelection(editedData).then(() => {
        let clTasks = this.filterOnlyCLTasks(editedData);
        setTimeout(() => {
          if (clTasks.length && id_token) {
            let valueWasUpdated =
              JSON.stringify(originalData.map((x) => x.CurrentResult)) !==
              JSON.stringify(this.props.data.map((x) => x.CurrentResult));
            if (valueWasUpdated)
              setTasksValues(clTasks).then(() => {
                if (!commentWasUpdated) this.props.handlerData(true);
              });
            let tasksAddinComments = clTasks.filter((t) => t.CommentId === -1);
            let tasksUpdatingComments = clTasks.filter(
              (t) => t.CommentId !== -1
            );

            if (tasksAddinComments.length)
              addComments(tasksAddinComments).then(() => {
                if (!tasksUpdatingComments.length && commentWasUpdated)
                  this.refreshTasks();
              });
            if (tasksUpdatingComments.length)
              updateComments(tasksUpdatingComments).then(() => {
                this.refreshTasks();
              });

            if (!commentWasUpdated) displayPreload(false);
          } else displayPreload(false);
        }, 250);
      });
    }
  };

  refreshTasks = () => {
    setTimeout(() => {
      this.setState({ commentWasUpdated: false }, () =>
        this.props.handlerData(true)
      );
    }, 250);
  };

  hasCLTasks = (tasks) => {
    if (!tasks) return;
    return tasks.find((x) => x?.EventSubtypeDesc !== "eCIL");
  };

  filterOnlyCLTasks = (data) => {
    return data.filter((x) => x.EventSubtypeDesc !== "eCIL");
  };

  onCompleteAllTasks = () => {
    const {
      saveEditData,
      selectRowsByIndexes,
      getRowIndexByKey,
      getVisibleRows,
      getDataSource,
      clearSelection,
    } = this.refGrid.current.instance;

    let items = !this.state.isCompletedAll
      ? getVisibleRows()
      : getDataSource()._items;

    let indexes = [];
    if (!this.state.isCompletedAll) {
      items.forEach((_row) => {
        let row = Object.assign({}, _row);
        if (row.rowType === "data") {
          if (row?.data) {
            let value = this.getUserPrompt(row.data.CurrentResult);
            let isCL = row?.data.EventSubtypeDesc.includes("CL");

            if (value !== "Defect" && !isCL) {
              row.data.IsEdited = true;
              row.data.IsSelected = true;
              row.data.CurrentResult = this.getServerPrompt("Ok");
              indexes.push(getRowIndexByKey(row.data));
            }
          }
        }
      });
      saveEditData();
      selectRowsByIndexes(indexes);
    } else {
      // second time
      items.forEach((row) => {
        let isCL = row?.EventSubtypeDesc.includes("CL");
        let value = row.CurrentResult;
        let originalValue = [...this.state.originalData].find(
          (t) => t.TestId === row.TestId
        )?.CurrentResult;
        if (this.getUserPrompt(value) !== "Defect" && !isCL) {
          row.IsEdited = false;
          row.IsSelected = false;
          row.CurrentResult = originalValue;
          indexes = [];
        }
      });
      clearSelection();
    }

    this.setState({ isCompletedAll: !this.state.isCompletedAll });
  };

  accordionHandler = async (tourSelected, closing = false) => {
    let TourDesc = tourSelected?.TourDesc;
    let divs = document.getElementsByClassName("accslide");
    let tourMapId = document.getElementById("tourMapId");
    let collapseGridWidth = "40%";
    let isExpanded = divs[0]?.style.width === collapseGridWidth;
    let originalData = [];
    if (!divs || !divs[0]) return;
    let dynamicColumns = gridColumns(
      this.props.t,
      this.state.promps,
      this.refGrid,
      this.props.refDefects,
      this.props.handlerDefects,
      this.getUserPrompt,
      this.getServerPrompt,
      this.getTasksStateValues,
      this.onClickCellInfo,
      this.onClickCellMove,
      this.onClickCellComment
    );
    sortBy("asc", dynamicColumns, "caption");
    if (closing) {
      tourMapId.style.display = "none";
      divs[0].style.width = "98%";
      divs[1].style.width = "0%";
      this.props.data.forEach((task) =>
        originalData.push(Object.assign({}, task))
      );
      this.setState(
        {
          dynamicColumns,
          tourMapLink: "",
          dataFiltered: this.props.data,
          originalData,
          TourDesc,
          noTourStopTasksMessage: "",
          isExpanded: false,
        },
        () => {
          this.refGridTourMaps.current?.instance.clearSelection();
        }
      );
      return;
    }
    if (tourSelected?.TourId) {
      displayPreload(true);
      const imgdata = (await getTourMapImage(tourSelected.TourId)) || "";
      let tourMapLink = imgdata || "";
      let data = this.props.data;
      let res = [];
      let noTourStopTasksMessage = "";
      res = data.filter((x) => x.TourId === tourSelected.TourId);
      noTourStopTasksMessage = res.length ? "" : "No tasks for this tour stop";
      if (!imgdata || imgdata?.status === 500) {
        // no image
        this.setState(
          {
            dataFiltered: res,
            showTourMapLinks: false,
            noTourStopTasksMessage,
            isExpanded: false,
          },
          () => {
            warning("There is no image uploaded for this Tour Stop");
            tourMapId.style.display = "block";
            displayPreload(false);
          }
        );
        return;
      }
      if (isExpanded) {
        this.setState(
          {
            tourMapLink,
            dataFiltered: res,
            showTourMapLinks: false,
            TourDesc,
            noTourStopTasksMessage,
          },
          () => {
            setTimeout(() => {
              tourMapId.style.display = "block";
              divs[1].style.display = "block";
              displayPreload(false);
            }, 500);
          }
        );
        return;
      } else {
        divs[0].style.width = collapseGridWidth;
        divs[1].style.width = "56%";
        divs[1].style.display = "block";
        let specificColumns = [
          "IsSelected",
          "ColInfo",
          "TourTaskOrder",
          "VarDesc",
          "ColDoc",
          "DueTime",
          "CurrentResult",
          "CommentInfo",
          "NbrDefects",
        ];
        dynamicColumns.forEach((col, index) => {
          let temp = specificColumns.find((y) => col.dataField === y);
          if (temp) {
            col.visibility = true;
            col.visibleIndex = index;
            if (col.dataField === "TourTaskOrder") {
              col.sortOrder = "asc";
              col.visibleIndex = 9;
            }
            if (col.dataField === "DueTime") col.sortOrder = "";
          } else {
            col.visibility = false;
            col.showInColumnChooser = true;
            col.visibleIndex = index;
          }
        });
        this.setState(
          {
            dynamicColumns,
            tourMapLink,
            showTourMapLinks: false,
            dataFiltered: res,
            TourDesc,
            noTourStopTasksMessage,
            isExpanded: true,
          },
          () => {
            setTimeout(() => {
              this.refGrid.current?.instance.refresh();
              tourMapId.style.display = "block";
              displayPreload(false);
            }, 750);
          }
        );
      }
    }
  };

  onClickTourMap = () => {
    this.setState({ showTourMapLinks: true });
  };

  renderPopUps = (showTourMapLinks) => {
    const { t, data, tourMaps } = this.props;
    return (
      <>
        {/* Information Detail Grid */}
        <div className={styles.infoDetailGrid}>
          <DataGrid
            identity="grdTaskSelectionInfoDetail"
            reference={this.refGridInfoDetail}
            dataSource={{
              store: { type: "array", data: this.state.taskInfoDS },
            }}
            columnAutoWidth={true}
          >
            <Export fileName="gvDetails" />
            <Column caption="Item" dataField="caption" />
            <Column caption="Description" dataField="value" />
          </DataGrid>
        </div>

        <Popup
          id="showCustomViewDialog"
          visible={this.state.showCustomViewDialog}
          onHiding={this.onHidingToolbar}
          width="750px"
        >
          <CustomViewDialog
            t={t}
            viewName="DataEntry"
            refGrid={this.refGrid}
            opened={this.state.showCustomViewDialog}
          />
        </Popup>

        <Popup
          id="showPostponeTaskDialog"
          title={t("Postponed Task")}
          visible={this.state.showPostponeTaskDialog}
          onHiding={this.onHidingToolbar}
          width="300px"
        >
          <form className={styles.moveDialog}>
            <div>
              <h5>
                {t("Current Schedule Time")}
                <label name="txtCurrentTime"></label>
                <label name="txtCSTRowIndex"></label>
              </h5>
              <hr />
              <h5>{t("Postponed Schedule Time")}:</h5>
              <DateBox
                ref={this.refDtpPostponedTask}
                type="datetime"
                displayFormat="yyyy-MM-dd HH:mm"
                acceptCustomValue={false}
              />
              <hr />
            </div>

            <Button
              text="Accept"
              onClick={() => {
                const { cellValue, saveEditData } =
                  this.refGrid.current.instance;

                let currentValue = document.querySelector(
                  "[name=txtCurrentTime]"
                ).textContent;
                var rowIndex = parseInt(
                  document.querySelector("[name=txtCSTRowIndex]").textContent
                );

                var value =
                  this.refDtpPostponedTask.current.instance._changedValue;

                if (!dayjs(currentValue).isSame(dayjs(value))) {
                  cellValue(rowIndex, "IsEdited", true);
                  cellValue(rowIndex, "IsSelected", true);
                  cellValue(rowIndex, "ScheduleTime", value);
                  saveEditData();
                }
                this.setState({ showPostponeTaskDialog: false }, () => {
                  let refGrid = this.refGrid.current.instance;
                  let pageIndex = refGrid.pageIndex();
                  setTimeout(() => {
                    refGrid.pageIndex(pageIndex);
                  }, 50);
                });
              }}
            />
          </form>
        </Popup>

        <Popup
          id="showTourMapLinks"
          visible={showTourMapLinks}
          onHiding={() => this.setState({ showTourMapLinks: false })}
          width="400px"
          height="400px"
          title={t("Tour Stops Maps")}
          dragEnabled={true}
        >
          <div>
            {tourMaps?.length ? (
              <>
                <DataGrid
                  identity="grdTourStop"
                  keyExpr="TourId"
                  reference={this.refGridTourMaps}
                  dataSource={tourMaps}
                  showBorders={false}
                  rowAlternationEnabled={false}
                  allowFiltering={false}
                  headerFilter={{ visible: false }}
                  filterRow={false}
                  height="280px"
                >
                  <Column
                    dataField={"TourDesc"}
                    caption={t("Tour Stop")}
                    allowSearch={false}
                    allowSorting={false}
                  />
                  <Selection mode="single" showCheckBoxesMode="none" />
                </DataGrid>
                <br />
                <div style={{ textAlign: "center" }}>
                  <Button
                    text={t("Ok")}
                    primary
                    style={{ width: "60px" }}
                    onClick={() => {
                      let refGridTourMaps =
                        this.refGridTourMaps.current?.instance.getSelectedRowsData();
                      refGridTourMaps?.length
                        ? this.accordionHandler(refGridTourMaps[0], false)
                        : this.setState({ showTourMapLinks: false });
                    }}
                  />
                  <Button
                    text={t("Cancel")}
                    style={{ width: "80px" }}
                    onClick={() => {
                      this.setState({ showTourMapLinks: false });
                    }}
                  />
                  <Button
                    text={t("Close Right Panel")}
                    style={{ width: "200px" }}
                    disabled={
                      document.getElementsByClassName("accslide")[0]?.style
                        .width !== "40%"
                    }
                    onClick={() => {
                      this.accordionHandler("", true);
                      this.setState({
                        dataFiltered: data,
                        showTourMapLinks: false,
                      });
                    }}
                  />
                </div>
              </>
            ) : (
              <div
                className={styles.isDefectLookedMessage}
                style={{ height: "35px" }}
              >
                {/* <img alt="" src={icons.info} /> */}
                <Icon name="circle-info" />
                <label>
                  {"No tour stops are assigned for this selection."}
                </label>
              </div>
            )}
          </div>
        </Popup>
      </>
    );
  };

  onCellClick = (e) => {
    let { rowIndex, component, text } = e;
    let { originalData } = this.state;
    // is CheckBox first column
    if (["true", "false"].includes(text)) {
      let val = e.data;
      let originalValue = [...originalData].find(
        (t) => t.TestId === val.TestId
      )?.CurrentResult;
      val.CurrentResult = originalValue;
      component.cellValue(rowIndex, "IsEdited", false);
      component.cellValue(rowIndex, "IsSelected", false);
      component.clearSelection();
      component.refresh();
    }
  };

  render() {
    const { t, data, viewActive } = this.props;
    const {
      dataFiltered,
      tourMapLink,
      dynamicColumns,
      showTourMapLinks,
      TourDesc,
      noTourStopTasksMessage,
      isExpanded,
    } = this.state;
    let eDHAccessToken = getProfile()?.EDHAccessToken;
    let noTaskMessage = viewActive.toLowerCase().includes("route")
      ? t("No tasks are currently due for this route.")
      : t("No tasks are currently due for this selection.");

    return (
      <div>
        <ul
          id="tabs"
          style={{
            width: "100%",
            transform: "translate(-30px, -10px)",
            marginTop: "-20px",
          }}
          class="accordion"
          className={nav.accordion}
        >
          <li>
            <input
              id="rad1"
              type="checkbox"
              name="rad"
              checked={true}
              class="accInput"
              onClick={() => this.accordionHandler("", true)}
            />
            <div class="accslide" style={{ width: "95%" }}>
              <div class="content">
                <div className={styles.contentGrid}>
                  {!eDHAccessToken && dataFiltered?.length !== 0 && (
                    <div>
                      <div className={styles.eDhNotAccessMessage}>
                        {/* <img alt="" src={icons.info} /> */}
                        <Icon name="circle-info" />
                        <label>
                          {t(
                            "The current user doesn't have access to the eDefects server."
                          )}
                        </label>
                      </div>
                    </div>
                  )}
                  {this.renderPopUps(showTourMapLinks)}
                  {noTourStopTasksMessage !== "" && (
                    <div>
                      <div className={styles.eDhNotAccessMessage}>
                        <Icon name="circle-info" />
                        {/* <img alt="" src={icons.info} /> */}
                        <label>{noTourStopTasksMessage}</label>
                      </div>
                    </div>
                  )}

                  {!data?.length && (
                    <div className={styles.isDefectLookedMessage}>
                      <Icon name="circle-info" />
                      <label>{noTaskMessage}</label>
                      <br />
                    </div>
                  )}
                  <DataGrid
                    identity="grdTasksSelection"
                    reference={this.refGrid}
                    dataSource={{
                      store: dataFiltered,
                      filter: this.onFilterGrid(),
                    }}
                    onAdaptiveDetailRowPreparing={(e) => {
                      e.formOptions.items = [
                        ...e.formOptions.items,
                        {
                          itemType: "group",
                          // caption: "",
                          colCount: "auto",
                          colCountByScreen: {
                            xs: 3,
                            sm: 3,
                            md: 3,
                            lg: 3,
                          },
                        },
                      ];
                    }}
                    showBorders={false}
                    scrollingMode={
                      window.innerWidth > 992 ? "standard" : "virtual"
                    }
                    columnChooserEnabled={true}
                    groupPanelVisible={true}
                    columnAutoWidth={true}
                    // onContentReady={this.setIdsGridComponents}
                    columnResizingMode={"nextColumn"}
                    columnHidingEnabled={false}
                    onCellPrepared={this.onCellPrepared}
                    onRowPrepared={this.onRowPrepared}
                    // height="calc(95% - 35px)"
                    height={
                      document.getElementById("crdTasksSelectionGrid")
                        ?.offsetHeight -
                      100 +
                      "px"
                    }
                    width={"100%"}
                    onToolbarPreparing={(e) =>
                      gridToolbarPreparing(
                        e,
                        t,
                        this.onSaveSelectedTasks,
                        this.onCompleteAllTasks,
                        this.onClickCustomize,
                        this.onClickRefreshGrid,
                        this.onClickQuickPrint,
                        this.onClickExportToExcel,
                        this.onClickExportToPDF,
                        this.onClickTourMap,
                        viewActive,
                        isExpanded,
                        this.props.handlerFilters
                      )
                    }
                    columns={dynamicColumns}
                    onCellClick={this.onCellClick}
                  >
                    <Export enabled={false} fileName="gvTasks" />
                    <Paging enabled={true} pageSize={20} />
                    <Pager
                      showPageSizeSelector={false}
                      showNavigationButtons={false}
                      showInfo={true}
                      visible={true}
                    />
                    <Editing
                      mode="cell"
                      allowUpdating={true}
                      allowAdding={false}
                    />
                    <GroupPanel visible={true} />
                    <Grouping expandMode="rowClick" autoExpandAll={true} />
                    <Sorting mode="multiple" />
                  </DataGrid>
                </div>
              </div>
            </div>
          </li>
          <li>
            <div class="accslide" style={{ width: "0%", display: "none" }}>
              <div id="tourMapId" class="content" style={{ display: "none" }}>
                <Button
                  hint={t("Cancel")}
                  classes={styles.buttons}
                  imgsrc={icons.close}
                  style={{ float: "right", cursor: "pointer" }}
                  onClick={() => this.accordionHandler("", true)}
                />
                <label style={{ fontSize: "small", whiteSpace: "pre-wrap" }}>
                  <strong>{t("Tour Stop")}:</strong> {TourDesc}
                </label>
                <div style={{ padding: "20px 0px" }}>
                  <TransformWrapper initialScale={1}>
                    {({ zoomIn, zoomOut, resetTransform, ...rest }) => (
                      <React.Fragment>
                        <TransformComponent>
                          <img
                            src={`data:image/jpeg;base64,${tourMapLink}`}
                            alt=""
                            width={"100%"}
                            height={"100%"}
                          />
                        </TransformComponent>
                      </React.Fragment>
                    )}
                  </TransformWrapper>
                </div>
              </div>
            </div>
          </li>
        </ul>
      </div>
    );
  }
}

export default Grid;
