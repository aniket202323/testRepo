import { filterGridByMultipleFields, getIcon } from "../../../../utils";
import icons from "../../../../resources/icons";

//#region grid tasks properties

function gridTasksToolbarPreparing(
  e,
  t,
  handlerTaskEditor,
  onClickEditMultipleTasks,
  onClickDeleteMultipleTasks,
  onClickSaveChanges,
  onClickCustomizeView,
  onClickRefreshGrid,
  onClickQuickPrint,
  onClickExportToExcel,
  onClickExportToPDF,
  onClickExportRawDataFormat,
  customizeViewListItems
) {
  var columnChooser = e.toolbarOptions.items.find(
    (i) => i.name === "columnChooserButton"
  );

  columnChooser.location = "before";
  columnChooser.options.icon = getIcon(icons.columnChooser);

  return e.toolbarOptions.items.unshift(
    {
      cssClass: "btnCreateTask",
      location: "before",
      widget: "dxButton",
      options: {
        disabled: false,
        icon: getIcon(icons.gridAdd),
        hint: t("Create a new Task"),
        onClick: handlerTaskEditor,
      },
    },
    {
      location: "before",
      widget: "dxButton",
      cssClass: "btnEditMultipleTasksMgmt",
      options: {
        disabled: true,
        icon: getIcon(icons.editTask),
        hint: t("Edit Multiple"),
        onClick: onClickEditMultipleTasks,
      },
    },
    {
      location: "before",
      widget: "dxButton",
      cssClass: "btnObsoleteMultipleTasksMgmt",
      options: {
        disabled: true,
        icon: getIcon(icons.removeTask),
        hint: t("Obsolete Multiple"),
        onClick: onClickDeleteMultipleTasks,
      },
    },
    {
      location: "before",
      widget: "dxButton",
      cssClass: "btnSaveChangesTasksMgmt",
      options: {
        disabled: true,
        icon: getIcon(icons.save),
        hint: t("Save Changes"),
        onClick: onClickSaveChanges,
      },
    },
    {
      location: "before",
      widget: "dxDropDownButton",
      cssClass: "btnCustomizeGridTasksMgmt",
      options: {
        hint: t("Customize"),
        icon: getIcon(icons.customize),
        keyExpr: "id",
        displayExpr: "text",
        onSelectionChanged: onClickCustomizeView,
        items: customizeViewListItems(),
        dropDownOptions: {
          width: "auto",
          color: "",
        },
      },
    },
    {
      location: "before",
      widget: "dxButton",
      cssClass: "btnRefreshGridTasksMgmt",
      options: {
        hint: t("Refresh List"),
        icon: getIcon(icons.refresh_grid),
        onClick: onClickRefreshGrid,
      },
    },
    {
      location: "after",
      widget: "dxButton",
      cssClass: "btnQuickPrintTasksMgmt",
      options: {
        hint: t("Quick Print"),
        icon: getIcon(icons.print),
        onClick: onClickQuickPrint,
      },
    },
    {
      location: "after",
      widget: "dxButton",
      cssClass: "btnExcelExportTasksMgmt",
      options: {
        hint: t("Export to Excel"),
        icon: getIcon(icons.excel),
        onClick: onClickExportToExcel,
      },
    },
    {
      location: "after",
      widget: "dxButton",
      cssClass: "btnPdfExportTasksMgmt",
      options: {
        hint: t("Export to PDF"),
        icon: getIcon(icons.pdf),
        onClick: onClickExportToPDF,
      },
    },
    {
      location: "after",
      widget: "dxButton",
      cssClass: "btnRawDataExportTasksMgmt",
      options: {
        hint: t("Export Raw Data Format"),
        icon: getIcon(icons.excel),
        onClick: onClickExportRawDataFormat,
      },
    }
  );
}

function gridTasksColumns(t) {
  return [
    {
      dataField: "Status",
      caption: "Status",
      visibility: true,
      allowEditing: false,
      allowSearch: false,
      allowFiltering: true,
      visibleIndex: 3,
      showInColumnChooser: false,
      width: "80px",
      exportEnable: false,
      cellTemplate: (container, options) => {
        let add = "background: #1bff00;";
        let modify = "background: #ffff00;";
        let obsolete = "background: #ff0000;color: white;";
        if (options.value === "Add") container.style = add;
        if (options.value === "Modify") container.style = modify;
        if (options.value === "Obsolete") container.style = obsolete;

        let j = document.createElement("span");
        j.appendChild(document.createTextNode(options.value));
        container.appendChild(j);
      },
    },
    {
      dataField: "succes_failure",
      caption: "Success/Failure",
      visibility: true,
      allowEditing: false,
      allowSearch: false,
      allowFiltering: true,
      visibleIndex: 4,
      showInColumnChooser: false,
      exportEnable: false,
    },
    {
      dataField: "DepartmentDesc",
      caption: "Area",
      visibility: true,
      allowEditing: false,
      allowSearch: true,
      allowFiltering: true,
      visibleIndex: 5,
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
      visibleIndex: 6,
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
      visibleIndex: 7,
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
      visibleIndex: 8,
      showInColumnChooser: true,
      exportEnable: true,
      cellTemplate: (container, options) => {
        if (options.data.SlaveUnitDesc.includes("U:")) {
          options.value = options.data.SlaveUnitDesc.replace("U:", "");
        }
        let j = document.createElement("span");
        j.appendChild(document.createTextNode(options.value));
        container.appendChild(j);
      },
    },
    {
      dataField: "ProductionGroupDesc",
      caption: "Group",
      visibility: true,
      allowEditing: false,
      allowSearch: true,
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
      allowSearch: true,
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
      allowSearch: true,
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
      allowSearch: true,
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
      allowSearch: true,
      allowFiltering: true,
      visibleIndex: 13,
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
      visibleIndex: 14,
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
      visibleIndex: 15,
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
      visibleIndex: 16,
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
      visibleIndex: 17,
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
      visibleIndex: 18,
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
      visibleIndex: 19,
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
      visibleIndex: 20,
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
      visibleIndex: 21,
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
      visibleIndex: 22,
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
      visibleIndex: 23,
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
      visibleIndex: 24,
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
      visibleIndex: 25,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "ShiftOffset",
      caption: "Shift Offset",
      visibility: false,
      allowEditing: false,
      allowSearch: true,
      allowFiltering: true,
      visibleIndex: 26,
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
      visibleIndex: 27,
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
      visibleIndex: 28,
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
      visibleIndex: 29,
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
      visibleIndex: 30,
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
      visibleIndex: 31,
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
      visibleIndex: 32,
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
      visibleIndex: 33,
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
      visibleIndex: 34,
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
      visibleIndex: 35,
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
      visibleIndex: 36,
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
      visibleIndex: 37,
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
      visibleIndex: 38,
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
      visibleIndex: 39,
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
      visibleIndex: 40,
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
      visibleIndex: 41,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "IsHSE",
      caption: "Is HSE?",
      visibility: false,
      allowEditing: false,
      allowSearch: true,
      allowFiltering: true,
      visibleIndex: 42,
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
      visibleIndex: 43,
      showInColumnChooser: true,
      exportEnable: true,
      cellTemplate: (container, options) => {
        let hidden = "visibility: hidden;";
        if (options.value < 0) container.style = hidden;

        let j = document.createElement("span");
        j.appendChild(document.createTextNode(options.value));
        container.appendChild(j);
      },
    },
    {
      dataField: "KeyId",
      caption: "Key_Id",
      visibility: false,
      allowEditing: false,
      allowSearch: false,
      allowFiltering: false,
      visibleIndex: 44,
      showInColumnChooser: false,
      exportEnable: false,
    },
    {
      dataField: "LineVersion",
      caption: "Line Version",
      visibility: false,
      allowEditing: false,
      allowSearch: true,
      allowFiltering: true,
      visibleIndex: 45,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "ModuleFeatureVersion",
      caption: "Module Feature Version",
      visibility: false,
      allowEditing: false,
      allowSearch: true,
      allowFiltering: true,
      visibleIndex: 46,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "ScheduleScope",
      caption: "Schedule Scope",
      visibility: false,
      allowEditing: false,
      allowSearch: true,
      allowFiltering: true,
      visibleIndex: 47,
      showInColumnChooser: true,
      exportEnable: true,
    },
    {
      dataField: "DepartmentId",
      caption: "Department_Id",
      visibility: false,
      allowEditing: false,
      allowSearch: false,
      allowFiltering: false,
      visibleIndex: 48,
      showInColumnChooser: false,
      exportEnable: false,
    },
    {
      dataField: "PLId",
      caption: "Line_Id",
      visibility: false,
      allowEditing: false,
      allowSearch: false,
      allowFiltering: false,
      visibleIndex: 49,
      showInColumnChooser: false,
      exportEnable: false,
    },
    {
      dataField: "MasterUnitId",
      caption: "MasterUnit_Id",
      visibility: false,
      allowEditing: false,
      allowSearch: false,
      allowFiltering: false,
      visibleIndex: 50,
      showInColumnChooser: false,
      exportEnable: false,
    },
    {
      dataField: "SlaveUnitId",
      caption: "SlaveUnit_Id",
      visibility: false,
      allowEditing: false,
      allowSearch: false,
      allowFiltering: false,
      visibleIndex: 51,
      showInColumnChooser: false,
      exportEnable: false,
    },
    {
      dataField: "ProductionGroupId",
      caption: "ProductionGroup_Id",
      visibility: false,
      allowEditing: false,
      allowSearch: false,
      allowFiltering: false,
      visibleIndex: 52,
      showInColumnChooser: false,
      exportEnable: false,
    },
    {
      dataField: "DisplayLink",
      caption: "Display Link",
      visibility: false,
      allowEditing: false,
      allowSearch: false,
      allowFiltering: false,
      visibleIndex: 53,
      showInColumnChooser: false,
      exportEnable: false,
    },
    {
      dataField: "ExternalLink",
      caption: "External Link",
      visibility: false,
      allowEditing: false,
      allowSearch: false,
      allowFiltering: false,
      visibleIndex: 54,
      showInColumnChooser: false,
      exportEnable: false,
    },
    {
      dataField: "LateTime",
      caption: "Late Time",
      visibility: false,
      allowEditing: false,
      allowSearch: false,
      allowFiltering: false,
      visibleIndex: 55,
      showInColumnChooser: false,
      exportEnable: false,
    },
    {
      dataField: "DueTime",
      caption: "Due Time",
      visibility: false,
      allowEditing: false,
      allowSearch: false,
      allowFiltering: false,
      visibleIndex: 56,
      showInColumnChooser: false,
      exportEnable: false,
    },
    {
      dataField: "AutoPostpone",
      caption: "Auto Postpone",
      visibility: false,
      allowEditing: false,
      allowSearch: true,
      allowFiltering: true,
      visibleIndex: 57,
      showInColumnChooser: true,
      exportEnable: true,
      alignment: "center",
      // cellRender: (e) => {
      //   return (
      //     <CheckBox
      //       value={e.data.AutoPostpone === 1}
      //       visible={e.data.AutoPostpone !== -1}
      //     />
      //   );
      // },
    },
  ];
}

function gridRawDataFormatColumns() {
  return [
    {
      dataField: "FL1",
      caption: "FL1",
      exportEnable: true,
    },
    {
      dataField: "FL2",
      caption: "FL2",
      exportEnable: true,
    },
    {
      dataField: "FL3",
      caption: "FL3",
      exportEnable: true,
    },
    {
      dataField: "FL4",
      caption: "FL4",
      exportEnable: true,
    },
    {
      dataField: "Criteria",
      caption: "eCIL_Criteria",
      exportEnable: true,
    },
    {
      dataField: "Duration",
      caption: "eCIL_Duration",
      exportEnable: true,
    },
    {
      dataField: "FixedFrequency",
      caption: "eCIL_Fixed_Frequency",
      exportEnable: true,
    },
    {
      dataField: "Hazards",
      caption: "eCIL_Hazard",
      exportEnable: true,
    },
    {
      dataField: "LongTaskName",
      caption: "eCIL_LongTaskName",
      exportEnable: true,
    },
    {
      dataField: "VarDesc",
      caption: "eCIL_TaskName",
      exportEnable: true,
    },
    {
      dataField: "Lubricant",
      caption: "eCIL_Lubricant",
      exportEnable: true,
    },
    {
      dataField: "Method",
      caption: "eCIL_Method",
      exportEnable: true,
    },
    {
      dataField: "NbrItems",
      caption: "eCIL_NbrItems",
      exportEnable: true,
    },
    {
      dataField: "NbrPeople",
      caption: "eCIL_NbrPeople",
      exportEnable: true,
    },
    {
      dataField: "PPE",
      caption: "eCIL_PPE",
      exportEnable: true,
    },
    {
      dataField: "TaskAction",
      caption: "eCIL_Task_Action",
      exportEnable: true,
    },
    {
      dataField: "Active",
      caption: "eCIL_Active",
      exportEnable: true,
    },
    {
      dataField: "Window",
      caption: "eCIL_Window",
      exportEnable: true,
    },
    {
      dataField: "Frequency",
      caption: "eCIL_Frequency",
      exportEnable: true,
    },
    {
      dataField: "TaskType",
      caption: "eCIL_Task_Type",
      exportEnable: true,
    },
    {
      dataField: "TestTime",
      caption: "eCIL_Test_Time",
      exportEnable: true,
    },
    {
      dataField: "Tools",
      caption: "eCIL_Tools",
      exportEnable: true,
    },
    {
      dataField: "VMId",
      caption: "eCIL_VMId",
      exportEnable: true,
    },
    {
      dataField: "TaskLocation",
      caption: "eCIL_Task_Location",
      exportEnable: true,
    },
    {
      dataField: "ScheduleScope",
      caption: "eCIL_Schedule_Scope",
      exportEnable: true,
    },
    {
      dataField: "",
      caption: "eCIL_LastCompletionDate",
      exportEnable: true,
    },
    {
      dataField: "StartDate",
      caption: "eCIL_First_Effective_Date",
      exportEnable: true,
    },
    {
      dataField: "LineVersion",
      caption: "eCIL_Line_Version",
      exportEnable: true,
    },
    {
      dataField: "ModuleFeatureVersion",
      caption: "eCIL_Module_Feature_Version",
      exportEnable: true,
    },
    {
      dataField: "TaskId",
      caption: "eCIL_TaskId",
      exportEnable: true,
    },
    {
      dataField: "SlaveUnitDesc",
      caption: "eCIL_Module",
      exportEnable: true,
    },
    {
      dataField: "DocumentLinkTitle",
      caption: "eCIL_DocumentDescription1",
      exportEnable: true,
    },
    {
      dataField: "DocumentLinkPath",
      caption: "eCIL_DocumentLink1",
      exportEnable: true,
    },
    {
      dataField: "",
      caption: "eCIL_DocumentDescription2",
      exportEnable: true,
    },
    {
      dataField: "",
      caption: "eCIL_DocumentLink2",
      exportEnable: true,
    },
    {
      dataField: "",
      caption: "eCIL_DocumentDescription3",
      exportEnable: true,
    },
    {
      dataField: "",
      caption: "eCIL_DocumentLink3",
      exportEnable: true,
    },
    {
      dataField: "",
      caption: "eCIL_DocumentDescription4",
      exportEnable: true,
    },
    {
      dataField: "",
      caption: "eCIL_DocumentLink4",
      exportEnable: true,
    },
    {
      dataField: "",
      caption: "eCIL_DocumentDescription5",
      exportEnable: true,
    },
    {
      dataField: "",
      caption: "eCIL_DocumentLink5",
      exportEnable: true,
    },
    {
      dataField: "IsHSE",
      caption: "eCIL_HSEFlag",
      exportEnable: true,
    },
    {
      dataField: "FrequencyType",
      caption: "eCIL_FrequencyType",
      exportEnable: true,
    },
    {
      dataField: "ShiftOffset",
      caption: "eCIL_ShiftOffset",
      exportEnable: true,
    },
    {
      dataField: "AutoPostpone",
      caption: "eCIL_Autopostpone",
      exportEnable: true,
    },
  ];
}

function filterGrid(state) {
  let fields = [];
  let editedTasks = state.data.filter((task) => task.Status);

  if (state.tasksMgmtFilterGroup === "Plant Model") {
    let { lines, units, workcells, groups } = state.plantModel;

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

  // return filterGridByMultipleFields(fields);
  let filter = filterGridByMultipleFields(fields);

  // add the Plant Model ID's for the edited tasks even if are not part of the filters
  if (editedTasks.length > 0) {
    if (filter) {
      // Production Line
      if (filter[0])
        filter[0].push("or", [
          ["Status", "=", "Add"],
          "and",
          filterGridByMultipleFields([
            { fieldName: "PLId", fieldValues: editedTasks.map((t) => t.PLId) },
          ]),
        ]);

      // Master Unit
      if (filter[1])
        filter[1].push("or", [
          ["Status", "=", "Add"],
          "and",
          filterGridByMultipleFields([
            {
              fieldName: "MasterUnitId",
              fieldValues: editedTasks.map((t) => t.MasterUnitId),
            },
          ]),
        ]);

      // Module
      if (filter[2])
        filter[2].push("or", [
          ["Status", "=", "Add"],
          "and",
          filterGridByMultipleFields([
            {
              fieldName: "SlaveUnitId",
              fieldValues: editedTasks.map((t) => t.SlaveUnitId),
            },
          ]),
        ]);

      // Production Group
      if (filter[3])
        filter[3].push("or", [
          ["Status", "=", "Add"],
          "and",
          filterGridByMultipleFields([
            {
              fieldName: "ProductionGroupId",
              fieldValues: editedTasks.map((t) => t.ProductionGroupId),
            },
          ]),
        ]);
    }
  }

  return filter;
}

function gridTasksSetButtonsState(refGrid) {
  const grid = refGrid.current?.instance;
  if (grid === undefined) return;
  let rowsSelected = grid.getSelectedRowsData().length;

  if (rowsSelected === 0) {
    document
      .querySelector(".btnEditMultipleTasksMgmt .dx-button")
      .classList.add("dx-state-disabled");
    document
      .querySelector(".btnObsoleteMultipleTasksMgmt .dx-button")
      .classList.add("dx-state-disabled");
    document
      .querySelector(".btnSaveChangesTasksMgmt .dx-button")
      .classList.add("dx-state-disabled");
  }

  if (rowsSelected === 1) {
    document
      .querySelector(".btnEditMultipleTasksMgmt .dx-button")
      .classList.add("dx-state-disabled");
    document
      .querySelector(".btnObsoleteMultipleTasksMgmt .dx-button")
      .classList.add("dx-state-disabled");
    document
      .querySelector(".btnSaveChangesTasksMgmt .dx-button")
      .classList.remove("dx-state-disabled");
  }

  if (rowsSelected > 1) {
    document
      .querySelector(".btnEditMultipleTasksMgmt .dx-button")
      .classList.remove("dx-state-disabled");
    document
      .querySelector(".btnObsoleteMultipleTasksMgmt .dx-button")
      .classList.remove("dx-state-disabled");
    document
      .querySelector(".btnSaveChangesTasksMgmt .dx-button")
      .classList.remove("dx-state-disabled");
  }
}

//#endregion

//#region grid tasks edit mode

function gridTasksEditModeColumns(level = 0) {
  return [
    {
      dataField: "PlantModel",
      caption: "Plant Model",
      allowFiltering: false,
      allowSearch: false,
      allowEditing: false,
    },
    // {
    //   dataField: "ItemDesc",
    //   caption: "Plant Model",
    //   allowFiltering: false,
    //   allowSearch: false,
    //   allowEditing: false,
    // },
    {
      dataField: "FL1",
      caption: "FL1",
      allowFiltering: false,
      allowSearch: false,
      allowEditing: level === 1,
    },
    {
      dataField: "FL2",
      caption: "FL2",
      allowFiltering: false,
      allowSearch: false,
      allowEditing: level === 2,
    },
    {
      dataField: "FL3",
      caption: "FL3",
      allowFiltering: false,
      allowSearch: false,
      allowEditing: level === 3,
    },
    {
      dataField: "FL4",
      caption: "FL4",
      allowFiltering: false,
      allowSearch: false,
      allowEditing: level === 4,
    },
    {
      dataField: "GlobalDesc",
      caption: "Global Desc",
      allowFiltering: false,
      allowSearch: false,
    },
    {
      dataField: "LocalDesc",
      caption: "Local Desc",
      allowFiltering: false,
      allowSearch: false,
      allowEditing: false,
    },
    {
      dataField: "LineVersion",
      caption: "Line Version",
      allowFiltering: false,
      allowSearch: false,
      allowEditing: level === 1,
    },
    {
      dataField: "ModuleFeatureVersion",
      caption: "Module Feature",
      allowFiltering: false,
      allowSearch: false,
      allowEditing: level === 3,
    },
  ];
}

function filterGridTasksEditMode(state) {
  let fields = [];

  if (true) {
    const { departments, lines, units, workcells, groups } = state.plantModel;

    var itemIdValues = groups.length
      ? groups
      : workcells.length
      ? workcells
      : units.length
      ? units
      : lines.length
      ? lines
      : departments;

    var levelValue = groups.length
      ? ["4"]
      : workcells.length
      ? ["3"]
      : units.length
      ? ["2"]
      : lines.length
      ? ["1"]
      : ["0"];

    fields.push(
      { fieldName: "ItemId", fieldValues: itemIdValues },
      { fieldName: "Level", fieldValues: levelValue }
    );
  }

  return filterGridByMultipleFields(fields);
}

//#endregion

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

function taskClass() {
  return {
    Active: true,
    AlarmFlag: false,
    AutoPostpone: false,
    CommentId: null,
    CommentInfo: "",
    Commit: false,
    Criteria: "",
    CurrentResult: "",
    Defects: null,
    DepartmentDesc: "",
    DepartmentId: null,
    DisplayLink: "",
    DocumentLinkPath: "",
    DocumentLinkTitle: "",
    DueTime: "",
    Duration: "",
    ExternalLink: "",
    FL5: "",
    FL1: "",
    FL2: "",
    FL3: "",
    FL4: "",
    Fixed: "",
    FixedFrequency: false,
    Frequency: null,
    FrequencyType: "Shiftly",
    Hazards: "",
    InitialResult: "",
    IsChangedActive: false,
    IsChangedAutopostponed: false,
    IsChangedFixedFrequency: false,
    IsChangedHSE: false,
    IsDefectLooked: false,
    IsDirty: false,
    IsFixedFrequency: false,
    IsHSE: false,
    IsInShift: false,
    IsPosponed: false,
    ItemNo: 0,
    KeyId: null,
    LateTime: "",
    LineDesc: "",
    LineVersion: "",
    LongTaskName: "",
    Lubricant: "",
    MasterUnitDesc: null,
    MasterUnitId: null,
    Method: "",
    ModuleFeatureVersion: "",
    NbrDefects: 0,
    NbrItems: "",
    NbrPeople: "",
    PLId: null,
    PPE: "",
    PrimaryQFactor: false,
    ProductionGroupDesc: "",
    ProductionGroupId: null,
    QFactorType: "",
    RouteDesc: "",
    SaveErrorMessage: "",
    ScheduleScope: "",
    ScheduleTime: "",
    ShiftOffset: 0,
    SlaveUnitDesc: "",
    SlaveUnitId: null,
    StartDate: "",
    Status: "Add",
    TaskAction: "",
    TaskFreq: "",
    TaskId: "",
    TaskLocation: "",
    TaskOrder: 0,
    TaskType: "",
    TeamDesc: "",
    TestId: null,
    TestTime: "00:00",
    Tools: "",
    UserNameTest: "",
    VMId: "",
    VarDesc: "",
    VarId: Math.floor(Math.random() * 9000000000) + 1000000000,
    Window: null,
    VMLocalId: 0,
    KeyFlag: Math.random().toString(36).slice(2).substring(0, 5),
    succes_failure: "",
  };
}

export {
  gridTasksToolbarPreparing,
  gridTasksColumns,
  gridRawDataFormatColumns,
  gridTasksSetButtonsState,
  filterGrid,
  updateFLView,
  updatePlantModelView,
  taskClass,
  gridTasksEditModeColumns,
  filterGridTasksEditMode,
};
