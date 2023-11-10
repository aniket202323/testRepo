import icons from "../../../../resources/icons";
import { getIcon } from "../../../../utils";

const cellTemplate = (element, info) => {
  let j = document.createElement("span");
  j.className = info.value === 0 ? "redCellValue" : "";

  if (info.value === undefined) {
    info.value = 0;
  }
  j.appendChild(document.createTextNode(info.value));
  element.appendChild(j);
};

//#region grid routes

function gridRoutesToolbarPreparing(
  e,
  t,
  globalAccessLevel,
  handlerAddRoute,
  handlerDeleteRoutes,
  handlerAllRouteTeams,
  handlerAllRouteTasks,
  handlerExportToPDF,
  handlerExportToExcel
) {
  return e.toolbarOptions.items.unshift(
    [4, 3].includes(globalAccessLevel)
      ? {
          location: "before",
          widget: "dxButton",
          cssClass: "btnAddRoute",
          options: {
            icon: getIcon(icons.add),
            hint: t("Add Route"),
            onClick: handlerAddRoute,
          },
        }
      : {},
    [4, 3].includes(globalAccessLevel)
      ? {
          location: "before",
          widget: "dxButton",
          cssClass: "btnDeleteRoute",
          options: {
            icon: getIcon(icons.remove),
            hint: t("Delete Route"),
            onClick: handlerDeleteRoutes,
          },
        }
      : {},
    {
      location: "before",
      widget: "dxButton",
      cssClass: "btnAllRouteTeams",
      options: {
        text: t("All Route-Teams"),
        onClick: handlerAllRouteTeams,
      },
    },
    {
      location: "before",
      widget: "dxButton",
      cssClass: "btnAllRouteTasks",
      options: {
        text: t("All Route-Tasks"),
        onClick: handlerAllRouteTasks,
      },
    },
    {
      location: "after",
      widget: "dxButton",
      cssClass: "btnExcelExportRoutesMgmt",
      options: {
        icon: getIcon(icons.excel),
        hint: t("Export to Excel"),
        onClick: () => handlerExportToExcel("Routes"),
      },
    },
    {
      location: "after",
      widget: "dxButton",
      cssClass: "btnPdfExportRoutesMgmt",
      options: {
        icon: getIcon(icons.pdf),
        hint: t("Export to PDF"),
        onClick: () => handlerExportToPDF("Routes"),
      },
    }
  );
}

function gridRoutesColumns() {
  return [
    {
      dataField: "RouteId",
      caption: "Route Id",
      visibility: false,
    },
    {
      dataField: "RouteDescription",
      caption: "Route Description",
      alignment: "left",
      allowEditing: true,
      allowFiltering: true,
      validationRules: [{ type: "required" }],
    },
    {
      dataField: "NbrTasks",
      caption: "# Tasks",
      alignment: "center",
      width: "100px",
      allowFiltering: false,
      cellTemplate: (element, info) => cellTemplate(element, info),
    },
    {
      dataField: "NbrTeams",
      caption: "# Teams",
      alignment: "center",
      width: "100px",
      allowFiltering: false,
      cellTemplate: (element, info) => cellTemplate(element, info),
    },
  ];
}

//#endregion

//#region grid teams
function gridTeamsToolbarPreparing(
  t,
  e,
  handlerExportToExcel,
  handlerExportToPDF
) {
  return e.toolbarOptions.items.unshift(
    {
      location: "after",
      widget: "dxButton",
      cssClass: "btnExcelExportRoutesMgmtTeams",
      options: {
        icon: getIcon(icons.excel),
        hint: t("Export to Excel"),
        onClick: () => handlerExportToExcel("Teams"),
      },
    },
    {
      location: "after",
      widget: "dxButton",
      cssClass: "btnPDFExportRoutesMgmtTeams",
      options: {
        icon: getIcon(icons.pdf),
        hint: t("Export to PDF"),
        onClick: () => handlerExportToPDF("Teams"),
      },
    }
  );
}

function gridTeamsColumns() {
  return [
    {
      dataField: "Selected",
      caption: "Selected",
      sortOrder: "desc",
      visibility: false,
    },
    {
      dataField: "TeamId",
      caption: "Team Id",
      visibility: false,
    },
    {
      dataField: "TeamDesc",
      caption: "Team Description",
    },
  ];
}

//#endregion

//#region grid tasks

function gridTasksToolbarPreparing(
  e,
  t,
  changeRowsForPageTasks,
  handlerExportToPDF,
  handlerExportToExcel
) {
  return e.toolbarOptions.items.unshift(
    {
      location: "before",
      template: "totalRowsPerPage",
    },
    {
      location: "before",
      widget: "dxSelectBox",
      cssClass: "sboRowsPerPageRoutesMgmt",
      options: {
        width: 100,
        heigth: 100,
        items: [
          {
            value: 10,
            text: "10",
          },
          {
            value: 20,
            text: "20",
          },
          {
            value: 30,
            text: "30",
          },
          {
            value: 40,
            text: "40",
          },
          {
            value: 50,
            text: "50",
          },
        ],
        displayExpr: "text",
        valueExpr: "value",
        value: 30,
        onValueChanged: changeRowsForPageTasks,
      },
    },
    {
      location: "after",
      widget: "dxButton",
      cssClass: "btnExcelExportRoutesMgmtTasks",
      options: {
        hint: t("Export to Excel"),
        icon: getIcon(icons.excel),
        onClick: () => handlerExportToExcel("Tasks"),
      },
    },
    {
      location: "after",
      widget: "dxButton",
      cssClass: "btnPDFExportRoutesMgmtTasks",
      options: {
        icon: getIcon(icons.pdf),
        hint: t("Export to PDF"),
        onClick: () => handlerExportToPDF("Tasks"),
      },
    }
  );
}

function gridTasksColumns(t) {
  return [
    { dataField: "Line", caption: t("Line") },
    { dataField: "MasterUnit", caption: t("Primary Unit") },
    { dataField: "SlaveUnit", caption: t("Module"), width: "100px" },
    { dataField: "Group", caption: t("Group"), width: "80px" },
    { dataField: "Task", caption: t("Task"), allowSorting: false },
    {
      dataField: "TourDesc",
      caption: t("Tour Stop"),
      visibility: true,
    },
    {
      dataField: "TaskOrder",
      caption: t("Task Order"),
      dataType: "number",
      width: "120px",
      alignment: "center",
      cellTemplate: (container, options) => {
        var taskOrder =
          options.component.pageSize() * options.component.pageIndex() +
          (options.rowIndex + 1);
        let j = document.createElement("span");
        j.appendChild(document.createTextNode(taskOrder));
        container.appendChild(j);
      },
    },
    { dataField: "ItemId", caption: t("Item Id"), visibility: false },
    { dataField: "TourId", caption: t("Tour Id"), visibility: false },
    { dataField: "IsAdded", caption: t("IsAdded"), visibility: false },
    {
      dataField: "TourTaskOrder",
      caption: t("Tour Task Order"),
      visibility: false,
      dataType: "number",
      alignment: "left",
      width: "120px",
      allowSorting: false,
    },
  ];
}

//#endregion

//#region grid all route teams / taks

function gridAllRouteToolbarPreparing(
  e,
  handlerBackToRoutes,
  handlerExportToPDF,
  handlerExportToExcel,
  gridToExport
) {
  return e.toolbarOptions.items.unshift(
    {
      location: "before",
      widget: "dxButton",
      cssClass: "btnReturnToRoutesMgmt",
      options: {
        icon: getIcon(icons.back),
        hint: "Return to Routes Management",
        onClick: handlerBackToRoutes,
      },
    },
    {
      location: "after",
      widget: "dxButton",
      cssClass: "btnAllRouteExcelExport",
      options: {
        icon: getIcon(icons.excel),
        hint: "Export to Excel",
        onClick: () => handlerExportToExcel(gridToExport),
      },
    },
    {
      location: "after",
      widget: "dxButton",
      cssClass: "btnAllRoutePDFExport",
      options: {
        icon: getIcon(icons.pdf),
        hint: "Export to PDF",
        onClick: () => handlerExportToPDF(gridToExport),
      },
    }
  );
}

function gridAllRouteTeams() {
  return [
    {
      dataField: "Route",
      caption: "Route",
      groupIndex: 1,
      allowGrouping: true,
    },
    { dataField: "Team", caption: "Teams" },
    { dataField: "TeamId", caption: "TeamId", visibility: false },
  ];
}

function gridAllRouteTasks() {
  return [
    {
      dataField: "Route",
      caption: "Route",
      groupIndex: 1,
      allowGrouping: true,
    },
    { dataField: "Line", caption: "Line" },
    { dataField: "MasterUnit", caption: "Primary Unit" },
    { dataField: "SlaveUnit", caption: "Module" },
    { dataField: "Group", caption: "Group" },
    { dataField: "Task", caption: "Task" },
    { dataField: "TaskOrder", caption: "TaskOrder" },
  ];
}

//#endregion

export {
  gridRoutesToolbarPreparing,
  gridRoutesColumns,
  gridTeamsToolbarPreparing,
  gridTeamsColumns,
  gridTasksToolbarPreparing,
  gridTasksColumns,
  gridAllRouteToolbarPreparing,
  gridAllRouteTeams,
  gridAllRouteTasks,
};
