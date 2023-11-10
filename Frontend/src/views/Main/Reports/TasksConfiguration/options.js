import icons from "../../../../resources/icons";
import { filterGridByMultipleFields, getIcon } from "../../../../utils/index";

//#region plant model

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

function updateFLView(key, values, state) {
  const { fl1, fl2, fl3, fl4 } = state.fl;

  let temp = {};

  temp.fl1 = state.fl1;
  temp.fl2 = state.fl2;
  temp.fl3 = state.fl3;
  temp.fl4 = state.fl4;

  temp.fl = {
    fl1,
    fl2,
    fl3,
    fl4,
  };

  switch (key) {
    case "fl1":
      temp.fl2 = [];
      temp.fl3 = [];
      temp.fl4 = [];
      temp.fl.fl1 = values;
      temp.fl.fl2 = [];
      temp.fl.fl3 = [];
      temp.fl.fl4 = [];
      break;
    case "fl2":
      temp.fl3 = [];
      temp.fl4 = [];
      temp.fl.fl2 = values;
      temp.fl.fl3 = [];
      temp.fl.fl4 = [];
      break;
    case "fl3":
      temp.fl4 = [];
      temp.fl.fl3 = values;
      temp.fl.fl4 = [];
      break;
    case "fl4":
      temp.fl.fl4 = values;
      break;
    default:
      break;
  }

  return temp;
}

//#endregion

//#region grid tasks properties

function gridTasksToolbarPreparing(
  e,
  t,
  onClickCustomizeView,
  onClickExportToExcel,
  onClickExportToPDF,
  customizeViewListItems
) {
  var columnChooser = e.toolbarOptions.items.find(
    (i) => i.name === "columnChooserButton"
  );

  columnChooser.location = "before";
  columnChooser.options.icon = getIcon(icons.columnChooser);

  return e.toolbarOptions.items.unshift(
    {
      location: "before",
      widget: "dxDropDownButton",
      cssClass: "btnCustomizeGridTasksConfiguration",
      options: {
        hint: t("Customize"),
        icon: getIcon(icons.customize),
        keyExpr: "id",
        displayExpr: "text",
        onSelectionChanged: onClickCustomizeView,
        items: customizeViewListItems(),
        dropDownOptions: {
          width: "auto",
        },
      },
    },
    {
      location: "after",
      widget: "dxButton",
      cssClass: "btnExcelExportTasksConfiguration",
      options: {
        hint: t("Export to Excel"),
        icon: getIcon(icons.excel),
        onClick: onClickExportToExcel,
      },
    },
    {
      location: "after",
      widget: "dxButton",
      cssClass: "btnPdfExportTasksConfiguration",
      options: {
        hint: t("Export to PDF"),
        icon: getIcon(icons.pdf),
        onClick: onClickExportToPDF,
      },
    }
  );
}

function gridTasksColumns() {
  return [
    {
      dataField: "DepartmentDesc",
      caption: "Area",
      visibility: true,
      allowEditing: false,
      allowSearch: true,
      allowFiltering: true,
      visibleIndex: 1,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "LineDesc",
      caption: "Line",
      visibility: true,
      allowEditing: false,
      allowSearch: true,
      allowFiltering: true,
      visibleIndex: 2,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "MasterUnitDesc",
      caption: "Primary Unit",
      visibility: true,
      allowEditing: false,
      allowSearch: true,
      allowFiltering: true,
      visibleIndex: 3,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "SlaveUnitDesc",
      caption: "Module",
      visibility: true,
      allowEditing: false,
      allowSearch: true,
      allowFiltering: true,
      visibleIndex: 4,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "ProductionGroupDesc",
      caption: "Group",
      visibility: true,
      allowEditing: false,
      allowSearch: true,
      allowFiltering: true,
      visibleIndex: 5,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "FL1",
      caption: "FL1",
      visibility: false,
      allowEditing: false,
      allowSearch: true,
      allowFiltering: true,
      visibleIndex: 6,
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
      visibleIndex: 7,
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
      visibleIndex: 8,
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
      visibleIndex: 9,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "VarDesc",
      caption: "Task Name",
      visibility: true,
      allowEditing: false,
      allowSearch: true,
      allowFiltering: true,
      visibleIndex: 10,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "VMId",
      caption: "VMId",
      visibility: true,
      allowEditing: false,
      allowSearch: true,
      allowFiltering: true,
      visibleIndex: 11,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "TaskLocation",
      caption: "Task Location",
      visibility: true,
      allowEditing: false,
      allowSearch: true,
      allowFiltering: true,
      visibleIndex: 12,
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
      visibleIndex: 13,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "TaskType",
      caption: "Task Type",
      visibility: true,
      allowEditing: false,
      allowSearch: true,
      allowFiltering: true,
      visibleIndex: 14,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "TaskAction",
      caption: "Task Action",
      visibility: true,
      allowEditing: false,
      allowSearch: true,
      allowFiltering: true,
      visibleIndex: 15,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "Active",
      caption: "Active",
      alignment: "center",
      visibility: true,
      allowEditing: false,
      allowSearch: false,
      allowFiltering: false,
      visibleIndex: 16,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "FrequencyType",
      caption: "Frequency",
      visibility: true,
      allowEditing: true,
      allowSearch: true,
      allowFiltering: true,
      visibleIndex: 17,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "Frequency",
      caption: "Period",
      visibility: true,
      allowEditing: false,
      allowSearch: true,
      allowFiltering: true,
      visibleIndex: 18,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "Window",
      caption: "Window",
      visibility: true,
      allowEditing: false,
      allowSearch: true,
      allowFiltering: true,
      visibleIndex: 19,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "TestTime",
      caption: "Test Time",
      visibility: true,
      allowEditing: false,
      allowSearch: true,
      allowFiltering: true,
      visibleIndex: 20,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "FixedFrequency",
      caption: "Fixed Frequency",
      alignment: "center",
      visibility: true,
      allowEditing: false,
      allowSearch: false,
      allowFiltering: false,
      visibleIndex: 21,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "StartDate",
      caption: "Start Date",
      visibility: false,
      allowEditing: false,
      allowSearch: true,
      allowFiltering: true,
      visibleIndex: 22,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "LongTaskName",
      caption: "Long Task Name",
      visibility: false,
      allowEditing: false,
      allowSearch: true,
      allowFiltering: true,
      visibleIndex: 23,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "NbrItems",
      caption: "# Items",
      visibility: false,
      allowEditing: false,
      allowSearch: true,
      allowFiltering: true,
      visibleIndex: 24,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "Duration",
      caption: "Duration",
      visibility: false,
      allowEditing: false,
      allowSearch: true,
      allowFiltering: true,
      visibleIndex: 25,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "NbrPeople",
      caption: "# People",
      visibility: false,
      allowEditing: false,
      allowSearch: true,
      allowFiltering: true,
      visibleIndex: 25,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "Criteria",
      caption: "Criteria",
      visibility: false,
      allowEditing: false,
      allowSearch: true,
      allowFiltering: true,
      visibleIndex: 26,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "Hazards",
      caption: "Hazards",
      visibility: false,
      allowEditing: false,
      allowSearch: true,
      allowFiltering: true,
      visibleIndex: 27,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "Method",
      caption: "Method",
      visibility: false,
      allowEditing: false,
      allowSearch: true,
      allowFiltering: true,
      visibleIndex: 28,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "PPE",
      caption: "PPE",
      visibility: false,
      allowEditing: false,
      allowSearch: true,
      allowFiltering: true,
      visibleIndex: 29,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "Tools",
      caption: "Tools",
      visibility: false,
      allowEditing: false,
      allowSearch: true,
      allowFiltering: true,
      visibleIndex: 30,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "Lubricant",
      caption: "Lubricant",
      visibility: false,
      allowEditing: false,
      allowSearch: true,
      allowFiltering: true,
      visibleIndex: 31,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "DocumentLinkTitle",
      caption: "Document Link Title",
      visibility: false,
      allowEditing: false,
      allowSearch: true,
      allowFiltering: true,
      visibleIndex: 32,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "DocumentLinkPath",
      caption: "Document Link Path",
      visibility: false,
      allowEditing: false,
      allowSearch: true,
      allowFiltering: true,
      visibleIndex: 33,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "QFactorType",
      caption: "Q-Factor Type",
      visibility: false,
      allowEditing: false,
      allowSearch: true,
      allowFiltering: true,
      visibleIndex: 34,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "PrimaryQFactor",
      caption: "Primary Q-Factor",
      visibility: false,
      allowEditing: false,
      allowSearch: true,
      allowFiltering: true,
      visibleIndex: 35,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "VarId",
      caption: "Var_Id",
      visibility: false,
      allowEditing: false,
      allowSearch: false,
      allowFiltering: true,
      visibleIndex: 36,
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

function filterGrid(state) {
  let fields = [];

  if (state.tasksConfigFilterGroup === "Plant Model") {
    const { lines, units, workcells, groups } = state.plantModel;

    fields.push(
      { fieldName: "PLId", fieldValues: lines },
      { fieldName: "MasterUnitId", fieldValues: units },
      { fieldName: "SlaveUnitId", fieldValues: workcells },
      { fieldName: "ProductionGroupId", fieldValues: groups }
    );
  } else {
    const { fl2, fl3, fl4 } = state.fl;

    fields.push(
      { fieldName: "FL2", fieldValues: fl2 },
      { fieldName: "FL3", fieldValues: fl3 },
      { fieldName: "FL4", fieldValues: fl4 }
    );
  }

  return filterGridByMultipleFields(fields);
}

//#endregion

function getFLIds(flStore, flSelected) {
  return flStore
    .filter((fl) => flSelected.find((f) => f === fl.ItemDesc))
    .map((m) => m.Id);
}

export {
  updateFLView,
  updatePlantModelView,
  gridTasksToolbarPreparing,
  gridTasksColumns,
  filterGrid,
  getFLIds,
};
