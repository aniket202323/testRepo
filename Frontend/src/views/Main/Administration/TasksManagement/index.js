import React, { PureComponent, memo } from "react";
import Filters from "./subs/Filters";
import TaskEditor from "./subs/TaskEditor";
import DataGrid from "../../../../components/DataGrid";
import Card from "../../../../components/Card";
import Button from "../../../../components/Button";
import Input from "../../../../components/Input";
import RadioGroup from "../../../../components/RadioGroup";
import { displayPreload } from "../../../../components/Framework/Preload";
import { setBreadcrumbEvents } from "../../../../components/Framework/Breadcrumb/events";
import {
  Column,
  FilterRow,
  Pager,
  Paging,
  Export,
  Grouping,
  GroupPanel,
  SearchPanel,
  ColumnChooser,
  FilterPanel,
  Selection,
  Editing,
} from "devextreme-react/ui/data-grid";
import { confirm } from "devextreme/ui/dialog";
import { Popup } from "devextreme-react/ui/popup";
import {
  entriesCompare,
  generateExportData,
  generateExportDocument,
  generateQuickPrint,
  getIcon,
  setIdsByClassName,
} from "../../../../utils";
import {
  getDepartments,
  getLines,
  getUnits,
  getWorkcells,
  getProductionGroups,
  getFL1,
  getFL2,
  getFL3,
  getFL4,
  getPlantModelEditMode,
  updateProdLineUDP,
  updateProdUnitUDP,
  updateProdGroupUDP,
} from "../../../../services/plantModel";
import {
  getPPAVersion,
  getTasksPlantModelEditList,
  getTasksFLEditList,
  saveTasks,
} from "../../../../services/tasks";
import {
  getCustomView,
  saveCustomView,
  deleteCustomView,
} from "../../../../services/customView";
import { getUserId, getUserRole } from "../../../../services/auth";
import { warning, error } from "../../../../services/notification";
import {
  gridTasksToolbarPreparing,
  gridTasksColumns,
  gridRawDataFormatColumns,
  gridTasksSetButtonsState,
  filterGrid,
  filterGridTasksEditMode,
  updateFLView,
  updatePlantModelView,
  taskClass,
  gridTasksEditModeColumns,
} from "./options";
import icons from "../../../../resources/icons";
import DataSource from "devextreme/data/data_source";
import { isTablet } from "../../../../utils";
import styles from "./styles.module.scss";

const initialState = {
  aspectedSite: false,
  showTaskEditor: false,
  taskSelected: null,
  taskMode: "",
  // data: [],
  dataRawFormat: [],
  localFilterGrid: [],
  localFilterGridTasksEditMode: [],
  lines: [],
  units: [],
  workcells: [],
  groups: [],
  fl2: [],
  fl3: [],
  fl4: [],
  plantModel: {
    departments: [],
    lines: [],
    units: [],
    workcells: [],
    groups: [],
  },
  fl: {
    fl1: [],
    fl2: [],
    fl3: [],
    fl4: [],
  },
  cellsEdited: [],
  cvInputLength: 0,
};

class TasksManagement extends PureComponent {
  constructor(props) {
    super(props);

    this.refGrid = React.createRef();
    this.refGridRawData = React.createRef();
    this.refGridEditMode = React.createRef();
    this.refRdgCustomView = React.createRef();

    this.state = {
      data: [],
      showFilters: true,
      columnResizingMode: "widget",
      columnHidingEnabled: false,
      chkEditMode: false,
      tasksMgmtFilterGroup: "Plant Model",
      customsViews: [],
      customViewActive: "Plant Model View",
      customViewDialogOpened: false,
      customViewRdgOption: "NewView",
      departments: [],
      fl1: [],
      ...initialState,
      loading: {
        departments: false,
        lines: false,
        units: false,
        workcells: false,
        groups: false,
        fl1: false,
        fl2: false,
        fl3: false,
        fl4: false,
      },
    };
  }

  componentDidMount = () => {
    const { t } = this.props;
    setBreadcrumbEvents(
      <nav>
        <Button
          id="btnShowHideFilters"
          icon="filter"
          hint={t("Show/Hide Filters")}
          primary
          classes={[styles.breadcrumbButton, "taskMgmtBreadcrumbButton"].join(
            " "
          )}
          onClick={this.handlerFilters}
        />
        <Button
          id="btnRunTasksMgmt"
          icon="rocket"
          hint={t("Execute")}
          primary
          disabled={false}
          classes={[styles.breadcrumbButton, "taskMgmtBreadcrumbButton"].join(
            " "
          )}
          onClick={this.runSelection}
        />
      </nav>
    );

    displayPreload(true);
    Promise.all([getPPAVersion(), getDepartments()]).then((response) => {
      const [ppa, departments] = response;
      this.setState({ aspectedSite: ppa, departments, data: [] }, () =>
        displayPreload(false)
      );
    });

    getCustomView("TasksManagement").then((response) => {
      this.setState({ customsViews: response });
    });

    this.setState({
      ...initialState,
      localFilterGrid: filterGrid(this.state),
      localFilterGridTasksEditMode: filterGridTasksEditMode(this.state),
    });
  };

  componentDidUpdate = (prevProps, prevState) => {
    this.disabledToRun();
    this.handlerData(prevState);
  };

  runSelection = () => {
    this.setState({ showFilters: false }, () => {
      let tasksMgmtFilterGroup = this.state.tasksMgmtFilterGroup;

      if (tasksMgmtFilterGroup === "Plant Model") {
        let { departments } = this.state.plantModel;
        departments = departments || [];

        displayPreload(true);
        if (departments !== []) {
          if (this.state.chkEditMode) {
            // if (!this.state.data.length) {
            getPlantModelEditMode().then((response) => {
              //getItemDesc
              function getItemDesc(parentId) {
                return response.find((r) => r.Id === parentId).ItemDesc;
              }
              //getParentId
              function getParentId(parentId) {
                return response.find((r) => r.Id === parentId).ParentId;
              }
              if (response !== undefined)
                response.forEach((res) => {
                  let level = res.Level;
                  let parentId = res.ParentId;
                  let itemDesc = "";
                  let plantModel = [];
                  for (let i = level; i >= 0; i--) {
                    itemDesc = getItemDesc(i === level ? res.Id : parentId);
                    parentId = getParentId(i === level ? res.Id : parentId);
                    plantModel.push(itemDesc);
                  }
                  res.PlantModel = plantModel.reverse().join("/");
                });
              this.setState(
                {
                  data: response,
                  cellsEdited: [],
                  localFilterGridTasksEditMode: filterGridTasksEditMode(
                    this.state
                  ),
                },
                () => displayPreload(false)
              );
            });
            // } else displayPreload(false);
          } else {
            getTasksPlantModelEditList(departments.join(",")).then((response) =>
              this.setState(
                {
                  data: response,
                  cellsEdited: [],
                  localFilterGrid: filterGrid(this.state),
                },
                () => {
                  displayPreload(false);
                }
              )
            );
          }
        } else {
          if (this.state.chkEditMode) {
            this.setState(
              {
                localFilterGridTasksEditMode: filterGridTasksEditMode(
                  this.state
                ),
              },
              () => displayPreload(false)
            );
          } else {
            this.setState(
              {
                localFilterGrid: filterGrid(this.state),
              },
              () => displayPreload(false)
            );
          }
        }
      } else {
        let { fl1 } = this.state.fl;
        fl1 = fl1 || [];
        displayPreload(true);
        if (fl1 !== []) {
          getTasksFLEditList(fl1.join(",")).then((response) =>
            this.setState(
              {
                data: response,
                localFilterGrid: filterGrid(this.state),
              },
              () => displayPreload(false)
            )
          );
        } else {
          this.setState(
            {
              localFilterGrid: filterGrid(this.state),
            },
            () => displayPreload(false)
          );
        }
      }
    });
  };

  disabledToRun = () => {
    let disabled = true;
    let { departments } = this.state.plantModel;
    let { fl1 } = this.state.fl;

    departments = departments || [];
    fl1 = fl1 || [];

    disabled = departments.length !== 0 || fl1.length !== 0;

    let btnRocket = document.getElementById("btnRunTasksMgmt");
    if (btnRocket !== null) btnRocket.disabled = !disabled;
  };

  handlerData = (prevState) => {
    if (this.state.tasksMgmtFilterGroup === "Plant Model") {
      const { departments, lines, units, workcells } = this.state.plantModel;
      const {
        departments: prevDepartments,
        lines: prevLines,
        units: prevUnits,
        workcells: prevWorkcells,
      } = prevState.plantModel;

      if (this.state.chkEditMode)
        this.refGridEditMode.current.instance.cancelEditData();

      if (prevDepartments !== departments && departments.length > 0) {
        // if (this.state.chkEditMode) {
        //   getLines(departments.join(",")).then(
        //     (response) => this.setState({ lines: response }) // edit mode
        //   );
        // } else {
        getLines(departments.join(",")).then((response) =>
          this.setState({ lines: response }, () => {
            // getTasksPlantModelEditList
          })
        );
        // }
      }
      // else if (prevDepartments !== departments && departments.length === 0) {
      //   this.setState({ data: [] });
      // }

      if (prevLines !== lines && lines.length > 0) {
        getUnits(lines.join(",")).then((response) =>
          this.setState({ units: response })
        );
      }

      if (prevUnits !== units && units.length > 0) {
        getWorkcells(units.join(",")).then((response) =>
          this.setState({ workcells: response })
        );
      }

      if (prevWorkcells !== workcells && workcells.length > 0) {
        getProductionGroups(workcells.join(",")).then((response) =>
          this.setState({ groups: response })
        );
      }
    } else {
      const { fl1, fl2, fl3 } = this.state.fl;
      const { fl1: prevFl1, fl2: prevFl2, fl3: prevFl3 } = prevState.fl;

      if (this.state.fl1.length === 0) {
        displayPreload(true);
        getFL1().then((response) =>
          this.setState(
            {
              fl1: response,
            },
            () => displayPreload(false)
          )
        );
      }

      if (prevFl1 !== fl1 && fl1.length > 0) {
        // displayPreload(true);

        let FLIds = this.state.fl1
          .filter((fl) => fl1.find((f) => f === fl.ItemDesc))
          .map((m) => m.Id);

        if (FLIds.length > 0)
          getFL2(FLIds.join(",")).then((response) =>
            this.setState({ fl2: response }, () => {
              // getTasksFLEditList(fl1.join(",")).then((response) =>
              //   this.setState({ data: response }, () => displayPreload(false))
              // );
            })
          );
      }
      // else if (prevFl1 !== fl1 && fl1.length === 0) {
      //   this.setState({ data: [] });
      // }

      if (prevFl2 !== fl2 && fl2.length > 0) {
        let FLIds = this.state.fl2
          .filter((fl) => fl2.find((f) => f === fl.ItemDesc))
          .map((m) => m.Id);

        if (FLIds.length > 0)
          getFL3(FLIds.join(",")).then((response) =>
            this.setState({ fl3: response })
          );
      }

      if (prevFl3 !== fl3 && fl3.length > 0) {
        let FLIds = this.state.fl3
          .filter((fl) => fl3.find((f) => f === fl.ItemDesc))
          .map((m) => m.Id);

        if (FLIds.length > 0)
          getFL4(FLIds.join(",")).then((response) =>
            this.setState({ fl4: response })
          );
      }
    }
  };

  setIdsGridComponents = () => {
    setIdsByClassName([
      // DataGrid Buttons
      "btnCreateTask",
      "btnEditMultipleTasksMgmt",
      "btnObsoleteMultipleTasksMgmt",
      "btnSaveChangesTasksMgmt",
      "btnCustomizeGridTasksMgmt",
      "btnRefreshGridTasksMgmt",
      {
        class: "dx-datagrid-column-chooser-button",
        ids: ["btnColumnChooserTasksMgmt"],
      },
      "btnQuickPrintTasksMgmt",
      "btnExcelExportTasksMgmt",
      "btnPdfExportTasksMgmt",
      "btnRawDataExportTasksMgmt",
      // // Grid buttons: Duplicate, Edit and Obsolete
      {
        idContainer: "grdTaskMgtm",
        class: "btnDuplicateTasksMgmt",
        ids: ["btnDuplicateTasksMgmt"],
        same: true,
      },
      {
        idContainer: "grdTaskMgtm",
        class: "btnEditTasksMgmt",
        ids: ["btnEditTasksMgmt"],
        same: true,
      },
      {
        idContainer: "grdTaskMgtm",
        class: "btnObsoleteTasksMgmt",
        ids: ["btnObsoleteTasksMgmt"],
        same: true,
      },
    ]);
  };

  setIdEditMode = () => {
    setTimeout(() => {
      setIdsByClassName([
        {
          idContainer: "grdTasksMgmtEditMode",
          class: "btnEditTasksMgmtEditMode",
          ids: ["btnEditTasksMgmtEditMode"],
          same: true,
        },
        {
          idContainer: "grdTasksMgmtEditMode",
          class: "btnSaveTasksMgmtEditMode",
          ids: ["btnSaveTasksMgmtEditMode"],
          same: true,
        },
        {
          idContainer: "grdTasksMgmtEditMode",
          class: "btnCancelTasksMgmtEditMode",
          ids: ["btnCancelTasksMgmtEditMode"],
          same: true,
        },
      ]);
    }, 1000);
  };

  handlerFilters = () => {
    this.setState({ showFilters: !this.state.showFilters }, () =>
      gridTasksSetButtonsState(this.refGrid)
    );
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

  onClickQuickPrint = () => {
    let fontReady = document
      .getElementById("root")
      .getAttribute("data-pdf-font-ready");

    if (fontReady === "false" && localStorage.i18nextLng === "zh") {
      warning(
        "The font to export to pdf is not already loaded, please wait a seconds and try again"
      );
    } else {
      let columns = this.generateExportColumns();
      let data = generateExportData(this.refGrid.current.instance);
      generateQuickPrint("gvTasks", columns, data);
    }
  };

  generateExportColumns = () => {
    return Array(
      this.refGrid.current.instance
        .getVisibleColumns()
        .filter(
          (column) => column.type !== "buttons" && column.type !== "selection"
        )
        .reduce(
          (obj, item) => (
            // eslint-disable-next-line no-sequences
            (obj[item.dataField] = this.props.t(item.caption)), obj
          ),
          {}
        )
    );
  };

  onClickExportToExcel = () => {
    let grid = this.refGrid.current.instance;
    grid.exportToExcel(false);
  };

  onClickExportRawDataFormat = () => {
    displayPreload(true);
    var dataRawFormat = JSON.parse(
      JSON.stringify(
        this.refGrid.current.instance.getDataSource().store()._array
      )
    );

    dataRawFormat.forEach((task) => {
      task.Active = task.Active ? "1" : "0";
      task.FixedFrequency = task.FixedFrequency ? "1" : "0";
      task.IsHSE = task.IsHSE ? "1" : "0";
      task.ShiftOffset = task.ShiftOffset.toString();
      task.Window = task.Window === "" ? "0" : task.Window;
      task.Frequency =
        task.Frequency === "" || task.Frequency === null ? "0" : task.Frequency;
      task.AutoPostpone = task.AutoPostpone ? "1" : "0";
      if (task.TaskType === "Anytime") task.TaskType = "A";
      else if (task.TaskType === "Downtime") task.TaskType = "D";
      else if (task.TaskType === "Running") task.TaskType = "R";
    });
    this.setState({ dataRawFormat }, () => {
      let grid = this.refGridRawData.current.instance;
      grid.refresh();
      setTimeout(() => {
        grid.exportToExcel(false);
        displayPreload(false);
      }, 1000);
    });
  };

  handlerSelectPlantModel = (key, values) => {
    let selection = updatePlantModelView(key, values, this.state);
    if (!entriesCompare(values, this.state.plantModel[key])) {
      this.setState({
        // ...this.state,
        ...selection,
      });
    }
  };

  handlerSelectFL = (key, values) => {
    let selection = updateFLView(key, values, this.state);
    if (!entriesCompare(values, this.state.fl[key])) {
      this.setState({
        // ...this.state,
        ...selection,
      });
    }
  };

  handlerTaskMgmtFilterGroup = (e) => {
    this.setState({
      ...this.state,
      ...initialState,
      data: [],
      localFilterGrid: filterGrid(this.state),
      localFilterGridTasksEditMode: filterGridTasksEditMode(this.state),
      chkEditMode: !e.value === "Functiona Localtion",
      cellsEdited: [],
      tasksMgmtFilterGroup: e.value,
    });
  };

  handlerChkEditMode = () => {
    this.setState(
      {
        ...this.state,
        ...initialState,
        chkEditMode: !this.state.chkEditMode,
        data: [],
        cellsEdited: [],
      },
      () => {
        this.setIdEditMode();
      }
    );
  };

  handlerTaskEditor = () => {
    this.refGrid.current.instance.hideColumnChooser();

    this.setState(
      {
        showTaskEditor: !this.state.showTaskEditor,
        taskSelected: taskClass(),
        taskMode: "",
      },
      () => {
        this.hideBreadcrumbButtons();
        if (!this.state.showTaskEditor) gridTasksSetButtonsState(this.refGrid);
      }
    );
  };

  onClickDuplicateSingleTask = (e) => {
    let data = Object.assign({}, e.row.data);

    data.Status = "Add";
    data.ProductionGroupDesc = null;
    data.ProductionGroupId = null;
    data.SlaveUnitId = null;
    data.SlaveUnitDesc = null;
    data.TaskId = null;
    data.VMId = null;
    data.VarId = Math.floor(Math.random() * -9000) - 1000;
    data.FL1 = "";
    data.FL2 = "";
    data.FL3 = "";
    data.FL4 = "";
    data.StartDate = new Date();
    // data.TestTime = data.TestTime === "" ? "00:00" : data.TestTime;
    data.KeyFlag = Math.random().toString(36).slice(2).substring(0, 5);
    data.succes_failure = "";

    this.setState(
      {
        showTaskEditor: true,
        taskSelected: data,
        taskMode: "duplicate",
      },
      () => {
        this.hideBreadcrumbButtons();
      }
    );
  };

  onClickEditSingleTask = (e) => {
    // e.row.data.Status = e.row.data.Status === "Add" ? "Add" : "Modify";
    let data = Object.assign({}, e.row.data);
    // data.TestTime = data.TestTime === "" ? "00:00" : data.TestTime;

    this.setState(
      {
        showTaskEditor: true,
        taskSelected: data,
        taskMode: "edit",
      },
      () => {
        this.hideBreadcrumbButtons();
      }
    );
  };

  onClickEditMultipleTasks = () => {
    const { t } = this.props;
    let grid = this.refGrid.current.instance;
    let rowsSelected = grid.getSelectedRowsData();

    let dialog = confirm(
      `<span>You are about to update ${rowsSelected.length} tasks. All changes you will do will be reflected on ALL selected tasks. Continue?</span>`,
      t("Edit Multiple Tasks")
    );
    dialog.then((dialogResult) => {
      // rowsSelected[0].Status = "Modify";

      if (dialogResult) {
        this.setState(
          {
            showTaskEditor: true,
            taskSelected: rowsSelected[0],
            taskMode: "editMultiple",
          },
          () => {
            this.hideBreadcrumbButtons();
          }
        );
      }
    });
  };

  hideBreadcrumbButtons = () => {
    let btnvisibility = this.state.showTaskEditor ? "hidden" : "visible";
    document.getElementById("btnShowHideFilters").style.visibility =
      btnvisibility;
    document.getElementById("btnRunTasksMgmt").style.visibility = btnvisibility;
  };

  onClickAddTask = (task) => {
    let grid = this.refGrid.current.instance;

    grid.getDataSource().store()._array.unshift(task);
    grid.refresh();
    this.handlerTaskEditor();

    this.setState({
      localFilterGrid: filterGrid(this.state),
    });
  };

  onClickUpdateTask = (task) => {
    let grid = this.refGrid.current.instance;
    const { taskSelected, cellsEdited } = this.state;

    var key = task.VarId;
    // let rowIndex = grid.getRowIndexByKey(key);

    // cells edited
    if (cellsEdited.find((f) => f.key === key) === undefined) {
      cellsEdited.push(Object.assign({}, { key: key, cells: [] }));
    }
    var tempCells = cellsEdited.find((f) => f.key === key).cells;

    var rowData = grid
      .getDataSource()
      .store()
      ._array.find((item) => item.VarId === key);

    Object.keys(taskSelected).forEach((objKey) => {
      if (taskSelected[objKey] !== task[objKey]) {
        rowData[objKey] = task[objKey];
        tempCells.push(objKey);

        // grid.cellValue(rowIndex, objKey, task[objKey]);
        // grid.saveEditData();
      }
    });

    // saveEditData();
    this.handlerTaskEditor();
  };

  onClickUpdataMultipleTasks = (task) => {
    const { cellsEdited, taskSelected } = this.state;
    let grid = this.refGrid.current.instance;
    let rowsSelected = grid.getSelectedRowsData();
    let fieldsEdited = [];

    grid.clearSelection();

    Object.keys(taskSelected).forEach((objKey) => {
      if (taskSelected[objKey] !== task[objKey]) {
        fieldsEdited.push(objKey);
      }
    });

    rowsSelected.forEach((row) => {
      cellsEdited.push(
        Object.assign({}, { key: row.VarId, cells: fieldsEdited })
      );
      fieldsEdited.forEach((fieldUpdated) => {
        row[fieldUpdated] = task[fieldUpdated];
      });
    });
    this.handlerTaskEditor();
  };

  onClickDeleteSingleTask = (e) => {
    const { t } = this.props;
    let dialog = confirm(
      "<span>You are about to obsolete this task. Continue?</span>",
      t("Obsolete Task")
    );
    dialog.then((dialogResult) => {
      if (dialogResult) {
        let grid = this.refGrid.current.instance;
        const { cellValue, saveEditData } = grid;
        cellValue(e.row.rowIndex, "Status", "Obsolete");
        saveEditData();
      }
    });
  };

  onClickDeleteMultipleTasks = () => {
    const { t } = this.props;
    let grid = this.refGrid.current.instance;
    let rowsSelected = grid.getSelectedRowsData();

    let dialog = confirm(
      `<span>You are about to obsolete ${rowsSelected.length} task. Continue?</span>`,
      t("Obsolete Multiple Tasks")
    );
    dialog.then((dialogResult) => {
      if (dialogResult) {
        const { cellValue, saveEditData } = grid;

        rowsSelected.forEach((task) => {
          let rowIndex = grid.getRowIndexByKey(task.VarId);
          cellValue(rowIndex, "Status", "Obsolete");
        });
        saveEditData();
      }
    });
  };

  onClickCustomizeView = (e) => {
    const { t } = this.props;
    const { customsViews, customViewActive } = this.state;

    let customViewDetail = customsViews.find(
      (cv) => cv.ViewDescription === customViewActive
    );

    if (e.item.id === -1) {
      //save custom view
      this.setState(
        {
          customViewDialogOpened: true,
          customViewRdgOption:
            customViewDetail.ViewType !== 99 ? "NewView" : "CurrentView",
        },
        () =>
          setTimeout(() => {
            document.querySelector("[name=customViewName]").value =
              this.state.customViewRdgOption !== "NewView"
                ? customViewDetail.ViewDescription
                : "";
          }, 400)
      );
    } else if (e.item.id === -2) {
      //delete custom view
      let dialog = confirm(
        `<span>Are you sure you want to delete this view: ${customViewDetail.ViewDescription}?</span>`,
        t("Delete Custom View")
      );
      dialog.then((dialogResult) => {
        if (dialogResult) {
          deleteCustomView(customViewDetail.UPId).then(() =>
            getCustomView("TasksManagement").then((response) =>
              this.setState({
                customsViews: response,
                customViewActive: "Plant Model View",
              })
            )
          );
        }
      });
    } else {
      let customView = customsViews.find((cv) => cv.UPId === e.item.id);
      this.refGrid.current.instance.state(JSON.parse(customView.Data));
      this.setState({ customViewActive: customView.ViewDescription });
    }
  };

  onClickSaveCustomView = () => {
    const { t } = this.props;
    const { customsViews, customViewActive, customViewRdgOption } = this.state;

    var customViewDetail = customsViews.find(
      (cv) => cv.ViewDescription === customViewActive
    );

    let newViewDesc = document.querySelector("[name=customViewName]").value;
    let newViewUPId =
      customViewRdgOption === "NewView" ? 0 : customViewDetail?.UPId;

    if (newViewDesc !== "") {
      if (
        this.state.customsViews?.filter(
          (view) =>
            view.ViewDescription.toLowerCase() === newViewDesc.toLowerCase() &&
            view.UPId !== newViewUPId
        ).length === 0
      ) {
        //Check that the name doesn't already exist
      } else {
        error(t(`This view description already exists`));
        return;
      }
    } else {
      warning(t(`You must enter a description.`));
      return;
    }

    let viewClass = {
      UPId: newViewUPId,
      ViewType: 99,
      UserId: getUserId(),
      ViewDescription: newViewDesc,
      Data: JSON.stringify(this.refGrid.current.instance.state()),
      ScreenDescription: "TasksManagement",
      ScreenId: 2,
      DefaultViewId: 7,
      IsPublic: true,
      IsDefault: 0,
      IsUserDefault: false,
      IsSiteDefault: false,
      MenuItemIndex: 0,
      IsWrapEnable: false,
    };

    saveCustomView(viewClass).then(() =>
      getCustomView("TasksManagement").then((response) =>
        this.setState({ customsViews: response, customViewDialogOpened: false })
      )
    );
  };

  onClickCloseCustomViewDialog = () => {
    this.setState({ customViewDialogOpened: false });
  };

  onClickSaveChanges = () => {
    let grid = this.refGrid.current.instance;
    let tasksMgmtFilterGroup = this.state.tasksMgmtFilterGroup;
    let { fl1 } = this.state.fl;

    displayPreload(true);
    saveTasks(grid.getSelectedRowsData().filter((r) => r.Status !== ""))
      .then((response) => {
        if (tasksMgmtFilterGroup === "Plant Model") {
          let data = Array.copy(this.state.data);
          response.forEach((task) => {
            data.find((item) => item.KeyFlag === task.KeyFlag).succes_failure =
              task.succes_failure;
          });

          this.setState({ data, cellsEdited: [] }, () => {
            var selectedKeys = grid.getSelectedRowKeys();
            grid.deselectRows(selectedKeys);
            displayPreload(false);
          });

          // getTasksPlantModelEditList(departments.join(",")).then((response) =>
          //   this.setState({ data: response, cellsEdited: [] }, () => {
          //     var selectedKeys = grid.getSelectedRowKeys();
          //     grid.deselectRows(selectedKeys);
          //     displayPreload(false);
          //   })
          // );
        } else if (tasksMgmtFilterGroup === "Functional Location") {
          getTasksFLEditList(fl1.join(",")).then((response) => {
            this.setState({ data: response, cellsEdited: [] }, () => {
              var selectedKeys = grid.getSelectedRowKeys();
              grid.deselectRows(selectedKeys);
              displayPreload(false);
            });
          });
        }
      })
      .catch(() => displayPreload(false));
  };

  onClickSaveEditMode = (e) => {
    const { data } = this.state;

    var level = this.getEditModeLevel();

    let grid = this.refGridEditMode.current.instance;
    const { cellValue, saveEditData } = grid;

    const { ItemDesc, FL1, FL2, FL3, FL4, LineVersion, ModuleFeatureVersion } =
      e.row.data;

    if (level === 1) {
      displayPreload(true);

      updateProdLineUDP(ItemDesc, "FL1", FL1).then(() => {
        updateProdLineUDP(ItemDesc, "eCIL_LineVersion", LineVersion).then(
          () => {
            cellValue(e.row.rowIndex, "FL1", FL1);
            cellValue(e.row.rowIndex, "LineVersion", LineVersion);
            saveEditData();

            displayPreload(false);
            this.refGridEditMode.current.instance.cancelEditData();
          }
        );
      });
    }

    if (level === 2) {
      displayPreload(true);

      var line = data.find((f) => f.Id === e.row.data.ParentId).LineDesc;

      updateProdUnitUDP(line, ItemDesc, "FL2", FL2).then(() => {
        cellValue(e.row.rowIndex, "FL2", FL2);
        saveEditData();

        displayPreload(false);
        this.refGridEditMode.current.instance.cancelEditData();
      });
    }

    if (level === 3) {
      displayPreload(true);

      let line = data.find(
        (f) => f.Id === data.find((f) => f.Id === e.row.data.ParentId).ParentId
      ).LineDesc;

      let ind = e.row.rowIndex;

      updateProdUnitUDP(line, ItemDesc, "FL3", FL3).then(() => {
        updateProdUnitUDP(
          line,
          ItemDesc,
          "eCIL_ModuleFeatureVersion",
          ModuleFeatureVersion
        ).then(() => {
          cellValue(ind, "FL3", FL3);
          cellValue(ind, "ModuleFeatureVersion", ModuleFeatureVersion);
          saveEditData();

          displayPreload(false);
          this.refGridEditMode.current.instance.cancelEditData();
        });
      });
    }

    if (level === 4) {
      displayPreload(true);

      let line = data.find(
        (f) =>
          f.Id ===
          data.find(
            (f) =>
              f.Id === data.find((f) => f.Id === e.row.data.ParentId).ParentId
          ).ParentId
      ).LineDesc;

      let unit = data.find((f) => f.Id === e.row.data.ParentId).SlaveUnitDesc;

      updateProdGroupUDP(line, unit, ItemDesc, "FL4", FL4).then(() => {
        cellValue(e.row.rowIndex, "FL4", FL4);
        saveEditData();

        displayPreload(false);
        this.refGridEditMode.current.instance.cancelEditData();
      });
    }
    this.setIdEditMode();
  };

  onClickRefreshGrid = () => {
    if (this.state.plantModel.departments.length > 0) {
      let grid = this.refGrid.current.instance;

      displayPreload(true);
      getTasksPlantModelEditList(
        this.state.plantModel.departments.join(",")
      ).then((response) =>
        this.setState(
          {
            data: response,
            cellsEdited: [],
          },
          () => {
            var selectedKeys = grid.getSelectedRowKeys();
            grid.deselectRows(selectedKeys);
            displayPreload(false);
          }
        )
      );
    } else if (this.state.fl.fl1.length > 0) {
      let grid = this.refGrid.current.instance;
      let { fl1 } = this.state.fl;
      displayPreload(true);
      getTasksFLEditList(fl1.join(",")).then((response) =>
        this.setState(
          {
            data: response,
            localFilterGrid: filterGrid(this.state),
          },
          () => {
            var selectedKeys = grid.getSelectedRowKeys();
            grid.deselectRows(selectedKeys);
            displayPreload(false);
          }
        )
      );
    }
  };

  onRdgCustomViewChange = (e) => {
    const { customsViews, customViewActive } = this.state;

    var customViewDetail = customsViews.find(
      (cv) => cv.ViewDescription === customViewActive
    );

    this.setState({ customViewRdgOption: e.value });
    document.querySelector("[name=customViewName]").value =
      e.value !== "NewView" ? customViewDetail.ViewDescription : "";
    this.setState({
      cvInputLength: document.querySelector("[name=customViewName]").value
        .length,
    });
  };

  customizeViewListItems = () => {
    const { t } = this.props;
    const { customsViews, customViewActive } = this.state;

    let customViewDetail =
      customsViews?.find((cv) => cv.ViewDescription === customViewActive) ?? [];
    let views = customsViews || [];

    return [
      {
        id: -1,
        text: t("Save Custom View"),
        icon: getIcon(icons.save),
      },
      {
        id: -2,
        text: t("Delete Custom View"),
        icon: getIcon(icons.close),
        disabled: customViewDetail?.ViewType !== 99,
      },
      { html: "<hr/>", disabled: true },
      ...views
        .filter((cv) => cv.ViewType !== 99)
        .map((cv) => {
          return {
            id: cv.UPId,
            text: cv.ViewDescription,
            icon: cv.ViewDescription === customViewActive ? "check" : "empty",
          };
        }),
      {
        html: "<hr/>",
        disabled: true,
        visible: views.filter((cv) => cv.ViewType === 99).length > 0,
      },
      ...views
        .filter((cv) => cv.ViewType === 99)
        .map((cv) => {
          return {
            id: cv.UPId,
            text: cv.ViewDescription,
            icon: cv.ViewDescription === customViewActive ? "check" : "empty",
          };
        }),
    ];
  };

  cellsEditedColorCoding = (e) => {
    var grid = e.component;
    // var selectedKeys = grid.getSelectedRowKeys();
    // grid.deselectRows(selectedKeys);

    var cellsEdited = this.state.cellsEdited;
    cellsEdited.forEach((item) => {
      item.cells.forEach((cell) => {
        if (cell !== "Status") {
          var rowIndex = grid.getRowIndexByKey(item.key);
          var elem = grid.getCellElement(rowIndex, cell);
          // if (elem !== undefined) elem.style.background = "#ffa500";
          if (elem !== undefined) elem.classList.add(styles.editedCell);
        }
      });
    });
    this.setIdsGridComponents();
  };

  getEditModeLevel = () => {
    const { lines, units, workcells, groups } = this.state.plantModel;

    return groups.length
      ? 4
      : workcells.length
      ? 3
      : units.length
      ? 2
      : lines.length
      ? 1
      : 0;
  };

  render() {
    const { t } = this.props;
    const globalAccessLevel = getUserRole();
    const {
      chkEditMode,
      tasksMgmtFilterGroup,
      // columnHidingEnabled,
      // columnResizingMode,
      departments,
      lines,
      units,
      workcells,
      groups,
      fl1,
      fl2,
      fl3,
      fl4,
      plantModel,
      fl,
      data,
      dataRawFormat,
      showTaskEditor,
      customsViews,
      customViewActive,
      customViewDialogOpened,
      customViewRdgOption,
      loading,
      localFilterGrid,
      localFilterGridTasksEditMode,
    } = this.state;

    var customViewDetail = customsViews?.find(
      (cv) => cv?.ViewDescription === customViewActive
    );

    return (
      <React.Fragment>
        <div className={styles.container}>
          <Card id="crdFilters" hidden={!this.state.showFilters}>
            <Filters
              t={t}
              store={{
                departments,
                lines,
                units,
                workcells,
                groups,
                fl1,
                fl2,
                fl3,
                fl4,
              }}
              plantModel={plantModel}
              fl={fl}
              loading={loading}
              chkEditMode={chkEditMode}
              tasksMgmtFilterGroup={tasksMgmtFilterGroup}
              handlerSelectPlantModel={this.handlerSelectPlantModel}
              handlerSelectFL={this.handlerSelectFL}
              handlerTaskMgmtFilterGroup={this.handlerTaskMgmtFilterGroup}
              handlerChkEditMode={this.handlerChkEditMode}
            />
          </Card>

          <Card id="crdTasksMgmt" autoHeight hidden={false}>
            <div className={styles.grdTasksSelection}>
              {/* Edit Mode Grid */}
              {chkEditMode && (
                <DataGrid
                  identity="grdTasksMgmtEditMode"
                  reference={this.refGridEditMode}
                  dataSource={{
                    key: "Id",
                    store: data,
                    reshapeOnPush: true,
                    filter: localFilterGridTasksEditMode,
                  }}
                  columnResizingMode="nextColumn"
                  columnHidingEnabled={false}
                  columnAutoWidth={true}
                  scrollingMode="standard"
                  onContentReady={this.setIdEditMode()}
                  columns={gridTasksEditModeColumns(this.getEditModeLevel())}
                >
                  <FilterRow visible={false} />
                  {[4].includes(globalAccessLevel) && (
                    <Editing
                      mode="row"
                      useIcons={true}
                      allowAdding={false}
                      allowUpdating={true}
                    />
                  )}
                  <Column
                    caption=""
                    type="buttons"
                    width="50px"
                    buttons={[
                      {
                        name: "edit",
                        icon: getIcon(icons.gridEdit),
                        hint: t("Edit"),
                        cssClass: "btnEditTasksMgmtEditMode",
                        visible: (e) =>
                          e.row.data.Level > 0 && e.row.isEditing !== true,
                      },
                      {
                        name: "save",
                        icon: getIcon(icons.save),
                        hint: t("Save"),
                        cssClass: "btnSaveTasksMgmtEditMode",
                        onClick: this.onClickSaveEditMode,
                      },
                      {
                        name: "cancel",
                        icon: getIcon(icons.gridRemove),
                        hint: t("Cancel"),
                        cssClass: "btnCancelTasksMgmtEditMode",
                      },
                    ]}
                  />
                </DataGrid>
              )}

              {/* Task Mgmt Grid */}
              {!chkEditMode && (
                <DataGrid
                  identity="grdTaskMgtm"
                  reference={this.refGrid}
                  dataSource={{
                    store: {
                      type: "array",
                      key: "VarId",
                      data,
                    },
                    reshapeOnPush: true,
                    filter: localFilterGrid,
                  }}
                  onContentReady={this.cellsEditedColorCoding}
                  onAdaptiveDetailRowPreparing={(e) => {
                    e.formOptions.items = [
                      ...e.formOptions.items,
                      {
                        // caption: "",
                        itemType: "group",
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
                  // columnResizingMode={columnResizingMode}
                  // columnHidingEnabled={columnHidingEnabled}
                  // columnAutoWidth={true}
                  columnResizingMode="widget"
                  columnHidingEnabled={false}
                  columnAutoWidth={true}
                  scrollingMode="standard"
                  highlightChanges={true}
                  onToolbarPreparing={(e) =>
                    gridTasksToolbarPreparing(
                      e,
                      t,
                      this.handlerTaskEditor,
                      this.onClickEditMultipleTasks,
                      this.onClickDeleteMultipleTasks,
                      this.onClickSaveChanges,
                      this.onClickCustomizeView,
                      this.onClickRefreshGrid,
                      this.onClickQuickPrint,
                      this.onClickExportToExcel,
                      this.onClickExportToPDF,
                      this.onClickExportRawDataFormat,
                      this.customizeViewListItems
                    )
                  }
                  onSelectionChanged={() =>
                    gridTasksSetButtonsState(this.refGrid)
                  }
                  // onCellPrepared={this.onCellPrepared}
                  // onRowPrepared={this.onRowPrepared}
                  columns={gridTasksColumns(t)}
                >
                  <SearchPanel visible={false} />
                  <ColumnChooser
                    enabled={true}
                    mode={isTablet() ? "select" : "dragAndDrop"}
                  />
                  <Export enabled={false} fileName="gvTasks" />
                  <GroupPanel visible={true} />
                  <Grouping autoExpandAll={true} contextMenuEnabled={false} />
                  <FilterRow visible={true} applyFilter="auto" />
                  <FilterPanel filterEnabled={true} />
                  <Paging enabled={true} pageSize={20} />
                  <Pager
                    showPageSizeSelector={false}
                    showNavigationButtons={false}
                    showInfo={true}
                    visible={true}
                  />
                  {[4].includes(globalAccessLevel) && (
                    <Selection
                      mode="multiple"
                      showCheckBoxesMode="always"
                      width="80px"
                    />
                  )}
                  <Column
                    caption={t("Action")}
                    type="buttons"
                    buttons={[
                      {
                        icon: getIcon(icons.gridCopy),
                        hint: t("Duplicate a single task"),
                        cssClass: "btnDuplicateTasksMgmt",
                        onClick: this.onClickDuplicateSingleTask,
                        visible: (e) => e.row.data.Status !== "Obsolete",
                      },
                      {
                        icon: getIcon(icons.gridEdit),
                        hint: t("Edit a single task"),
                        cssClass: "btnEditTasksMgmt",
                        onClick: this.onClickEditSingleTask,
                        visible: (e) => e.row.data.Status !== "Obsolete",
                      },
                      {
                        icon: getIcon(icons.gridRemove),
                        hint: t("Obsolete a single task"),
                        cssClass: "btnObsoleteTasksMgmt",
                        onClick: this.onClickDeleteSingleTask,
                        visible: (e) => e.row.data.Status !== "Obsolete",
                      },
                    ]}
                  />
                </DataGrid>
              )}
            </div>
            <div className={styles.rawDataGrid}>
              <DataGrid
                identity="grdTasksMgmtRawData"
                reference={this.refGridRawData}
                // dataSource={dataRawFormat}
                dataSource={{
                  store: {
                    type: "array",
                    data: dataRawFormat,
                  },
                  reshapeOnPush: true,
                  filter: filterGrid(this.state),
                }}
                columnAutoWidth={true}
                columns={gridRawDataFormatColumns()}
              >
                <Export enabled={false} fileName="gvTasks" />
              </DataGrid>
            </div>
          </Card>
        </div>

        {showTaskEditor && (
          <div
            className={[styles.container, styles.container_taskEditor].join(
              " "
            )}
          >
            <Card id="crdTasksMgmtEditor" autoHeight>
              <TaskEditor
                t={t}
                aspectedSite={this.state.aspectedSite}
                taskMode={this.state.taskMode}
                taskSelected={Object.assign({}, this.state.taskSelected)}
                addTask={this.onClickAddTask}
                updateTask={this.onClickUpdateTask}
                updateMultipleTasks={this.onClickUpdataMultipleTasks}
                handlerTaskEditor={this.handlerTaskEditor}
              />
            </Card>
          </div>
        )}

        <Popup
          visible={customViewDialogOpened}
          onHiding={this.onClickCloseCustomViewDialog}
          dragEnabled={false}
          closeOnOutsideClick={true}
          showTitle={true}
          title={t("Save Custom View")}
          showCloseButton={false}
          width="350px"
          height="185px"
        >
          <RadioGroup
            ref={this.refRdgCustomView}
            value={customViewRdgOption}
            valueExpr="value"
            onValueChanged={this.onRdgCustomViewChange}
            items={[
              {
                text: t("Save Current View"),
                value: "CurrentView",
                disabled: customViewDetail?.ViewType !== 99,
              },
              {
                text: t("Save New View"),
                value: "NewView",
                disabled: false,
                visible: true,
              },
            ]}
          />
          <Input
            id="txtTasksMgmtCustomView"
            type="text"
            name="customViewName"
            border
            defaultValue=""
            onChange={(e) =>
              this.setState({ cvInputLength: e.target.value.length })
            }
            maxLength={40}
          />
          <div id="viewDescCharRemaining">
            {40 - this.state.cvInputLength} {t("Characters Remaining")}
          </div>
          <Button
            id="btnSaveCustomView"
            text={t("Save")}
            onClick={this.onClickSaveCustomView}
          />
          <Button
            id="btnCloseCustomView"
            text={t("Close")}
            onClick={this.onClickCloseCustomViewDialog}
          />
        </Popup>
      </React.Fragment>
    );
  }
}

export default memo(TasksManagement);
