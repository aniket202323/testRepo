import React, { PureComponent } from "react";
import Button from "../../../../../components/Button";
import CheckBox from "../../../../../components/CheckBox";
import { Popup } from "devextreme-react/ui/popup";
import { displayPreload } from "../../../../../components/Framework/Preload";
import { alert } from "devextreme/ui/dialog";
import { Accordion, Item } from "devextreme-react/ui/accordion";
import Form, {
  GroupItem,
  SimpleItem,
  EmptyItem,
  Label,
  RequiredRule,
  CustomRule,
  PatternRule,
} from "devextreme-react/ui/form";
import {
  getDepartments,
  getLines,
  getUnits,
  getWorkcells,
  getProductionGroups,
  addModule,
  addProdGroup,
} from "../../../../../services/plantModel";
import { getIcon, setIdsByClassName } from "../../../../../utils";
import { updatePlantModelView } from "../options";
import icons from "../../../../../resources/icons";
import dayjs from "dayjs";
import styles from "../styles.module.scss";
import Icon from "../../../../../components/Icon";

const RequiredBadge = ({ id }) => {
  return (
    <span id={id} className={[styles.requiredBadge, "hidden"].join(" ")}></span>
  );
};

class TaskEditor extends PureComponent {
  constructor(props) {
    super(props);

    this.refFormDefinitions = React.createRef();
    this.refFormScheduling = React.createRef();
    this.refFormNewModule = React.createRef();
    this.refFormNewGroup = React.createRef();

    // group validations
    this.validateWindow = null;
    this.validateShiftOffset = null;

    this.state = {
      departments: [],
      lines: [],
      units: [],
      workcells: [],
      groups: [],
      plantModel: {
        departments: null,
        lines: null,
        units: null,
        workcells: null,
        groups: null,
      },
      selected: {
        chkActive: true,
        chkClean: false,
        chkInspect: false,
        chkLubricate: false,
        rdgTaskFrequency: "Shiftly",
      },
      newModuleDialogOpened: false,
      newGroupDialogOpened: false,
      taskSelectedTemp: {},
    };
  }

  componentDidMount = () => {
    const { taskMode, taskSelected } = this.props;
    displayPreload(true);

    if (taskMode !== "") {
      const {
        DepartmentId,
        PLId,
        MasterUnitId,
        SlaveUnitId,
        FrequencyType,
        TaskAction,
        TestTime,
      } = taskSelected;

      //set PrimaryQFactor and Autopostpone value
      // taskSelected.AutoPostpone = taskSelected.AutoPostpone === 1;
      var taskSelectedTemp = {};
      taskSelectedTemp.FrequencyType = FrequencyType;
      taskSelectedTemp.TestTime = TestTime;
      taskSelected.PrimaryQFactor = taskSelected.PrimaryQFactor === "Yes";
      taskSelected.StartDate = taskSelected.StartDate || null;

      getDepartments().then((departments) =>
        getLines(DepartmentId).then((lines) =>
          getUnits(PLId).then((units) =>
            getWorkcells(MasterUnitId).then((workcells) =>
              getProductionGroups(SlaveUnitId).then((groups) => {
                displayPreload(false);

                this.setState(
                  {
                    departments,
                    lines,
                    units,
                    workcells,
                    groups: taskMode !== "duplicate" ? groups : [],
                    plantModel: {
                      ...this.state.plantModel,
                      groups:
                        taskMode !== "duplicate" || taskMode !== ""
                          ? SlaveUnitId
                          : null,
                    },
                    selected: {
                      ...this.state.selected,
                      rdgTaskFrequency: FrequencyType,
                      chkClean: TaskAction?.includes("C") ?? false,
                      chkInspect: TaskAction?.includes("I") ?? false,
                      chkLubricate: TaskAction?.includes("L") ?? false,
                    },
                  },
                  () => {
                    setTimeout(() => {
                      var fdef = this.refFormDefinitions.current;
                      var fscg = this.refFormScheduling.current;

                      if (this.refFormScheduling.current !== null) {
                        if (
                          taskSelected.FrequencyType === "Multi-Day" &&
                          taskSelected.FixedFrequency
                        ) {
                          fscg.instance
                            .getEditor("AutoPostpone")
                            .option("disabled", true);
                        }

                        fdef.instance
                          .getEditor("PrimaryQFactor")
                          .option("disabled", taskSelected.QFactorType === "");

                        // fscg.instance
                        //   .getEditor("StartDate")
                        //   .option(
                        //     "disabled",
                        //     dayjs(new Date(taskSelected.StartDate)).format(
                        //       "YYYY-MM-DD"
                        //     ) < dayjs(new Date()).format("YYYY-MM-DD")
                        //   );
                      }
                    }, 2000);
                  }
                );
              })
            )
          )
        )
      );
    } else
      getDepartments().then((response) =>
        this.setState({ departments: response }, () => {
          displayPreload(false);
        })
      );
  };

  componentDidUpdate = (prevProps, prevState) => {
    const { departments, lines, units, workcells } = this.state.plantModel;
    const {
      departments: prevDepartments,
      lines: prevLines,
      units: prevUnits,
      workcells: prevWorkcells,
    } = prevState.plantModel;

    if (prevDepartments !== departments && departments.toString() !== "") {
      getLines(departments).then((response) =>
        this.setState({ lines: response })
      );
    }

    if (prevLines !== lines && lines.toString() !== "") {
      getUnits(lines).then((response) => this.setState({ units: response }));
    }

    if (prevUnits !== units && units.toString() !== "") {
      getWorkcells(units).then((response) =>
        this.setState({ workcells: response })
      );
    }

    if (prevWorkcells !== workcells && workcells.toString() !== "") {
      getProductionGroups(workcells).then((response) =>
        this.setState({ groups: response })
      );
    }
    setTimeout(() => {
      setIdsByClassName([
        "txtTaskName",
        "sboSlaveUnit",
        "sboTaskLocation",
        "sboTaskDepartment",
        "sboProductionGroup",
        "sboTaskType",
        "sboPL",
        "txtTaskId",
        "chkTaskAction",
        "sboMasterUnit",
        "txtVMId",
        "txtLongTaskName",
        "txtDocumentLinkPath",
        "txtDocumentLinkTitle",
        "nbrItems",
        "nbrPeoples",
        "txtDuration",
        "sboQFactorType",
        "chkPrimaryQFactor",
        "chkIsHSE",
        "chkActive",
        "rgpFrequencyType",
        "txtFrequency",
        "txtWindow",
        "chkFixedFrequency",
        "chkAutoPostpone",
        "txtShiftOffset",
        "dbxStartDate",
        "txtCriteria",
        "txtHazards",
        "txtMethod",
        "txtPPE",
        "txtTools",
        "txtLubricant",
        "txtFL3",
        "txtModuleDescription",
        "txtFL4",
        "txtGroupDescription",
      ]);
    }, 1000);
  };

  onChkValueChanged = (e) => {
    this.setState({ selected: { ...this.state.selected, [e.tag]: e.value } });
  };

  onRgdValueChanged = (e) => {
    this.setState(
      {
        selected: { ...this.state.selected, rdgTaskFrequency: e.value },
      },
      () => {
        let taskSelectedTemp = this.state.taskSelectedTemp;
        let formScheduling = this.refFormScheduling.current.instance;
        formScheduling.updateData("Frequency", null);
        formScheduling.updateData("Window", null);
        formScheduling.updateData("ShiftOffset", 0);
        if (taskSelectedTemp.FrequencyType !== e.value) {
          formScheduling.updateData("TestTime", "");
        } else {
          formScheduling.updateData("TestTime", taskSelectedTemp.TestTime);
        }
        formScheduling.updateData("FixedFrequency", false);
        formScheduling.updateData("AutoPostpone", false);
      }
    );
  };

  onDdlValueChanged = (key, values) => {
    if (values !== this.state.plantModel[key]) {
      this.setState({
        ...this.state,
        ...this.state.selected,
        ...this.state.plantModel,
        ...updatePlantModelView(key, values, this.state),
      });
    }
  };

  onClickSaveTask = (e) => {
    const { taskMode, addTask, updateTask, updateMultipleTasks } = this.props;
    const { chkClean, chkInspect, chkLubricate } = this.state.selected;

    let formDefinitions = this.refFormDefinitions.current.instance;
    let formScheduling = this.refFormScheduling.current.instance;

    let taskActionGroupValue = chkClean || chkInspect || chkLubricate;
    let taskActionElem = document.getElementById("taskActionGroup");
    if (taskActionGroupValue) taskActionElem.classList.add("hidden");
    else taskActionElem.classList.remove("hidden");

    if (
      formDefinitions.validate().isValid &&
      formScheduling.validate().isValid &&
      taskActionGroupValue
    ) {
      let task = formDefinitions.option("formData");

      task.StartDate =
        task.StartDate !== null && task.StartDate !== ""
          ? dayjs(task.StartDate).format("YYYY-MM-DD")
          : "";

      // task.AutoPostpone = task.FixedFrequency
      //   ? -1
      //   : task.AutoPostpone
      //   ? 1
      //   : 0;

      task.PrimaryQFactor = task.PrimaryQFactor ? "Yes" : "No";

      const {
        departments,
        lines,
        units,
        workcells,
        groups,
        // plantModel,
      } = this.state;

      if (taskMode === "" || taskMode === "duplicate") {
        task.DepartmentDesc = departments.find(
          (f) => f.DeptId === task.DepartmentId
        )?.DeptDesc;

        task.LineDesc = lines.find((f) => f.LineId === task.PLId)?.LineDesc;

        task.MasterUnitDesc = units.find(
          (f) => f.MasterId === task.MasterUnitId
        )?.MasterDesc;

        task.SlaveUnitDesc = workcells.find(
          (f) => f.SlaveId === task.SlaveUnitId
        )?.SlaveDesc;

        task.TaskAction = String().concat(
          chkClean ? "C" : "",
          chkInspect ? "I" : "",
          chkLubricate ? "L" : ""
        );
      }

      let pug = groups.find((f) => f.PUGId === task.ProductionGroupId)?.PUGDesc;
      if (task.ProductionGroupDesc !== pug) {
        task.ProductionGroupDesc = pug;
        task.FL4 = pug === "eCIL" ? "" : pug;
      }

      if (taskMode === "edit") {
        task.Status = task.Status === "Add" ? "Add" : "Modify";
      }

      if (taskMode === "editMultiple") {
        task.Status = "Modify";
      }

      if (taskMode === "") addTask(task);
      if (taskMode === "edit") updateTask(task);
      if (taskMode === "duplicate") addTask(task);
      if (taskMode === "editMultiple") updateMultipleTasks(task);
    }
  };

  onClickAddNewModule = () => {
    let canBeAdded = true;

    if (Array.isArray(this.state.plantModel.units)) {
      if (
        this.state.plantModel.units.length === 0 ||
        this.props.taskSelected.MasterUnitId === null
      )
        canBeAdded = false;
    } else {
      canBeAdded = this.props.taskSelected.MasterUnitId !== null;
    }

    if (canBeAdded) {
      let formNewModule = this.refFormNewModule.current.instance;
      this.setState({ newModuleDialogOpened: true }, () =>
        formNewModule.resetValues()
      );
    } else
      alert(
        "You must select a Production Line and Primary Unit to create a new Module"
      );
  };

  onClickAddNewGroup = () => {
    let canBeAdded = true;

    if (Array.isArray(this.state.plantModel.workcells)) {
      if (
        this.state.plantModel.workcells.length === 0 ||
        this.props.taskSelected.SlaveUnitId === null
      )
        canBeAdded = false;
    } else {
      canBeAdded = this.props.taskSelected.SlaveUnitId !== null;
    }

    if (canBeAdded) {
      let formNewGroup = this.refFormNewGroup.current.instance;
      this.setState({ newGroupDialogOpened: true }, () =>
        formNewGroup.resetValues()
      );
    } else alert("You must select a Module to create a new Production Group");
  };

  onClickCloseDialog = () => {
    this.setState({
      newGroupDialogOpened: false,
      newModuleDialogOpened: false,
    });

    let txtProdGroup_FL4 = document.querySelector("[name=txtProdGroup_FL4]");

    if (txtProdGroup_FL4 !== null)
      txtProdGroup_FL4.removeEventListener("input", this.duplicateProdGroup);
  };

  duplicateProdGroup = () => {
    var fDef = this.refFormNewGroup.current.instance;

    let fl4 = document.querySelector("[name=txtProdGroup_FL4]");
    let groupDesc = document.querySelector("[name=txtGroup_Desc]");

    groupDesc.value = fl4.value !== "" ? fl4.value : "eCIL";
    fDef
      .getEditor("description")
      .option("value", fl4.value !== "" ? fl4.value : "eCIL");
  };

  render() {
    const { t, taskMode, taskSelected, handlerTaskEditor } = this.props;
    const { departments, lines, units, workcells, groups } = this.state;
    const { chkClean, chkInspect, chkLubricate, rdgTaskFrequency } =
      this.state.selected;

    return (
      <React.Fragment>
        <div className={styles.butttonCommand}>
          <Button
            id="btnTasksMgmtSaveTask"
            classes={styles.buttons}
            onClick={this.onClickSaveTask}
            hint={
              taskMode === "editMultiple" ? t("Accept Multiple") : t("Accept")
            }
            imgsrc={
              taskMode === "editMultiple" ? icons.acceptMultiple : icons.accept
            }
          />
          <Button
            id="btnTasksMgmtCancel"
            hint={t("Cancel")}
            classes={styles.buttons}
            imgsrc={icons.close}
            onClick={handlerTaskEditor}
          />
        </div>
        <div id="taskMgmtEditor" className={styles.editorContainer}>
          <Accordion collapsible={true} multiple={true}>
            <Item title={t("Definitions")}>
              <form onSubmit={this.handlerSubmit}>
                <Form
                  ref={this.refFormDefinitions}
                  formData={taskSelected}
                  labelLocation="left"
                  showColonAfterLabel={true}
                  colCount={3}
                  // colCountByScreen={{ xs: 1, sm: 2, md: 2, lg: 3 }}
                  // colCount="auto"
                  // minColWidth={200}
                >
                  <SimpleItem
                    cssClass="txtTaskName"
                    dataField="VarDesc"
                    editorType="dxTextBox"
                    editorOptions={{ tabIndex: 1, maxLength: 50 }}
                    disabled={
                      this.props.aspectedSite === false
                        ? false
                        : taskMode === "edit" || taskMode === "editMultiple"
                    }
                  >
                    <Label text={t("Task Name")} />
                    <RequiredRule message="" />
                  </SimpleItem>
                  <SimpleItem
                    cssClass="sboSlaveUnit"
                    dataField="SlaveUnitId"
                    editorType="dxSelectBox"
                    isRequired={true}
                    disabled={
                      taskMode === "edit" || taskMode === "editMultiple"
                    }
                    editorOptions={{
                      tabIndex: 5,
                      dataSource: workcells,
                      valueExpr: "SlaveId",
                      displayExpr: "SlaveDesc",
                      placeholder: "",
                      // placeholder: t("---- No Selection ----"),
                      onValueChanged: (e) =>
                        this.onDdlValueChanged("workcells", e.value),
                      buttons: [
                        {
                          name: "addModule",
                          location: "after",
                          options: {
                            icon: getIcon(icons.add),
                            height: "30px",
                            width: "30px",
                            stylingMode: "text",
                            onClick: this.onClickAddNewModule,
                          },
                        },
                        {
                          name: "dropDown",
                          location: "after",
                        },
                      ],
                    }}
                  >
                    <Label text={t("Module")} />
                    <RequiredRule message="" />
                  </SimpleItem>
                  <SimpleItem
                    cssClass="sboTaskLocation"
                    dataField="TaskLocation"
                    editorType="dxSelectBox"
                    editorOptions={{
                      tabIndex: 9,
                      dataSource: [
                        { TLId: "G", TLDesc: "Global" },
                        { TLId: "L", TLDesc: "Local" },
                      ],
                      valueExpr: "TLId",
                      displayExpr: "TLDesc",
                      showClearButton: true,
                      showDropDownButton: true,
                      placeholder: "",
                      // placeholder: t("---- No Selection ----"),
                    }}
                  >
                    <Label text={t("Task Location")} />
                  </SimpleItem>
                  <SimpleItem
                    cssClass="sboTaskDepartment"
                    dataField="DepartmentId"
                    editorType="dxSelectBox"
                    isRequired={true}
                    disabled={
                      taskMode === "edit" || taskMode === "editMultiple"
                    }
                    editorOptions={{
                      tabIndex: 2,
                      dataSource: departments,
                      valueExpr: "DeptId",
                      displayExpr: "DeptDesc",
                      placeholder: "",
                      // placeholder: t("---- No Selection ----"),
                      onValueChanged: (e) =>
                        this.onDdlValueChanged("departments", e.value),
                    }}
                  >
                    <Label text={"Area"} />
                    <RequiredRule message="" />
                  </SimpleItem>
                  <SimpleItem
                    cssClass="sboProductionGroup"
                    dataField="ProductionGroupId"
                    editorType="dxSelectBox"
                    isRequired={true}
                    editorOptions={{
                      tabIndex: 5,
                      dataSource: groups,
                      valueExpr: "PUGId",
                      displayExpr: "PUGDesc",
                      placeholder: "",
                      // placeholder: t("---- No Selection ----"),
                      onValueChanged: (e) =>
                        this.onDdlValueChanged("groups", e.value),
                      buttons: [
                        {
                          name: "addProdGroup",
                          location: "after",
                          options: {
                            icon: getIcon(icons.add),
                            height: "30px",
                            width: "30px",
                            stylingMode: "text",
                            onClick: this.onClickAddNewGroup,
                          },
                        },
                        {
                          name: "dropDown",
                          location: "after",
                        },
                      ],
                    }}
                  >
                    <Label text={t("Group")} />
                    <RequiredRule message="" />
                  </SimpleItem>
                  <SimpleItem
                    cssClass="sboTaskType"
                    dataField="TaskType"
                    editorType="dxSelectBox"
                    isRequired={true}
                    editorOptions={{
                      tabIndex: 10,
                      dataSource: ["Anytime", "Downtime", "Running", "Route"],
                      placeholder: "",
                      // placeholder: t("---- No Selection ----"),
                    }}
                  >
                    <Label text={t("Task Type")} />
                    <RequiredRule message="" />
                  </SimpleItem>
                  <SimpleItem
                    cssClass="sboPL"
                    dataField="PLId"
                    editorType="dxSelectBox"
                    isRequired={true}
                    disabled={
                      taskMode === "edit" || taskMode === "editMultiple"
                    }
                    editorOptions={{
                      tabIndex: 3,
                      dataSource: lines,
                      valueExpr: "LineId",
                      displayExpr: "LineDesc",
                      placeholder: "",
                      // placeholder: t("---- No Selection ----"),
                      onValueChanged: (e) =>
                        this.onDdlValueChanged("lines", e.value),
                    }}
                  >
                    <Label text={t("Line")} />
                    <RequiredRule message="" />
                  </SimpleItem>
                  <SimpleItem
                    cssClass="txtTaskId"
                    dataField="TaskId"
                    editorType="dxTextBox"
                    editorOptions={{ tabIndex: 7 }}
                    disabled={taskMode === "editMultiple"}
                  >
                    <Label text={t("Task Id")} />
                    {/* <RequiredRule message="" /> */}
                  </SimpleItem>
                  <SimpleItem
                    cssClass="chkTaskAction"
                    editorOptions={{ tabIndex: 11 }}
                    disabled={
                      taskMode === "edit" || taskMode === "editMultiple"
                    }
                  >
                    <Label text={t("Task Action")} />
                    <CheckBox
                      tag="chkClean"
                      text={t("Clean")}
                      value={chkClean}
                      onValueChanged={this.onChkValueChanged}
                    />
                    <CheckBox
                      tag="chkInspect"
                      text={t("Inspect")}
                      value={chkInspect}
                      onValueChanged={this.onChkValueChanged}
                    />
                    <CheckBox
                      tag="chkLubricate"
                      text={t("Lubricate")}
                      value={chkLubricate}
                      onValueChanged={this.onChkValueChanged}
                    />
                    <RequiredBadge id="taskActionGroup" />
                    <RequiredRule message="" />
                  </SimpleItem>
                  <SimpleItem
                    cssClass="sboMasterUnit"
                    dataField="MasterUnitId"
                    editorType="dxSelectBox"
                    isRequired={true}
                    disabled={
                      taskMode === "edit" || taskMode === "editMultiple"
                    }
                    editorOptions={{
                      tabIndex: 4,
                      dataSource: units,
                      valueExpr: "MasterId",
                      displayExpr: "MasterDesc",
                      placeholder: "",
                      // placeholder: t("---- No Selection ----"),
                      onValueChanged: (e) =>
                        this.onDdlValueChanged("units", e.value),
                    }}
                  >
                    <Label text={t("Primary Unit")} />
                    <RequiredRule message="" />
                  </SimpleItem>
                  <SimpleItem
                    cssClass="txtVMId"
                    dataField="VMId"
                    editorType="dxTextBox"
                    editorOptions={{ tabIndex: 8 }}
                    disabled={taskMode === "editMultiple"}
                  >
                    <Label text={t("VM Id")} />
                    <RequiredRule message="" />
                  </SimpleItem>
                  <EmptyItem />
                  <SimpleItem
                    cssClass="txtLongTaskName"
                    dataField="LongTaskName"
                    editorType="dxTextBox"
                    editorOptions={{ tabIndex: 12 }}
                    colSpan={3}
                  >
                    <Label text={t("Long Task Name")} />
                  </SimpleItem>
                  <SimpleItem
                    cssClass="txtDocumentLinkPath"
                    dataField="DocumentLinkPath"
                    editorType="dxTextBox"
                    editorOptions={{ tabIndex: 13 }}
                    colSpan={3}
                  >
                    <Label text={t("Document Link Path")} />
                  </SimpleItem>
                  <SimpleItem
                    cssClass="txtDocumentLinkTitle"
                    dataField="DocumentLinkTitle"
                    editorType="dxTextBox"
                    editorOptions={{ tabIndex: 14 }}
                    colSpan={3}
                  >
                    <Label text={t("Document Link Title")} />
                  </SimpleItem>
                  <SimpleItem
                    cssClass="nbrItems"
                    dataField="NbrItems"
                    editorType="dxNumberBox"
                    editorOptions={{
                      tabIndex: 15,
                      onKeyDown: function (e) {
                        var event = e.event,
                          str = event.key || String.fromCharCode(event.which);
                        if (/^[+-.,e]$/.test(str)) {
                          event.preventDefault();
                        }
                      },
                    }}
                  >
                    <Label text={t("# Items")} />
                  </SimpleItem>
                  <SimpleItem
                    cssClass="nbrPeoples"
                    dataField="NbrPeople"
                    editorType="dxNumberBox"
                    editorOptions={{
                      tabIndex: 17,
                      onKeyDown: function (e) {
                        var event = e.event,
                          str = event.key || String.fromCharCode(event.which);
                        if (/^[+-.,e]$/.test(str)) {
                          event.preventDefault();
                        }
                      },
                    }}
                  >
                    <Label text={t("# People")} />
                  </SimpleItem>
                  <SimpleItem
                    cssClass="txtDuration"
                    dataField="Duration"
                    editorType="dxTextBox"
                    editorOptions={{ tabIndex: 19 }}
                  >
                    <Label text={t("Duration")} />
                  </SimpleItem>
                  <SimpleItem
                    cssClass="sboQFactorType"
                    dataField="QFactorType"
                    editorType="dxSelectBox"
                    editorOptions={{
                      tabIndex: 16,
                      dataSource: ["Q-Parameter", "Q-Task"],
                      showClearButton: true,
                      placeholder: "",
                      // placeholder: t("---- No Selection ----"),
                      onValueChanged: (e) => {
                        var form = this.refFormDefinitions.current.instance;

                        form
                          .getEditor("PrimaryQFactor")
                          .option("disabled", e.value === null);
                        if (e.value === null)
                          form
                            .getEditor("PrimaryQFactor")
                            .option("value", false);
                      },
                    }}
                  >
                    <Label text={t("Q-Factor Type")} />
                  </SimpleItem>
                  <SimpleItem
                    dataField="PrimaryQFactor"
                    editorType="dxCheckBox"
                    editorOptions={{
                      tabIndex: 18,
                      disabled: true,
                    }}
                    cssClass={styles.checkbox + " chkPrimaryQFactor"}
                  >
                    <Label text={t("Primary Q-Factor?")} />
                  </SimpleItem>
                  <SimpleItem
                    dataField="IsHSE"
                    editorType="dxCheckBox"
                    editorOptions={{ tabIndex: 20 }}
                    cssClass={styles.checkbox + " chkIsHSE"}
                  >
                    <Label text={t("Is HSE?")} />
                  </SimpleItem>
                  {/* <ButtonItem
                    horizontalAlignment="left"
                    buttonOptions={{
                      text: "Success",
                      type: "success",
                      useSubmitBehavior: true,
                    }}
                  /> */}
                </Form>
              </form>
            </Item>
          </Accordion>

          <Accordion collapsible={true} multiple={true}>
            <Item title={t("Scheduling")}>
              <form onSubmit={this.handlerSubmit}>
                <Form
                  ref={this.refFormScheduling}
                  formData={taskSelected}
                  labelLocation="left"
                  showColonAfterLabel={true}
                  colCount={5}
                >
                  <SimpleItem
                    dataField="Active"
                    editorType="dxCheckBox"
                    cssClass={styles.checkbox + " chkActive"}
                    editorOptions={{ tabIndex: 21 }}
                  >
                    <Label text={t("Active")} />
                  </SimpleItem>

                  <EmptyItem />
                  <EmptyItem />
                  <EmptyItem />
                  <EmptyItem />

                  <SimpleItem
                    cssClass={"rgpFrequencyType"}
                    dataField="FrequencyType"
                    editorType="dxRadioGroup"
                    editorOptions={{
                      tabIndex: 22,
                      items: ["Shiftly", "Daily", "Multi-Day", "Minutes"],
                      onValueChanged: this.onRgdValueChanged,
                    }}
                  >
                    <Label text={t("Task Frequency")} />
                  </SimpleItem>

                  <GroupItem visible={rdgTaskFrequency !== ""}>
                    <SimpleItem
                      cssClass="txtFrequency"
                      dataField="Frequency"
                      editorType="dxTextBox"
                      visibleIndex={0}
                      isRequired={true}
                      editorOptions={{
                        placeholder:
                          rdgTaskFrequency === "Multi-Day" ? "Hrs/Days" : "Min",
                        maxLength: 3,
                        onKeyDown: (e) => {
                          if (
                            !isFinite(e.event.key) &&
                            e.event.key !== "Backspace"
                          ) {
                            e.event.preventDefault();
                          }
                        },
                      }}
                      visible={
                        rdgTaskFrequency === "Multi-Day" ||
                        rdgTaskFrequency === "Minutes"
                      }
                    >
                      <Label text={t("Frequency")} />
                      <RequiredRule message="" />
                      <CustomRule
                        message={
                          rdgTaskFrequency === "Multi-Day"
                            ? "Frequency must be numeric and between 2 and 365"
                            : "Frequency must be numeric and between 1 and 634 and must be multiple of 5 minutes"
                        }
                        reevaluate={true}
                        validationCallback={(e) => {
                          // e.validator.validate()
                          var form = this.refFormScheduling.current.instance;
                          setTimeout(() => {
                            const { Window, ShiftOffset } = taskSelected;

                            if (this.validateWindow !== null) {
                              form.updateData("Window", Window);
                              this.validateWindow.validator.validate();
                            }

                            if (rdgTaskFrequency === "Minutes") {
                              if (this.validateShiftOffset !== null) {
                                form.updateData("ShiftOffset", ShiftOffset);
                                this.validateShiftOffset.validator.validate();
                              }
                            }
                          }, 250);

                          let frequency = parseInt(e.value ?? 0);
                          if (rdgTaskFrequency === "Multi-Day")
                            return frequency >= 2 && frequency <= 365;
                          else
                            return (
                              frequency >= 1 &&
                              frequency <= 634 &&
                              frequency % 5 === 0
                            );
                        }}
                      />
                    </SimpleItem>

                    <SimpleItem
                      cssClass={"txtWindow"}
                      dataField="Window"
                      editorType="dxTextBox"
                      editorOptions={{
                        maxLength: 3,
                        // tabIndex: 23,
                        placeholder:
                          rdgTaskFrequency === "Shiftly" ||
                          rdgTaskFrequency === "Daily"
                            ? "Hours"
                            : rdgTaskFrequency === "Multi-Day"
                            ? "Days"
                            : "Minutes",
                        onKeyDown: (e) => {
                          if (
                            !isFinite(e.event.key) &&
                            e.event.key !== "Backspace"
                          ) {
                            e.event.preventDefault();
                          }
                        },
                      }}
                      visible={rdgTaskFrequency !== ""}
                      visibleIndex={1}
                    >
                      <Label text={t("Window")} />
                      <CustomRule
                        message="Window value must be less than Frequency value"
                        reevaluate={true}
                        validationCallback={(e) => {
                          // e.validator.validate()
                          this.validateWindow = e;

                          if (
                            rdgTaskFrequency === "Multi-Day" ||
                            rdgTaskFrequency === "Minutes"
                          ) {
                            let window = parseInt(e.value ?? 0);
                            let frequency = parseInt(
                              taskSelected.Frequency ?? 0
                            );
                            return window < frequency;
                          } else if (
                            rdgTaskFrequency === "Shiftly" ||
                            rdgTaskFrequency === "Daily"
                          ) {
                            let window = parseInt(e.value ?? 0);
                            return window < 24;
                          } else return true;
                        }}
                      />
                      <CustomRule
                        message="Window value must be multiple of 5 minutes"
                        reevaluate={true}
                        validationCallback={(e) => {
                          if (rdgTaskFrequency === "Minutes") {
                            let window = parseInt(e.value ?? 0);
                            return window % 5 === 0;
                          } else return true;
                        }}
                      />
                    </SimpleItem>

                    <SimpleItem
                      dataField="FixedFrequency"
                      editorType="dxCheckBox"
                      editorOptions={{
                        onValueChanged: (e) => {
                          if (rdgTaskFrequency === "Multi-Day") {
                            var form = this.refFormScheduling.current.instance;

                            form
                              .getEditor("AutoPostpone")
                              .option("disabled", e.value);

                            if (e.value)
                              form
                                .getEditor("AutoPostpone")
                                .option("value", false);
                          }
                        },
                      }}
                      visibleIndex={2}
                      cssClass={styles.checkbox + " chkFixedFrequency"}
                      visible={
                        rdgTaskFrequency === "Multi-Day" ||
                        rdgTaskFrequency === "Minutes"
                      }
                    >
                      <Label text={t("Fixed Frequency")} />
                    </SimpleItem>

                    <SimpleItem
                      dataField="AutoPostpone"
                      editorType="dxCheckBox"
                      editorOptions={{
                        disabled: false,
                      }}
                      visibleIndex={3}
                      cssClass={styles.checkbox + " chkAutoPostpone"}
                      visible={rdgTaskFrequency === "Multi-Day"}
                    >
                      <Label text={t("Auto Postpone")} />
                    </SimpleItem>

                    <SimpleItem
                      cssClass="txtTestTime"
                      dataField="TestTime"
                      editorType="dxTextBox"
                      visibleIndex={4}
                      visible={
                        rdgTaskFrequency === "Multi-Day" ||
                        rdgTaskFrequency === "Daily"
                      }
                      editorOptions={{
                        // mask: "00:00",
                        maskInvalidMessage:
                          "The Test Time format must be HH:MM",
                        useMaskedValue: true,
                        placeholder: "HH:MM",
                        maskRules: { X: /[02-9]/ },
                      }}
                    >
                      <Label text={t("Test Time")} />
                      <PatternRule
                        message="The Test Time format must be HH:MM"
                        pattern="^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$"
                      />
                    </SimpleItem>

                    <SimpleItem
                      cssClass="txtShiftOffset"
                      dataField="ShiftOffset"
                      editorType="dxTextBox"
                      editorOptions={{
                        placeholder: "Min",
                        maxLength: 3,
                        onKeyDown: (e) => {
                          if (
                            !isFinite(e.event.key) &&
                            e.event.key !== "Backspace"
                          ) {
                            e.event.preventDefault();
                          }
                        },
                      }}
                      visibleIndex={5}
                      visible={rdgTaskFrequency === "Minutes"}
                    >
                      <Label text={t("Shift Start Offset")} />
                      <CustomRule
                        message={t(
                          "Shift Start Offset value must be less than Frequency value and must be multiple of 5 minutes"
                        )}
                        reevaluate={true}
                        validationCallback={(e) => {
                          this.validateShiftOffset = e;

                          if (rdgTaskFrequency === "Minutes") {
                            let offset = parseInt(e.value ?? 0);
                            let frequency = parseInt(
                              taskSelected.Frequency ?? 0
                            );

                            return offset % 5 === 0 && offset <= frequency;
                          } else return true;
                        }}
                      />
                    </SimpleItem>
                  </GroupItem>

                  <EmptyItem />

                  <SimpleItem colSpan={2}>
                    {rdgTaskFrequency === "Shiftly" && (
                      <div className={styles.scheduleExplanation}>
                        {/* <img alt="" src={icons.info} /> */}
                        <Icon name="circle-info" />
                        <label>
                          When selecting Shiftly, the task will be scheduled
                          every shift.
                        </label>
                        <label>
                          You have the option to specify a Window, which is in
                          hours and corresponds to time it will take for the
                          task to become late, starting from scheduled time
                          (beginning of the shift).
                        </label>
                      </div>
                    )}

                    {rdgTaskFrequency === "Daily" && (
                      <div className={styles.scheduleExplanation}>
                        {/* <img alt="" src={icons.info} /> */}
                        <Icon name="circle-info" />
                        <label>
                          When selecting Daily, the task will be scheduled every
                          day.
                        </label>
                        <label>
                          You have the option to specify a Window, which is in
                          hours and corresponds to time it will take for the
                          task to become late, starting from scheduled time
                          (beginning of the shift).
                        </label>
                        <br />
                        <label>
                          With Daily tasks, you also have the possibility to set
                          a Test Time. By default, the task will be scheduled at
                          00:00 every day, but you could set the Test Time at
                          08:00 to have the task scheduled at this test time
                          instead of the default 00:00.
                        </label>
                        <br />
                        <label>
                          Note that this will affect the Late evaluation. If you
                          set a Window of 4 hours, it will be calculated from
                          the Schedule Time, meaning that if you do not set a
                          Test Time, the task will be late at 04:00, but if you
                          set a Test Time of 08:00, the task will be late at
                          12:00.
                        </label>
                      </div>
                    )}

                    {rdgTaskFrequency === "Multi-Day" && (
                      <div className={styles.scheduleExplanation}>
                        {/* <img alt="" src={icons.info} /> */}
                        <Icon name="circle-info" />
                        <label>
                          When selecting Multi-Day, the task will be scheduled
                          at each “n” days, where “n” depends on the number you
                          will put in the Frequency field.
                        </label>
                        <label>
                          You have the option to specify a Window, which is in
                          days and corresponds to number of days it will take
                          for the task to become late, starting from scheduled
                          time.
                        </label>
                        <label>
                          The Fixed Frequency is used to indicate if a Multi-Day
                          task must be scheduled at a fixed frequency or not.
                        </label>
                        <br />
                        <label>
                          Suppose we have a Multi-Day task with a frequency of 7
                          days. If this field is checked, the task will be
                          scheduled every 7 days, regardless of the completion
                          date of the last instance of the task.
                        </label>
                        <label>
                          But if this field is unchecked, the task will be
                          scheduled 7 days after the last completion date of the
                          previous instance of the task.
                        </label>
                        <br />
                        <label>
                          With Multi-Day tasks, you also have the possibility to
                          set a Test Time. By default, the task will be
                          scheduled at 00:00 every “n” days, but you could set
                          the Test Time at 08:00 to have the task scheduled at
                          this test time instead of the default 00:00.
                        </label>
                      </div>
                    )}

                    {rdgTaskFrequency === "Minutes" && (
                      <div className={styles.scheduleExplanation}>
                        {/* <img alt="" src={icons.info} /> */}
                        <Icon name="circle-info" />
                        <label>
                          When selecting Minutes, the task will be scheduled at
                          each “n” minutes, where “n” depends on the number you
                          will put in the Frequency field.
                        </label>
                        <label>
                          You have the option to specify a Window, which is in
                          minutes and corresponds to number of minutes it will
                          take for the task to become late, starting from
                          scheduled time.
                        </label>
                        <br />
                        <label>
                          The Fixed Frequency is used to indicate if a Minutes
                          task must be scheduled at a fixed frequency or not.
                        </label>
                        <br />
                        <label>
                          Suppose we have a Minutes task with a frequency of 120
                          minutes. If this field is checked, the task will be
                          scheduled every 120 minutes, regardless of the
                          completion time of the last instance of the task.
                        </label>
                        <label>
                          But if this field is unchecked, the task will be
                          scheduled 120 minutes after the last completion time
                          of the previous instance of the task.
                        </label>
                        <br />
                        <label>
                          With Minutes tasks, you also have the possibility to
                          set a Shift Start Offset. By default, the task will be
                          scheduled the specified number of minutes after the
                          start of the shift. When using the shift offset, you
                          can specify that the first instance is offset by a
                          certain number of minutes after the start of the
                          shift. For example, the task will be performed 60
                          minutes after the start of a shift and ever 120
                          minutes after that first task (as shown below).
                        </label>
                      </div>
                    )}
                  </SimpleItem>

                  <SimpleItem
                    cssClass="dbxStartDate"
                    dataField="StartDate"
                    editorType="dxDateBox"
                    editorOptions={{
                      placeholder: "YYYY-MM-DD",
                      displayFormat: "yyyy-MM-dd",
                      tabIndex: 23,
                      min:
                        dayjs(
                          new Date(
                            taskSelected.StartDate ??
                              dayjs(new Date()).add(1, "day")
                          )
                        ).format("YYYY-MM-DD") <
                        dayjs(new Date()).format("YYYY-MM-DD")
                          ? dayjs(dayjs(new Date(taskSelected.StartDate))).add(
                              -1,
                              "day"
                            )
                          : new Date(),
                      disabled:
                        dayjs(
                          new Date(
                            taskSelected.StartDate ??
                              dayjs(new Date()).add(1, "day")
                          )
                        ).format("YYYY-MM-DD") <
                        dayjs(new Date()).format("YYYY-MM-DD"),
                    }}
                  >
                    <Label text={t("Start Date")} />
                  </SimpleItem>
                </Form>
              </form>
            </Item>
          </Accordion>

          <Accordion collapsible={true} multiple={true}>
            <Item title={t("Instructions")}>
              <form onSubmit={this.handlerSubmit}>
                <Form
                  formData={taskSelected}
                  labelLocation="left"
                  showColonAfterLabel={true}
                  colCount={1}
                >
                  <SimpleItem
                    cssClass="txtCriteria"
                    dataField="Criteria"
                    editorType="dxTextBox"
                    editorOptions={{ tabIndex: 24 }}
                  >
                    <Label text={t("Criteria")} />
                  </SimpleItem>

                  <SimpleItem
                    cssClass="txtHazards"
                    dataField="Hazards"
                    editorType="dxTextBox"
                    editorOptions={{ tabIndex: 25 }}
                  >
                    <Label text={t("Hazards")} />
                  </SimpleItem>

                  <SimpleItem
                    cssClass="txtMethod"
                    dataField="Method"
                    editorType="dxTextBox"
                    editorOptions={{ tabIndex: 26 }}
                  >
                    <Label text={t("Method")} />
                  </SimpleItem>

                  <SimpleItem
                    cssClass="txtPPE"
                    dataField="PPE"
                    editorType="dxTextBox"
                    editorOptions={{ tabIndex: 27 }}
                  >
                    <Label text={t("PPE")} />
                  </SimpleItem>

                  <SimpleItem
                    cssClass="txtTools"
                    dataField="Tools"
                    editorType="dxTextBox"
                    editorOptions={{ tabIndex: 28 }}
                  >
                    <Label text={t("Tools")} />
                  </SimpleItem>

                  <SimpleItem
                    cssClass="txtLubricant"
                    dataField="Lubricant"
                    editorType="dxTextBox"
                    editorOptions={{ tabIndex: 29 }}
                  >
                    <Label text={t("Lubricant")} />
                  </SimpleItem>
                </Form>
              </form>
            </Item>
          </Accordion>
        </div>

        <Popup
          id="popNewModule"
          visible={this.state.newModuleDialogOpened}
          onHiding={this.onClickCloseDialog}
          dragEnabled={false}
          closeOnOutsideClick={true}
          showTitle={true}
          title={t("New Module")}
          showCloseButton={true}
          width="300px"
          height="180px"
        >
          <form>
            <Form
              ref={this.refFormNewModule}
              formData={{ fl3: "", description: "" }}
              labelLocation="left"
              showColonAfterLabel={true}
              colCount={1}
            >
              <SimpleItem
                cssClass="txtFL3"
                dataField="fl3"
                editorType="dxTextBox"
                editorOptions={{ tabIndex: 30, maxLength: 3 }}
              >
                <Label text={t("FL3")} />
                <RequiredRule message="" />
              </SimpleItem>
              <SimpleItem
                cssClass="txtModuleDescription"
                dataField="description"
                editorType="dxTextBox"
                editorOptions={{ tabIndex: 31 }}
              >
                <Label text={t("Module Description")} />
                <RequiredRule message="" />
              </SimpleItem>
            </Form>
          </form>
          <Button
            id="btnTaskEditorCreateModule"
            text={t("Create Module")}
            classes={styles.popupBtnSave}
            onClick={() => {
              var formNewModule = this.refFormNewModule.current.instance;
              if (formNewModule.validate().isValid) {
                var { lines: lineId, units: unitId } = this.state.plantModel;
                var lineDesc = this.state.lines.find(
                  (l) => l.LineId === lineId
                )?.LineDesc;

                lineId = lineId || taskSelected.PLId;
                lineDesc = lineDesc || taskSelected.LineDesc;
                unitId = unitId || taskSelected.MasterUnitId;

                // if (taskMode !== "") {
                //   lineId = taskSelected.PLId;
                //   lineDesc = taskSelected.LineDesc;
                //   unitId = taskSelected.MasterUnitId;
                // }

                let data = formNewModule.option("formData");

                if (
                  this.state.workcells.filter(
                    (g) => g.SlaveDesc === data.description
                  ).length === 0
                ) {
                  displayPreload(true);
                  addModule(
                    lineId,
                    lineDesc,
                    unitId,
                    data.description,
                    data.fl3
                  ).then(() => {
                    getWorkcells(unitId).then((response) =>
                      setTimeout(() => {
                        this.setState(
                          { workcells: response, newModuleDialogOpened: false },
                          () => displayPreload(false)
                        );
                      }, 500)
                    );
                  });
                } else {
                  this.setState({ newModuleDialogOpened: false });
                }
              }
            }}
          />
        </Popup>

        <Popup
          id="popNewProductionGroup"
          visible={this.state.newGroupDialogOpened}
          onHiding={this.onClickCloseDialog}
          dragEnabled={false}
          closeOnOutsideClick={true}
          showTitle={true}
          title={t("New Production Group")}
          showCloseButton={true}
          onShowing={() => {
            document
              .querySelector("[name=txtProdGroup_FL4]")
              .addEventListener("input", this.duplicateProdGroup);
            document.querySelector("[name=txtGroup_Desc]").value = "eCIL";
          }}
          width="300px"
          height="180px"
        >
          <form>
            <Form
              ref={this.refFormNewGroup}
              formData={{ fl4: "", description: "" }}
              labelLocation="left"
              showColonAfterLabel={true}
              colCount={1}
            >
              <SimpleItem
                cssClass="txtFL4"
                dataField="fl4"
                editorType="dxTextBox"
                editorOptions={{
                  name: "txtProdGroup_FL4",
                  tabIndex: 1,
                  maxLength: 3,
                }}
              >
                <Label text={t("FL4")} />
              </SimpleItem>
              <SimpleItem
                cssClass="txtGroupDescription"
                dataField="description"
                editorType="dxTextBox"
                editorOptions={{
                  name: "txtGroup_Desc",
                  tabIndex: 2,
                  disabled: true,
                }}
              >
                <Label text={t("Group Description")} />
                <RequiredRule message="" />
              </SimpleItem>
            </Form>
          </form>
          <Button
            id="btnCreateGroup"
            text={t("Create Group")}
            classes={styles.popupBtnSave}
            onClick={() => {
              var formNewGroup = this.refFormNewGroup.current.instance;
              if (formNewGroup.validate().isValid) {
                const { lines, workcells } = this.state;
                var { lines: lineId, workcells: slaveId } =
                  this.state.plantModel;
                let lineDesc = lines.find((l) => l.LineId === lineId)?.LineDesc;
                let slaveDesc = workcells.find(
                  (w) => w.SlaveId === slaveId
                )?.SlaveDesc;

                lineDesc = lineDesc || taskSelected.LineDesc;
                slaveId = slaveId || taskSelected.SlaveUnitId;
                slaveDesc = slaveDesc || taskSelected.SlaveUnitDesc;

                let data = formNewGroup.option("formData");
                let groupDesc =
                  data.description === "" ? "eCIL" : data.description;
                let fl4 = data.fl4;

                if (
                  this.state.groups.filter((g) => g.PUGDesc === groupDesc)
                    .length === 0
                ) {
                  displayPreload(true);
                  addProdGroup(
                    lineDesc,
                    slaveId,
                    slaveDesc,
                    groupDesc,
                    fl4
                  ).then(() => {
                    setTimeout(() => {
                      getProductionGroups(slaveId).then((response) =>
                        this.setState(
                          { groups: response, newGroupDialogOpened: false },
                          () => displayPreload(false)
                        )
                      );
                    }, 500);
                  });
                } else {
                  this.setState({ newGroupDialogOpened: false });
                }
              }
            }}
          />
        </Popup>
      </React.Fragment>
    );
  }
}

export default TaskEditor;
