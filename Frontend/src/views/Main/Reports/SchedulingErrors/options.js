import icons from "../../../../resources/icons";
import { getIcon } from "../../../../utils";

//#region plant model filters

function updatePlantModelView(key, values, state) {
  const { departments, lines, units, workcells, groups } = state.plantModel;

  let temp = {};

  temp.departments = state.departments;
  temp.lines = state.lines;
  temp.units = state.units;
  temp.workcells = state.workcells;
  temp.groups = state.groups;

  temp.plantModel = {
    departments,
    lines,
    units,
    workcells,
    groups,
  };

  switch (key) {
    case "departments":
      temp.lines = [];
      temp.units = [];
      temp.workcells = [];
      temp.groups = [];
      temp.plantModel.departments = values;
      temp.plantModel.lines = [];
      temp.plantModel.units = [];
      temp.plantModel.workcells = [];
      temp.plantModel.groups = [];
      break;
    case "lines":
      temp.units = [];
      temp.workcells = [];
      temp.groups = [];
      temp.plantModel.lines = values;
      temp.plantModel.units = [];
      temp.plantModel.workcells = [];
      temp.plantModel.groups = [];
      break;
    case "units":
      temp.workcells = [];
      temp.groups = [];
      temp.plantModel.units = values;
      temp.plantModel.workcells = [];
      temp.plantModel.groups = [];
      break;
    case "workcells":
      temp.groups = [];
      temp.plantModel.workcells = values;
      temp.plantModel.groups = [];
      break;
    case "groups":
      temp.plantModel.groups = values;
      break;
    default:
      break;
  }

  return temp;
}
//#endregion

//#region grid

function gridSchedulingErrorsToolbarPreparing(
  e,
  t,
  onClickExportToExcel,
  onClickExportToPDF
) {
  return e.toolbarOptions.items.unshift(
    {
      location: "after",
      widget: "dxButton",
      cssClass: "btnExcelExportSchedulingErrors",
      options: {
        hint: t("Export to Excel"),
        icon: getIcon(icons.excel),
        onClick: onClickExportToExcel,
      },
    },
    {
      location: "after",
      widget: "dxButton",
      cssClass: "btnPdfExportSchedulingErrors",
      options: {
        hint: t("Export to PDF"),
        icon: getIcon(icons.pdf),
        onClick: onClickExportToPDF,
      },
    }
  );
}

function gridSchedulingErrorsColumns() {
  return [
    {
      dataField: "RowType",
      caption: "Scheduling Source",
      visibility: true,
      allowEditing: false,
      allowSearch: false,
      allowFiltering: true,
      visibleIndex: 1,
      showInColumnChooser: true,
      exportEnable: true,
      width: "90px",
      cellTemplate: function (container, value) {
        if (value.value === "ERROR") {
          container.style = "background-color: #ff0000;text-align:center;";
          let j = document.createElement("span");
          j.appendChild(document.createTextNode(value.value));
          container.appendChild(j);
        } else {
          container.style = "text-align:center;";
          let j = document.createElement("span");
          j.appendChild(document.createTextNode(value.value));
          container.appendChild(j);
        }
      },
    },
    {
      dataField: "DepartmentDesc",
      caption: "Area",
      visibility: true,
      allowEditing: false,
      allowSearch: false,
      allowFiltering: true,
      visibleIndex: 2,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "LineDesc",
      caption: "Line",
      visibility: true,
      allowEditing: false,
      allowSearch: false,
      allowFiltering: true,
      visibleIndex: 3,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "MasterUnitDesc",
      caption: "Primary Unit",
      visibility: true,
      allowEditing: false,
      allowSearch: false,
      allowFiltering: true,
      visibleIndex: 4,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "SlaveUnitDesc",
      caption: "Module",
      visibility: true,
      allowEditing: false,
      allowSearch: false,
      allowFiltering: true,
      visibleIndex: 5,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "ProductionGroupDesc",
      caption: "Group",
      visibility: true,
      allowEditing: false,
      allowSearch: false,
      allowFiltering: true,
      visibleIndex: 6,
      showInColumnChooser: true,
      exportEnable: true,
      widht: "50px",
    },
    {
      dataField: "FL1",
      caption: "FL1",
      visibility: true,
      allowEditing: false,
      allowSearch: false,
      allowFiltering: true,
      visibleIndex: 7,
      showInColumnChooser: true,
      exportEnable: true,
      width: "50px",
    },
    {
      dataField: "FL2",
      caption: "FL2",
      visibility: true,
      allowEditing: false,
      allowSearch: false,
      allowFiltering: true,
      visibleIndex: 8,
      showInColumnChooser: true,
      exportEnable: true,
      width: "50px",
    },
    {
      dataField: "FL3",
      caption: "FL3",
      visibility: true,
      allowEditing: false,
      allowSearch: false,
      allowFiltering: true,
      visibleIndex: 9,
      showInColumnChooser: true,
      exportEnable: true,
      width: "50px",
    },
    {
      dataField: "FL4",
      caption: "FL4",
      visibility: true,
      allowEditing: false,
      allowSearch: false,
      allowFiltering: true,
      visibleIndex: 10,
      showInColumnChooser: true,
      exportEnable: true,
      width: "50px",
    },
    {
      dataField: "VarDesc",
      caption: "Task Name",
      visibility: true,
      allowEditing: false,
      allowSearch: false,
      allowFiltering: true,
      visibleIndex: 11,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "ProdCode",
      caption: "Product",
      visibility: true,
      allowEditing: false,
      allowSearch: false,
      allowFiltering: true,
      visibleIndex: 12,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "Active",
      caption: "Active",
      visibility: true,
      allowEditing: false,
      allowSearch: false,
      allowFiltering: true,
      visibleIndex: 13,
      showInColumnChooser: true,
      exportEnable: true,
      alignment: "center",
      width: "80px",
    },
    {
      dataField: "Period",
      caption: "Period",
      visibility: true,
      allowEditing: false,
      allowSearch: false,
      allowFiltering: false,
      visibleIndex: 14,
      showInColumnChooser: false,
      exportEnable: false,
    },
    {
      dataField: "Window",
      caption: "Window",
      visibility: true,
      allowEditing: false,
      allowSearch: false,
      allowFiltering: false,
      visibleIndex: 15,
      showInColumnChooser: false,
      exportEnable: false,
      widht: "50px",
    },
    {
      dataField: "VarId",
      caption: "VarId",
      visibility: false,
      allowEditing: false,
      allowSearch: false,
      allowFiltering: true,
      visibleIndex: 16,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      visibility: true,
      width: 1,
      showInColumnChooser: false,
    },
  ];
}

//#endregion

export {
  updatePlantModelView,
  gridSchedulingErrorsToolbarPreparing,
  gridSchedulingErrorsColumns,
};
