import icons from "../../../../resources/icons";
import { filterGridByMultipleFields, getIcon } from "../../../../utils/index";

//#region plant model filters

function updatePlantModelView(key, values, state) {
  const { departments, lines, units, teams, myteams, routes, myroutes } =
    state.plantModel;

  let temp = {};

  temp.departments = state.departments;
  temp.lines = state.lines;
  temp.units = state.units;

  temp.teams = state.teams;
  temp.myteams = state.myteams;
  temp.routes = state.routes;
  temp.myroutes = state.myroutes;

  temp.plantModel = {
    departments,
    lines,
    units,
    teams,
    myteams,
    routes,
    myroutes,
  };

  switch (key) {
    case "departments":
      temp.lines = [];
      temp.units = [];
      temp.plantModel.departments = values;
      temp.plantModel.lines = [];
      temp.plantModel.units = [];
      break;
    case "lines":
      temp.units = [];
      temp.plantModel.lines = values;
      temp.plantModel.units = [];
      break;
    case "units":
      temp.plantModel.units = values;
      break;
    default:
      break;
  }

  return temp;
}
//#endregion

//#region grid

function gridTasksPlanningToolbarPreparing(
  e,
  t,
  onClickCustomize,
  onClickExportToExcel,
  onClickExportToPDF
) {
  var columnChooser = e.toolbarOptions.items.find(
    (i) => i.name === "columnChooserButton"
  );

  columnChooser.location = "before";
  columnChooser.options.icon = getIcon(icons.columnChooser);

  return e.toolbarOptions.items.unshift(
    {
      location: "before",
      widget: "dxButton",
      cssClass: "btnCustomizeGridTasksPlanning",
      options: {
        hint: t("Customize"),
        icon: getIcon(icons.customize),
        onClick: onClickCustomize,
      },
    },
    {
      location: "after",
      widget: "dxButton",
      cssClass: "btnExcelExportTasksPlanning",
      options: {
        hint: t("Export to Excel"),
        icon: getIcon(icons.excel),
        onClick: onClickExportToExcel,
      },
    },
    {
      location: "after",
      widget: "dxButton",
      cssClass: "btnPdfExportTasksPlanning",
      options: {
        hint: t("Export to PDF"),
        icon: getIcon(icons.pdf),
        onClick: onClickExportToPDF,
      },
    }
  );
}

function gridTasksPlanningColumns(onClickCellInfo) {
  return [
    {
      dataField: "Team",
      caption: "Team",
      visibility: true,
      allowEditing: false,
      allowSearch: false,
      allowFiltering: true,
      visibleIndex: 1,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "Route",
      caption: "Route",
      visibility: true,
      allowEditing: false,
      allowSearch: false,
      allowFiltering: true,
      visibleIndex: 2,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "Department",
      caption: "Department",
      visibility: true,
      allowEditing: false,
      allowSearch: false,
      allowFiltering: true,
      visibleIndex: 3,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "Line",
      caption: "Line",
      visibility: true,
      allowEditing: false,
      allowSearch: false,
      allowFiltering: true,
      visibleIndex: 4,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "MasterUnit",
      caption: "Primary Unit",
      visibility: true,
      allowEditing: false,
      allowSearch: false,
      allowFiltering: true,
      visibleIndex: 5,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "SlaveUnit",
      caption: "Module",
      visibility: true,
      allowEditing: false,
      allowSearch: false,
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
      allowSearch: false,
      allowFiltering: true,
      visibleIndex: 7,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "Task",
      caption: "Task Description",
      visibility: true,
      allowEditing: false,
      allowSearch: false,
      allowFiltering: true,
      visibleIndex: 8,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "ProjectedScheduleDate",
      caption: "Projected Schedule Date",
      visibility: true,
      allowEditing: false,
      allowSearch: false,
      allowFiltering: true,
      visibleIndex: 9,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "FL1",
      caption: "FL1",
      visibility: false,
      allowEditing: false,
      allowSearch: false,
      allowFiltering: true,
      visibleIndex: 10,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "FL2",
      caption: "FL2",
      visibility: false,
      allowEditing: false,
      allowSearch: false,
      allowFiltering: true,
      visibleIndex: 11,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "FL3",
      caption: "FL3",
      visibility: false,
      allowEditing: false,
      allowSearch: false,
      allowFiltering: true,
      visibleIndex: 12,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "FL4",
      caption: "FL4",
      visibility: false,
      allowEditing: false,
      allowSearch: false,
      allowFiltering: true,
      visibleIndex: 13,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "Duration",
      caption: "Duration",
      visibility: false,
      allowEditing: false,
      allowSearch: false,
      allowFiltering: true,
      visibleIndex: 14,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "LongTaskName",
      caption: "Long Task Name",
      visibility: false,
      allowEditing: false,
      allowSearch: false,
      allowFiltering: true,
      visibleIndex: 15,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "Info",
      caption: "Info",
      alignment: "center",
      visibility: false,
      allowEditing: false,
      allowSearch: false,
      allowFiltering: false,
      visibleIndex: 16,
      showInColumnChooser: true,
      exportEnable: false,
      width: "50px",
      cellTemplate: (container, options) => {
        container.setAttribute("style", "text-align: center;");

        let j = document.createElement("img");
        j.setAttribute("src", getIcon(icons.gridInfo));
        j.setAttribute("class", "btnColumnInfoTasksPlanningGrid");
        j.onclick = () => {
          onClickCellInfo(options.row.data);
        };
        container.appendChild(j);
      },
    },
    {
      dataField: "ExternalLink",
      caption: "Doc",
      visibility: false,
      allowEditing: false,
      allowSearch: false,
      allowFiltering: false,
      visibleIndex: 17,
      showInColumnChooser: true,
      exportEnable: false,
      width: "50px",
      cellTemplate: (container, options) => {
        if (options.row.data?.ExternalLink) {
          container.setAttribute("style", "text-align: center;");

          var link = options.row.data.ExternalLink;

          let j;
          j = document.createElement("img");

          if (link.endsWith(".xlsx") || link.endsWith("xls")) {
            j.setAttribute("src", getIcon(icons.linkExcel));
          } else if (link.endsWith(".docx") || link.endsWith(".doc")) {
            j.setAttribute("src", getIcon(icons.linkWord));
          } else if (link.endsWith(".pdf")) {
            j.setAttribute("src", getIcon(icons.linkPDF));
          } else {
            j.setAttribute("src", getIcon(icons.linkPage));
          }

          j.setAttribute("title", options.row.data.DisplayLink);
          j.setAttribute("class", "btnDocumentTasksPlanningGrid");
          j.onclick = () => {
            window.open(options.row.data.ExternalLink, "_blank");
          };

          container.appendChild(j);
        }
      },
    },
    {
      dataField: "TaskFrequency",
      caption: "Task Freq",
      visibility: false,
      allowEditing: false,
      allowSearch: false,
      allowFiltering: true,
      visibleIndex: 18,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "TaskType",
      caption: "Task Type",
      visibility: false,
      allowEditing: false,
      allowSearch: false,
      allowFiltering: true,
      visibleIndex: 19,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "LateTime",
      caption: "Late Date",
      visibility: false,
      allowEditing: false,
      allowSearch: false,
      allowFiltering: true,
      visibleIndex: 20,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "Lubricant",
      caption: "Lubricant",
      visibility: false,
      allowEditing: false,
      allowSearch: false,
      allowFiltering: true,
      visibleIndex: 21,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "Criteria",
      caption: "Criteria",
      visibility: false,
      allowEditing: false,
      allowSearch: false,
      allowFiltering: false,
      visibleIndex: 22,
      showInColumnChooser: false,
      exportEnable: false,
    },
    {
      dataField: "Hazards",
      caption: "Hazards",
      visibility: false,
      allowEditing: false,
      allowSearch: false,
      allowFiltering: false,
      visibleIndex: 23,
      showInColumnChooser: false,
      exportEnable: false,
    },
    {
      dataField: "Method",
      caption: "Method",
      visibility: false,
      allowEditing: false,
      allowSearch: false,
      allowFiltering: false,
      visibleIndex: 24,
      showInColumnChooser: false,
      exportEnable: false,
    },
    {
      dataField: "PPE",
      caption: "PPE",
      visibility: false,
      allowEditing: false,
      allowSearch: false,
      allowFiltering: false,
      visibleIndex: 25,
      showInColumnChooser: false,
      exportEnable: false,
    },
    {
      dataField: "Tools",
      caption: "Tools",
      visibility: false,
      allowEditing: false,
      allowSearch: false,
      allowFiltering: false,
      visibleIndex: 26,
      showInColumnChooser: false,
      exportEnable: false,
    },
    {
      dataField: "VarId",
      caption: "VarId",
      visibility: false,
      allowEditing: false,
      allowSearch: false,
      allowFiltering: true,
      visibleIndex: 27,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "TaskAction",
      caption: "Task Action",
      visibility: false,
      allowEditing: false,
      allowSearch: false,
      allowFiltering: false,
      visibleIndex: 28,
      showInColumnChooser: false,
      exportEnable: false,
    },
    {
      dataField: "EntryOn",
      caption: "Last Modification",
      visibility: false,
      allowEditing: false,
      allowSearch: false,
      allowFiltering: false,
      visibleIndex: 29,
      showInColumnChooser: false,
      exportEnable: false,
    },
    {
      visibility: true,
      width: 1,
      showInColumnChooser: false,
    },
  ];
}

function filterGrid(state) {
  const { rdgEntryType, rdgGranularity } = state;

  let fields = [];

  if (rdgEntryType === "Plant Model") {
    if (rdgGranularity !== "Site") {
      const { departments: fdepts, lines: flines, units: funits } = state;
      const {
        departments: pdepts,
        lines: plines,
        units: punits,
      } = state.plantModel;

      let dept = fdepts.find((t) => t.DeptId === parseInt(pdepts));
      let line = flines.find((t) => t.LineId === parseInt(plines));
      let unit = funits.find((t) => t.MasterId === parseInt(punits));

      fields.push(
        { fieldName: "Department", fieldValues: [dept?.DeptDesc] },
        { fieldName: "Line", fieldValues: [line?.LineDesc] },
        { fieldName: "MasterUnit", fieldValues: [unit?.MasterDesc] }
      );
    }
  }

  return filterGridByMultipleFields(fields);
}

//#endregion

export {
  updatePlantModelView,
  gridTasksPlanningToolbarPreparing,
  gridTasksPlanningColumns,
  filterGrid,
};
