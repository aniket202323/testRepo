import React, { PureComponent } from "react";
import SelectBox from "../../../../../components/SelectBox";
import RadioGroup from "../../../../../components/RadioGroup";
import CheckBox from "../../../../../components/CheckBox";
import { setIdsByClassName } from "../../../../../utils/index";
import styles from "../styles.module.scss";

export default class Filters extends PureComponent {
  handlerPM = (key, value) => {
    this.props.handlerSelectPlantModel(key, value);
  };

  handlerFL = (key, value) => {
    this.props.handlerSelectFL(key, value);
  };

  componentDidUpdate = () => {
    this.setIdsComponents();
  };

  setIdsComponents = () => {
    setIdsByClassName([
      {
        class: "dx-radiobutton",
        ids: ["rbnTaskMgmtPlantModel", "rbnTaskMgmtFL"],
      },
      {
        idContainer: "sboDepartmentsTasksMgmt",
        tagName: "input",
        ids: ["txtSearchsboDepartmentsTasksMgmt"],
      },
      {
        idContainer: "sboDepartmentsTasksMgmt",
        tagName: "button",
        ids: ["btnClearsboDepartmentsTasksMgmt"],
      },
      {
        idContainer: "sboLinesTasksMgmt",
        tagName: "input",
        ids: ["txtSearchsboLinesTasksMgmt"],
      },
      {
        idContainer: "sboLinesTasksMgmt",
        tagName: "button",
        ids: ["btnClearsboLinesTasksMgmt"],
      },
      {
        idContainer: "sboUnitsTasksMgmt",
        tagName: "input",
        ids: ["txtSearchsboUnitsTasksMgmt"],
      },
      {
        idContainer: "sboUnitsTasksMgmt",
        tagName: "button",
        ids: ["btnClearsboUnitsTasksMgmt"],
      },
      {
        idContainer: "sboWorkcellsTasksMgmt",
        tagName: "input",
        ids: ["txtSearchsboWorkcellsTasksMgmt"],
      },
      {
        idContainer: "sboWorkcellsTasksMgmt",
        tagName: "button",
        ids: ["btnClearsboWorkcellsTasksMgmt"],
      },
      {
        idContainer: "sboGroupsTasksMgmt",
        tagName: "input",
        ids: ["txtSearchsboGroupsTasksMgmt"],
      },
      {
        idContainer: "sboGroupsTasksMgmt",
        tagName: "button",
        ids: ["btnClearsboGroupsTasksMgmt"],
      },
      {
        idContainer: "sboFl1TasksMgmt",
        tagName: "input",
        ids: ["txtSearchsboFl1TasksMgmt"],
      },
      {
        idContainer: "sboFl1TasksMgmt",
        tagName: "button",
        ids: ["btnClearsboFl1TasksMgmt"],
      },
      {
        idContainer: "sboFl2TasksMgmt",
        tagName: "input",
        ids: ["txtSearchsboFl2TasksMgmt"],
      },
      {
        idContainer: "sboFl2TasksMgmt",
        tagName: "button",
        ids: ["btnClearsboFl2TasksMgmt"],
      },
      {
        idContainer: "sboFl3TasksMgmt",
        tagName: "input",
        ids: ["txtSearchsboFl3TasksMgmt"],
      },
      {
        idContainer: "sboFl3TasksMgmt",
        tagName: "button",
        ids: ["btnClearsboFl3TasksMgmt"],
      },
      {
        idContainer: "sboFl4TasksMgmt",
        tagName: "input",
        ids: ["txtSearchsboFl4TasksMgmt"],
      },
      {
        idContainer: "sboFl4TasksMgmt",
        tagName: "button",
        ids: ["btnClearsboFl4TasksMgmt"],
      },
    ]);
  };

  render() {
    const {
      t,
      chkEditMode,
      handlerChkEditMode,
      tasksMgmtFilterGroup,
      handlerTaskMgmtFilterGroup,
      store,
      plantModel,
      fl,
      loading,
    } = this.props;

    return (
      <React.Fragment>
        <div
          className={[
            "tasksMgmtMainFilterGroup",
            styles.tasksMgmtMainFilterGroup,
          ].join(" ")}
        >
          <RadioGroup
            items={[
              { text: t("Plant Model"), value: "Plant Model" },
              { text: t("Functional Location"), value: "Functional Location" },
            ]}
            valueExpr="value"
            displayExpr="text"
            value={tasksMgmtFilterGroup}
            onValueChanged={handlerTaskMgmtFilterGroup}
          />
          <CheckBox
            id="chkEditModeTasksMgmt"
            text={t("Edit Mode")}
            classes={styles.chkEditMode}
            value={chkEditMode}
            disabled={tasksMgmtFilterGroup === "Functional Location"}
            onValueChanged={handlerChkEditMode}
          />
        </div>
        {tasksMgmtFilterGroup === "Plant Model" ? (
          <div className={styles.multiSelectionGroup}>
            <SelectBox
              id="sboDepartmentsTasksMgmt"
              text={t("Department")}
              enableSelectAll={true}
              enableClear={true}
              store={store.departments}
              isMultiple={true}
              className={styles.selectBoxPM}
              value={plantModel.departments}
              onChange={(values) => this.handlerPM("departments", values)}
              labelKey="DeptDesc"
              valueKey="DeptId"
              isLoading={loading.departments}
              isDisable={false}
            />
            <SelectBox
              id="sboLinesTasksMgmt"
              text={t("Production Line")}
              enableSelectAll={true}
              enableClear={true}
              store={store.lines}
              isMultiple={true}
              className={styles.selectBoxPM}
              value={plantModel.lines}
              onChange={(values) => this.handlerPM("lines", values)}
              labelKey="LineDesc"
              valueKey="LineId"
              isLoading={loading.lines}
              isDisable={false}
            />
            <SelectBox
              id="sboUnitsTasksMgmt"
              text={t("Primary Unit")}
              enableSelectAll={true}
              enableClear={true}
              store={store.units}
              isMultiple={true}
              className={styles.selectBoxPM}
              value={plantModel.units}
              onChange={(values) => this.handlerPM("units", values)}
              labelKey="MasterDesc"
              valueKey="MasterId"
              isLoading={loading.units}
              isDisable={false}
            />
            <SelectBox
              id="sboWorkcellsTasksMgmt"
              text={t("Module")}
              enableSelectAll={true}
              enableClear={true}
              store={store.workcells}
              isMultiple={true}
              className={styles.selectBoxPM}
              value={plantModel.workcells}
              onChange={(values) => this.handlerPM("workcells", values)}
              labelKey="SlaveDesc"
              valueKey="SlaveId"
              isLoading={loading.workcells}
              isDisable={false}
            />
            <SelectBox
              id="sboGroupsTasksMgmt"
              text={t("Production Group")}
              enableSelectAll={true}
              enableClear={true}
              store={store.groups}
              isMultiple={true}
              className={styles.selectBoxPM}
              value={plantModel.groups}
              onChange={(values) => this.handlerPM("groups", values)}
              labelKey="PUGDesc"
              valueKey="PUGId"
              isLoading={loading.groups}
              isDisable={false}
            />
          </div>
        ) : (
          <div className={styles.multiSelectionGroup}>
            <SelectBox
              id="sboFl1TasksMgmt"
              text={t("FL1")}
              enableSelectAll={true}
              enableClear={true}
              store={store.fl1}
              isMultiple={true}
              className={styles.selectBoxFL}
              value={fl.fl1}
              onChange={(values) => this.handlerFL("fl1", values)}
              labelKey="ItemDesc"
              valueKey="ItemDesc"
              isLoading={loading.fl1}
              isDisable={false}
            />
            <SelectBox
              id="sboFl2TasksMgmt"
              text={t("FL2")}
              enableSelectAll={true}
              enableClear={true}
              store={store.fl2}
              isMultiple={true}
              className={styles.selectBoxFL}
              value={fl.fl2}
              onChange={(values) => this.handlerFL("fl2", values)}
              labelKey="ItemDesc"
              valueKey="ItemDesc"
              isLoading={loading.fl2}
              isDisable={false}
            />
            <SelectBox
              id="sboFl3TasksMgmt"
              text={t("FL3")}
              enableSelectAll={true}
              enableClear={true}
              store={store.fl3}
              isMultiple={true}
              className={styles.selectBoxFL}
              value={fl.fl3}
              onChange={(values) => this.handlerFL("fl3", values)}
              labelKey="ItemDesc"
              valueKey="ItemDesc"
              isLoading={loading.fl3}
              isDisable={false}
            />
            <SelectBox
              id="sboFl4TasksMgmt"
              text={t("FL4")}
              enableSelectAll={true}
              enableClear={true}
              store={store.fl4}
              isMultiple={true}
              className={styles.selectBoxFL}
              value={fl.fl4}
              onChange={(values) => this.handlerFL("fl4", values)}
              labelKey="ItemDesc"
              valueKey="ItemDesc"
              isLoading={loading.fl4}
              isDisable={false}
            />
          </div>
        )}
      </React.Fragment>
    );
  }
}
