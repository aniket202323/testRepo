import React, { Component } from "react";
import Input from "../../../../components/Input";
import Button from "../../../../components/Button";
import CheckBox from "../../../../components/CheckBox";
import RadioGroup from "../../../../components/RadioGroup";
import DataGrid, { Column, Paging } from "devextreme-react/ui/data-grid";
import Form, { SimpleItem, Label, RequiredRule } from "devextreme-react/form";
import {
  getTasksInfoItems,
  getEcilDefectsColumns,
  getFLDefectsColumns,
} from "../options";
import {
  getDefectTypes,
  getDefectComponents,
  getDefectHowFoundList,
  getDefectPriorities,
  getInstanceOpenedDefects,
  getTaskOpenedDefects,
  getDefectsHistory,
  getFLDefects,
  getPlantModelByFLCode,
  addDefect,
} from "../../../../services/defects";
import DateTime from "../../../../components/DateTime";
// import { updateTaskSelection } from "../../../../services/tasks";
import { getProfile, getUserId } from "../../../../services/auth";
import {
  filterGridByMultipleFields,
  entriesCompare,
  setIdsByClassName,
} from "../../../../utils";
import { displayPreload } from "../../../../components/Framework/Preload";
import icons from "../../../../resources/icons";
import styles from "../styles.module.scss";
import Icon from "../../../../components/Icon";

const initialState = {
  // eCilDefectsSelected: defectSelected,
  selectors: {
    chkSapPMNotification: false,
    chkDefectFixed: false,
    chkRepeatDefect: false,
    dtDueDate: null,
  },
  selectorsFL: {
    chkOSNO: false,
    chkNOPO: false,
    chkNOPR: false,
    chkNOCO: false,
    rbtnFL: "",
    rbtnDefectSource: "eCIL Only",
  },
  nbrOfPreviousDefect: 3,
  instanceOpenedDefectsDS: [],
  taskOpenedDefectsDS: [],
  defectsHistoryDS: [],
  flDefectsDS: [],
  flItems: [],
  plantModelByFLCode: null,
};

const defectFormItems = {
  ReportedBy: "",
  FLCode: "",
  Description: "",
  DefectType: "",
  DefectComponent: "",
  HowFound: "",
  Priority: "",
  CM1: "",
  CM2: "",
  CM3: "",
  PMNotification: false,
  DefectFixed: false,
  RepeatDefect: false,
  DueDate: null,
};

class Defects extends Component {
  constructor(props) {
    super(props);

    this.refECIL = React.createRef();
    this.refFormDefects = React.createRef();

    this.state = {
      data: {},
      dataSaved: false,
      eCilDefectsSelected: this.props.t("Task Instance Defects"),
      defectTypes: [],
      defectComponent: [],
      defectHowFound: [],
      defectPriorities: [],
      databinding: false,
      ...initialState,
    };
  }

  shouldComponentUpdate = (nextProps, nextState) => {
    if (
      nextProps.showDefects !== this.props.showDefects ||
      !entriesCompare(nextState, this.state)
    ) {
      return true;
    } else return false;
  };

  componentDidUpdate = (prevProps, prevState) => {
    if (!this.state.databinding) {
      this.setState({ databinding: true }, () =>
        Promise.all([
          getDefectTypes(),
          getDefectComponents(),
          getDefectHowFoundList(),
          getDefectPriorities(),
        ]).then((response) => {
          const [
            defectTypes,
            defectComponent,
            defectHowFound,
            defectPriorities,
          ] = response;

          this.setState(
            {
              databinding: true,
              defectTypes,
              defectComponent,
              defectHowFound,
              defectPriorities,
            },
            () => this.setInitialState()
          );
        })
      );
    }
    this.setIdsFormComponents();
  };

  setIdsFormComponents = () => {
    setIdsByClassName([
      "txtDescription",
      "sboDefectType",
      "sboDefectComponent",
      "sboHowFound",
      "sboPriority",
      "txtCM1",
      "txtCM2",
      "txtCM3",
      {
        idContainer: "rbnGroupEcil",
        class: "dx-item dx-radiobutton",
        ids: ["rbnEcilTasksSelection"],
        same: true,
      },
      {
        idContainer: "rbnGroupFLs",
        class: "dx-item dx-radiobutton",
        ids: ["rbnFLsTasksSelection"],
        same: true,
      },
      {
        idContainer: "rbnGroupDefectsSource",
        class: "dx-item dx-radiobutton",
        ids: ["rbnDefectsSourceTasksSelection"],
        same: true,
      },
    ]);
  };

  clearState = () => {
    this.setState({ ...initialState });
  };

  setData = (data) => {
    displayPreload(true);

    const { FL1, FL2, FL3, FL4, TestId, VarId } = data;
    // document.querySelector("[name=fl]").value = this.buildFLName(data);
    let FLCode = this.buildFLName(data);
    this.setFormValue("FLCode", FLCode);

    Promise.all([
      getInstanceOpenedDefects(TestId),
      getTaskOpenedDefects(VarId),
      getDefectsHistory(VarId),
      getPlantModelByFLCode(FLCode),
    ]).then((response) => {
      const [
        instanceOpenedDefectsDS,
        taskOpenedDefectsDS,
        defectsHistoryDS,
        plantModelByFLCode,
      ] = response;

      this.setState(
        {
          instanceOpenedDefectsDS,
          taskOpenedDefectsDS,
          defectsHistoryDS,
          plantModelByFLCode,
          data,
          flItems: [
            { text: "FL1", disabled: FL1 === "" },
            { text: "FL2", disabled: FL2 === "" },
            { text: "FL3", disabled: FL3 === "" },
            { text: "FL4", disabled: FL4 === "" },
          ],
        },
        () => {
          displayPreload(false);
          this.setInitialState();
        }
      );
    });
  };

  onECILChange = (e) => {
    const { t } = this.props;
    this.setState(
      {
        eCilDefectsSelected: e.value,
      },
      () => {
        if (e.value === t("FL Defects")) {
          const { DepartmentId, ProdLineId, ProdUnitId } =
            this.state.plantModelByFLCode;

          getFLDefects(DepartmentId, ProdLineId, ProdUnitId).then(
            (response) => {
              this.setState({
                flDefectsDS: response,
              });
            }
          );
        }
      }
    );
  };

  onNumberOfPreviousDefects = () => {
    Promise.all([
      getDefectsHistory(
        this.state.data.VarId,
        document.getElementById("numberOfPrevious").value
      ),
    ]).then((response) => {
      const [defectsHistoryDS] = response;
      this.setState({
        defectsHistoryDS,
      });
    });
  };

  onSelectorValueChanged = (e) => {
    let field;
    if (e.tag === "chkSapPMNotification") field = "PMNotification";
    if (e.tag === "chkDefectFixed") field = "DefectFixed";
    if (e.tag === "chkRepeatDefect") field = "RepeatDefect";
    this.setFormValue(field, e.value);

    this.setState({
      selectors: { ...this.state.selectors, [e.tag]: e.value },
    });
  };

  onFLDefectsDefectStatusChange = (e) => {
    this.setState({
      selectorsFL: { ...this.state.selectorsFL, [e.tag]: e.value },
    });
  };

  onDueDateValueChanged = (e) => {
    this.setFormValue("DueDate", e.value);
    this.setState({
      selectors: { ...this.state.selectors, dtDueDate: e.value },
    });
  };

  saveDefect = () => {
    let formDefects = this.refFormDefects.current.instance;

    if (formDefects.validate().isValid) {
      displayPreload(true);
      const { data, defectTypes } = this.state;
      const {
        FLCode,
        Description,
        DefectType,
        DefectComponent,
        HowFound,
        Priority,
        CM1,
        CM2,
        CM3,
        PMNotification,
        DefectFixed,
        RepeatDefect,
        DueDate,
      } = formDefects.option("formData");

      var UserId, UserName;
      UserId = getUserId();
      UserName = getProfile().UserName;

      let defect = {
        FLCode: FLCode,
        UserId: UserId,
        UserName: UserName,
        FoundBy: UserName,
        Description: Description,
        SourceRecordID: data.TestId,
        DefectTypeId: DefectType,
        DefectTypeCode: defectTypes.find((dt) => dt.Id === DefectType)?.Code,
        DefectComponentId: DefectComponent,
        HowFoundId: HowFound,
        PriorityId: Priority,
        CM1: CM1,
        CM2: CM2,
        CM3: CM3,
        Fixed: DefectFixed,
        PMNotification: PMNotification ? 1 : 0,
        ClosedBy: DefectFixed ? UserName : null,
        FixedBy: DefectFixed ? UserName : null,
        ServerCurrentResult: data.CurrentResult,
        Repeat: RepeatDefect,
        DueDate: DueDate === null ? null : new Date(DueDate),
      };

      addDefect(defect).then((res) => {
        formDefects.resetValues();

        this.setFormValue("DefectFixed", false);
        this.setFormValue("PMNotification", false);
        this.setFormValue("RepeatDefect", false);
        this.setFormValue("DueDate", null);

        displayPreload(false);

        if (res !== -1) {
          displayPreload(true);

          Promise.all([
            getInstanceOpenedDefects(this.state.data.TestId),
            getTaskOpenedDefects(this.state.data.VarId),
            getDefectsHistory(this.state.data.VarId),
            getPlantModelByFLCode(FLCode),
          ]).then((response) => {
            const [
              instanceOpenedDefectsDS,
              taskOpenedDefectsDS,
              defectsHistoryDS,
              plantModelByFLCode,
            ] = response;

            let task = this.state.data;
            task.NbrDefects = instanceOpenedDefectsDS.length;

            this.setState(
              {
                ...initialState,
                data: task,
                dataSaved: true,
                instanceOpenedDefectsDS,
                taskOpenedDefectsDS,
                defectsHistoryDS,
                plantModelByFLCode,
              },
              () => {
                this.setInitialState();
                displayPreload(false);
              }
            );
          });
        } else this.setState({ ...initialState });
      });
    }
  };

  buildFLName = (data) => {
    var { FL1, FL2, FL3, FL4 } = data;

    FL3 = FL3 ?? "";
    FL4 = FL4 ?? "";

    if (FL3 === "") {
      return "";
    }

    let FL = [];

    if (FL1 !== "") FL.push(FL1);
    if (FL2 !== "") FL.push(FL2);
    if (FL3 !== "") FL.push(FL3);
    if (FL4 !== "") FL.push(FL4);

    return FL.join("-");
  };

  filterFLDataGrid = () => {
    let fields = [];

    let selectorsFL = this.state.selectorsFL;
    let rbtnFL = selectorsFL.rbtnFL;
    let rbtnDefectSource = selectorsFL.rbtnDefectSource;
    let nbrOfPreviousDefect = this.state.nbrOfPreviousDefect;

    let tempArr = this.state.flDefectsDS;
    tempArr = tempArr ?? [];
    tempArr.sort(function (a, b) {
      var da = new Date(a.PMOpenDate).getTime();
      var db = new Date(b.PMOpenDate).getTime();
      return da < db ? -1 : da > db ? 1 : 0;
    });

    let previousDates = tempArr
      .reverse()
      .slice(0, nbrOfPreviousDefect)
      .map((item) => item.PMOpenDate);

    if (previousDates.length > 0)
      fields.push({ fieldName: "PMOpenDate", fieldValues: previousDates });

    let tempDefectStatus = [];

    if (selectorsFL.chkOSNO) tempDefectStatus.push("OSNO");
    if (selectorsFL.chkNOPO) tempDefectStatus.push("NOPO");
    if (selectorsFL.chkNOPR) tempDefectStatus.push("NOPR");
    if (selectorsFL.chkNOCO) tempDefectStatus.push("NOCO");

    fields.push({ fieldName: "PMStatus", fieldValues: tempDefectStatus });

    if (rbtnDefectSource === "eCIL Only") {
      fields.push({
        fieldName: "HowFound",
        fieldValues: ["CIL"],
      });
    }

    if (rbtnFL !== "") {
      if (rbtnFL === "FL1") {
        fields.push({
          fieldName: "ProdLineDesc",
          fieldValues: ["FL1"],
        });
      }
      if (rbtnFL === "FL2") {
        fields.push({
          fieldName: "ProdUnitDesc",
          fieldValues: ["FL2"],
        });
      }
      if (rbtnFL === "FL3") {
        fields.push({
          fieldName: "Department",
          fieldValues: ["FL3"],
        });
      }
      if (rbtnFL === "FL4") {
        fields.push({
          fieldName: "PUGroupDesc",
          fieldValues: ["FL4"],
        });
      }
    }

    return filterGridByMultipleFields(fields);
  };

  handlerClose = () => {
    var dataSaved = this.state.dataSaved;
    var task = this.state.data;

    this.setState(
      {
        ...initialState,
        data: {},
        dataSaved: false,
      },
      () => {
        this.setInitialState();
        this.props.handlerDefects(dataSaved, task);
      }
    );
  };

  setInitialState = () => {
    let formDefects = this.refFormDefects.current.instance;
    formDefects.resetValues();

    const { data, defectHowFound, defectTypes, defectPriorities } = this.state;
    var howFound = defectHowFound?.find((v, i) => i === 0)?.Id ?? "";

    if (defectTypes)
      this.setFormValue(
        "DefectType",
        !data.IsDefectLooked && data.IsHSE
          ? defectTypes.find((j) => j.GlobalName.includes("Unsafe Conditions"))
              ?.Id ?? null
          : null
      );
    if (defectPriorities)
      this.setFormValue(
        "Priority",
        !data.IsDefectLooked && data.IsHSE
          ? defectPriorities.find((j) => j.GlobalName.includes("Critical"))
              ?.Id ?? null
          : null
      );

    this.setFormValue("Description", "");
    this.setFormValue("HowFound", howFound);
    // this.setFormValue("DefectComponent", "");
    this.setFormValue("CM1", "");
    this.setFormValue("CM2", "");
    this.setFormValue("CM3", "");
  };

  setFormValue = (field, value) => {
    let formDefects = this.refFormDefects.current.instance;
    formDefects.updateData(field, value);
  };

  render() {
    const {
      data,
      flDefectsDS,
      instanceOpenedDefectsDS,
      taskOpenedDefectsDS,
      defectsHistoryDS,
      eCilDefectsSelected,
      defectTypes,
      defectComponent,
      defectHowFound,
      defectPriorities,
      selectors,
      selectorsFL,
      nbrOfPreviousDefect,
      flItems,
    } = this.state;
    const { t } = this.props;

    let eDHAccessToken = getProfile()?.EDHAccessToken;

    return (
      <div id="containerDefects" className={styles.containerDefects}>
        <div className={styles.butttonCommand}>
          {!eDHAccessToken && (
            <div>
              <div className={styles.eDhNotAccessMessage}>
                {/* <img alt="" src={icons.info} /> */}
                <Icon name="circle-info" />

                <label>
                  {t(
                    "The current user doesn't have access to the eDefects server."
                  )}
                </label>
              </div>
            </div>
          )}
          {data.IsDefectLooked && (
            <div className={styles.isDefectLookedMessage}>
              {/* <img alt="" src={icons.info} /> */}
              <Icon name="circle-info" />
              <label>
                {t(
                  "You cannot add a defect on this task instance. Add your defect on the most recent instance."
                )}
              </label>
            </div>
          )}
          <Button
            id="btnSaveDefect"
            hint={t("Save Defect")}
            classes={styles.buttons}
            style={data.IsDefectLooked && { backgroundColor: "#ececec" }}
            imgsrc={icons.save}
            disabled={data.IsDefectLooked}
            onClick={this.saveDefect}
          />
          {/* <Button
            hint={t("Cancel Defect")}
            classes={styles.buttons}
            imgsrc={icons.cancel}
          /> */}
          <Button
            id="btnCloseDefect"
            hint={t("Close")}
            classes={styles.buttons}
            imgsrc={icons.close}
            onClick={this.handlerClose}
          />
        </div>
        <div className={styles.flexRow}>
          <div className={styles.boxLeft}>
            <label className={styles.title}>{t("Task Information")}</label>
            <div className={styles.taksInfo}>
              {getTasksInfoItems().map((item) => {
                var value =
                  item.caption === "Functional Location"
                    ? this.buildFLName(data)
                    : item.caption === "Reported By"
                    ? getProfile().UserName
                    : data[item?.dataField];

                return (
                  <div key={item.caption} className={styles.taskInfoItem}>
                    <b>{t(item.caption)}</b>
                    <label>{value}</label>
                  </div>
                );
              })}
            </div>
          </div>
          <div className={styles.boxRight}>
            <label className={styles.title}>{t("New Defect")}</label>
            <form>
              <Form
                id="frmDefect"
                ref={this.refFormDefects}
                formData={defectFormItems}
                labelLocation="left"
                disabled={data.IsDefectLooked}
                showColonAfterLabel={true}
                colCount={2}
              >
                <SimpleItem
                  name="txtDescription"
                  dataField="Description"
                  editorType="dxTextBox"
                  colSpan={2}
                  cssClass="txtDescription"
                >
                  <Label text={t("Description")} />
                  <RequiredRule message="" />
                </SimpleItem>

                <SimpleItem
                  dataField="DefectType"
                  editorType="dxSelectBox"
                  cssClass="sboDefectType"
                  editorOptions={{
                    dataSource: defectTypes,
                    valueExpr: "Id",
                    displayExpr: "GlobalName",
                    showClearButton: true,
                    placeholder: "",
                    // defaultValue:
                    //   !data.IsDefectLooked && data.IsHSE
                    //     ? defectTypes.find(
                    //         (j) => j.GlobalName === "Unsafe Conditions"
                    //       )?.Id ?? null
                    //     : null,
                  }}
                >
                  <Label text={t("Defect Type")} />
                  <RequiredRule message="" />
                </SimpleItem>

                <SimpleItem
                  dataField="CM1"
                  editorType="dxTextBox"
                  cssClass="txtCM1"
                >
                  <Label text={t("CM1")} />
                </SimpleItem>

                <SimpleItem
                  dataField="DefectComponent"
                  editorType="dxSelectBox"
                  cssClass="sboDefectComponent"
                  editorOptions={{
                    dataSource: defectComponent,
                    valueExpr: "Id",
                    displayExpr: "GlobalName",
                    placeholder: "",
                    // showClearButton: true,
                  }}
                >
                  <Label text={t("Defect Component")} />
                  <RequiredRule message="" />
                </SimpleItem>

                <SimpleItem
                  dataField="CM2"
                  editorType="dxTextBox"
                  cssClass="txtCM2"
                >
                  <Label text={t("CM2")} />
                </SimpleItem>

                <SimpleItem
                  dataField="HowFound"
                  editorType="dxSelectBox"
                  cssClass="sboHowFound"
                  editorOptions={{
                    dataSource: defectHowFound,
                    valueExpr: "Id",
                    displayExpr: "GlobalName",
                    placeholder: "",
                  }}
                >
                  <Label text={t("How Found?")} />
                  <RequiredRule message="" />
                </SimpleItem>

                <SimpleItem
                  dataField="CM3"
                  editorType="dxTextBox"
                  cssClass="txtCM3"
                >
                  <Label text={t("CM3")} />
                </SimpleItem>

                <SimpleItem
                  dataField="Priority"
                  editorType="dxSelectBox"
                  cssClass="sboPriority"
                  editorOptions={{
                    dataSource: defectPriorities,
                    valueExpr: "Id",
                    displayExpr: "GlobalName",
                    placeholder: "",
                    showClearButton: true,
                    // defaultValue:
                    //   !data.IsDefectLooked && data.IsHSE
                    //     ? defectPriorities.find(
                    //         (j) => j.GlobalName === "Critical"
                    //       )?.Id ?? null
                    //     : null,
                  }}
                >
                  <Label text={t("Priority")} />
                  <RequiredRule message="" />
                </SimpleItem>

                <SimpleItem dataField="DueDate" cssClass="sboDueDate">
                  <Label text={t("Due Date")} />
                  <DateTime
                    id="dtDueDate"
                    type="datetime"
                    displayFormat="yyyy-MM-dd hh:mm aa"
                    value={selectors.dtDueDate}
                    onValueChanged={(e) => this.onDueDateValueChanged(e)}
                    min={new Date()}
                  />
                </SimpleItem>

                <SimpleItem dataField="PMNotification">
                  <CheckBox
                    id="chkSapPMNotification"
                    tag="chkSapPMNotification"
                    text={t("External resourse or part needed")}
                    disabled={selectors.chkDefectFixed}
                    value={selectors.chkSapPMNotification}
                    onValueChanged={(e) => this.onSelectorValueChanged(e)}
                  />
                  <Label text={t("SAP PM Notification")} />
                </SimpleItem>

                <SimpleItem dataField="DefectFixed">
                  <CheckBox
                    id="chkDefectFixed"
                    tag="chkDefectFixed"
                    text=""
                    disabled={selectors.chkSapPMNotification}
                    value={selectors.chkDefectFixed}
                    onValueChanged={(e) => this.onSelectorValueChanged(e)}
                  />
                  <Label text={t("Defect Fixed")} />
                </SimpleItem>
                <SimpleItem dataField="RepeatDefect">
                  <CheckBox
                    id="chkRepeatDefect"
                    tag="chkRepeatDefect"
                    text=""
                    value={selectors.chkRepeatDefect}
                    onValueChanged={(e) => this.onSelectorValueChanged(e)}
                  />
                  <Label text={t("Repeat Defect")} />
                </SimpleItem>
              </Form>
            </form>
          </div>
        </div>

        <div className={styles.flexRow}>
          <div id="rbnGroupEcil" className={styles.boxLeft}>
            <label className={styles.title}>{t("eCIL")}</label>
            <RadioGroup
              items={[
                t("Task Instance Defects"),
                t("Task Defects"),
                t("Defects History"),
                t("FL Defects"),
              ]}
              value={eCilDefectsSelected}
              onValueChanged={this.onECILChange}
            />
          </div>

          {eCilDefectsSelected === t("Defects History") && (
            <div className={styles.boxLeft}>
              <label className={styles.title}>{t("Filters")}</label>
              <div>
                <label className={styles.title}>
                  {t("Number of Previous Defects")}
                </label>
                <div>
                  <Input
                    id="numberOfPrevious"
                    type="number"
                    border
                    min={1}
                    max={25}
                    defaultValue={"3"}
                    className={styles.numericInput}
                  />
                  <Button
                    id="btnRefreshPreviousDefects"
                    hint={t("Refresh")}
                    classes={styles.refreshDefectHistoryButton}
                    imgsrc={icons.refresh}
                    onClick={this.onNumberOfPreviousDefects}
                  />
                </div>
              </div>
            </div>
          )}

          {eCilDefectsSelected === t("FL Defects") && (
            <div className={styles.boxRight}>
              <label className={styles.title}>{t("Filters")}</label>

              <div>
                <label className={styles.title}>{t("Defects Status")}</label>
                <br />
                <CheckBox
                  id="chkOSNO"
                  tag="chkOSNO"
                  text={t("OSNO - Outstanding")}
                  value={selectorsFL.chkOSNO}
                  onValueChanged={(e) => this.onFLDefectsDefectStatusChange(e)}
                />
                <br />
                <CheckBox
                  id="chkNOPO"
                  tag="chkNOPO"
                  text={t("NOPO - Postponed")}
                  value={selectorsFL.chkNOPO}
                  onValueChanged={(e) => this.onFLDefectsDefectStatusChange(e)}
                />
                <br />
                <CheckBox
                  id="chkNOPR"
                  tag="chkNOPR"
                  text={t("NOPR - In Process")}
                  value={selectorsFL.chkNOPR}
                  onValueChanged={(e) => this.onFLDefectsDefectStatusChange(e)}
                />
                <br />
                <CheckBox
                  id="chkNOCO"
                  tag="chkNOCO"
                  text={t("NOCO - Completed")}
                  value={selectorsFL.chkNOCO}
                  onValueChanged={(e) => this.onFLDefectsDefectStatusChange(e)}
                />
              </div>

              <div>
                <label className={styles.title}>
                  {t("Number of Previous Defects")}
                </label>
                <Input
                  id="nbrPreviousDefect"
                  type="number"
                  border
                  min={1}
                  max={25}
                  value={nbrOfPreviousDefect}
                  onChange={(e) =>
                    this.setState({ nbrOfPreviousDefect: e.target.value })
                  }
                  className={styles.numericInput}
                />
              </div>

              <div id="rbnGroupFLs">
                <label className={styles.title}>
                  {t("Functional Locations")}
                </label>
                <RadioGroup
                  items={flItems}
                  value={selectorsFL.rbtnFL}
                  onValueChanged={(e) =>
                    this.setState({
                      selectorsFL: {
                        ...this.state.selectorsFL,
                        rbtnFL: e.value,
                      },
                    })
                  }
                />
              </div>

              <div id="rbnGroupDefectsSource">
                <label className={styles.title}>{t("Defects Source")}</label>
                <RadioGroup
                  items={["All", "eCIL Only"]}
                  value={selectorsFL.rbtnDefectSource}
                  onValueChanged={(e) =>
                    this.setState({
                      selectorsFL: {
                        ...this.state.selectorsFL,
                        rbtnDefectSource: e.value,
                      },
                    })
                  }
                />
              </div>

              <br />
              <div className={styles.divButtonRefresh}>
                <Button
                  id="btnRefreshFLDefects"
                  hint={t("Refresh")}
                  text={t("Refresh")}
                  classes={styles.refreshFLDefectsButton}
                  imgsrc={icons.refresh}
                  onClick={this.filterFLDataGrid}
                />
              </div>
            </div>
          )}
        </div>

        <div className={[styles.detailGrid, styles.flexRow].join(" ")}>
          {eCilDefectsSelected !== t("FL Defects") ? (
            <DataGrid
              id="grdFLDefects"
              ref={this.refECIL}
              dataSource={
                eCilDefectsSelected === t("Task Instance Defects")
                  ? instanceOpenedDefectsDS
                  : eCilDefectsSelected === t("Task Defects")
                  ? taskOpenedDefectsDS
                  : defectsHistoryDS
              }
              allowColumnReordering={false}
              allowFiltering={false}
              showBorders={true}
              allowColumnResizing={true}
              rowAlternationEnabled={false}
              showColumnLines={true}
              showRowLines={true}
              headerFilter={{ visible: false }}
              columnAutoWidth={true}
              wordWrapEnabled={true}
              height="300px"
              width="100%"
            >
              <Paging enabled={false} />
              {getEcilDefectsColumns().map((field) => (
                <Column
                  key={field.caption}
                  caption={t(field.caption)}
                  dataField={field.dataField}
                  visible={
                    !(
                      eCilDefectsSelected !== t("Defects History") &&
                      field.dataField === "DefectEnd"
                    )
                  }
                />
              ))}
            </DataGrid>
          ) : (
            <DataGrid
              id="grdFLDefects"
              dataSource={{
                store: flDefectsDS,
                filter: this.filterFLDataGrid(),
              }}
              allowColumnReordering={false}
              allowFiltering={false}
              showBorders={true}
              allowColumnResizing={true}
              rowAlternationEnabled={false}
              showColumnLines={true}
              showRowLines={true}
              headerFilter={{ visible: false }}
              columnAutoWidth={true}
              wordWrapEnabled={true}
              height="300px"
              width="100%"
            >
              <Paging enabled={false} />
              {getFLDefectsColumns().map((field) => (
                <Column
                  key={field.caption}
                  caption={t(field.caption)}
                  dataField={field.dataField}
                  cellTemplate={field.cellTemplate || undefined}
                />
              ))}
            </DataGrid>
          )}
        </div>
      </div>
    );
  }
}

export default Defects;
