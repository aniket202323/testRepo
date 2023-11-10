import React, { PureComponent } from "react";
import Panel from "../../../../../components/Panel";
import DateTime from "../../../../../components/DateTime";
import RadioGroup from "../../../../../components/RadioGroup";
import SelectBox from "../../../../../components/SelectBox";
import CheckBox from "../../../../../components/CheckBox";
import {
  getDepartments,
  getLines,
  getUnits,
} from "../../../../../services/plantModel";
import { getTimeFrames } from "../../../../../services/application";
import { getTeams, getMyTeams } from "../../../../../services/teams";
import { getRoutes, getMyRoutes } from "../../../../../services/routes";
import { getUserRole } from "../../../../../services/auth";
import { updatePlantModelView } from "../options";
import { CUSTOM_PERIOD, GRANULARITY } from "../../../../../utils/constants";
import { setIdsByClassName } from "../../../../../utils";
import { displayPreload } from "../../../../../components/Framework/Preload";
import dayjs from "dayjs";
import styles from "../styles.module.scss";

const initialState = {
  data: [],
  rdgEntryType: "Plant Model",
  rdgGranularity: GRANULARITY.Site,
  rdgTimeFrame: CUSTOM_PERIOD.ThisWeek,
  rdgTeamsDetails: 2,
  chkRouteDetails: true,
  chkPlantModelDetails: false,
  dtStartTime: null,
  dtEndTime: null,
  departments: [],
  lines: [],
  units: [],
  teams: [],
  myteams: [],
  routes: [],
  myroutes: [],
  plantModel: {
    departments: [],
    lines: [],
    units: [],
    teams: [],
    myteams: [],
    routes: [],
    myroutes: [],
  },
  departmentsWasLoaded: false,
};

class Filters extends PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      ...initialState,
      timeFrames: [],
    };
  }

  componentDidMount = () => {
    displayPreload(true);
    getTimeFrames().then((response) => {
      var timeFrame =
        response?.find((tm) => tm.TimeFrameId === this.state.rdgTimeFrame) ??
        [];
      this.setState(
        {
          timeFrames: response,
          dtStartTime: timeFrame.StartTime,
          dtEndTime: timeFrame.EndTime,
        },
        () => displayPreload(false)
      );
    });
  };

  componentDidUpdate = (prevProps, prevState) => {
    const {
      myteams,
      teams,
      myroutes,
      routes,
      rdgEntryType,
      rdgGranularity,
      plantModel,
    } = this.state;

    if (rdgEntryType === "Plant Model") {
      if (rdgGranularity !== GRANULARITY.Site) {
        const { departments, lines } = plantModel;
        const { departments: prevDepartments, lines: prevLines } =
          prevState.plantModel;

        if (
          this.state.departments.length === 0 &&
          !this.state.departmentsWasLoaded
        ) {
          getDepartments().then((response) =>
            this.setState({
              departments: response,
              departmentsWasLoaded: true,
            })
          );
        }

        if (
          (prevDepartments !== departments ||
            prevState.rdgGranularity !== rdgGranularity) &&
          departments.length > 0 &&
          rdgGranularity !== GRANULARITY.Department
        ) {
          getLines(departments.join(", ")).then((response) =>
            this.setState({ lines: response })
          );
        }

        if (
          (prevLines !== lines ||
            prevState.rdgGranularity !== rdgGranularity) &&
          lines.length > 0 &&
          rdgGranularity === GRANULARITY.MasterUnit
        ) {
          getUnits(lines.join(", ")).then((response) =>
            this.setState({ units: response })
          );
        }
      }
    }

    if (rdgEntryType === "My Teams") {
      if (myteams.length === 0 && rdgEntryType !== prevState.rdgEntryType) {
        getMyTeams().then((response) => this.setState({ myteams: response }));
      }
    }

    if (rdgEntryType === "Teams Selection") {
      if (teams.length === 0 && rdgEntryType !== prevState.rdgEntryType) {
        getTeams().then((response) => this.setState({ teams: response }));
      }
    }

    if (rdgEntryType === "My Routes") {
      if (myroutes.length === 0 && rdgEntryType !== prevState.rdgEntryType) {
        getMyRoutes().then((response) => this.setState({ myroutes: response }));
      }
    }

    if (rdgEntryType === "Routes Selection") {
      if (routes.length === 0 && rdgEntryType !== prevState.rdgEntryType) {
        getRoutes().then((response) => this.setState({ routes: response }));
      }
    }
    this.setComponentsIds();
    this.disabledToRun();
  };

  disabledToRun = () => {
    const { rdgEntryType, rdgGranularity, plantModel } = this.state;
    const { departments: depts, lines, units } = plantModel;

    var disabled = false;
    if (rdgEntryType === "Plant Model") {
      if (
        (rdgGranularity === GRANULARITY.Department && depts.length === 0) ||
        (rdgGranularity === GRANULARITY.Line && lines.length === 0) ||
        (rdgGranularity === GRANULARITY.MasterUnit && units.length === 0)
      ) {
        disabled = true;
      }
    }

    document.getElementById("btnRunReport").disabled = disabled;
  };

  handlerRgdEntryType = (e) => {
    const { chkRouteDetails, chkPlantModelDetails } = this.state;

    var timeFrame = this.state.timeFrames.find(
      (tm) => tm.TimeFrameId === initialState.rdgTimeFrame
    );

    this.setState({
      ...initialState,
      rdgEntryType: e.value,
      rdgGranularity: e.value.includes("Teams")
        ? GRANULARITY.Team
        : e.value.includes("Routes")
        ? GRANULARITY.Route
        : GRANULARITY.Site,
      rdgTeamsDetails: e.value.includes("Routes")
        ? 2
        : e.value === "Plant Model"
        ? 2
        : e.value === "My Teams"
        ? 2
        : chkRouteDetails
        ? 2
        : chkPlantModelDetails
        ? 0
        : 1,
      dtStartTime: timeFrame.StartTime,
      dtEndTime: timeFrame.EndTime,
    });
  };

  handlerRgdTimeFrame = (e) => {
    let timeFrame;
    if (e.value !== CUSTOM_PERIOD.UserDefined)
      timeFrame = this.state.timeFrames.find(
        (tf) => tf.TimeFrameId === e.value
      );

    this.setState({
      rdgTimeFrame: e.value,
      dtStartTime:
        e.value === CUSTOM_PERIOD.UserDefined
          ? new Date(new Date().setHours(6, 0, 0))
          : timeFrame.StartTime,
      dtEndTime:
        e.value === CUSTOM_PERIOD.UserDefined ? new Date() : timeFrame.EndTime,
    });
  };

  handlerRgdGranularity = (e) => {
    if (e.value === "Site")
      this.setState({
        departments: [],
        lines: [],
        units: [],
        rdgGranularity: e.value,
        plantModel: {
          ...this.state.plantModel,
          departments: [],
          lines: [],
          units: [],
        },
      });
    else this.setState({ rdgGranularity: e.value });
  };

  handlerCheckBox = (e) => {
    const { chkRouteDetails, chkPlantModelDetails } = this.state;

    var chkrd, chkpm;
    chkrd = e.tag === "chkRouteDetails" ? e.value : chkRouteDetails;
    chkpm = e.tag === "chkPlantModelDetails" ? e.value : chkPlantModelDetails;

    this.setState({
      [e.tag]: e.value,
      rdgTeamsDetails: chkrd && chkpm ? 6 : chkrd ? 2 : chkpm ? 4 : 0,
    });
  };

  handlerSelectBox = (key, values) => {
    if (key.includes("teams") || key.includes("routes")) {
      this.setState({
        plantModel: { ...this.state.plantModel, [key]: values },
      });
    } else {
      let filters = updatePlantModelView(key, values, this.state);
      this.setState({ plantModel: { ...this.state.plantModel }, ...filters });
    }
  };

  handleInputDate = (e, elemName) => {
    this.setState(
      {
        [elemName]: e.value,
      },
      () => {
        // if (
        //   new Date(this.state.dtStartTime).getTime() >=
        //   new Date(this.state.dtEndTime).getTime()
        // ) {
        //   this.setState({ dtEndTime: this.state.dtStartTime });
        // }
      }
    );
  };

  setComponentsIds = () => {
    setIdsByClassName([
      {
        idContainer: "pnlTasksPlanningSelectionType",
        class: "dx-item dx-radiobutton",
        ids: ["rbnSelectionTypeTasksPlanning"],
        same: true,
      },
      {
        idContainer: "pnlTasksPlanningPlantModelSelection",
        class: "dx-item dx-radiobutton",
        ids: ["rbnGranularityTasksPlanning"],
        same: true,
      },
      {
        idContainer: "pnlTasksPlanningPeriodSelection",
        class: "dx-item dx-radiobutton",
        ids: ["rbnPeriodSelectionTasksPlanning"],
        same: true,
      },
      // SelectBox Input & Buttons
      {
        idContainer: "sboDepartmentsPlantModelTasksPlanning",
        tagName: "input",
        ids: ["txtSearchsboDepartmentsTasksPlanning"],
      },
      {
        idContainer: "sboLinesPlantModelTasksPlanning",
        tagName: "input",
        ids: ["txtSearchSboLinesTasksPlanning"],
      },
      {
        idContainer: "sboUnitsPlantModelTasksPlanning",
        tagName: "input",
        ids: ["txtSearchSboUnitsTasksPlanning"],
      },
      {
        idContainer: "sboMyteamsTasksPlanning",
        tagName: "input",
        ids: ["txtSearchSboMyTeamsTasksPlanning"],
      },
      {
        idContainer: "sboMyteamsTasksPlanning",
        tagName: "button",
        ids: ["btnSelectAllSboMyTeamsTasksPlanning"],
      },
      {
        idContainer: "sboTeamsSelectionTasksPlanning",
        tagName: "input",
        ids: ["txtSearchSboTeamsTasksPlanning"],
      },
      {
        idContainer: "sboTeamsSelectionTasksPlanning",
        tagName: "button",
        ids: ["btnSelectAllSboTeamsTasksPlanning"],
      },
      {
        idContainer: "sboMyRoutesTasksPlanning",
        tagName: "input",
        ids: ["txtSearchSboMyRoutesTasksPlanning"],
      },
      {
        idContainer: "sboMyRoutesTasksPlanning",
        tagName: "button",
        ids: ["btnSelectAllSboMyRoutesTasksPlanning"],
      },
      {
        idContainer: "sboRoutesSelectionTasksPlanning",
        tagName: "input",
        ids: ["txtSearchSboRoutesTasksPlanning"],
      },
      {
        idContainer: "sboRoutesSelectionTasksPlanning",
        tagName: "button",
        ids: ["btnSelectAllSboRoutesTasksPlanning"],
      },
    ]);
  };

  render() {
    const { t } = this.props;
    const {
      departments,
      lines,
      units,
      teams,
      myteams,
      routes,
      myroutes,
      rdgEntryType,
      rdgGranularity,
      rdgTimeFrame,
      chkRouteDetails,
      chkPlantModelDetails,
      plantModel,
      dtStartTime,
      dtEndTime,
    } = this.state;

    let globalAccessLevel = getUserRole();

    return (
      <React.Fragment>
        <div className={styles.filterContent}>
          <div>
            <Panel
              id="pnlTasksPlanningSelectionType"
              title={`1. ${t("Report Entry Point")}`}
              borderTop={false}
              borderBottom={false}
              paddingTop={0}
              paddingBottom={0}
              collapsible={false}
            >
              <label>{t("Selection Type")}</label>
              <RadioGroup
                items={[
                  {
                    text: t("Plant Model"),
                    value: "Plant Model",
                    globalAccessLevel: [1, 2, 3, 4],
                  },
                  {
                    text: t("My Teams"),
                    value: "My Teams",
                    globalAccessLevel: [1, 2, 3, 4],
                  },
                  {
                    text: t("Teams Selection"),
                    value: "Teams Selection",
                    globalAccessLevel: [3, 4],
                  },
                  {
                    text: t("My Routes"),
                    value: "My Routes",
                    globalAccessLevel: [1, 2, 3, 4],
                  },
                  {
                    text: t("Routes Selection"),
                    value: "Routes Selection",
                    globalAccessLevel: [3, 4],
                  },
                ].filter((item) =>
                  item.globalAccessLevel.includes(globalAccessLevel)
                )}
                valueExpr="value"
                displayExpr="text"
                value={rdgEntryType}
                onValueChanged={this.handlerRgdEntryType}
              />
            </Panel>
          </div>

          <div>
            {rdgEntryType === "Plant Model" && (
              <Panel
                id="pnlTasksPlanningPlantModelSelection"
                title={`2. ${t("Plant Model Selection")}`}
                borderTop={false}
                borderBottom={false}
                paddingTop={0}
                paddingBottom={0}
                collapsible={false}
              >
                <label>{t("Granularity")}</label>
                <RadioGroup
                  items={[
                    { text: t("Site"), value: GRANULARITY.Site },
                    { text: t("Department"), value: GRANULARITY.Department },
                    { text: t("Line"), value: GRANULARITY.Line },
                    { text: t("Primary Unit"), value: GRANULARITY.MasterUnit },
                  ]}
                  valueExpr="value"
                  displayExpr="text"
                  value={rdgGranularity}
                  onValueChanged={this.handlerRgdGranularity}
                />
                <div>
                  <label>{t("Selection Filter")}</label>
                  <div className={styles.plantModelSelection}>
                    <SelectBox
                      id="sboDepartmentsPlantModelTasksPlanning"
                      text={t("Department")}
                      enableSelectAll={false}
                      enableClear={false}
                      store={departments}
                      isMultiple={false}
                      className={styles.selectBoxPM}
                      value={plantModel.departments}
                      onChange={(values) =>
                        this.handlerSelectBox("departments", values)
                      }
                      labelKey="DeptDesc"
                      valueKey="DeptId"
                      isLoading={false}
                      isDisable={rdgGranularity === GRANULARITY.Site}
                      // visible={rdgGranularity !== GRANULARITY.Site}
                    />
                    <SelectBox
                      id="sboLinesPlantModelTasksPlanning"
                      text={t("Line")}
                      enableSelectAll={false}
                      enableClear={false}
                      store={lines}
                      isMultiple={false}
                      className={styles.selectBoxPM}
                      value={plantModel.lines}
                      onChange={(values) =>
                        this.handlerSelectBox("lines", values)
                      }
                      labelKey="LineDesc"
                      valueKey="LineId"
                      isLoading={false}
                      isDisable={
                        rdgGranularity === GRANULARITY.Site ||
                        rdgGranularity === GRANULARITY.Department
                      }
                      // visible={
                      //   rdgGranularity === GRANULARITY.Line ||
                      //   rdgGranularity === GRANULARITY.MasterUnit
                      // }
                    />
                    <SelectBox
                      id="sboUnitsPlantModelTasksPlanning"
                      text={t("Primary Unit")}
                      enableSelectAll={false}
                      enableClear={false}
                      store={units}
                      isMultiple={false}
                      className={styles.selectBoxPM}
                      value={plantModel.units}
                      onChange={(values) =>
                        this.handlerSelectBox("units", values)
                      }
                      labelKey="MasterDesc"
                      valueKey="MasterId"
                      isLoading={false}
                      isDisable={rdgGranularity !== GRANULARITY.MasterUnit}
                      // visible={rdgGranularity === GRANULARITY.MasterUnit}
                    />
                  </div>
                </div>
              </Panel>
            )}

            {rdgEntryType === "My Teams" && (
              <Panel
                id="pnlTasksPlanningMyTeams"
                title={`2. ${t("My Teams")}`}
                borderTop={false}
                borderBottom={false}
                paddingTop={0}
                paddingBottom={0}
                collapsible={false}
              >
                <label>{t("Team Details")}</label>
                <CheckBox
                  id="chkRouteDetailsMyTeams"
                  tag="chkRouteDetails"
                  text="Route Details"
                  value={chkRouteDetails}
                  onValueChanged={this.handlerCheckBox}
                />
                <CheckBox
                  id="chkPlantModelDetailsMyTeams"
                  tag="chkPlantModelDetails"
                  text="Plant Model Details"
                  value={chkPlantModelDetails}
                  onValueChanged={this.handlerCheckBox}
                />
                <div className={styles.plantModelSelection}>
                  <SelectBox
                    id="sboMyteamsTasksPlanning"
                    enableSelectAll={true}
                    enableClear={true}
                    store={myteams}
                    isMultiple={true}
                    className={styles.selectBoxPM}
                    value={plantModel.myteams}
                    onChange={(values) =>
                      this.handlerSelectBox("myteams", values)
                    }
                    labelKey="TeamDesc"
                    valueKey="TeamId"
                    isLoading={false}
                    isDisable={false}
                  />
                </div>
              </Panel>
            )}

            {rdgEntryType === "Teams Selection" && (
              <Panel
                id="pnlTasksPlanningTeamsSelection"
                title={`2. ${t("Teams Selection")}`}
                borderTop={false}
                borderBottom={false}
                paddingTop={0}
                paddingBottom={0}
                collapsible={false}
              >
                <label>{t("Team Details")}</label>
                <CheckBox
                  id="chkRouteDetailsTeamsSelection"
                  tag="chkRouteDetails"
                  text="Route Details"
                  value={chkRouteDetails}
                  onValueChanged={this.handlerCheckBox}
                />
                <CheckBox
                  id="chkPlantModelDetailsTeamsSelection"
                  tag="chkPlantModelDetails"
                  text="Plant Model Details"
                  value={chkPlantModelDetails}
                  onValueChanged={this.handlerCheckBox}
                />
                <div className={styles.plantModelSelection}>
                  <SelectBox
                    id="sboTeamsSelectionTasksPlanning"
                    enableSelectAll={true}
                    enableClear={true}
                    store={teams}
                    isMultiple={true}
                    className={styles.selectBoxPM}
                    value={plantModel.teams}
                    onChange={(values) =>
                      this.handlerSelectBox("teams", values)
                    }
                    labelKey="TeamDescription"
                    valueKey="TeamId"
                    isLoading={false}
                    isDisable={false}
                  />
                </div>
              </Panel>
            )}

            {rdgEntryType === "My Routes" && (
              <Panel
                id="pnlTasksPlanningMyRoutes"
                title={`2. ${t("My Routes")}`}
                borderTop={false}
                borderBottom={false}
                paddingTop={0}
                paddingBottom={0}
                collapsible={false}
              >
                <div className={styles.plantModelSelection}>
                  <SelectBox
                    id="sboMyRoutesTasksPlanning"
                    enableSelectAll={true}
                    enableClear={true}
                    store={myroutes}
                    isMultiple={true}
                    className={styles.selectBoxPM}
                    value={plantModel.myroutes}
                    onChange={(values) =>
                      this.handlerSelectBox("myroutes", values)
                    }
                    labelKey="RouteDesc"
                    valueKey="RouteId"
                    isLoading={false}
                    isDisable={false}
                  />
                </div>
              </Panel>
            )}

            {rdgEntryType === "Routes Selection" && (
              <Panel
                id="pnlTasksPlanningRoutesSelection"
                title={`2. ${t("Routes Selection")}`}
                borderTop={false}
                borderBottom={false}
                paddingTop={0}
                paddingBottom={0}
                collapsible={false}
              >
                <div>
                  <div className={styles.plantModelSelection}>
                    <SelectBox
                      id="sboRoutesSelectionTasksPlanning"
                      enableSelectAll={true}
                      enableClear={true}
                      store={routes}
                      isMultiple={true}
                      className={styles.selectBoxPM}
                      value={plantModel.routes}
                      onChange={(values) =>
                        this.handlerSelectBox("routes", values)
                      }
                      labelKey="RouteDescription"
                      valueKey="RouteId"
                      isLoading={false}
                      isDisable={false}
                    />
                  </div>
                </div>
              </Panel>
            )}
          </div>

          <div>
            <Panel
              id="pnlTasksPlanningPeriodSelection"
              title={`3. ${t("Period Selection")}`}
              borderTop={false}
              borderBottom={false}
              paddingTop={0}
              paddingBottom={0}
              collapsible={false}
            >
              <label>{t("Time Frame")}</label>
              <RadioGroup
                items={[
                  { text: t("Today"), value: CUSTOM_PERIOD.Today },
                  { text: t("Tomorrow"), value: CUSTOM_PERIOD.Tomorrow },
                  { text: t("This Week"), value: CUSTOM_PERIOD.ThisWeek },
                  { text: t("Next Week"), value: CUSTOM_PERIOD.NextWeek },
                  { text: t("This Month"), value: CUSTOM_PERIOD.ThisMonth },
                  { text: t("Next Month"), value: CUSTOM_PERIOD.NextMonth },
                  { text: t("Next 30 Days"), value: CUSTOM_PERIOD.Next30Days },
                  { text: t("User-Defined"), value: CUSTOM_PERIOD.UserDefined },
                ]}
                valueExpr="value"
                displayExpr="text"
                value={rdgTimeFrame}
                onValueChanged={this.handlerRgdTimeFrame}
              />

              {rdgTimeFrame === CUSTOM_PERIOD.UserDefined && (
                <div>
                  <label>{t("Start Time")}</label>
                  <DateTime
                    id="dtmStartTimeTasksPlanning"
                    type="datetime"
                    displayFormat="yyyy-MM-dd hh:mm aa"
                    min={dayjs(dayjs(new Date()).startOf("day"))}
                    max={dayjs(
                      new Date(
                        dayjs(dayjs(new Date()).endOf("day")).add(30, "day")
                      )
                    )}
                    value={dtStartTime}
                    onValueChanged={(e) =>
                      this.handleInputDate(e, "dtStartTime")
                    }
                  />
                  <label>{t("End Time")}</label>
                  <DateTime
                    id="dtmEndTimeTasksPlanning"
                    type="datetime"
                    displayFormat="yyyy-MM-dd hh:mm aa"
                    min={dayjs(dayjs(new Date()).startOf("day"))}
                    max={dayjs(
                      new Date(
                        dayjs(dayjs(new Date()).endOf("day")).add(30, "day")
                      )
                    )}
                    value={dtEndTime}
                    onValueChanged={(e) => this.handleInputDate(e, "dtEndTime")}
                  />
                </div>
              )}
            </Panel>
          </div>
        </div>
      </React.Fragment>
    );
  }
}

export default Filters;
