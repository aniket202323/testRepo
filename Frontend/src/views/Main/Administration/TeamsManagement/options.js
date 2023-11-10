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

//#region grid teams

function gridTeamsToolbarPreparing(
  e,
  t,
  globalAccessLevel,
  handlerAddTeam,
  handlerDeleteTeam,
  handlerAllTeamRoutes,
  handlerAllTeamUsers,
  handlerAllTeamTasks,
  handlerExportToPDF,
  handlerExportToExcel
) {
  return e.toolbarOptions.items.unshift(
    [4, 3].includes(globalAccessLevel)
      ? {
          location: "before",
          widget: "dxButton",
          cssClass: "btnAddTeam",
          options: {
            icon: getIcon(icons.add),
            hint: t("Add Team"),
            onClick: handlerAddTeam,
          },
        }
      : {},
    [4, 3].includes(globalAccessLevel)
      ? {
          location: "before",
          widget: "dxButton",
          cssClass: "btnDeleteTeam",
          options: {
            icon: getIcon(icons.remove),
            hint: t("Delete Team"),
            onClick: handlerDeleteTeam,
          },
        }
      : {},
    {
      location: "before",
      widget: "dxButton",
      cssClass: "btnAllTeamRoutes",
      options: {
        text: t("All Team-Routes"),
        onClick: handlerAllTeamRoutes,
      },
    },
    {
      location: "before",
      widget: "dxButton",
      cssClass: "btnAllTeamUsers",
      options: {
        text: t("All Team-Users"),
        onClick: handlerAllTeamUsers,
      },
    },
    {
      location: "before",
      widget: "dxButton",
      cssClass: "btnAllTeamTasks",
      options: {
        text: t("All Team-Tasks"),
        onClick: handlerAllTeamTasks,
      },
    },
    {
      location: "after",
      widget: "dxButton",
      cssClass: "btnExcelExportTeamsMgmt",
      options: {
        icon: getIcon(icons.excel),
        hint: t("Export to Excel"),
        onClick: () => handlerExportToExcel("Teams"),
      },
    },
    {
      location: "after",
      widget: "dxButton",
      cssClass: "btnPdfExportTeamsMgmt",
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
      dataField: "TeamId",
      caption: "Team Id",
      visibility: false,
    },
    {
      dataField: "TeamDescription",
      caption: "Team Description",
      alignment: "left",
      allowEditing: true,
      validationRules: [{ type: "required" }],
    },
    {
      dataField: "NbrUsers",
      caption: "# Users",
      alignment: "center",
      width: "100px",
      cellTemplate: (element, info) => cellTemplate(element, info),
    },
    {
      dataField: "NbrRoutes",
      caption: "# Routes",
      alignment: "center",
      width: "100px",
      cellTemplate: (element, info) => cellTemplate(element, info),
    },
    {
      dataField: "NbrTasks",
      caption: "# Tasks",
      alignment: "center",
      width: "100px",
      //cellTemplate: (element, info) => cellTemplate(element, info),
    },
  ];
}

//#endregion

//#region grid routes

function gridRoutesToolbarPreparing(
  t,
  e,
  handlerExportToPDF,
  handlerExportToExcel
) {
  return e.toolbarOptions.items.unshift(
    {
      location: "after",
      widget: "dxButton",
      cssClass: "btnExcelExportTeamsMgmtRoutes",
      options: {
        icon: getIcon(icons.excel),
        hint: t("Export to Excel"),
        onClick: () => handlerExportToExcel("Routes"),
      },
    },
    {
      location: "after",
      widget: "dxButton",
      cssClass: "btnPDFExportTeamsMgmtRoutes",
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
      dataField: "Selected",
      caption: "Selected",
      sortOrder: "desc",
      visibility: false,
    },
    {
      dataField: "RouteId",
      caption: "Route Id",
      visibility: false,
    },
    {
      dataField: "RouteDesc",
      caption: "Route Description",
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
      cssClass: "sboRowsPerPageTeamsMgmt",
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
      cssClass: "btnExcelExportTeamsMgmtTasks",
      options: {
        hint: t("Export to Excel"),
        icon: getIcon(icons.excel),
        onClick: () => handlerExportToExcel("Tasks"),
      },
    },
    {
      location: "after",
      widget: "dxButton",
      cssClass: "btnPDFExportTeamsMgmtTasks",
      options: {
        icon: getIcon(icons.pdf),
        hint: t("Export to PDF"),
        onClick: () => handlerExportToPDF("Tasks"),
      },
    }
  );
}

function gridTasksColumns() {
  return [
    { dataField: "Line", caption: "Line" },
    { dataField: "MasterUnit", caption: "Primary Unit" },
    { dataField: "SlaveUnit", caption: "Module" },
    { dataField: "Group", caption: "Group" },
    { dataField: "Task", caption: "Task" },
    { dataField: "ItemId", caption: "Item Id", visibility: false },
  ];
}

//#endregion

//#region grid users

function gridUsersToolbarPreparing(
  e,
  t,
  handlerExportToPDF,
  handlerExportToExcel
) {
  return e.toolbarOptions.items.unshift(
    {
      location: "after",
      widget: "dxButton",
      cssClass: "btnExcelExportTeamsMgmtUsers",
      options: {
        icon: getIcon(icons.excel),
        hint: t("Export to Excel"),
        onClick: () => handlerExportToExcel("Users"),
      },
    },
    {
      location: "after",
      widget: "dxButton",
      cssClass: "btnPDFExportTeamsMgmtUsers",
      options: {
        icon: getIcon(icons.pdf),
        hint: t("Export to PDF"),
        onClick: () => handlerExportToPDF("Users"),
      },
    }
  );
}

function gridUsersColumns() {
  return [
    {
      dataField: "Selected",
      caption: "Selected",
      sortOrder: "desc",
      visibility: false,
    },
    {
      dataField: "UserId",
      caption: "User Id",
      visibility: false,
    },
    {
      dataField: "Username",
      caption: "User Name",
    },
  ];
}

//#endregion

//#region grid all teams report

function gridAllReportsToolbarPreparing(
  e,
  t,
  handlerBackToTeams,
  handlerExportToPDF,
  handlerExportToExcel,
  gridToExport
) {
  e.toolbarOptions.items.unshift(
    {
      location: "before",
      widget: "dxButton",
      cssClass: "btnReturnToTeamsMgmt",
      options: {
        icon: getIcon(icons.back),
        hint: t("Return to Teams Management"),
        onClick: handlerBackToTeams,
      },
    },
    {
      location: "after",
      widget: "dxButton",
      cssClass: "btnAllTeamExcelExport",
      options: {
        icon: getIcon(icons.excel),
        hint: t("Export to Excel"),
        onClick: () => handlerExportToExcel(gridToExport),
      },
    },
    {
      location: "after",
      widget: "dxButton",
      cssClass: "btnAllTeamPDFExport",
      options: {
        icon: getIcon(icons.pdf),
        hint: t("Export to PDF"),
        onClick: () => handlerExportToPDF(gridToExport),
      },
    }
  );
}

function gridAllTeamRoutesColumns() {
  return [
    {
      caption: "Route",
      dataField: "Route",
      groupIndex: "0",
    },
    {
      caption: "RouteId",
      dataField: "RouteId",
      visibility: false,
    },
    {
      caption: "Team",
      dataField: "Team",
    },
  ];
}

function gridAllTeamUsersColumns() {
  return [
    { caption: "Team", dataField: "Team", groupIndex: "0" },
    { caption: "Username", dataField: "Username" },
  ];
}

function gridAllTeamTasksColumns() {
  return [
    {
      caption: "Team",
      dataField: "Team",
      groupIndex: "0",
    },
    {
      caption: "Line",
      dataField: "Line",
    },
    {
      caption: "Primary Unit",
      dataField: "MasterUnit",
    },
    {
      caption: "Module",
      dataField: "SlaveUnit",
    },
    {
      caption: "Group",
      dataField: "Group",
    },
    {
      caption: "Task",
      dataField: "Task",
    },
  ];
}

//#endregion

export {
  gridTeamsToolbarPreparing,
  gridTeamsColumns,
  gridRoutesToolbarPreparing,
  gridRoutesColumns,
  gridTasksToolbarPreparing,
  gridTasksColumns,
  gridUsersToolbarPreparing,
  gridUsersColumns,
  gridAllReportsToolbarPreparing,
  gridAllTeamRoutesColumns,
  gridAllTeamUsersColumns,
  gridAllTeamTasksColumns,
};
