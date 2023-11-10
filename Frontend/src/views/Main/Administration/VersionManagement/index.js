import React, { PureComponent } from "react";
import Card from "../../../../components/Card";
import Popup from "../../../../components/Popup";
import SelectBox from "../../../../components/SelectBox";
import RadioGroup from "../../../../components/RadioGroup";
import Input from "../../../../components/Input";
import DropDownList from "../../../../components/DropDownList";
import Button from "../../../../components/Button";
import MasterUnitAssinment from "./subs/MasterUnitAssignment";
import { confirm } from "devextreme/ui/dialog";
import { displayPreload } from "../../../../components/Framework/Preload";
import icons from "../../../../resources/icons";
import { showMsg, warning } from "../../../../services/notification";
import DataGrid, {
  Column,
  FilterRow,
  Paging,
  Pager,
  Export,
  Grouping,
  GroupPanel,
  LoadPanel,
  SearchPanel,
  ColumnChooser,
  FilterPanel,
  Selection,
  Summary,
  TotalItem,
} from "devextreme-react/ui/data-grid";
import { Accordion, Item } from "devextreme-react/ui/accordion";
import { FileUploader } from "devextreme-react/ui/file-uploader";
import { getUserId } from "../../../../services/auth";
import {
  getLines,
  getUnits,
  getWorkcells,
  updateProdLineUDP,
  updateProdUnitUDP,
} from "../../../../services/plantModel";
import { saveTasksVersionMgmt } from "../../../../services/tasks";
import {
  readandValidateRawDatafile,
  readProficyData,
  validateProficyPlantModelConfiguration,
  addNewModulestoPlantModelDataSource,
  compareRawDataAndProficy,
  taskToUpdate,
  getLineVersionStatistics,
  getModuleVersionStatistics,
  saveAndUploadExcelFile,
  deleteFile,
} from "../../../../services/versionManagement";
import {
  getCustomView,
  saveCustomView,
  deleteCustomView,
} from "../../../../services/customView";
import {
  gridTasksUpdatesColumns,
  gridTaskUpdateToolbarPreparing,
  getDataSourceComparisionProgress,
  gridErrorColumns,
} from "./options";
import {
  generateExportDocument,
  getHtmlElementIcon,
  getIcon,
  setIdsByClassName,
} from "../../../../utils";
import { error } from "../../../../services/notification";
import { requestSuccess } from "../../../../utils";
import styles from "./styles.module.scss";

class VersionManagement extends PureComponent {
  constructor(props) {
    super(props);
    this.refGridComparision = React.createRef();
    this.refGridTaskUpdate = React.createRef();
    this.refGridLineVersion = React.createRef();
    this.refGridModuleVersion = React.createRef();
    this.refAccordion = React.createRef();
    this.refFileUploader = React.createRef();

    this.onSelectedFilesChanged = this.onSelectedFilesChanged.bind(this);

    this.filterOperations = ["contains", "=", "<>"];

    this.state = {
      tasksDS: [],
      linesDS: [],
      unitsDS: [],
      modulesDS: [],
      compareDS: [],
      unitsForaLine: [],
      plantModelDS: [],
      errorStep1_DS: [],
      errorStep2_DS: [],
      errorStep3_DS: "",
      errorStep4_DS: "",
      errorMesageStep5: "",
      taskUpdateDS: [],
      rowsMasterAssignmentUpdated: [],
      lineVersionDS: [],
      moduleVersionsDS: [],
      selected: {
        lines: [],
        units: [],
        modules: [],
      },
      customsViews: [],
      customViewActive: "Plant Model View",
      customViewDialogOpened: false,
      customViewRdgOption: "NewView",

      disableLineSection: true,
      disableErrorSection: true,
      disableVersionSection: true,
      disableTaskSection: true,

      showComparePopup: false,
      showMasterUnitAssignmentPopup: false,
      fileSelected: "",
      versionLevel: "By Line",
      path: "",
    };
  }

  componentDidMount = () => {
    window.addEventListener("resize", this.updateSize);
    displayPreload(true);
    getLines().then((response) =>
      this.setState({ linesDS: response }, () => displayPreload(false))
    );

    getCustomView("VersionManagement").then((response) => {
      this.setState({ customsViews: response });
    });
  };

  componentDidUpdate = () => {
    setIdsByClassName([
      "flpFileUpload",
      {
        idContainer: "sboLinesVersionMgmt",
        tagName: "input",
        ids: ["txtSearchsboLinesVersionMgmt"],
      },
      {
        idContainer: "sboUnitsVersionMgmt",
        tagName: "input",
        ids: ["txtSearchsboUnitsVersionMgmt"],
      },
      {
        idContainer: "sboModulesVersionMgmt",
        tagName: "input",
        ids: ["txtSearchsboModulesVersionMgmt"],
      },
    ]);
  };

  setIdsTasksUpdateGridComponents = () => {
    setIdsByClassName([
      "btnSaveChangesVersionMgmt",
      "btnCustomizeVersionMgmt",
      {
        class: "dx-datagrid-column-chooser-button",
        ids: ["btnColumnChooserTaskUpdateVersionMgmt"],
      },
      "btnExcelExportVersionMgmt",
      "btnPdfExportVersionMgmt",
      // Input search
      {
        idContainer: "grdTasksUpdate",
        class: "dx-texteditor-input",
        ids: ["txtSearchGrdTasksUpdate"],
        same: true,
      },
      // Checkbox rows
      {
        idContainer: "grdTasksUpdate",
        class: "dx-checkbox-container",
        ids: ["chkGrdTasksUpdateVersionMgmt"],
        same: true,
      },
      {
        idContainer: "grdTasksUpdate",
        class: "dx-datagrid-drag-action",
        ids: ["btnColumnHeaderDragActionGrdTasksUpdate"],
        same: true,
      },
      {
        idContainer: "grdTasksUpdate",
        class: "dx-column-indicators",
        ids: ["btnColumnHeaderFilterOptionsGrdTasksUpdate"],
        same: true,
      },
      {
        idContainer: "grdTasksUpdate",
        class: "dx-icon dx-icon-filter-operation-default",
        ids: ["btnColumnHeaderTypeOfSearchGrdTasksUpdate"],
        same: true,
      },
      {
        idContainer: "grdTasksUpdate",
        class: "dx-page",
        ids: ["btnPageGrdTasksUpdate"],
        same: true,
      },
    ]);
  };

  uploadFile = () => {
    let file = this.state.fileSelected;
    const formData = new FormData();
    formData.append("file", file);
    const config = {
      headers: {
        "content-type": "multipart/form-data",
      },
    };
    return saveAndUploadExcelFile(formData, config);
  };

  showLineSection = () => {
    this.setState({
      disableLineSection: false,
    });
    this.refAccordion.current.instance.expandItem(1);
  };

  showVersionSection = () => {
    this.setState({
      disableVersionSection: false,
    });
    this.refAccordion.current.instance.expandItem(4);
  };

  showTasksUpdateSection = () => {
    this.refAccordion.current.instance.expandItem(3);
  };

  onSelectedFilesChanged = (e) => {
    let refGrid = this.refGridTaskUpdate?.current;

    this.setState(
      {
        fileSelected: e.value[0],
      },
      () => {
        if (refGrid !== null) {
          refGrid.instance.clearFilter();
          refGrid.instance.clearSelection();
        }
      }
    );
  };

  prepareData = () => {
    let lineLevelComparision = true;
    let modulelevelcomparision = false;
    let moduleId = 0;
    let lineId =
      this.state.selected.lines[this.state.selected.lines.length - 1];

    if (this.state.selected.modules.length !== 0) {
      moduleId = this.state.selected.modules;
      lineLevelComparision = false;
      modulelevelcomparision = true;
    }

    return {
      lineLevelComparision,
      modulelevelcomparision,
      lineId,
      moduleId,
    };
  };

  startCompare = () => {
    let refAccordion = this.refAccordion.current.instance;
    let { fileSelected, selected, versionLevel } = this.state;
    const t = this.props.t;
    if (fileSelected === "") {
      showMsg("warning", t("Please, upload a file"));
      refAccordion.expandItem(0);
    } else if (selected.lines.length === 0) {
      showMsg("warning", t("Please, select at least one line"));
      refAccordion.expandItem(1);
    } else if (selected.modules.length === 0 && versionLevel === "By Module") {
      showMsg("warning", t("Please, select at least one taskleast one module"));
      refAccordion.expandItem(1);
    } else {
      getDataSourceComparisionProgress.forEach((item) => {
        item.Status = "waiting";
        item.Information = "";
      });

      this.setState(
        {
          compareDS: [],
          taskUpdateDS: [],
          fileSelected: "",
          lineVersionDS: [],
          moduleVersionsDS: [],
          errorStep1_DS: [],
          errorStep2_DS: [],
          errorStep3_DS: "",
          errorStep4_DS: "",
          errorMesageStep5: "",
          disableErrorSection: true,
          showComparePopup: true,
          disableTaskSection: true,
        },
        () => {
          setTimeout(() => {
            let refFileUploader = this.refFileUploader.current.instance;
            refFileUploader._files[0].value = {};
            refFileUploader._$fileInput[0].value = "";
            refFileUploader._refresh();
          }, 500);
        }
      );

      let { lineLevelComparision, modulelevelcomparision, lineId, moduleId } =
        this.prepareData();

      // 1
      getDataSourceComparisionProgress[0].Status = "Waiting";
      this.uploadFile().then((res) => {
        if (res === undefined) return;
        var path = res.data;
        this.setState({ path });

        if (res.status === 200) {
          getDataSourceComparisionProgress[0].Status = "Success";
          getDataSourceComparisionProgress[0].Information = "Success";
          this.reloadComparisionDataSource();
        } else {
          getDataSourceComparisionProgress[0].Status = "Error";
          getDataSourceComparisionProgress[0].Information = res;
          this.reloadComparisionDataSource();

          deleteFile(path);
          return;
        }

        // 2
        getDataSourceComparisionProgress[1].Status = "Waiting";
        readandValidateRawDatafile(
          path,
          "Sheet",
          lineLevelComparision,
          modulelevelcomparision
        ).then((response) => {
          if (response === undefined) return;
          if (response === null) {
            getDataSourceComparisionProgress[1].Status = "Success";
            getDataSourceComparisionProgress[1].Information = "Success";
            this.reloadComparisionDataSource();
          } else {
            getDataSourceComparisionProgress[1].Status = "Error";
            getDataSourceComparisionProgress[1].Information = "Error";
            this.reloadComparisionDataSource();

            deleteFile(path);

            // ERROR SECION
            this.setState({
              errorStep2_DS: this.loadErrorSection(response),
              disableErrorSection: false,
            });
            setTimeout(() => {
              this.onHidingPopup();
              refAccordion.expandItem(2);
            }, 1000);
            return;
            // END ERROR SECION
          }

          // 3
          getDataSourceComparisionProgress[2].Status = "Waiting";
          readProficyData(
            path,
            modulelevelcomparision,
            lineLevelComparision,
            lineId,
            moduleId
          ).then((response) => {
            if (response === undefined) return;
            if (response === null) {
              getDataSourceComparisionProgress[2].Status = "Success";
              getDataSourceComparisionProgress[2].Information = "Success";
              this.reloadComparisionDataSource();
            } else {
              getDataSourceComparisionProgress[2].Status = "Error";
              getDataSourceComparisionProgress[2].Information = "Error";
              this.reloadComparisionDataSource();

              deleteFile(path);

              // ERROR SECION
              this.setState({
                errorStep3_DS: response,
                disableErrorSection: false,
              });
              setTimeout(() => {
                this.onHidingPopup();
                refAccordion.expandItem(2);
              }, 1000);
              return;
              // END ERROR SECION
            }

            this.step4(
              path,
              lineLevelComparision,
              modulelevelcomparision,
              lineId,
              moduleId
            );
          });
        });
      });
    }
  };

  step4 = (
    path,
    lineLevelComparision,
    modulelevelcomparision,
    lineId,
    moduleId
  ) => {
    let refAccordion = this.refAccordion.current.instance;

    getDataSourceComparisionProgress[3].Status = "Waiting";
    validateProficyPlantModelConfiguration(
      path,
      lineLevelComparision,
      modulelevelcomparision,
      lineId,
      moduleId,
      "Sheet"
    ).then((response) => {
      if (response === undefined) return;
      var resp = [];
      response === null ? (resp[0] = "Success") : (resp = response);
      if (resp[0] === "Success") {
        getUnits(lineId).then((units) => {
          this.setState({ unitsForaLine: units });
        });
        addNewModulestoPlantModelDataSource(
          path,
          lineLevelComparision,
          modulelevelcomparision,
          lineId,
          moduleId,
          "Sheet"
        ).then((plantModel) => {
          getDataSourceComparisionProgress[3].Status = "Success";
          getDataSourceComparisionProgress[3].Information = "Success";
          this.reloadComparisionDataSource();
          if (plantModel.length !== 0) {
            displayPreload(true);
            this.setState(
              {
                showMasterUnitAssignmentPopup: true,
                plantModelDS: plantModel,
              },
              () => {
                displayPreload(false);
              }
            );
            return;
          } else {
            this.step5(
              lineLevelComparision,
              modulelevelcomparision,
              lineId,
              moduleId
            );
          }
        });
      } else {
        getDataSourceComparisionProgress[3].Status = "Error";
        getDataSourceComparisionProgress[3].Information = "Error";
        this.reloadComparisionDataSource();

        deleteFile(path);

        // ERROR SECTION
        let newArray = [];
        resp.map((item, index) =>
          newArray.push({
            rowNbr: index + 2,
            error_message: item,
          })
        );
        this.setState({
          errorStep4_DS: newArray,
          disableErrorSection: false,
        });
        setTimeout(() => {
          this.onHidingPopup();
          refAccordion.expandItem(2);
        }, 1000);
        return;
        // END ERROR SECTION
      }
    });
  };

  step5 = (lineLevelComparision, modulelevelcomparision, lineId, moduleId) => {
    let t = this.props.t;
    let path = this.state.path;
    let refAccordion = this.refAccordion.current.instance;

    getDataSourceComparisionProgress[4].Status = "Waiting";
    compareRawDataAndProficy(
      path,
      modulelevelcomparision,
      "Sheet",
      lineId,
      moduleId
    ).then((response) => {
      if (response === undefined) return;
      if (response === null) {
        getDataSourceComparisionProgress[4].Status = "Success";
        getDataSourceComparisionProgress[4].Information = t("Success");
        this.step6(
          path,
          lineLevelComparision,
          modulelevelcomparision,
          lineId,
          moduleId
        );
        this.reloadComparisionDataSource();
      } else {
        getDataSourceComparisionProgress[4].Status = "Error";
        getDataSourceComparisionProgress[4].Information = response;
        this.reloadComparisionDataSource();

        deleteFile(path);

        // ERROR SECION
        this.setState({
          errorMesageStep5: response,
          disableErrorSection: false,
        });
        setTimeout(() => {
          this.onHidingPopup();
          refAccordion.expandItem(2);
        }, 1000);
        return;
        // END ERROR SECION
      }
    });
  };

  step6 = (
    path,
    lineLevelComparision,
    modulelevelcomparision,
    lineId,
    moduleId
  ) => {
    let t = this.props.t;
    getDataSourceComparisionProgress[5].Status = "Waiting";
    taskToUpdate(
      path,
      "Sheet",
      lineLevelComparision,
      modulelevelcomparision,
      lineId,
      moduleId
    ).then((taskToUpdateResponse) => {
      getDataSourceComparisionProgress[5].Status = "Success";
      getDataSourceComparisionProgress[5].Information = t("Success");
      this.reloadComparisionDataSource();

      // Auto generate an Id for all the tasks to use for own purpose
      taskToUpdateResponse.forEach((row, index) => {
        row.VMLocalId = index;
      });

      if (lineLevelComparision) {
        // Line Information
        getLineVersionStatistics(
          path,
          "Sheet",
          lineLevelComparision,
          lineId
        ).then((response) => {
          if (response === undefined) return;
          const lineVersionDS = response;
          const moduleVersionsDS = this.clearDataSource(
            response[0]?.ModuleVersion ?? []
          );
          moduleVersionsDS.map((m) => m);
          this.setState({
            lineVersionDS,
            moduleVersionsDS,
          });
          this.AllStepsSuccess(taskToUpdateResponse);

          deleteFile(path);
        });
      } else {
        // Module Information
        getModuleVersionStatistics(
          path,
          "Sheet",
          modulelevelcomparision,
          moduleId
        ).then((response) => {
          if (response === undefined) return;
          const moduleVersionsDS = this.clearDataSource(response);
          this.setState({
            moduleVersionsDS,
          });
          this.AllStepsSuccess(taskToUpdateResponse);

          deleteFile(path);
        });
      }
    });
  };

  clearDataSource = (ds) => {
    ds.forEach((currentItem) => {
      Object.keys(currentItem).forEach((x) => {
        if (currentItem[x] !== null) {
          let value = currentItem[x].toString();
          if (value.includes("U:")) {
            currentItem[x] = value.replace("U:", "");
          }
        }
      });
    });
    return ds;
  };

  AllStepsSuccess = (response) => {
    displayPreload(true);
    this.onHidingPopup();
    this.refAccordion.current.instance.expandItem(3);
    this.setState(
      {
        disableTaskSection: false,
        disableVersionSection: false,
        taskUpdateDS: response,
      },
      () => {
        this.updateTasksToUpdateDS();
        this.refGridTaskUpdate.current.instance.refresh();
        displayPreload(false);
      }
    );
  };

  loadErrorSection = (response) => {
    let errorArray = [];
    let errorObj = {};
    for (let i = 0; i < response.length; i++) {
      for (var key in response[i]) {
        if (response[i][key] !== null) {
          errorObj = {
            rowNbr: i + 2,
            columnName: key,
            errorMessage: response[i][key],
          };
          errorArray.push(errorObj);
        }
      }
    }
    return errorArray;
  };

  reloadComparisionDataSource = () => {
    this.setState(
      {
        compareDS: getDataSourceComparisionProgress,
      },
      () => this.refGridComparision.current.instance.refresh()
    );
  };

  handlerversionLevel = (value) => {
    this.setState({
      versionLevel: value,
      selected: {
        lines: [],
        units: [],
        modules: [],
      },
      unitsDS: [],
      modulesDS: [],
    });
  };

  handleSelectBox = (key, values) => {
    let versionLevel = this.state.versionLevel;
    if (versionLevel === "By Module") {
      if (key === "lines") {
        getUnits(values).then((response) =>
          this.setState({
            unitsDS: response,
          })
        );
      } else if (key === "units") {
        getWorkcells(values).then((response) =>
          this.setState({
            modulesDS: response,
          })
        );
      }
    }

    this.setState({
      selected: {
        ...this.state.selected,
        [key]: values,
      },
    });
  };

  onHidingPopup = () => {
    this.setState({
      showComparePopup: false,
      compareDS: [],
    });
  };

  onClickExportToPDF = () => {
    var fontReady = document
      .getElementById("root")
      .getAttribute("data-pdf-font-ready");

    if (fontReady === "false" && localStorage.i18nextLng === "zh") {
      warning(
        "The font to export to pdf is not already loaded, please wait a seconds and try again"
      );
    } else {
      var columns = this.refGridTaskUpdate.current.instance
        .getVisibleColumns()
        .reduce(
          (obj, item) => (
            // eslint-disable-next-line no-sequences
            (obj[item.dataField] = this.props.t(item.caption)), obj
          ),
          {}
        );

      var dataSource = this.refGridTaskUpdate.current.instance
        .getDataSource()
        .store()._array;

      var pdfdoc = generateExportDocument([columns], dataSource);
      pdfdoc.save("gvTasks.pdf");
    }
  };

  onClickExportToExcel = () => {
    let grid = this.refGridTaskUpdate.current.instance;
    grid.exportToExcel(false);
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
            getCustomView("VersionManagement").then((response) =>
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
      this.refGridTaskUpdate.current.instance.state(
        JSON.parse(customView.Data)
      );
      this.setState({ customViewActive: customView.ViewDescription });
    }
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
        icon: getIcon(icons.remove),
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

  onClickSaveCustomView = () => {
    const { customsViews, customViewActive, customViewRdgOption } = this.state;

    var customViewDetail = customsViews.find(
      (cv) => cv.ViewDescription === customViewActive
    );

    let viewClass = {
      UPId: customViewRdgOption === "NewView" ? 0 : customViewDetail?.UPId,
      ViewType: 99,
      UserId: getUserId(),
      ViewDescription: document.querySelector("[name=customViewName]").value,
      Data: JSON.stringify(this.refGridTaskUpdate.current.instance.state()),
      ScreenDescription: "VersionManagement",
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
      getCustomView("VersionManagement").then((response) =>
        this.setState({ customsViews: response, customViewDialogOpened: false })
      )
    );
  };

  onClickCloseCustomViewDialog = () => {
    this.setState({ customViewDialogOpened: false });
  };

  onRdgCustomViewChange = (e) => {
    const { customsViews, customViewActive } = this.state;

    var customViewDetail = customsViews.find(
      (cv) => cv.ViewDescription === customViewActive
    );

    this.setState({ customViewRdgOption: e.value });
    document.querySelector("[name=customViewName]").value =
      e.value !== "NewView" ? customViewDetail.ViewDescription : "";
  };

  onClickSaveChanges = () => {
    let refGrid = this.refGridTaskUpdate.current.instance;
    let tasksUpdateSelectedRows = [...refGrid.getSelectedRowsData()];
    let result = [];

    // Replace the "U:" and clear the succes_failure only in data source for SAVE Method.
    // Not in datagrid for keep the yellow color.
    tasksUpdateSelectedRows.forEach((currentItem) => {
      var item = Object.assign({}, currentItem);
      Object.keys(item).forEach((x) => {
        item["succes_failure"] = "";
        if (item[x] !== null) {
          let value = item[x].toString();
          if (value.includes("U:")) {
            item[x] = value.replace("U:", "");
          }
        }
      });
      result.push(item);
    });

    if (refGrid.getSelectedRowsData().length > 0) {
      displayPreload(true);

      saveTasksVersionMgmt(result).then((response) => {
        let taskUpdateDS = this.state.taskUpdateDS;

        let errorExist = response.find(
          (task) => task.succes_failure !== "Success"
        );
        if (errorExist) error("Error on save", "");
        else requestSuccess();

        // Use the key VMLocalId to match the data that we send with the response
        response.forEach((resp) => {
          let item = taskUpdateDS.find(
            (task) => task.VMLocalId === resp.VMLocalId
          );

          if (item !== undefined) item.succes_failure = resp.succes_failure;
        });

        refGrid.clearSelection();
        refGrid.columnOption("succes_failure", "filterOperations", ["<>"]);
        refGrid.columnOption("succes_failure", "filterValues", [""]);
        refGrid.columnOption("succes_failure", "filterType", "exclude");

        //update UDP value for LineVersion and ModuleVersion
        const { versionLevel, lineVersionDS, moduleVersionsDS } = this.state;
        if (versionLevel === "By Line") {
          let lineVersion = lineVersionDS[lineVersionDS.length - 1];
          if (lineVersion.CurrentVersion !== lineVersion.NewVersion) {
            const { LineDesc, NewVersion: NewLineVersion } = lineVersion;

            if (lineVersion.CurrentVersion !== null) {
              updateProdLineUDP(
                LineDesc,
                "eCIL_LineVersion",
                NewLineVersion
              ).then(() => {
                let moduleVersion =
                  moduleVersionsDS[moduleVersionsDS.length - 1];
                if (moduleVersion.CurrentVersion !== moduleVersion.NewVersion) {
                  if (moduleVersion.CurrentVersion !== null) {
                    const { ModuleDesc, NewVersion: NewModuleVersion } =
                      moduleVersion;
                    updateProdUnitUDP(
                      LineDesc,
                      ModuleDesc,
                      "eCIL_ModuleFeatureVersion",
                      NewModuleVersion
                    );
                  }
                }
              });
            }
          }
        } else {
          let moduleVersion = moduleVersionsDS[moduleVersionsDS.length - 1];
          if (moduleVersion.CurrentVersion !== moduleVersion.NewVersion) {
            if (moduleVersion.CurrentVersion !== null) {
              const { ModuleDesc, NewVersion: NewModuleVersion } =
                moduleVersion;
              updateProdUnitUDP(
                moduleVersion.LineDesc,
                ModuleDesc,
                "eCIL_ModuleFeatureVersion",
                NewModuleVersion
              );
            }
          }
        }

        displayPreload(false);
      });
    } else showMsg("warning", this.props.t("Please, select at least one task"));
  };

  calculateSummary = (options) => {
    if (options.name === "AddedTasksSummary") {
      if (options.summaryProcess === "start") {
        options.totalValue = 0;
      } else if (options.summaryProcess === "calculate") {
        if (options.value.Status === "Add") {
          options.totalValue = options.totalValue + 1;
        }
      }
    }
    if (options.name === "ModifiedTasksSummary") {
      if (options.summaryProcess === "start") {
        options.totalValue = 0;
      } else if (options.summaryProcess === "calculate") {
        if (options.value.Status === "Modify") {
          options.totalValue = options.totalValue + 1;
        }
      }
    }
    if (options.name === "ObsoletedTasksSummary") {
      if (options.summaryProcess === "start") {
        options.totalValue = 0;
      } else if (options.summaryProcess === "calculate") {
        if (options.value.Status === "Obsolete") {
          options.totalValue = options.totalValue + 1;
        }
      }
    }
  };

  onHidingMasterUnitAssignmentPopup = () => {
    this.setState({
      showMasterUnitAssignmentPopup: false,
    });
  };

  updateRowsMasterAssignment = (updatedRows) => {
    displayPreload(true);
    this.setState(
      {
        rowsMasterAssignmentUpdated: updatedRows,
      },
      () => {
        this.onHidingMasterUnitAssignmentPopup();
        displayPreload(false);
        let { lineLevelComparision, modulelevelcomparision, lineId, moduleId } =
          this.prepareData();
        this.step5(
          lineLevelComparision,
          modulelevelcomparision,
          lineId,
          moduleId
        );
      }
    );
  };

  updateTasksToUpdateDS = () => {
    let rowsMasterAssignmentUpdated = this.state.rowsMasterAssignmentUpdated;
    let taskUpdateDS = this.state.taskUpdateDS;

    rowsMasterAssignmentUpdated.forEach((rowUpdated) => {
      taskUpdateDS.forEach((task) => {
        if (rowUpdated.SlaveUnitDesc === task.SlaveUnitDesc.replace("U:", "")) {
          task["MasterUnitDesc"] = rowUpdated["MasterUnitDesc"];
        }
      });
    });

    this.refGridTaskUpdate.current.instance.refresh();
  };

  render() {
    const { t } = this.props;
    const {
      disableLineSection,
      disableErrorSection,
      disableVersionSection,
      disableTaskSection,
      linesDS,
      unitsDS,
      modulesDS,
      compareDS,
      unitsForaLine,
      plantModelDS,
      errorStep1_DS,
      errorStep2_DS,
      errorStep3_DS,
      errorStep4_DS,
      errorMesageStep5,
      taskUpdateDS,
      lineVersionDS,
      moduleVersionsDS,
      selected,
      versionLevel,
      showComparePopup,
      showMasterUnitAssignmentPopup,
      customsViews,
      customViewActive,
      customViewDialogOpened,
      customViewRdgOption,
    } = this.state;

    var customViewDetail = customsViews.find(
      (cv) => cv.ViewDescription === customViewActive
    );

    return (
      <Card id="crdVersionMgmt" autoHeight>
        <div>
          <div className={styles.versionLevel}>
            <label>{t("Version Level")} </label>
            <DropDownList
              id="ddnVersionLevel"
              key={"versionLevel"}
              options={[
                { Id: 1, text: t("By Line") },
                { Id: 2, text: t("By Module") },
              ]}
              onSelect={(value) => {
                this.handlerversionLevel(value);
              }}
              valueKey={"text"}
              defaultItem={null}
              value={versionLevel}
              width={250}
            />
          </div>
        </div>

        <Accordion
          id="acdVersionMgmt"
          ref={this.refAccordion}
          animationDuration={300}
        >
          <Item key="fileUpload" title={t("File Upload")}>
            <div className={styles.itemContainers}>
              <FileUploader
                name="file"
                ref={this.refFileUploader}
                multiple={false}
                uploadMode="useForm"
                accept=".xls,.xlsx"
                allowedFileExtensions={[".xlsx", ".xls"]}
                uploadFailedMessage=""
                className="flpFileUpload"
                labelText={t("or Drop file here")}
                maxFileSize={3000000}
                onValueChanged={this.onSelectedFilesChanged}
              />
              <br />
              <div className={styles.divButtons}>
                <Button
                  id="btnVersionMgmtSubmit"
                  icon="angle-right"
                  text={t("Next step")}
                  type="submit"
                  disabled={this.state.fileSelected === ""}
                  primary
                  classes={styles.nextButton}
                  onClick={this.showLineSection}
                />
              </div>
            </div>
          </Item>

          <Item
            key="lineSelection"
            title={
              versionLevel === "By Line"
                ? t("Line selection")
                : t("Module selection")
            }
            disabled={disableLineSection}
          >
            <div className={styles.itemContainers}>
              <div className={styles.multiSelectionGroup}>
                <React.Fragment>
                  <SelectBox
                    id="sboLinesVersionMgmt"
                    key={"ProductionLine"}
                    text={t("Production Line")}
                    enableSelectAll={false}
                    store={linesDS}
                    isMultiple={false}
                    className={styles.selectBox}
                    value={selected.lines}
                    onChange={(values) => this.handleSelectBox("lines", values)}
                    labelKey="LineDesc"
                    valueKey="LineId"
                    isDisable={false}
                  />
                  <SelectBox
                    id="sboUnitsVersionMgmt"
                    key={"MasterEquipment"}
                    text={t("Primary Unit")}
                    enableSelectAll={false}
                    store={unitsDS}
                    isMultiple={false}
                    className={styles.selectBox}
                    value={selected.units}
                    onChange={(values) => this.handleSelectBox("units", values)}
                    labelKey="MasterDesc"
                    valueKey="MasterId"
                    isDisable={versionLevel === "By Module" ? false : true}
                  />
                  <SelectBox
                    id="sboModulesVersionMgmt"
                    key={"Module"}
                    text={t("Module")}
                    enableSelectAll={false}
                    store={modulesDS}
                    isMultiple={false}
                    className={styles.selectBox}
                    value={selected.modules}
                    onChange={(values) =>
                      this.handleSelectBox("modules", values)
                    }
                    labelKey="SlaveDesc"
                    valueKey="SlaveId"
                    isDisable={versionLevel === "By Module" ? false : true}
                  />
                </React.Fragment>
              </div>
              <br />
              <div className={styles.divButtons}>
                <Button
                  id="btnStartCompare"
                  icon="compress"
                  text="Start Compare"
                  primary
                  disabled={selected.lines.length <= 0}
                  classes={styles.compareBtn}
                  onClick={this.startCompare}
                />
              </div>
            </div>
          </Item>

          <Item
            key="errorMessages"
            title={t("Error Messages")}
            visible={true}
            disabled={disableErrorSection}
          >
            {/* ### 1 */}
            {errorStep1_DS.length > 0 && (
              <div className={styles.itemContainers}>
                <label className={styles.subTitle}>
                  {t("Raw Data File Upload")}
                </label>
                <hr />
                <br />
                <DataGrid
                  id="grdErrorStep1"
                  dataSource={errorStep1_DS}
                  ref={this.refGridError}
                  className={styles.dataGrids}
                  width="100%"
                  height="100%"
                >
                  <Pager
                    showPageSizeSelector={false}
                    showNavigationButtons={false}
                    showInfo={true}
                    visible={true}
                  />
                  <Paging enabled={true} pageSize={10} defaultPageSize={10} />
                  <LoadPanel
                    enabled={true}
                    showIndicator={true}
                    shading={true}
                    showPane={true}
                  />
                  {gridErrorColumns.map((col, index) => (
                    <Column
                      key={index}
                      caption={t(col.caption)}
                      dataField={col.dataField}
                      alignment="center"
                    />
                  ))}
                </DataGrid>
              </div>
            )}

            {/* ### 2 */}
            {errorStep2_DS.length > 0 && (
              <div className={styles.itemContainers}>
                <label className={styles.subTitle}>
                  {t("Raw Data File Validation")}
                </label>
                <hr />
                <br />
                <DataGrid
                  id="grdErrorStep2"
                  dataSource={errorStep2_DS}
                  ref={this.refGridError}
                  className={styles.dataGrids}
                  width="100%"
                  height="100%"
                >
                  <Pager
                    showPageSizeSelector={false}
                    showNavigationButtons={false}
                    showInfo={true}
                    visible={true}
                  />
                  <Paging enabled={true} pageSize={10} defaultPageSize={10} />
                  <LoadPanel
                    enabled={true}
                    showIndicator={true}
                    shading={true}
                    showPane={true}
                  />
                  {gridErrorColumns.map((col, index) => (
                    <Column
                      key={index}
                      caption={t(col.caption)}
                      dataField={col.dataField}
                      alignment="center"
                    />
                  ))}
                </DataGrid>
              </div>
            )}

            {/* ### 3 */}
            {errorStep3_DS !== "" && (
              <div className={styles.itemContainers}>
                <label className={styles.subTitle}>
                  {t("Proficy Data Upload")}
                </label>
                <hr />
                <br />
                <label className={styles.subTitle}>
                  {t("Error Messages")}: {errorStep3_DS}
                </label>
              </div>
            )}

            {/* ### 4 */}
            {errorStep4_DS.length > 0 && (
              <div className={styles.itemContainers}>
                <br />
                <label className={styles.subTitle}>
                  {t("Proficy Plant Model Validation")}
                </label>
                <hr />
                <br />
                <DataGrid
                  id="grdErrorStep4"
                  dataSource={errorStep4_DS}
                  ref={this.refGridError}
                  className={styles.dataGrids}
                  width="100%"
                  height="100%"
                >
                  <Pager
                    showPageSizeSelector={false}
                    showNavigationButtons={false}
                    showInfo={true}
                    visible={true}
                  />
                  <Paging enabled={true} pageSize={10} defaultPageSize={10} />
                  <LoadPanel
                    enabled={true}
                    showIndicator={true}
                    shading={true}
                    showPane={true}
                  />
                  <Column
                    caption={t("Error message")}
                    dataField={"error_message"}
                    alignment="center"
                  />
                </DataGrid>
              </div>
            )}

            {/* ### 5 */}
            {errorMesageStep5 !== "" && (
              <div className={styles.itemContainers}>
                <br />
                <label className={styles.subTitle}>
                  {t("Data Comparision")}
                </label>
                <hr />
                <br />
                <label className={styles.subTitle}>
                  {t("Error message")}: {t(errorMesageStep5)}
                </label>
              </div>
            )}
          </Item>

          <Item
            key="taskUpdate"
            title={t("Tasks Update")}
            disabled={disableTaskSection}
          >
            <div className={styles.itemContainers}>
              <DataGrid
                id="grdTasksUpdate"
                key="modules"
                ref={this.refGridTaskUpdate}
                dataSource={taskUpdateDS}
                className={styles.dataGridTaskUpdate}
                noDataText={t("No difference found. Identical configuration.")}
                allowColumnReordering={true}
                allowFiltering={true}
                showBorders={false}
                allowColumnResizing={true}
                columnResizingMode={"widget"}
                rowAlternationEnabled={false}
                showColumnLines={true}
                showRowLines={true}
                headerFilter={{ visible: true }}
                columnAutoWidth={true}
                onContentReady={this.setIdsTasksUpdateGridComponents}
                onCellPrepared={(e) => {
                  if (e.rowType === "data") {
                    if (e.data.succes_failure !== "") {
                      // Hide checkbox when the field Success/Failure is not empty
                      // The checkbox column are on the position 0
                      if (e.columnIndex === 0) {
                        e.cellElement.classList.add("grid-chk-hidden");
                      }
                    }
                  }
                }}
                onToolbarPreparing={(e) =>
                  gridTaskUpdateToolbarPreparing(
                    e,
                    t,
                    this.onClickCustomizeView,
                    this.onClickSaveChanges,
                    this.onClickExportToPDF,
                    this.onClickExportToExcel,
                    this.customizeViewListItems
                  )
                }
              >
                <SearchPanel visible={false} />
                <ColumnChooser enabled={true} />
                <GroupPanel visible={true} />
                <Grouping autoExpandAll={true} contextMenuEnabled={false} />
                <Export enabled={false} fileName="gvTasks" />
                <FilterRow visible={true} applyFilter="auto" />
                <FilterPanel
                  visible={true}
                  texts={{
                    clearFilter: t("Clear Filters"),
                  }}
                />
                <Pager
                  showPageSizeSelector={false}
                  showNavigationButtons={false}
                  showInfo={true}
                  visible={true}
                />
                <Paging enabled={true} pageSize={10} defaultPageSize={10} />
                <LoadPanel
                  enabled={true}
                  showIndicator={true}
                  shading={true}
                  showPane={true}
                />
                <Selection
                  allowSelectAll={true}
                  mode="multiple"
                  showCheckBoxesMode="always"
                />
                {gridTasksUpdatesColumns.map((col, index) => {
                  if (col.dataField === "Status") {
                    return (
                      <Column
                        key={col.caption}
                        dataField={col.dataField}
                        caption={t(col.caption)}
                        allowEditing={col.allowEditing}
                        allowSearch={col.allowSearch}
                        allowFiltering={col.allowFiltering}
                        visible={col.visibility}
                        visibleIndex={col.visibleIndex}
                        showInColumnChooser={col.showInColumnChooser}
                        width={col.width || undefined}
                        cellTemplate={(container, value) => {
                          if (value.value === "Add")
                            container.style =
                              "background-color: #1bff00; text-align:center;";
                          if (value.value === "Modify")
                            container.style =
                              "background-color: #ffff00; text-align:center;";
                          if (value.value === "Obsolete")
                            container.style =
                              "background-color: #ff0000; color: white; text-align:center;";
                          let j = document.createElement("span");
                          j.appendChild(document.createTextNode(value.value));
                          container.appendChild(j);
                        }}
                      />
                    );
                  } else if (col.dataField === "succes_failure") {
                    return (
                      <Column
                        key={col.caption}
                        dataField={col.dataField}
                        caption={t(col.caption)}
                        alignment="center"
                        allowEditing={col.allowEditing}
                        allowSearch={col.allowSearch}
                        allowFiltering={col.allowFiltering}
                        visible={col.visibility}
                        visibleIndex={col.visibleIndex}
                        showInColumnChooser={col.showInColumnChooser}
                        width={col.width || undefined}
                      />
                    );
                  } else if (
                    col.dataField === "VarDesc" ||
                    col.dataField === "SlaveUnitDesc" ||
                    col.dataField === "ProductionGroupDesc" ||
                    col.dataField === "TaskLocation" ||
                    col.dataField === "TaskId" ||
                    col.dataField === "TaskType" ||
                    col.dataField === "PPE" ||
                    col.dataField === "TaskAction" ||
                    col.dataField === "TaskFreq" ||
                    col.dataField === "Frequency" ||
                    col.dataField === "FrequencyType" ||
                    col.dataField === "TestTime" ||
                    col.dataField === "Window" ||
                    col.dataField === "LongTaskName" ||
                    col.dataField === "NbrItems" ||
                    col.dataField === "Duration" ||
                    col.dataField === "NbrPeople" ||
                    col.dataField === "Criteria" ||
                    col.dataField === "Hazards" ||
                    col.dataField === "Method" ||
                    col.dataField === "Tools" ||
                    col.dataField === "Lubricant" ||
                    col.dataField === "DocumentLinkPath" ||
                    col.dataField === "DocumentLinkTitle" ||
                    col.dataField === "ScheduleScope" ||
                    col.dataField === "StartDate" ||
                    // col.dataField === "ShiftOffset" ||
                    col.dataField === "FL1" ||
                    col.dataField === "FL2" ||
                    col.dataField === "FL3" ||
                    col.dataField === "FL4"
                  ) {
                    return (
                      <Column
                        key={col.caption}
                        dataField={col.dataField}
                        caption={t(col.caption)}
                        alignment="center"
                        allowEditing={col.allowEditing}
                        allowSearch={col.allowSearch}
                        allowFiltering={col.allowFiltering}
                        visible={col.visibility}
                        visibleIndex={col.visibleIndex}
                        showInColumnChooser={col.showInColumnChooser}
                        width={col.width || undefined}
                        cellTemplate={(container, value) => {
                          if (
                            value.value !== null &&
                            value.value.toString().includes("U:")
                          ) {
                            if (value.values[1] !== "Obsolete") {
                              container.style =
                                "background-color: #ffff00; text-align:center;";
                            }

                            value.value = value.value.replace("U:", "");
                          }

                          let j = document.createElement("span");
                          j.appendChild(document.createTextNode(value.value));
                          container.appendChild(j);
                        }}
                      />
                    );
                  } else if (
                    col.dataField === "FixedFrequency" ||
                    col.dataField === "AutoPostpone"
                  ) {
                    return (
                      <Column
                        key={col.caption}
                        dataField={col.dataField}
                        caption={t(col.caption)}
                        allowEditing={col.allowEditing}
                        allowSearch={col.allowSearch}
                        allowFiltering={col.allowFiltering}
                        visible={col.visibility}
                        disabled={true}
                        visibleIndex={col.visibleIndex}
                        showInColumnChooser={col.showInColumnChooser}
                        width={col.width || undefined}
                        dataType="boolean"
                        cellTemplate={(container, value) => {
                          var checkbox = document.createElement("input");
                          checkbox.type = "checkbox";
                          checkbox.disabled = "true";

                          if (col.dataField === "FixedFrequency") {
                            let isChangedFixedFrequency =
                              value.row.data["IsChangedFixedFrequency"];
                            container.style = isChangedFixedFrequency
                              ? "background-color: #ffff00;text-align:center;"
                              : "text-align:center;";

                            checkbox.checked = value.data.FixedFrequency;
                          } else if (col.dataField === "AutoPostpone") {
                            let IsChangedAutopostponed =
                              value.row.data["IsChangedAutopostponed"];
                            container.style = IsChangedAutopostponed
                              ? "background-color: #ffff00;text-align:center;"
                              : "text-align:center;";

                            checkbox.checked = value.data.AutoPostpone;
                          }

                          container.appendChild(checkbox);
                        }}
                      />
                    );
                  } else if (col.dataField === "Active") {
                    return (
                      <Column
                        key={col.caption}
                        dataField={col.dataField}
                        caption={t(col.caption)}
                        allowEditing={col.allowEditing}
                        allowSearch={col.allowSearch}
                        allowFiltering={col.allowFiltering}
                        visible={col.visibility}
                        disabled={true}
                        visibleIndex={col.visibleIndex}
                        showInColumnChooser={col.showInColumnChooser}
                        width={col.width || undefined}
                        dataType="boolean"
                        cellTemplate={(container, value) => {
                          let isChangedActive =
                            value.row.data["IsChangedActive"];
                          container.style = isChangedActive
                            ? "background-color: #ffff00;text-align:center;"
                            : "text-align:center;";
                          var checkbox = document.createElement("input");
                          checkbox.type = "checkbox";
                          checkbox.disabled = "true";
                          checkbox.checked = value.data.Active;
                          container.appendChild(checkbox);
                        }}
                      />
                    );
                  } else if (col.dataField === "IsHSE") {
                    return (
                      <Column
                        key={col.caption}
                        dataField={col.dataField}
                        caption={t(col.caption)}
                        allowEditing={col.allowEditing}
                        allowSearch={col.allowSearch}
                        allowFiltering={col.allowFiltering}
                        visible={col.visibility}
                        disabled={true}
                        visibleIndex={col.visibleIndex}
                        showInColumnChooser={col.showInColumnChooser}
                        width={col.width || undefined}
                        dataType="boolean"
                        cellTemplate={(container, value) => {
                          let IsChangedHSE = value.row.data["IsChangedHSE"];
                          container.style = IsChangedHSE
                            ? "background-color: #ffff00;text-align:center;"
                            : "text-align:center;";
                          var checkbox = document.createElement("input");
                          checkbox.type = "checkbox";
                          checkbox.disabled = "true";
                          checkbox.checked = value.data.IsHSE;
                          container.appendChild(checkbox);
                        }}
                      />
                    );
                  } else if (col.dataField === "ShiftOffset") {
                    return (
                      <Column
                        key={col.caption}
                        dataField={col.dataField}
                        caption={t(col.caption)}
                        allowEditing={col.allowEditing}
                        allowSearch={col.allowSearch}
                        allowFiltering={col.allowFiltering}
                        visible={col.visibility}
                        disabled={true}
                        visibleIndex={col.visibleIndex}
                        showInColumnChooser={col.showInColumnChooser}
                        width={col.width || undefined}
                        dataType="boolean"
                        cellTemplate={(container, value) => {
                          let IsChangedShiftOffset =
                            value.row.data["IsChangedShiftOffset"];
                          container.style = IsChangedShiftOffset
                            ? "background-color: #ffff00;text-align:center;"
                            : "text-align:center;";
                          let j = document.createElement("span");
                          // value.value = value.value.replace("U:", "");
                          j.appendChild(document.createTextNode(value.value));
                          container.appendChild(j);
                        }}
                      />
                    );
                  } else {
                    return (
                      <Column
                        key={index}
                        caption={t(col.caption)}
                        dataField={col.dataField}
                        alignment="center"
                        visible={col.visibility}
                        allowEditing={col.allowEditing}
                        allowExporting={col.exportEnable}
                        showInColumnChooser={col.showInColumnChooser}
                      />
                    );
                  }
                })}
                <Summary calculateCustomSummary={this.calculateSummary}>
                  {" "}
                  <TotalItem
                    displayFormat={"Tasks Statistics: "}
                    showInColumn="succes_failure"
                  />{" "}
                  <TotalItem
                    name="AddedTasksSummary"
                    summaryType="custom"
                    displayFormat={"Add = {0}"}
                    showInColumn="DepartmentDesc"
                  />{" "}
                  <TotalItem
                    name="ModifiedTasksSummary"
                    summaryType="custom"
                    displayFormat={"Update = {0}"}
                    showInColumn="LineDesc"
                  />{" "}
                  <TotalItem
                    name="ObsoletedTasksSummary"
                    summaryType="custom"
                    displayFormat={"Obsolete = {0}"}
                    showInColumn="MasterUnitDesc"
                  />{" "}
                </Summary>
              </DataGrid>
            </div>
            <div className={styles.divButtons}>
              <Button
                id="btnVersionInformation"
                icon="thumbtack"
                text={t("Version Information")}
                primary
                classes={styles.nextButton}
                onClick={this.showVersionSection}
              />
            </div>
          </Item>

          <Item
            key="versionInformation"
            title={t("Version Information")}
            disabled={disableVersionSection}
          >
            <div className={styles.itemContainers}>
              {versionLevel === "By Line" && (
                <div>
                  <label className={styles.subTitle}>{t("Line Version")}</label>
                  <br />
                  <br />
                  <DataGrid
                    id="grdLineVersion"
                    key="lines"
                    ref={this.refGridLineVersion}
                    dataSource={lineVersionDS}
                    className={styles.dataGrids}
                    showBorders={false}
                    allowColumnResizing={true}
                    showColumnLines={true}
                    showRowLines={true}
                    columnAutoWidth={true}
                    width="100%"
                  >
                    <LoadPanel
                      enabled={true}
                      showIndicator={true}
                      shading={true}
                      showPane={true}
                    />
                    <Column
                      key={"LineDesc"}
                      caption={t("Line Description")}
                      dataField="LineDesc"
                      alignment="center"
                      allowSorting={false}
                    />
                    <Column
                      key={"CurrentVersion"}
                      caption={t("Current Version")}
                      dataField="CurrentVersion"
                      alignment="center"
                      allowSorting={false}
                    />
                    <Column
                      key={"NewVersion"}
                      caption={t("New Version")}
                      dataField="NewVersion"
                      alignment="center"
                      allowSorting={false}
                    />
                  </DataGrid>
                  <br />
                  <br />
                </div>
              )}
              <div>
                <label className={styles.subTitle}>
                  {t("Module Feature Versions")}
                </label>
                <br />
                <br />
                <DataGrid
                  id="grdModuleFeatureVersion"
                  key="modules"
                  ref={this.refGridModuleVersion}
                  dataSource={moduleVersionsDS}
                  className={styles.dataGrids}
                  showBorders={false}
                  allowColumnResizing={true}
                  showColumnLines={true}
                  showRowLines={true}
                  columnAutoWidth={true}
                  width="100%"
                >
                  <LoadPanel
                    enabled={true}
                    showIndicator={true}
                    shading={true}
                    showPane={true}
                  />

                  <Column
                    key={"ModuleDesc"}
                    caption={t("Module Description")}
                    dataField="ModuleDesc"
                    alignment="center"
                    allowSorting={false}
                  />
                  <Column
                    key={"CurrentVersion"}
                    caption={t("Current Version")}
                    dataField="CurrentVersion"
                    alignment="center"
                    allowSorting={false}
                  />
                  <Column
                    key={"NewVersion"}
                    caption={t("New Version")}
                    dataField="NewVersion"
                    alignment="center"
                    allowSorting={false}
                  />
                </DataGrid>
              </div>
              <div className={styles.divButtons}>
                <br />
                <Button
                  id="btnShowTasksUpdateSection"
                  icon="thumbtack"
                  text={t("Tasks Update")}
                  primary
                  classes={styles.nextButton}
                  onClick={this.showTasksUpdateSection}
                />
              </div>
            </div>
          </Item>
        </Accordion>

        <Popup
          id="popComparePopup"
          title={t("Comparision Progress")}
          visible={showComparePopup}
          onHiding={this.onHidingPopup}
          closeOnOutsideClick={false}
          maxWidth="60%"
        >
          <DataGrid
            id="grdComparision"
            key="comparision"
            dataSource={compareDS}
            ref={this.refGridComparision}
            className={styles.dataGrids}
            showBorders={false}
            showColumnLines={true}
            showRowLines={true}
            columnAutoWidth={true}
            width="100%"
            height="100%"
          >
            <Column
              key={"id"}
              caption="id"
              dataField="id"
              alignment="center"
              visible={false}
            />
            <Column
              key={"status"}
              caption={t("Status")}
              dataField="Status"
              alignment="center"
              allowSorting={false}
              width="10%"
              cellTemplate={(container, data) => {
                if (data.value === "Waiting") {
                  let k = getHtmlElementIcon(icons.loading); // document.createElement("img");
                  // k.setAttribute("src", getIcon(icons.loading));
                  // k.setAttribute("width", "20px");
                  // k.setAttribute("height", "20px");
                  container.appendChild(k);
                } else if (data.value === "Success") {
                  let k = document.createElement("span");
                  k.setAttribute("class", "dx-link dx-icon-check dx-link-icon");
                  k.setAttribute(
                    "style",
                    "text-decoration: none; color: green"
                  );
                  container.appendChild(k);
                } else if (data.value === "Error") {
                  let k = document.createElement("span");
                  k.setAttribute(
                    "class",
                    "dx-link dx-icon-remove dx-link-icon"
                  );
                  k.setAttribute("style", "text-decoration: none; color: red");
                  container.appendChild(k);
                }
              }}
            />
            <Column
              key={"step"}
              caption={t("Step")}
              dataField="Step"
              alignment="center"
              allowSorting={false}
              width="40%"
            />
            <Column
              key={"Information"}
              caption={t("Information")}
              dataField="Information"
              alignment="center"
              allowSorting={false}
              width="60%"
            />
          </DataGrid>
        </Popup>

        <Popup
          id="popCustomViewDialog"
          visible={customViewDialogOpened}
          onHiding={this.onClickCloseCustomViewDialog}
          dragEnabled={false}
          closeOnOutsideClick={true}
          showTitle={true}
          title={t("Save Custom View")}
          showCloseButton={false}
          width="350px"
          height="175px"
        >
          <RadioGroup
            ref={this.refRdgCustomView}
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
            value={customViewRdgOption}
            valueExpr="value"
            onValueChanged={this.onRdgCustomViewChange}
          />
          <Input
            id="txtCustomView"
            type="text"
            name="customViewName"
            onChange={(e) => e}
            border
            defaultValue=""
          />
          <Button
            id="btnSaveCustomView"
            text={t("Save")}
            onClick={this.onClickSaveCustomView}
          />
          <Button
            id="btnClose"
            text={t("Close")}
            onClick={this.onClickCloseCustomViewDialog}
          />
        </Popup>
        <Popup
          id="popMasterAssignment"
          visible={showMasterUnitAssignmentPopup}
          onHiding={this.onHidingMasterUnitAssignmentPopup}
          dragEnabled={true}
          closeOnOutsideClick={false}
          showTitle={true}
          title={t("New Modules - Primary Unit Assignment")}
          maxWidth="60%"
        >
          <MasterUnitAssinment
            t={t}
            opened={showMasterUnitAssignmentPopup}
            unitsForaLine={unitsForaLine}
            plantModelDS={plantModelDS}
            updateRowsMasterAssignment={(rowsMasterAssignmentUpdated) =>
              this.updateRowsMasterAssignment(rowsMasterAssignmentUpdated)
            }
          />
        </Popup>
      </Card>
    );
  }
}

export default VersionManagement;
