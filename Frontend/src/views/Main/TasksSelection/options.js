import React from "react";
import icons from "../../../resources/icons";
import { SelectBox } from "devextreme-react/ui/select-box";
import { getUserRole } from "../../../services/auth";
import {
  filterGridByMultipleFields,
  getHtmlElementIcon,
  getIcon,
  isTablet,
} from "../../../utils";
import { TASK_STATE_BG, CL_TASKS_STATE } from "../../../utils/constants";
import dayjs from "dayjs";

//#region plant model

function updatePlantModelView(key, values, state) {
  const { lines, units, workcells } = state.selected;

  let temp = {};

  temp.lines = state.lines;
  temp.units = state.units;
  temp.workcells = state.workcells;

  temp.selected = {
    lines,
    units,
    workcells,
  };

  switch (key) {
    case "lines":
      temp.units = [];
      temp.workcells = [];
      temp.selected.lines = values;
      temp.selected.units = [];
      temp.selected.workcells = [];
      break;
    case "units":
      temp.workcells = [];
      temp.selected.units = values;
      temp.selected.workcells = [];
      break;
    case "workcells":
      temp.selected.workcells = values;
      break;
    default:
      break;
  }

  return temp;
}

//#endregion

//#region grid properties

function gridToolbarPreparing(
  e,
  t,
  onSaveSelectedTasks,
  onCompleteAllTasks,
  onClickCustomize,
  onClickRefreshGrid,
  onClickQuickPrint,
  onClickExportToExcel,
  onClickExportToPDF,
  onClickTourMap,
  viewActive = "",
  isExpanded = false,
  onFiltersClick = null
) {
  var columnChooser = e.toolbarOptions.items.find(
    (i) => i.name === "columnChooserButton"
  );

  columnChooser.location = "before";
  columnChooser.options.icon = getIcon("columns");

  let globalAccessLevel = getUserRole();

  return e.toolbarOptions.items.unshift(
    {
      location: "before",
      widget: "dxButton",
      cssClass: "btnSaveSelectedTasksSelection",
      options: {
        hint: t("Save Selected"),
        icon: getIcon("save"),
        // icon: icons.save,
        onClick: onSaveSelectedTasks,
      },
    },
    [4, 3, 2].includes(globalAccessLevel)
      ? {
          location: "before",
          widget: "dxButton",
          cssClass: "btnCompleteAllTasksSelection",
          options: {
            hint: t("Complete All"),
            icon: getIcon("list-check"),
            // icon: icons.editTask,
            onClick: onCompleteAllTasks,
          },
        }
      : {},
    {
      location: "before",
      widget: "dxButton",
      cssClass: "btnCustomizeGridTasksSelection",
      options: {
        hint: t("Customize"),
        icon: getIcon("chalkboard-user"),
        // icon: icons.customize,
        onClick: onClickCustomize,
      },
      disabled: isExpanded,
    },
    {
      location: "before",
      widget: "dxButton",
      cssClass: "btnRefreshGridTasksSelection",
      options: {
        hint: t("Refresh List"),
        icon: getIcon("rotate-right"),
        // icon: icons.refresh_grid,
        onClick: onClickRefreshGrid,
      },
    },

    (sessionStorage.getItem("OpsHubPage") === "MyRoutes" || isTablet()) &&
      onFiltersClick
      ? {
          location: "before",
          widget: "dxButton",
          cssClass: "btnClickTourMap",
          options: {
            hint: "Filters",
            icon: getIcon("filter"),
            // icon: "filter",
            onClick: onFiltersClick,
          },
        }
      : {},

    viewActive.toLowerCase().includes("routes")
      ? {
          location: "after",
          widget: "dxButton",
          cssClass: "btnClickTourMap",
          options: {
            hint: "Tour Map Link",
            icon: getIcon("map-marked-alt"),
            // icon: icons.map,
            onClick: onClickTourMap,
          },
        }
      : {},
    {
      location: "after",
      widget: "dxButton",
      cssClass: "btnQuickPrintTasksSelection",
      options: {
        hint: t("Quick Print"),
        icon: getIcon("print"),
        // icon: icons.print,
        onClick: onClickQuickPrint,
      },
    },
    {
      location: "after",
      widget: "dxButton",
      cssClass: "btnExcelExportTasksSelection",
      options: {
        hint: t("Export to Excel"),
        icon: getIcon("file-excel"),
        onClick: onClickExportToExcel,
      },
    },
    {
      location: "after",
      widget: "dxButton",
      cssClass: "btnPdfExportTasksSelection",
      options: {
        hint: t("Export to PDF"),
        icon: getIcon("file-pdf"),
        // icon: icons.linkPDF,
        onClick: onClickExportToPDF,
      },
    }
  );
}

function gridColumns(
  t,
  promps,
  refGrid,
  refDefects,
  handlerDefects,
  getUserPrompt,
  getServerPrompt,
  getTasksStateValues,
  // getHeaderFilter,
  onClickCellInfo,
  onClickCellMove,
  onClickCellComment
) {
  return [
    {
      dataField: "IsEdited",
      caption: "#",
      visibility: false,
      allowEditing: false,
      allowSearch: false,
      allowFiltering: false,
      visibleIndex: 1,
      showInColumnChooser: false,
      exportEnable: false,
    },
    {
      dataField: "IsSelected",
      caption: "",
      visibility: true,
      allowEditing: true,
      allowSearch: false,
      allowFiltering: false,
      visibleIndex: 2,
      showInColumnChooser: false,
      width: "50px",
      exportEnable: false,
      allowExporting: false,
      alignment: "center",
    },
    {
      dataField: "TestId",
      caption: "Test ID",
      visibility: false,
      allowEditing: false,
      allowSearch: false,
      allowFiltering: true,
      visibleIndex: 3,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "LineDesc",
      caption: t("Line"),
      visibility: true,
      allowEditing: false,
      allowSearch: true,
      allowFiltering: true,
      visibleIndex: 4,
      showInColumnChooser: true,
      exportEnable: true,
      hidingPriority: 0,
    },
    {
      dataField: "MasterUnitDesc",
      caption: t("Primary Unit"),
      visibility: true,
      allowEditing: false,
      allowSearch: true,
      allowFiltering: true,
      visibleIndex: 5,
      showInColumnChooser: true,
      exportEnable: true,
      hidingPriority: 0,
    },
    {
      dataField: "SlaveUnitDesc",
      caption: t("Module"),
      visibility: true,
      allowEditing: false,
      allowSearch: true,
      allowFiltering: true,
      visibleIndex: 6,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "TaskId",
      caption: "Task Id",
      visibility: true,
      allowEditing: false,
      allowSearch: true,
      allowFiltering: true,
      visibleIndex: 7,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "ColInfo",
      caption: t("Info"),
      alignment: "center",
      visibility: true,
      allowEditing: false,
      allowSearch: false,
      allowFiltering: false,
      visibleIndex: 8,
      showInColumnChooser: true,
      exportEnable: false,
      width: "50px",
      cellTemplate: (container, options) => {
        container.setAttribute("style", "text-align: center;");

        let j = getHtmlElementIcon("circle-info");
        j.onclick = () => {
          onClickCellInfo(options.row.data);
        };
        container.appendChild(j);
      },
    },
    {
      dataField: "ColDoc",
      caption: t("Doc"),
      visibility: true,
      allowEditing: false,
      allowSearch: false,
      allowFiltering: false,
      visibleIndex: 9,
      showInColumnChooser: true,
      exportEnable: false,
      width: "50px",
      cellTemplate: (container, options) => {
        if (options.row.data?.ExternalLink) {
          container.setAttribute("style", "text-align: center;");

          var link = options.row.data.ExternalLink;
          let j = getHtmlElementIcon("file");

          if (link.endsWith(".xlsx") || link.endsWith("xls")) {
            j = getHtmlElementIcon("file-excel");
          } else if (link.endsWith(".docx") || link.endsWith(".doc")) {
            j = getHtmlElementIcon("file-word");
          } else if (link.endsWith(".pdf")) {
            j = getHtmlElementIcon("file-pdf");
          } else {
            j = getHtmlElementIcon("file");
          }

          j.setAttribute("title", options.row.data.DisplayLink);
          j.onclick = () => {
            window.open(options.row.data.ExternalLink, "_blank");
          };

          container.appendChild(j);
        }
      },
    },
    {
      dataField: "VarDesc",
      caption: t("Task Description"),
      visibility: true,
      allowEditing: false,
      allowSearch: true,
      allowFiltering: true,
      visibleIndex: 10,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "Fixed",
      caption: t("Fixed"),
      visibility: false,
      allowEditing: false,
      allowSearch: true,
      allowFiltering: true,
      visibleIndex: 11,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "ScheduleTime",
      caption: t("Schedule Date"),
      visibility: true,
      allowEditing: false,
      allowSearch: true,
      allowFiltering: true,
      visibleIndex: 12,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "LateTime",
      caption: t("Late Date"),
      visibility: true,
      allowEditing: false,
      allowSearch: true,
      allowFiltering: true,
      visibleIndex: 13,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "DueTime",
      caption: t("Due Date"),
      visibility: true,
      allowEditing: false,
      allowSearch: true,
      allowFiltering: true,
      visibleIndex: 14,
      showInColumnChooser: true,
      exportEnable: true,
      defaultSortOrder: "asc",
      // sortOrder: sessionStorage.getItem("OpsHubPage") ? "" : "asc",
    },
    {
      dataField: "CurrentResult",
      caption: t("Value"),
      visibility: true,
      allowEditing: true,
      allowSearch: true,
      allowFiltering: true,
      visibleIndex: 15,
      showInColumnChooser: true,
      exportEnable: true,
      width: "120px",
      cellTemplate: (container, options) => {
        let valueEntered = options.value;
        let value = promps.find(
          (t) => t.ServerPrompt === valueEntered
        )?.LangPrompt;
        let valueEN = getUserPrompt(valueEntered);
        let isCL = options.row.data.EventSubtypeDesc?.includes("CL");
        var j = document.createElement("span");
        let paramSpecSetting = parseInt(
          localStorage.getItem("paramSpecSetting")
        );

        if (isCL) {
          let val = options.row.data;
          let title = resetCLSpecValuesAndSetTitle(val);
          let L_Reject = val?.L_Reject === "" ? null : val?.L_Reject;
          let Target = val?.Target === "" ? null : val?.Target;
          let U_Reject = val?.U_Reject === "" ? null : val?.U_Reject;
          let VarDataType = val?.VarDataType; // String | Logical | Float | Yes/No | Integer
          container.setAttribute("style", "width: 80px;");
          container.setAttribute("custom-tooltip", title);
          setTimeout(() => {
            container.setAttribute("class", "tooltip_hover");
          }, 150);

          // paramSpecSetting =  0 --> include limits
          // paramSpecSetting = 1--> dont include limits

          let type = "";
          if (valueEntered !== "")
            if ("Float Integer".includes(VarDataType)) {
              L_Reject = L_Reject ? parseFloat(L_Reject) : null;
              Target = Target ? parseFloat(Target) : null;
              U_Reject = U_Reject ? parseFloat(U_Reject) : null;
              if (
                (L_Reject && !Target && !U_Reject) ||
                (L_Reject && Target && !U_Reject)
              ) {
                if (paramSpecSetting === 1)
                  type = valueEntered > L_Reject ? "inTarget" : "outTarget";
                else if (paramSpecSetting === 0)
                  type = valueEntered >= L_Reject ? "inTarget" : "outTarget";
              } else if (
                (!L_Reject && !Target && U_Reject) ||
                (!L_Reject && Target && U_Reject)
              ) {
                if (paramSpecSetting === 1)
                  type = valueEntered < U_Reject ? "inTarget" : "outTarget";
                else if (paramSpecSetting === 0)
                  type = valueEntered <= U_Reject ? "inTarget" : "outTarget";
              } else if (
                (L_Reject && Target && U_Reject) ||
                (L_Reject && !Target && U_Reject)
              ) {
                if (paramSpecSetting === 1)
                  type =
                    valueEntered > L_Reject && valueEntered < U_Reject
                      ? "inTarget"
                      : "outTarget";
                else if (paramSpecSetting === 0)
                  type =
                    valueEntered >= L_Reject && valueEntered <= U_Reject
                      ? "inTarget"
                      : "outTarget";
              } else if (!L_Reject && Target && !U_Reject) {
                type = valueEntered === Target ? "inTarget" : "outTarget";
              }
            } else if (
              "String Logical Yes/No Pass/Fail".includes(VarDataType)
            ) {
              type = valueEntered === Target ? "inTarget" : "outTarget";
            }
          container.setAttribute("style", CL_TASKS_STATE[type]);
          VarDataType !== "Float" && container.classList.add("taskgrid-ddb");
        } else {
          //eCIL
          container.setAttribute("style", TASK_STATE_BG[valueEN]);
          container.classList.add("taskgrid-ddb");
        }
        j.appendChild(document.createTextNode(value || valueEntered));
        container.appendChild(j);
      },
      editCellRender: (cell) => {
        var globalAccessLevel = getUserRole();
        let value = cell.value;
        let isCL = cell.data.EventSubtypeDesc.includes("CL");
        const { cellValue } = refGrid.current.instance;
        function setCLSpecificationValue(field, value) {
          let elem = document.getElementById(field);
          if (elem) document.getElementById(field).textContent = value;
        }
        let val = cell.row.data;
        let L_Reject = val?.L_Reject;
        let Target = val?.Target;
        let U_Reject = val?.U_Reject;
        let VarDataType = val?.VarDataType;
        let title = "";
        if (isCL) {
          title = resetCLSpecValuesAndSetTitle(val);
          setCLSpecificationValue(
            "VarDesc",
            "CL values specifications - " + val?.VarDesc
          );
          L_Reject &&
            setCLSpecificationValue("L_Reject", "Low Reject: " + L_Reject);
          Target && setCLSpecificationValue("Target", "Target: " + Target);
          U_Reject &&
            setCLSpecificationValue("U_Reject", "Upper Reject: " + U_Reject);
        }

        return !isCL ? (
          <SelectBox
            defaultValue={value}
            dataSource={getTasksStateValues(value)}
            disabled={globalAccessLevel === 1 ? true : false}
            displayExpr="LangPrompt"
            valueExpr="ServerPrompt"
            onFocusIn={(e) => {
              setTimeout(() => {
                e.component.open();
              }, 25);
            }}
            onValueChanged={(rowData) => {
              let value = getUserPrompt(rowData.value);

              if (value === "Defect") {
                handlerDefects();
                var data = Object.assign({}, cell.row.data);
                data.CurrentResult = getServerPrompt(value);

                refDefects.setData(data);
              } else {
                cell.setValue(rowData.value);
                cellValue(cell.rowIndex, "IsEdited", true);
                cellValue(cell.rowIndex, "IsSelected", true);
              }

              setTimeout(() => {
                refGrid.current.instance.closeEditCell();
              }, 25);
            }}
          />
        ) : "Yes/No Pass/Fail Logical".includes(VarDataType) ? (
          <>
            <span custom-tooltip={title} class="tooltip_click_CL">
              <SelectBox
                defaultValue={value}
                dataSource={
                  "Yes/No".includes(VarDataType)
                    ? [{ val: "Yes" }, { val: "No" }]
                    : "Pass/Fail".includes(VarDataType)
                    ? [{ val: "Pass" }, { val: "Fail" }]
                    : "Logical".includes(VarDataType)
                    ? [{ val: "1" }, { val: "0" }]
                    : []
                }
                disabled={globalAccessLevel === 1 ? true : false}
                displayExpr="val"
                valueExpr="val"
                onFocusIn={(e) => {
                  setTimeout(() => {
                    e.component.open();
                    hideTooltips();
                  }, 25);
                }}
                onValueChanged={(rowData) => {
                  let value = rowData.value;
                  var data = Object.assign({}, cell.row.data);
                  data.CurrentResult = value;
                  cell.setValue(rowData.value);
                  cellValue(cell.rowIndex, "IsEdited", true);
                  cellValue(cell.rowIndex, "IsSelected", true);
                  setTimeout(() => {
                    refGrid.current.instance.closeEditCell();
                    showTooltips();
                  }, 25);
                }}
              />
            </span>
          </>
        ) : (
          <>
            <td
              custom-tooltip={title}
              class={!title.includes("No specifications") ? "tooltip" : ""}
            >
              <input
                id={cell.row.data.TestId}
                type="text"
                defaultValue={value}
                onFocus={() => {
                  hideTooltips();
                }}
                onBlur={() => {
                  showTooltips();
                  if (
                    cell.row.data?.CurrentResult !==
                    document.getElementById(cell.row.data.TestId).value
                  ) {
                    let varDataType = cell.row.data.VarDataType;
                    let val = document.getElementById(
                      cell.row.data.TestId
                    ).value;
                    let values = val.split(".");
                    let hasDecimals = values.length === 2;
                    if (varDataType.includes("Float")) {
                      if (hasDecimals) {
                        let decimals = values[1];
                        if (decimals.length >= 2 && decimals !== "00")
                          val = parseFloat(val);
                      } else val = parseInt(val).toFixed(2);
                      val = isNaN(parseFloat(val))
                        ? document.getElementById(cell.row.data.TestId).value
                        : val;
                    }
                    cell.setValue(val);
                    cellValue(cell.rowIndex, "IsEdited", true);
                    cellValue(cell.rowIndex, "IsSelected", true);
                    setTimeout(() => {
                      refGrid.current.instance.closeEditCell();
                    }, 250);
                  }
                }}
              />
            </td>
          </>
        );
      },
    },
    {
      dataField: "",
      caption: t("Move"),
      visibility: true,
      allowEditing: false,
      allowSearch: false,
      allowFiltering: false,
      visibleIndex: 16,
      showInColumnChooser: true,
      exportEnable: false,
      alignment: "center",
      width: "50px",
      cellTemplate: (container, options) => {
        var globalAccessLevel = getUserRole();
        var valueEN = getUserPrompt(options.row.data?.CurrentResult);

        if (
          options.row.data.Fixed === "0" &&
          options.row.data.TaskFreq.includes("D") &&
          valueEN !== "Defect"
        ) {
          var disabled =
            globalAccessLevel !== 3 && globalAccessLevel !== 4
              ? "pointer-events: none;opacity: 0.5;"
              : "";

          let j = getHtmlElementIcon("calendar-check");
          if (disabled) j.setAttribute("style", disabled);

          j.onclick = () => {
            onClickCellMove(options);
          };

          container.appendChild(j);
        }
      },
    },
    {
      dataField: "CommentInfo",
      caption: t("Comment"),
      visibility: true,
      allowEditing: false,
      allowSearch: false,
      allowFiltering: false,
      visibleIndex: 17,
      showInColumnChooser: true,
      exportEnable: true,
      alignment: "center",
      width: "50px",
      cellTemplate: (container, data) => {
        var globalAccessLevel = getUserRole();

        if ([4, 3, 2].includes(globalAccessLevel)) {
          let icon = data.value === "" ? "plus" : "pencil";
          let title =
            data.value === ""
              ? t("Add a comment to this task")
              : t("Edit comment") + ": " + data.value;

          let j = getHtmlElementIcon(icon);
          j.setAttribute("title", title);

          j.onclick = (e) => {
            onClickCellComment(data.key);
          };

          container.appendChild(j);
        } else {
          let j = document.createElement("span");
          j.appendChild(document.createTextNode(data.value));
          j.setAttribute("title", data.value);
          container.appendChild(j);
        }
      },
    },
    {
      dataField: "NbrDefects",
      caption: t("Defects"),
      visibility: true,
      allowEditing: false,
      allowSearch: false,
      allowFiltering: false,
      visibleIndex: 18,
      showInColumnChooser: true,
      exportEnable: true,
      alignment: "center",
      width: "50px",
      cellTemplate: (container, options) => {
        // let isCL = options.row.data.EventSubtypeDesc?.includes("CL");
        if (options.row.data?.NbrDefects > 0) {
          container.setAttribute("style", "text-align: center;");

          let j = getHtmlElementIcon("screwdriver-wrench");
          j.setAttribute("src", icons.gridDefect);
          j.text = options.row.data.NbrDefects;
          j.onclick = () => {
            handlerDefects();
            refDefects.setData(options.row.data);
          };
          container.appendChild(j);
          container.appendChild(
            document.createTextNode(options.row.data.NbrDefects)
          );
        }
      },
    },

    {
      dataField: "RouteDesc",
      caption: t("Route"),
      visibility: false,
      allowEditing: false,
      allowSearch: true,
      allowFiltering: true,
      visibleIndex: 19,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "TaskOrder",
      caption: t("Route Task Order"),
      visibility: false,
      allowEditing: false,
      allowSearch: false,
      allowFiltering: false,
      visibleIndex: 20,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "TeamDesc",
      caption: t("Team"),
      visibility: false,
      allowEditing: false,
      allowSearch: true,
      allowFiltering: true,
      visibleIndex: 21,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "ItemNo",
      caption: "ItemNo",
      visibility: false,
      allowEditing: false,
      allowSearch: false,
      allowFiltering: false,
      visibleIndex: 22,
      showInColumnChooser: false,
      exportEnable: false,
    },
    {
      dataField: "FL1",
      caption: "FL1",
      visibility: false,
      allowEditing: false,
      allowSearch: true,
      allowFiltering: true,
      visibleIndex: 23,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "FL2",
      caption: "FL2",
      visibility: false,
      allowEditing: false,
      allowSearch: true,
      allowFiltering: true,
      visibleIndex: 24,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "FL3",
      caption: "FL3",
      visibility: false,
      allowEditing: false,
      allowSearch: true,
      allowFiltering: true,
      visibleIndex: 24,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "FL4",
      caption: "FL4",
      visibility: false,
      allowEditing: false,
      allowSearch: true,
      allowFiltering: true,
      visibleIndex: 25,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "TaskFreq",
      caption: t("Task Freq"),
      visibility: false,
      allowEditing: false,
      allowSearch: true,
      allowFiltering: true,
      visibleIndex: 26,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "TaskType",
      caption: t("Task Type"),
      visibility: false,
      allowEditing: false,
      allowSearch: true,
      allowFiltering: true,
      visibleIndex: 27,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "Duration",
      caption: t("Duration"),
      visibility: false,
      allowEditing: false,
      allowSearch: true,
      allowFiltering: true,
      visibleIndex: 28,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "LongTaskName",
      caption: t("Long Task Name"),
      visibility: false,
      allowEditing: false,
      allowSearch: true,
      allowFiltering: true,
      visibleIndex: 29,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "TaskAction",
      caption: t("Task Action"),
      visibility: false,
      allowEditing: false,
      allowSearch: true,
      allowFiltering: true,
      visibleIndex: 30,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "Criteria",
      caption: t("Criteria"),
      visibility: false,
      allowEditing: false,
      allowSearch: true,
      allowFiltering: true,
      visibleIndex: 31,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "Hazards",
      caption: t("Hazards"),
      visibility: false,
      allowEditing: false,
      allowSearch: true,
      allowFiltering: true,
      visibleIndex: 32,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "Method",
      caption: t("Method"),
      visibility: false,
      allowEditing: false,
      allowSearch: true,
      allowFiltering: true,
      visibleIndex: 33,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "PPE",
      caption: t("PPE"),
      visibility: false,
      allowEditing: false,
      allowSearch: true,
      allowFiltering: true,
      visibleIndex: 34,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "Tools",
      caption: t("Tools"),
      visibility: false,
      allowEditing: false,
      allowSearch: true,
      allowFiltering: true,
      visibleIndex: 35,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "Lubricant",
      caption: t("Lubricant"),
      visibility: false,
      allowEditing: false,
      allowSearch: true,
      allowFiltering: true,
      visibleIndex: 36,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "QFactorType",
      caption: t("Q-Factor Type"),
      visibility: false,
      allowEditing: false,
      allowSearch: true,
      allowFiltering: true,
      visibleIndex: 37,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "PrimaryQFactor",
      caption: t("Primary Q-Factor"),
      visibility: false,
      allowEditing: false,
      allowSearch: true,
      allowFiltering: true,
      visibleIndex: 38,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "NbrPeople",
      caption: t("# People"),
      visibility: false,
      allowEditing: false,
      allowSearch: true,
      allowFiltering: true,
      visibleIndex: 39,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "NbrItems",
      caption: t("# Items"),
      visibility: false,
      allowEditing: false,
      allowSearch: true,
      allowFiltering: true,
      visibleIndex: 40,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "IsDefectLooked",
      caption: t("Is Defect Looked"),
      visibility: false,
      allowEditing: false,
      allowSearch: false,
      allowFiltering: false,
      visibleIndex: 41,
      showInColumnChooser: false,
      exportEnable: false,
    },
    {
      dataField: "IsHSE",
      caption: t("Is HSE?"),
      visibility: false,
      allowEditing: false,
      allowSearch: true,
      allowFiltering: true,
      visibleIndex: 42,
      showInColumnChooser: true,
      exportEnable: true,
      alignment: "center",
    },
    {
      dataField: "EntryOn1",
      caption: t("Last Modification"),
      visibility: false,
      allowEditing: false,
      allowSearch: false,
      allowFiltering: false,
      visibleIndex: 43,
      showInColumnChooser: false,
      exportEnable: false,
    },
    {
      dataField: "TourDesc",
      caption: t("Tour Stop"),
      visibility: true,
      allowEditing: false,
      allowSearch: true,
      allowFiltering: true,
      visibleIndex: 44,
      showInColumnChooser: true,
      exportEnable: true,
      hidingPriority: 0,
      width: "50px",
      groupIndex: 0,
    },
    {
      dataField: "TourId",
      caption: t("Tour Id"),
      visibility: false,
      allowEditing: false,
      allowSearch: true,
      allowFiltering: true,
      visibleIndex: 45,
      showInColumnChooser: true,
      exportEnable: true,
      hidingPriority: 0,
    },
    {
      dataField: "EventSubtypeDesc",
      caption: t("Variable Type"),
      visibility: false,
      allowEditing: false,
      allowSearch: true,
      allowFiltering: true,
      visibleIndex: 46,
      showInColumnChooser: true,
      exportEnable: true,
      hidingPriority: 0,
    },
    {
      dataField: "TourTaskOrder",
      caption: t("Tour Stop Task Order"),
      visibility: false,
      allowEditing: false,
      allowSearch: false,
      allowFiltering: true,
      visibleIndex: 50,
      showInColumnChooser: true,
      exportEnable: false,
      hidingPriority: 0,
      defaultSortOrder: "asc",
      width: "100px",
      cellTemplate: (container, options) => {
        let value = options.value ?? "";
        value = value === 0 ? "" : value;
        let j = document.createElement("span");
        j.appendChild(document.createTextNode(value));
        container.appendChild(j);
      },
    },
    {
      dataField: "U_Reject",
      caption: t("Upper Reject"),
      visibility: false,
      allowEditing: false,
      allowSearch: true,
      allowFiltering: true,
      visibleIndex: 49,
      showInColumnChooser: true,
      exportEnable: true,
      hidingPriority: 0,
    },
    {
      dataField: "Target",
      caption: t("Target"),
      visibility: false,
      allowEditing: false,
      allowSearch: true,
      allowFiltering: true,
      visibleIndex: 47,
      showInColumnChooser: true,
      exportEnable: true,
      hidingPriority: 0,
    },
    {
      dataField: "L_Reject",
      caption: t("Lower Reject"),
      visibility: false,
      allowEditing: false,
      allowSearch: true,
      allowFiltering: true,
      visibleIndex: 48,
      showInColumnChooser: true,
      exportEnable: true,
      hidingPriority: 0,
    },
  ];
}

function showTooltips() {
  Array.from(document.getElementsByClassName("tooltip_hover_no")).forEach((y) =>
    y.setAttribute("class", "tooltip_hover")
  );
}

function hideTooltips() {
  Array.from(document.getElementsByClassName("tooltip_hover")).forEach((y) =>
    y.setAttribute("class", "tooltip_hover_no")
  );
}

function resetCLSpecValuesAndSetTitle(row) {
  let title = "";
  let keys = ["VarDesc", "L_Reject", "Target", "U_Reject"];
  keys.forEach((key) => {
    // let elem = document.getElementById(key);
    // if (elem) document.getElementById(key).textContent = "";
    if (key !== "VarDesc") title = setTooltip(title, row, key);
  });
  title =
    title !== ""
      ? "CL values specifications: " + title
      : "No specifications for CL";
  return title;
}

function setTooltip(title, row, field) {
  title += row[field]
    ? `
  ${field}:   ` +
      row[field] +
      ` `
    : "";
  return title;
}

function filterGrid(state) {
  let fields = [];

  if (state) {
    var units = state.units
      .filter((u) => state.selected.units.find((f) => f === u.MasterId))
      .map((m) => m.MasterDesc);

    fields.push(
      { fieldName: "MasterUnitDesc", fieldValues: units },
      {
        fieldName: "SlaveUnitId",
        fieldValues: state.selected.workcells,
      }
    );
  }

  return filterGridByMultipleFields(fields);
}

//#endregion

//#region defects properties

function getTasksInfoItems() {
  return [
    { caption: "Line", dataField: "LineDesc" },
    { caption: "Unit Desc", dataField: "MasterUnitDesc" },
    { caption: "Module", dataField: "SlaveUnitDesc" },
    { caption: "Long Task Name", dataField: "LongTaskName" },
    { caption: "Frequency", dataField: "TaskFreq" },
    { caption: "Duration", dataField: "Duration" },
    { caption: "Task Type", dataField: "TaskType" },
    { caption: "Task Due Date", dataField: "DueTime" },
    { caption: "Functional Location", dataField: "" },
    { caption: "Reported By", dataField: "" },
  ];
}

function getEcilDefectsColumns() {
  return [
    { caption: "Created On", dataField: "DefectStart" },
    { caption: "Closed On", dataField: "DefectEnd" },
    { caption: "FL", dataField: "FL" },
    { caption: "Type", dataField: "DefectType" },
    { caption: "Reported By", dataField: "ReportedBy" },
    { caption: "Notification", dataField: "Notification" },
    { caption: "Description", dataField: "Description" },
  ];
}

function getFLDefectsColumns() {
  return [
    {
      caption: "Created On",
      dataField: "DateFound",
      cellTemplate: (container, options) => {
        let value = options.value ?? "";

        if (value !== null && value !== "") {
          value = dayjs(value).format("YYYY-MM-DD HH:mm:ss");
        }

        let j = document.createElement("span");
        j.appendChild(document.createTextNode(value));
        container.appendChild(j);
      },
    },
    { caption: "FL", dataField: "FLCode" },
    { caption: "Type", dataField: "DefectType" },
    { caption: "Reported By", dataField: "CreatedBy" },
    { caption: "Notification", dataField: "PMNotification" },
    { caption: "Description", dataField: "Description" },
    { caption: "PM Status", dataField: "PMStatus" },
    { caption: "How Found", dataField: "HowFound" },
    {
      caption: "PMOpenDate",
      dataField: "PMOpenDate",
      cellTemplate: (container, options) => {
        let value = options.value ?? "";

        if (value !== null && value !== "") {
          value = dayjs(value).format("YYYY-MM-DD HH:mm:ss");
        }

        let j = document.createElement("span");
        j.appendChild(document.createTextNode(value));
        container.appendChild(j);
      },
    },
    { caption: "FD", dataField: "FD" },
    { caption: "RD", dataField: "RD" },
    { caption: "PM", dataField: "PM" },
  ];
}

//#endregion

export {
  updatePlantModelView,
  gridToolbarPreparing,
  gridColumns,
  filterGrid,
  getTasksInfoItems,
  getEcilDefectsColumns,
  getFLDefectsColumns,
};
